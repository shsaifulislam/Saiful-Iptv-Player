import { authenticate, isAdmin } from '../_shared/auth.ts';
import { errorResponse, isRecord, jsonResponse, preflight, readJson } from '../_shared/http.ts';
import { consumeRateLimit } from '../_shared/rate_limit.ts';

const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const severities = new Set(['info', 'warning', 'maintenance']);
const reportStatuses = new Set(['new', 'triaged', 'resolved', 'closed']);
const supportStatuses = new Set(['received', 'in_review', 'waiting_for_user', 'resolved']);
const platforms = new Set(['android', 'ios', 'windows', 'macos', 'linux', 'web']);
const secretKey = /password|username|token|secret|credential|authorization|api[_-]?key/i;

function auditRequestId(request: Request): string {
  const candidate = request.headers.get('x-request-id');
  return candidate && uuidPattern.test(candidate) ? candidate : crypto.randomUUID();
}

Deno.serve(async (request: Request): Promise<Response> => {
  const options = preflight(request);
  if (options) return options;
  if (request.method !== 'POST') return jsonResponse({ error: 'method_not_allowed' }, 405);

  try {
    const auth = await authenticate(request);
    if (auth instanceof Response) return auth;
    if (!isAdmin(auth.user)) return jsonResponse({ error: 'forbidden' }, 403);
    if (!(await consumeRateLimit(auth, 'admin_api', 120, 60))) {
      return jsonResponse({ error: 'rate_limited' }, 429);
    }

    const body = await readJson(request, 32768);
    if (!isRecord(body) || typeof body.action !== 'string') {
      return jsonResponse({ error: 'invalid_request' }, 422);
    }
    const db = auth.adminClient;
    const requestId = auditRequestId(request);

    if (body.action === 'service.health') {
      const [profiles, reports] = await Promise.all([
        db.from('profiles').select('id', { count: 'exact', head: true }),
        db.from('bug_reports').select('id', { count: 'exact', head: true }),
      ]);
      if (profiles.error || reports.error) return jsonResponse({ error: 'service_unavailable' }, 503);
      return jsonResponse({
        data: {
          status: 'healthy',
          checked_at: new Date().toISOString(),
          profile_count: profiles.count ?? 0,
          open_report_count: reports.count ?? 0,
        },
      });
    }

    if (body.action === 'users.list') {
      const page = Number.isSafeInteger(body.page) ? Math.max(1, Number(body.page)) : 1;
      const perPage = Number.isSafeInteger(body.per_page)
        ? Math.min(100, Math.max(1, Number(body.per_page)))
        : 50;
      const { data, error } = await db.auth.admin.listUsers({ page, perPage });
      if (error) return jsonResponse({ error: 'user_list_unavailable' }, 503);
      return jsonResponse({
        data: (data.users ?? []).map((user) => ({
          id: user.id,
          email: user.email ?? null,
          created_at: user.created_at,
          last_sign_in_at: user.last_sign_in_at ?? null,
          banned_until: user.banned_until ?? null,
          confirmed: Boolean(user.email_confirmed_at),
        })),
        page,
        per_page: perPage,
      });
    }

    if (body.action === 'users.set_access') {
      if (typeof body.user_id !== 'string' || !uuidPattern.test(body.user_id) ||
          typeof body.disabled !== 'boolean' || body.user_id === auth.user.id) {
        return jsonResponse({ error: 'invalid_user_action' }, 422);
      }
      const { error } = await db.auth.admin.updateUserById(body.user_id, {
        ban_duration: body.disabled ? '876000h' : 'none',
      });
      if (error) return jsonResponse({ error: 'user_update_failed' }, 400);
      await db.from('admin_audit_log').insert({
        actor_id: auth.user.id,
        target_user_id: body.user_id,
        action: body.disabled ? 'user.access_disabled' : 'user.access_enabled',
        request_id: requestId,
        metadata: {},
      });
      return jsonResponse({ data: { user_id: body.user_id, disabled: body.disabled } });
    }

    if (body.action === 'users.delete') {
      if (typeof body.user_id !== 'string' || !uuidPattern.test(body.user_id) ||
          body.user_id === auth.user.id || body.confirm_user_id !== body.user_id) {
        return jsonResponse({ error: 'explicit_user_confirmation_required' }, 422);
      }
      const { error: auditError } = await db.from('admin_audit_log').insert({
        actor_id: auth.user.id,
        target_user_id: body.user_id,
        action: 'user.deleted_by_admin',
        request_id: requestId,
        metadata: {},
      });
      if (auditError) return jsonResponse({ error: 'user_delete_unavailable' }, 503);

      const avatarBucket = db.storage.from('profile-avatars');
      let offset = 0;
      while (true) {
        const { data: objects, error: listError } = await avatarBucket.list(body.user_id, {
          limit: 100,
          offset,
        });
        if (listError) return jsonResponse({ error: 'user_delete_unavailable' }, 503);
        if (!objects || objects.length === 0) break;
        const { error: removeError } = await avatarBucket.remove(
          objects.map((object) => `${body.user_id}/${object.name}`),
        );
        if (removeError) return jsonResponse({ error: 'user_delete_unavailable' }, 503);
        offset += objects.length;
      }
      const { error } = await db.auth.admin.deleteUser(body.user_id);
      if (error) return jsonResponse({ error: 'user_delete_unavailable' }, 503);
      return jsonResponse({ data: { user_id: body.user_id, deleted: true } });
    }

    if (body.action === 'devices.list') {
      const { data, error } = await db.from('devices')
        .select('id,user_id,device_name,platform,app_version,last_seen_at,revoked_at,created_at')
        .order('last_seen_at', { ascending: false })
        .limit(500);
      if (error) return jsonResponse({ error: 'device_list_unavailable' }, 503);
      return jsonResponse({ data });
    }

    if (body.action === 'devices.revoke') {
      if (typeof body.device_id !== 'string' || !uuidPattern.test(body.device_id)) {
        return jsonResponse({ error: 'invalid_device' }, 422);
      }
      const { data, error } = await db.from('devices')
        .update({ revoked_at: new Date().toISOString() })
        .eq('id', body.device_id)
        .select('id,user_id,revoked_at')
        .single();
      if (error || !data) return jsonResponse({ error: 'device_not_found' }, 404);
      await db.from('admin_audit_log').insert({
        actor_id: auth.user.id,
        target_user_id: data.user_id,
        target_record_id: data.id,
        action: 'device.revoked_by_admin',
        request_id: requestId,
        metadata: {},
      });
      return jsonResponse({ data });
    }

    if (body.action === 'announcements.list') {
      const { data, error } = await db.from('app_announcements')
        .select('id,title,body,severity,locale,platforms,published,starts_at,ends_at,created_at,updated_at')
        .order('starts_at', { ascending: false })
        .limit(200);
      if (error) return jsonResponse({ error: 'announcement_list_unavailable' }, 503);
      return jsonResponse({ data });
    }

    if (body.action === 'announcements.save') {
      if (typeof body.title !== 'string' || body.title.trim().length < 1 || body.title.length > 160 ||
          typeof body.body !== 'string' || body.body.trim().length < 1 || body.body.length > 4000 ||
          typeof body.severity !== 'string' || !severities.has(body.severity) ||
          typeof body.locale !== 'string' || body.locale.length < 2 || body.locale.length > 20 ||
          typeof body.published !== 'boolean' || !Array.isArray(body.platforms) ||
          body.platforms.some((value) => typeof value !== 'string' || !platforms.has(value)) ||
          (body.id !== undefined && (typeof body.id !== 'string' || !uuidPattern.test(body.id)))) {
        return jsonResponse({ error: 'invalid_announcement' }, 422);
      }
      const announcement = {
        title: body.title.trim(),
        body: body.body.trim(),
        severity: body.severity,
        locale: body.locale,
        platforms: body.platforms,
        published: body.published,
        starts_at: typeof body.starts_at === 'string' ? body.starts_at : new Date().toISOString(),
        ends_at: typeof body.ends_at === 'string' && body.ends_at.length > 0 ? body.ends_at : null,
        created_by: auth.user.id,
      };
      const query = typeof body.id === 'string'
        ? db.from('app_announcements').update(announcement).eq('id', body.id)
        : db.from('app_announcements').insert(announcement);
      const { data, error } = await query.select('id,title,severity,locale,published,starts_at,ends_at').single();
      if (error) return jsonResponse({ error: 'announcement_save_failed' }, 400);
      await db.from('admin_audit_log').insert({
        actor_id: auth.user.id,
        target_record_id: data.id,
        action: 'announcement.saved',
        request_id: requestId,
        metadata: { published: data.published },
      });
      return jsonResponse({ data });
    }

    if (body.action === 'bug_reports.list') {
      const { data, error } = await db.from('bug_reports')
        .select('id,owner_id,category,summary,description,app_version,platform,diagnostics_opt_in,status,support_status,created_at,updated_at')
        .order('created_at', { ascending: false })
        .limit(200);
      if (error) return jsonResponse({ error: 'report_list_unavailable' }, 503);
      return jsonResponse({ data });
    }

    if (body.action === 'bug_reports.update') {
      if (typeof body.report_id !== 'string' || !uuidPattern.test(body.report_id) ||
          (body.status !== undefined && (typeof body.status !== 'string' || !reportStatuses.has(body.status))) ||
          (body.support_status !== undefined && (typeof body.support_status !== 'string' || !supportStatuses.has(body.support_status)))) {
        return jsonResponse({ error: 'invalid_report_update' }, 422);
      }
      const updates: Record<string, unknown> = {};
      if (body.status !== undefined) updates.status = body.status;
      if (body.support_status !== undefined) updates.support_status = body.support_status;
      const { data, error } = await db.from('bug_reports')
        .update(updates)
        .eq('id', body.report_id)
        .select('id,status,support_status,updated_at')
        .single();
      if (error) return jsonResponse({ error: 'report_update_failed' }, 400);
      await db.from('admin_audit_log').insert({
        actor_id: auth.user.id,
        target_record_id: data.id,
        action: 'bug_report.triaged',
        request_id: requestId,
        metadata: { status: data.status, support_status: data.support_status },
      });
      return jsonResponse({ data });
    }

    if (body.action === 'features.list') {
      const { data, error } = await db.from('feature_config')
        .select('feature_key,enabled,config,updated_at')
        .order('feature_key')
        .limit(200);
      if (error) return jsonResponse({ error: 'feature_list_unavailable' }, 503);
      return jsonResponse({ data });
    }

    if (body.action === 'features.set') {
      if (typeof body.feature_key !== 'string' ||
          !/^[a-z][a-z0-9_.-]{1,80}$/.test(body.feature_key) ||
          typeof body.enabled !== 'boolean' || !isRecord(body.config) ||
          JSON.stringify(body.config).length > 8192 ||
          Object.keys(body.config).some((key) => secretKey.test(key))) {
        return jsonResponse({ error: 'invalid_feature_config' }, 422);
      }
      const { data, error } = await db.from('feature_config').upsert({
        feature_key: body.feature_key,
        enabled: body.enabled,
        config: body.config,
        updated_by: auth.user.id,
      }).select('feature_key,enabled,config,updated_at').single();
      if (error) return jsonResponse({ error: 'feature_update_failed' }, 400);
      await db.from('admin_audit_log').insert({
        actor_id: auth.user.id,
        action: 'feature_config.updated',
        request_id: requestId,
        metadata: { feature_key: data.feature_key, enabled: data.enabled },
      });
      return jsonResponse({ data });
    }

    if (body.action === 'version.get') {
      const { data, error } = await db.from('app_release_info')
        .select('latest_version,minimum_supported_version,force_update,update_url,updated_at')
        .eq('singleton', true)
        .single();
      if (error) return jsonResponse({ error: 'version_info_unavailable' }, 503);
      return jsonResponse({ data });
    }

    if (body.action === 'version.set') {
      const versionPattern = /^\d+\.\d+\.\d+(?:\+[0-9]+)?$/;
      if (typeof body.latest_version !== 'string' || !versionPattern.test(body.latest_version) ||
          typeof body.minimum_supported_version !== 'string' ||
          !versionPattern.test(body.minimum_supported_version) ||
          typeof body.force_update !== 'boolean' ||
          (body.update_url !== undefined && body.update_url !== null &&
            (typeof body.update_url !== 'string' || !body.update_url.startsWith('https://')))) {
        return jsonResponse({ error: 'invalid_version_info' }, 422);
      }
      const { data, error } = await db.from('app_release_info').upsert({
        singleton: true,
        latest_version: body.latest_version,
        minimum_supported_version: body.minimum_supported_version,
        force_update: body.force_update,
        update_url: body.update_url ?? null,
        updated_by: auth.user.id,
      }).select('latest_version,minimum_supported_version,force_update,update_url,updated_at').single();
      if (error) return jsonResponse({ error: 'version_update_failed' }, 400);
      await db.from('admin_audit_log').insert({
        actor_id: auth.user.id,
        action: 'app_version.updated',
        request_id: requestId,
        metadata: { latest_version: data.latest_version, force_update: data.force_update },
      });
      return jsonResponse({ data });
    }

    return jsonResponse({ error: 'unknown_action' }, 404);
  } catch (error) {
    return errorResponse(error);
  }
});
