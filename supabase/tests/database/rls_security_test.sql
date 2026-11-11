begin;
create extension if not exists pgtap with schema extensions;
select plan(10);

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('10000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'owner-a@example.invalid', 'test-hash-a', now(), '{}'::jsonb, '{}'::jsonb, now(), now()),
  ('20000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'owner-b@example.invalid', 'test-hash-b', now(), '{}'::jsonb, '{}'::jsonb, now(), now())
on conflict (id) do nothing;

set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claims', '{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated","app_metadata":{}}', true);

select is(
  (select count(*)::integer from public.profiles where id = '10000000-0000-4000-8000-000000000001'),
  1,
  'owner can read own profile'
);
select is(
  (select count(*)::integer from public.profiles where id = '20000000-0000-4000-8000-000000000002'),
  0,
  'owner cannot read another profile'
);
select is(public.is_app_admin(), false, 'user metadata cannot grant admin role');

select lives_ok(
  $$select public.register_device(repeat('a', 64), 'test device a', 'android', 'test')$$,
  'authenticated user can register a device'
);

select lives_ok(
  $$select public.apply_sync_changes(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    '[{"idempotency_key":"30000000-0000-4000-8000-000000000003","entity_type":"playlist","entity_id":"40000000-0000-4000-8000-000000000004","operation":"upsert","base_revision":0,"payload":{"name":"Channels","source_kind":"m3u_file","enabled":true}}]'::jsonb
  )$$,
  'owner can sync valid playlist metadata'
);

select is(
  (public.apply_sync_changes(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    '[{"idempotency_key":"30000000-0000-4000-8000-000000000003","entity_type":"playlist","entity_id":"40000000-0000-4000-8000-000000000004","operation":"upsert","base_revision":0,"payload":{"name":"Channels","source_kind":"m3u_file","enabled":true}}]'::jsonb
  ) -> 'accepted' -> 0 ->> 'duplicate'),
  'true',
  'idempotency key prevents duplicate sync writes'
);

select is(
  (public.apply_sync_changes(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    '[{"idempotency_key":"50000000-0000-4000-8000-000000000005","entity_type":"playlist","entity_id":"40000000-0000-4000-8000-000000000004","operation":"upsert","base_revision":0,"payload":{"name":"Stale","source_kind":"m3u_file","enabled":true}}]'::jsonb
  ) -> 'conflicts' -> 0 ->> 'server_revision'),
  '1',
  'stale revision is reported as a sync conflict'
);

select throws_ok(
  $$select public.register_device(repeat('b', 64), 'bad device', 'tizen', 'test')$$,
  '22023',
  'invalid_device',
  'invalid platform is rejected'
);

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub', '20000000-0000-4000-8000-000000000002', true);
select set_config('request.jwt.claims', '{"sub":"20000000-0000-4000-8000-000000000002","role":"authenticated","app_metadata":{}}', true);

select is(
  (select count(*)::integer from public.devices where user_id = '10000000-0000-4000-8000-000000000001'),
  0,
  'device inventory is isolated by owner'
);
select throws_ok(
  $$select public.apply_sync_changes(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    '[{"idempotency_key":"60000000-0000-4000-8000-000000000006","entity_type":"playlist","entity_id":"70000000-0000-4000-8000-000000000007","operation":"upsert","base_revision":0,"payload":{"name":"Not mine","source_kind":"m3u_file"}}]'::jsonb
  )$$,
  '42501',
  'device_not_authorized',
  'another user cannot sync through the owner device'
);

select * from finish();
rollback;
