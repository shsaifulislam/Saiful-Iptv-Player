import { authenticate } from '../_shared/auth.ts';
import { errorResponse, isRecord, jsonResponse, preflight, readJson } from '../_shared/http.ts';
import { consumeRateLimit } from '../_shared/rate_limit.ts';

const categories = new Set(['playback', 'playlist', 'account', 'sync', 'accessibility', 'other']);
const platforms = new Set(['android', 'windows', 'macos', 'linux', 'web']);
const forbiddenKeys = new Set([
  'password', 'username', 'token', 'access_token', 'refresh_token',
  'api_key', 'service_role_key', 'authorization', 'stream_url',
  'source_url', 'playlist_url', 'epg_url', 'credentials',
]);
const secretText = /\b(password|passcode|token|api[_ -]?key|authorization)\b\s*[:=]\s*[^\s,;]+/i;
const credentialUrl = /https?:\/\/[^/\s:@]+:[^/\s@]+@/i;

function hasSecret(value: unknown): boolean {
  if (Array.isArray(value)) return value.some(hasSecret);
  if (!isRecord(value)) {
    return typeof value === 'string' && (secretText.test(value) || credentialUrl.test(value));
  }
  return Object.entries(value).some(([key, child]) =>
    forbiddenKeys.has(key.toLowerCase()) || hasSecret(child));
}

Deno.serve(async (request: Request): Promise<Response> => {
  const options = preflight(request);
  if (options) return options;
  if (request.method !== 'POST') return jsonResponse({ error: 'method_not_allowed' }, 405);

  try {
    const auth = await authenticate(request);
    if (auth instanceof Response) return auth;
    if (!(await consumeRateLimit(auth, 'bug_report', 5, 3600))) {
      return jsonResponse({ error: 'rate_limited' }, 429);
    }

    const body = await readJson(request, 24 * 1024);
    if (!isRecord(body) ||
        typeof body.client_idempotency_key !== 'string' ||
        !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(body.client_idempotency_key) ||
        typeof body.category !== 'string' || !categories.has(body.category) ||
        typeof body.summary !== 'string' || body.summary.trim().length < 1 || body.summary.length > 160 ||
        typeof body.description !== 'string' || body.description.trim().length < 1 || body.description.length > 8000 ||
        typeof body.app_version !== 'string' || body.app_version.length > 40 ||
        typeof body.platform !== 'string' || !platforms.has(body.platform) ||
        typeof body.diagnostics_opt_in !== 'boolean' ||
        (body.diagnostics !== undefined && !isRecord(body.diagnostics)) || hasSecret(body)) {
      return jsonResponse({ error: 'invalid_or_sensitive_report' }, 422);
    }

    const { data, error } = await auth.userClient.rpc('submit_bug_report', {
      p_client_idempotency_key: body.client_idempotency_key,
      p_category: body.category,
      p_summary: body.summary.trim(),
      p_description: body.description.trim(),
      p_app_version: body.app_version,
      p_platform: body.platform,
      p_diagnostics_opt_in: body.diagnostics_opt_in,
      p_diagnostics: body.diagnostics_opt_in ? (body.diagnostics ?? {}) : {},
    });
    if (error || !data) return jsonResponse({ error: 'report_rejected' }, 422);
    return jsonResponse({
      data: { id: data.id, status: data.status, support_status: data.support_status, created_at: data.created_at },
    }, 202);
  } catch (error) {
    return errorResponse(error);
  }
});
