import { createClient, type SupabaseClient, type User } from 'npm:@supabase/supabase-js@2';

export type AuthContext = {
  user: User;
  userClient: SupabaseClient;
  adminClient: SupabaseClient;
};

export function makeAdminClient(): SupabaseClient {
  const url = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !serviceRoleKey) throw new Error('server_configuration_error');
  return createClient(url, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

export async function authenticate(request: Request): Promise<AuthContext | Response> {
  const authorization = request.headers.get('authorization');
  const match = authorization?.match(/^Bearer\s+([^\s]+)$/i);
  const url = Deno.env.get('SUPABASE_URL');
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
  if (!match || !url || !anonKey) {
    return new Response(JSON.stringify({ error: 'unauthorized' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const token = match[1];
  const userClient = createClient(url, anonKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data, error } = await userClient.auth.getUser(token);
  if (error || !data.user) {
    return new Response(JSON.stringify({ error: 'unauthorized' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  return { user: data.user, userClient, adminClient: makeAdminClient() };
}

export function isAdmin(user: User): boolean {
  return user.app_metadata?.role === 'admin';
}
