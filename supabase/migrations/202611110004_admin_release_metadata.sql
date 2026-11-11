begin;

create table public.app_release_info (
  singleton boolean primary key default true check (singleton),
  latest_version text not null,
  minimum_supported_version text not null,
  force_update boolean not null default false,
  update_url text,
  updated_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now(),
  constraint release_latest_len check (char_length(latest_version) between 1 and 32),
  constraint release_minimum_len check (char_length(minimum_supported_version) between 1 and 32),
  constraint release_url_https check (update_url is null or update_url ~ '^https://')
);

insert into public.app_release_info(singleton, latest_version, minimum_supported_version)
values (true, '1.0.0', '1.0.0')
on conflict (singleton) do nothing;

alter table public.app_release_info enable row level security;
create policy release_info_read on public.app_release_info
  for select to anon, authenticated using (true);
create policy release_info_admin_write on public.app_release_info
  for all to authenticated
  using (public.is_app_admin()) with check (public.is_app_admin());
revoke all on public.app_release_info from anon, authenticated;
grant select on public.app_release_info to anon, authenticated;
grant update on public.app_release_info to authenticated;

commit;
