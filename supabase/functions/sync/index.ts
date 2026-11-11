import { authenticate } from '../_shared/auth.ts';
import { errorResponse, isRecord, jsonResponse, preflight, readJson } from '../_shared/http.ts';
import { consumeRateLimit } from '../_shared/rate_limit.ts';

const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const supportedEntities = new Set([
  'playlist', 'channel', 'favorite', 'watch_history', 'watch_progress', 'setting',
]);
const forbiddenKeys = new Set([
  'password', 'username', 'token', 'access_token', 'refresh_token',
  'api_key', 'service_role_key', 'authorization', 'stream_url',
  'source_url', 'playlist_url', 'epg_url', 'credentials',
]);

function containsForbiddenKey(value: unknown): boolean {
  if (Array.isArray(value)) return value.some(containsForbiddenKey);
  if (!isRecord(value)) return false;
  return Object.entries(value).some(([key, child]) =>
    forbiddenKeys.has(key.toLowerCase()) || containsForbiddenKey(child));
}

function validateChange(value: unknown): value is Record<string, unknown> {
  if (!isRecord(value) || !isRecord(value.payload)) return false;
  if (typeof value.idempotency_key !== 'string' || !uuidPattern.test(value.idempotency_key)) return false;
  if (typeof value.entity_id !== 'string' || !uuidPattern.test(value.entity_id)) return false;
  if (typeof value.entity_type !== 'string' || !supportedEntities.has(value.entity_type)) return false;
  if (value.operation !== 'upsert' && value.operation !== 'delete') return false;
  if (containsForbiddenKey(value.payload)) return false;
  if (new TextEncoder().encode(JSON.stringify(value.payload)).byteLength > 32768) return false;
  if (value.base_revision !== undefined &&
      (!Number.isSafeInteger(value.base_revision) || (value.base_revision as number) < 0)) return false;

  const payload = value.payload;
  if (value.entity_type === 'playlist' && value.operation === 'upsert') {
    if (typeof payload.name !== 'string' || payload.name.trim().length < 1 || payload.name.length > 120) return false;
    if (!['m3u_url', 'm3u_file', 'authorized_provider'].includes(String(payload.source_kind))) return false;
    if (payload.source_host !== undefined && payload.source_host !== null &&
        (typeof payload.source_host !== 'string' || !/^[A-Za-z0-9.-]{1,253}$/.test(payload.source_host))) return false;
  }
  if (value.entity_type === 'channel' && value.operation === 'upsert') {
    if (typeof payload.playlist_id !== 'string' || !uuidPattern.test(payload.playlist_id)) return false;
    if (typeof payload.name !== 'string' || payload.name.trim().length < 1 || payload.name.length > 240) return false;
    if (!['live', 'movie', 'series'].includes(String(payload.stream_kind))) return false;
    if (payload.logo_url !== undefined && payload.logo_url !== null &&
        (typeof payload.logo_url !== 'string' || !payload.logo_url.startsWith('https://'))) return false;
  }
  if (value.entity_type === 'favorite' && value.operation === 'upsert') {
    if (!['channel', 'movie'].includes(String(payload.target_type)) ||
        typeof payload.target_id !== 'string' || !uuidPattern.test(payload.target_id)) return false;
  }
  if (value.entity_type === 'watch_history' || value.entity_type === 'watch_progress') {
    if (value.operation === 'upsert' &&
        (!['channel', 'movie'].includes(String(payload.target_type)) ||
         typeof payload.target_id !== 'string' || !uuidPattern.test(payload.target_id) ||
         !Number.isSafeInteger(payload.position_seconds) || (payload.position_seconds as number) < 0)) return false;
  }
  if (value.entity_type === 'setting' && value.operation === 'upsert') {
    if (payload.theme !== undefined && !['dark', 'system', 'light'].includes(String(payload.theme))) return false;
    if (payload.settings !== undefined && !isRecord(payload.settings)) return false;
  }
  return true;
}

Deno.serve(async (request: Request): Promise<Response> => {
  const options = preflight(request);
  if (options) return options;
  if (request.method !== 'GET' && request.method !== 'POST') {
    return jsonResponse({ error: 'method_not_allowed' }, 405);
  }

  try {
    const auth = await authenticate(request);
    if (auth instanceof Response) return auth;
    if (!(await consumeRateLimit(auth, `sync_${request.method.toLowerCase()}`, 120, 60))) {
      return jsonResponse({ error: 'rate_limited' }, 429);
    }

    if (request.method === 'GET') {
      const params = new URL(request.url).searchParams;
      const deviceId = params.get('device_id') ?? '';
      const cursorText = params.get('cursor') ?? '0';
      const cursor = Number(cursorText);
      if (!uuidPattern.test(deviceId) || !Number.isSafeInteger(cursor) || cursor < 0) {
        return jsonResponse({ error: 'invalid_cursor_or_device' }, 422);
      }
      const { data: device, error: deviceError } = await auth.userClient
        .from('devices')
        .select('id')
        .eq('id', deviceId)
        .is('revoked_at', null)
        .maybeSingle();
      if (deviceError || !device) return jsonResponse({ error: 'device_not_authorized' }, 403);

      const { data, error } = await auth.userClient
        .from('sync_events')
        .select('id,entity_type,entity_id,operation,revision,payload,created_at')
        .gt('id', cursor)
        .order('id', { ascending: true })
        .limit(500);
      if (error) return jsonResponse({ error: 'sync_unavailable' }, 503);
      const events = data ?? [];
      return jsonResponse({
        events,
        next_cursor: events.length > 0 ? events[events.length - 1].id : cursor,
      });
    }

    const body = await readJson(request, 1024 * 1024);
    if (!isRecord(body) || typeof body.device_id !== 'string' ||
        !uuidPattern.test(body.device_id) || !Array.isArray(body.changes) ||
        body.changes.length < 1 || body.changes.length > 100 ||
        !body.changes.every(validateChange)) {
      return jsonResponse({ error: 'invalid_sync_batch' }, 422);
    }
    const { data: result, error } = await auth.userClient.rpc('apply_sync_changes', {
      p_device_id: body.device_id,
      p_changes: body.changes,
    });
    if (error) return jsonResponse({ error: 'sync_rejected' }, 400);
    return jsonResponse({ data: result });
  } catch (error) {
    return errorResponse(error);
  }
});
