import type { AuthContext } from './auth.ts';

export async function consumeRateLimit(
  context: AuthContext,
  action: string,
  limit: number,
  windowSeconds: number,
): Promise<boolean> {
  const { data, error } = await context.adminClient.rpc('consume_rate_limit', {
    p_subject_id: context.user.id,
    p_action: action,
    p_limit: limit,
    p_window_seconds: windowSeconds,
  });
  return !error && data === true;
}
