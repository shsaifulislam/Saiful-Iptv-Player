export const corsHeaders = {
  'Access-Control-Allow-Origin': Deno.env.get('APP_ALLOWED_ORIGIN') ?? '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, x-client-info, content-type, idempotency-key',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
  'Content-Type': 'application/json; charset=utf-8',
};

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}

export function preflight(request: Request): Response | null {
  return request.method === 'OPTIONS'
    ? new Response('ok', { headers: corsHeaders })
    : null;
}

export async function readJson(request: Request, maxBytes = 65536): Promise<unknown> {
  const contentLength = Number(request.headers.get('content-length') ?? '0');
  if (contentLength > maxBytes) throw new Error('payload_too_large');
  const text = await request.text();
  if (new TextEncoder().encode(text).byteLength > maxBytes) {
    throw new Error('payload_too_large');
  }
  try {
    return JSON.parse(text) as unknown;
  } catch {
    throw new Error('invalid_json');
  }
}

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

export function errorResponse(error: unknown): Response {
  const message = error instanceof Error ? error.message : 'request_failed';
  if (message === 'payload_too_large') return jsonResponse({ error: 'payload_too_large' }, 413);
  if (message === 'invalid_json') return jsonResponse({ error: 'invalid_json' }, 400);
  return jsonResponse({ error: 'request_failed' }, 400);
}
