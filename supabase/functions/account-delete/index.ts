import { authenticate } from '../_shared/auth.ts';
import { errorResponse, isRecord, jsonResponse, preflight, readJson } from '../_shared/http.ts';
import { consumeRateLimit } from '../_shared/rate_limit.ts';
import { createClient } from 'npm:@supabase/supabase-js@2';

Deno.serve(async (request: Request): Promise<Response> => {
  const options = preflight(request);
  if (options) return options;
  if (request.method !== 'POST') return jsonResponse({ error: 'method_not_allowed' }, 405);

  try {
    const auth = await authenticate(request);
    if (auth instanceof Response) return auth;
    if (!(await consumeRateLimit(auth, 'account_delete', 2, 86400))) {
      return jsonResponse({ error: 'rate_limited' }, 429);
    }

    const body = await readJson(request, 4096);
    if (!isRecord(body) || typeof body.password !== 'string' ||
        body.password.length < 1 || body.password.length > 1024) {
      return jsonResponse({ error: 'reauthentication_required' }, 422);
    }
    if (!auth.user.email) return jsonResponse({ error: 'reauthentication_unavailable' }, 403);

    const url = Deno.env.get('SUPABASE_URL');
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
    if (!url || !anonKey) return jsonResponse({ error: 'server_configuration_error' }, 503);
    const reauthClient = createClient(url, anonKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { error: reauthError } = await reauthClient.auth.signInWithPassword({
      email: auth.user.email,
      password: body.password,
    });
    if (reauthError) return jsonResponse({ error: 'reauthentication_failed' }, 403);

    const requestId = crypto.randomUUID();
    const avatarBucket = auth.adminClient.storage.from('profile-avatars');
    let offset = 0;
    while (true) {
      const { data: objects, error: listError } = await avatarBucket.list(auth.user.id, {
        limit: 100,
        offset,
      });
      if (listError) return jsonResponse({ error: 'account_deletion_unavailable' }, 503);
      if (!objects || objects.length === 0) break;
      const paths = objects.map((object) => `${auth.user.id}/${object.name}`);
      const { error: removeError } = await avatarBucket.remove(paths);
      if (removeError) return jsonResponse({ error: 'account_deletion_unavailable' }, 503);
      offset += objects.length;
    }

    const { error: auditError } = await auth.adminClient.from('admin_audit_log').insert({
      actor_id: auth.user.id,
      target_user_id: auth.user.id,
      action: 'account.delete_requested',
      request_id: requestId,
      metadata: { method: 'password_reauthenticated' },
    });
    if (auditError) return jsonResponse({ error: 'account_deletion_unavailable' }, 503);

    const { error: deleteError } = await auth.adminClient.auth.admin.deleteUser(auth.user.id);
    if (deleteError) return jsonResponse({ error: 'account_deletion_unavailable' }, 503);
    return jsonResponse({ data: { request_id: requestId, deleted: true } });
  } catch (error) {
    return errorResponse(error);
  }
});
