import { authenticate } from '../_shared/auth.ts';
import { errorResponse, isRecord, jsonResponse, preflight, readJson } from '../_shared/http.ts';
import { consumeRateLimit } from '../_shared/rate_limit.ts';

const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

Deno.serve(async (request: Request): Promise<Response> => {
  const options = preflight(request);
  if (options) return options;
  if (request.method !== 'POST') return jsonResponse({ error: 'method_not_allowed' }, 405);

  try {
    const auth = await authenticate(request);
    if (auth instanceof Response) return auth;
    if (!(await consumeRateLimit(auth, 'device_revoke', 10, 3600))) {
      return jsonResponse({ error: 'rate_limited' }, 429);
    }

    const body = await readJson(request, 2048);
    if (!isRecord(body) || typeof body.device_id !== 'string' || !uuidPattern.test(body.device_id)) {
      return jsonResponse({ error: 'invalid_device' }, 422);
    }

    const { data, error } = await auth.userClient.rpc('revoke_device', {
      p_device_id: body.device_id,
    });
    if (error) return jsonResponse({ error: 'device_not_found' }, 404);
    return jsonResponse({ device_id: body.device_id, revoked_at: data });
  } catch (error) {
    return errorResponse(error);
  }
});
