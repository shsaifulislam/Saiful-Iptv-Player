import { authenticate } from '../_shared/auth.ts';
import { errorResponse, isRecord, jsonResponse, preflight, readJson } from '../_shared/http.ts';
import { consumeRateLimit } from '../_shared/rate_limit.ts';

const platforms = new Set(['android', 'ios', 'windows', 'macos', 'linux', 'web']);

Deno.serve(async (request: Request): Promise<Response> => {
  const options = preflight(request);
  if (options) return options;
  if (request.method !== 'POST') return jsonResponse({ error: 'method_not_allowed' }, 405);

  try {
    const auth = await authenticate(request);
    if (auth instanceof Response) return auth;
    if (!(await consumeRateLimit(auth, 'device_register', 10, 3600))) {
      return jsonResponse({ error: 'rate_limited' }, 429);
    }

    const body = await readJson(request, 4096);
    if (!isRecord(body) ||
        typeof body.installation_id_hash !== 'string' ||
        !/^[0-9a-f]{64}$/.test(body.installation_id_hash) ||
        typeof body.device_name !== 'string' ||
        body.device_name.trim().length < 1 || body.device_name.length > 80 ||
        typeof body.platform !== 'string' || !platforms.has(body.platform) ||
        (body.app_version !== undefined && typeof body.app_version !== 'string')) {
      return jsonResponse({ error: 'invalid_device' }, 422);
    }

    const { data, error } = await auth.userClient.rpc('register_device', {
      p_installation_id_hash: body.installation_id_hash,
      p_device_name: body.device_name.trim(),
      p_platform: body.platform,
      p_app_version: typeof body.app_version === 'string' ? body.app_version : null,
    });
    if (error) return jsonResponse({ error: 'device_registration_failed' }, 400);
    return jsonResponse({ data }, 201);
  } catch (error) {
    return errorResponse(error);
  }
});
