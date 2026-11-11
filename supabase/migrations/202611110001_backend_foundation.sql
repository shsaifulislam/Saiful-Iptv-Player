begin;

create extension if not exists pgcrypto with schema extensions;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  locale text not null default 'en',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_display_name_len check (display_name is null or char_length(display_name) between 1 and 80),
  constraint profiles_locale_len check (char_length(locale) between 2 and 20),
  constraint profiles_avatar_https check (avatar_url is null or avatar_url ~ '^https://')
);

create table public.devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  installation_id_hash text not null,
  device_name text not null,
  platform text not null,
  app_version text,
  last_seen_at timestamptz not null default now(),
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  constraint devices_id_owner_unique unique (id, user_id),
  constraint devices_install_hash check (installation_id_hash ~ '^[0-9a-f]{64}$'),
  constraint devices_name_len check (char_length(device_name) between 1 and 80),
  constraint devices_platform_check check (platform in ('android', 'ios', 'windows', 'macos', 'linux', 'web')),
  constraint devices_revoked_after_create check (revoked_at is null or revoked_at >= created_at),
  constraint devices_user_install_unique unique (user_id, installation_id_hash)
);
create index devices_user_seen_idx on public.devices(user_id, last_seen_at desc);

create table public.user_settings (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  theme text not null default 'system',
  locale text not null default 'en',
  settings jsonb not null default '{}'::jsonb,
  schema_version integer not null default 1,
  revision bigint not null default 1,
  updated_at timestamptz not null default now(),
  constraint user_settings_theme_check check (theme in ('dark', 'system', 'light')),
  constraint user_settings_json_object check (jsonb_typeof(settings) = 'object'),
  constraint user_settings_payload_size check (octet_length(settings::text) <= 8192),
  constraint user_settings_schema_positive check (schema_version > 0),
  constraint user_settings_revision_positive check (revision > 0),
  constraint user_settings_locale_len check (char_length(locale) between 2 and 20)
);

create table public.playlists (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  source_kind text not null,
  source_host text,
  credentials_required boolean not null default false,
  enabled boolean not null default true,
  sort_order integer not null default 0,
  revision bigint not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint playlists_id_owner_unique unique (id, owner_id),
  constraint playlists_name_len check (char_length(name) between 1 and 120),
  constraint playlists_kind_check check (source_kind in ('m3u_url', 'm3u_file', 'authorized_provider')),
  constraint playlists_host_check check (source_host is null or source_host ~ '^[A-Za-z0-9.-]{1,253}$'),
  constraint playlists_revision_positive check (revision > 0)
);
create index playlists_owner_sort_idx on public.playlists(owner_id, sort_order, created_at);

create table public.channels (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  playlist_id uuid not null,
  provider_item_id text,
  name text not null,
  group_title text,
  logo_url text,
  tvg_id text,
  stream_kind text not null default 'live',
  sort_order integer not null default 0,
  revision bigint not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint channels_id_owner_unique unique (id, owner_id),
  constraint channels_playlist_owner_fk foreign key (playlist_id, owner_id)
    references public.playlists(id, owner_id) on delete cascade,
  constraint channels_name_len check (char_length(name) between 1 and 240),
  constraint channels_group_len check (group_title is null or char_length(group_title) <= 160),
  constraint channels_kind_check check (stream_kind in ('live', 'movie', 'series')),
  constraint channels_logo_https check (logo_url is null or logo_url ~ '^https://'),
  constraint channels_revision_positive check (revision > 0)
);
create index channels_playlist_order_idx on public.channels(owner_id, playlist_id, sort_order);
create index channels_group_idx on public.channels(owner_id, playlist_id, group_title);
create unique index channels_provider_item_unique on public.channels(playlist_id, provider_item_id)
  where provider_item_id is not null;

create table public.movie_metadata (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  playlist_id uuid,
  provider_item_id text,
  title text not null,
  synopsis text,
  release_year integer,
  rating numeric(3,1),
  genres text[] not null default '{}',
  duration_seconds integer,
  poster_url text,
  backdrop_url text,
  revision bigint not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint movie_metadata_id_owner_unique unique (id, owner_id),
  constraint movie_metadata_playlist_owner_fk foreign key (playlist_id, owner_id)
    references public.playlists(id, owner_id) on delete cascade,
  constraint movie_title_len check (char_length(title) between 1 and 240),
  constraint movie_year_check check (release_year is null or release_year between 1888 and 2200),
  constraint movie_rating_check check (rating is null or rating between 0 and 10),
  constraint movie_duration_check check (duration_seconds is null or duration_seconds >= 0),
  constraint movie_poster_https check (poster_url is null or poster_url ~ '^https://'),
  constraint movie_backdrop_https check (backdrop_url is null or backdrop_url ~ '^https://'),
  constraint movie_revision_positive check (revision > 0)
);
create index movie_metadata_owner_title_idx on public.movie_metadata(owner_id, lower(title));
create unique index movie_metadata_provider_item_unique on public.movie_metadata(playlist_id, provider_item_id)
  where playlist_id is not null and provider_item_id is not null;

create table public.favorites (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  channel_id uuid,
  movie_id uuid,
  revision bigint not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint favorites_id_owner_unique unique (id, owner_id),
  constraint favorites_one_target check (num_nonnulls(channel_id, movie_id) = 1),
  constraint favorites_channel_owner_fk foreign key (channel_id, owner_id)
    references public.channels(id, owner_id) on delete cascade,
  constraint favorites_movie_owner_fk foreign key (movie_id, owner_id)
    references public.movie_metadata(id, owner_id) on delete cascade,
  constraint favorites_revision_positive check (revision > 0)
);
create unique index favorites_channel_unique on public.favorites(owner_id, channel_id) where channel_id is not null;
create unique index favorites_movie_unique on public.favorites(owner_id, movie_id) where movie_id is not null;
create index favorites_owner_created_idx on public.favorites(owner_id, created_at desc);

create table public.watch_history (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  client_event_id uuid not null,
  channel_id uuid,
  movie_id uuid,
  watched_at timestamptz not null default now(),
  position_seconds bigint not null default 0,
  duration_seconds bigint,
  created_at timestamptz not null default now(),
  constraint watch_history_one_target check (num_nonnulls(channel_id, movie_id) = 1),
  constraint watch_history_position_nonnegative check (position_seconds >= 0),
  constraint watch_history_duration_nonnegative check (duration_seconds is null or duration_seconds >= 0),
  constraint watch_history_event_unique unique (owner_id, client_event_id),
  constraint watch_history_channel_owner_fk foreign key (channel_id, owner_id)
    references public.channels(id, owner_id) on delete cascade,
  constraint watch_history_movie_owner_fk foreign key (movie_id, owner_id)
    references public.movie_metadata(id, owner_id) on delete cascade
);
create index watch_history_owner_time_idx on public.watch_history(owner_id, watched_at desc);
create index watch_history_channel_idx on public.watch_history(owner_id, channel_id, watched_at desc)
  where channel_id is not null;
create index watch_history_movie_idx on public.watch_history(owner_id, movie_id, watched_at desc)
  where movie_id is not null;

create table public.watch_progress (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  channel_id uuid,
  movie_id uuid,
  position_seconds bigint not null default 0,
  duration_seconds bigint,
  completed boolean not null default false,
  revision bigint not null default 1,
  updated_at timestamptz not null default now(),
  constraint watch_progress_id_owner_unique unique (id, owner_id),
  constraint watch_progress_one_target check (num_nonnulls(channel_id, movie_id) = 1),
  constraint watch_progress_position_nonnegative check (position_seconds >= 0),
  constraint watch_progress_duration_nonnegative check (duration_seconds is null or duration_seconds >= 0),
  constraint watch_progress_revision_positive check (revision > 0),
  constraint watch_progress_channel_owner_fk foreign key (channel_id, owner_id)
    references public.channels(id, owner_id) on delete cascade,
  constraint watch_progress_movie_owner_fk foreign key (movie_id, owner_id)
    references public.movie_metadata(id, owner_id) on delete cascade
);
create unique index watch_progress_channel_unique on public.watch_progress(owner_id, channel_id)
  where channel_id is not null;
create unique index watch_progress_movie_unique on public.watch_progress(owner_id, movie_id)
  where movie_id is not null;
create index watch_progress_updated_idx on public.watch_progress(owner_id, updated_at desc);

create table public.epg_programs (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  channel_id uuid not null,
  provider_program_id text,
  title text not null,
  description text,
  category text,
  language text,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  created_at timestamptz not null default now(),
  constraint epg_channel_owner_fk foreign key (channel_id, owner_id)
    references public.channels(id, owner_id) on delete cascade,
  constraint epg_title_len check (char_length(title) between 1 and 300),
  constraint epg_time_order check (ends_at > starts_at)
);
create index epg_channel_time_idx on public.epg_programs(channel_id, starts_at, ends_at);
create index epg_owner_start_idx on public.epg_programs(owner_id, starts_at);
create unique index epg_provider_program_unique on public.epg_programs(channel_id, provider_program_id, starts_at)
  where provider_program_id is not null;

create table public.saved_youtube_links (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  youtube_video_id text not null,
  title text,
  thumbnail_url text,
  saved_at timestamptz not null default now(),
  constraint saved_youtube_id_check check (youtube_video_id ~ '^[A-Za-z0-9_-]{11}$'),
  constraint saved_youtube_title_len check (title is null or char_length(title) <= 300),
  constraint saved_youtube_thumbnail_https check (thumbnail_url is null or thumbnail_url ~ '^https://'),
  constraint saved_youtube_owner_video_unique unique (owner_id, youtube_video_id)
);
create index saved_youtube_owner_saved_idx on public.saved_youtube_links(owner_id, saved_at desc);

create table public.sync_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  device_id uuid,
  idempotency_key uuid not null,
  entity_type text not null,
  entity_id uuid not null,
  operation text not null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'queued',
  attempts integer not null default 0,
  next_attempt_at timestamptz,
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  error_code text,
  result_revision bigint,
  result_cursor bigint,
  constraint sync_device_owner_fk foreign key (device_id, user_id)
    references public.devices(id, user_id) on delete cascade,
  constraint sync_idempotency_unique unique (user_id, idempotency_key),
  constraint sync_entity_check check (entity_type in ('playlist', 'channel', 'favorite', 'watch_history', 'watch_progress', 'setting')),
  constraint sync_operation_check check (operation in ('upsert', 'delete')),
  constraint sync_status_check check (status in ('queued', 'processing', 'completed', 'retry', 'rejected')),
  constraint sync_attempts_nonnegative check (attempts >= 0),
  constraint sync_payload_object check (jsonb_typeof(payload) = 'object' and octet_length(payload::text) <= 32768)
);
create index sync_jobs_user_status_idx on public.sync_jobs(user_id, status, created_at desc);
create index sync_jobs_due_idx on public.sync_jobs(status, next_attempt_at)
  where status in ('queued', 'retry');

create table public.sync_events (
  id bigint generated always as identity primary key,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  entity_type text not null,
  entity_id uuid not null,
  operation text not null,
  revision bigint not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint sync_events_entity_check check (entity_type in ('playlist', 'channel', 'favorite', 'watch_history', 'watch_progress', 'setting')),
  constraint sync_events_operation_check check (operation in ('upsert', 'delete')),
  constraint sync_events_payload_size check (octet_length(payload::text) <= 32768)
);
create index sync_events_owner_cursor_idx on public.sync_events(owner_id, id);

create table public.app_announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  severity text not null default 'info',
  locale text not null default 'en',
  platforms text[] not null default '{}',
  published boolean not null default false,
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint announcements_severity_check check (severity in ('info', 'warning', 'maintenance')),
  constraint announcements_title_len check (char_length(title) between 1 and 160),
  constraint announcements_body_len check (char_length(body) between 1 and 4000),
  constraint announcements_time_order check (ends_at is null or ends_at > starts_at)
);
create index announcements_active_idx on public.app_announcements(starts_at, ends_at) where published;

create table public.bug_reports (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  client_idempotency_key uuid not null,
  category text not null,
  summary text not null,
  description text not null,
  app_version text not null,
  platform text not null,
  diagnostics_opt_in boolean not null default false,
  diagnostics jsonb not null default '{}'::jsonb,
  status text not null default 'new',
  support_status text not null default 'received',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint bug_report_idempotency_unique unique (owner_id, client_idempotency_key),
  constraint bug_report_category_check check (category in ('playback', 'playlist', 'account', 'sync', 'accessibility', 'other')),
  constraint bug_report_summary_len check (char_length(summary) between 1 and 160),
  constraint bug_report_description_len check (char_length(description) between 1 and 8000),
  constraint bug_report_diagnostics_object check (jsonb_typeof(diagnostics) = 'object' and octet_length(diagnostics::text) <= 16384),
  constraint bug_report_status_check check (status in ('new', 'triaged', 'resolved', 'closed')),
  constraint bug_report_support_status_check check (support_status in ('received', 'in_review', 'waiting_for_user', 'resolved'))
);
create index bug_reports_owner_created_idx on public.bug_reports(owner_id, created_at desc);
create index bug_reports_admin_status_idx on public.bug_reports(status, created_at desc);

create table public.feature_config (
  feature_key text primary key,
  enabled boolean not null default false,
  config jsonb not null default '{}'::jsonb,
  updated_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now(),
  constraint feature_config_key_check check (feature_key ~ '^[a-z][a-z0-9_.-]{1,80}$'),
  constraint feature_config_object check (jsonb_typeof(config) = 'object' and octet_length(config::text) <= 8192)
);

create table public.rate_limit_buckets (
  subject_id uuid not null,
  action text not null,
  window_start timestamptz not null,
  request_count integer not null default 0,
  primary key (subject_id, action, window_start),
  constraint rate_limit_action_len check (char_length(action) between 1 and 80),
  constraint rate_limit_count_nonnegative check (request_count >= 0)
);

create table public.admin_audit_log (
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users(id) on delete set null,
  action text not null,
  target_user_id uuid,
  target_record_id uuid,
  request_id uuid not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint admin_audit_action_len check (char_length(action) between 1 and 100),
  constraint admin_audit_metadata_object check (jsonb_typeof(metadata) = 'object' and octet_length(metadata::text) <= 4096)
);
create index admin_audit_created_idx on public.admin_audit_log(created_at desc);
create index admin_audit_target_idx on public.admin_audit_log(target_user_id, created_at desc);

create or replace function public.is_app_admin()
returns boolean
language sql
stable
set search_path = pg_catalog
as $$
  select coalesce((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin', false);
$$;

create or replace function public.create_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  insert into public.profiles(id, display_name)
  values (
    new.id,
    nullif(left(trim(coalesce(new.raw_user_meta_data ->> 'display_name', '')), 80), '')
  )
  on conflict (id) do nothing;

  insert into public.user_settings(user_id)
  values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.create_profile_for_new_user();

create trigger profiles_set_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger playlists_set_updated_at before update on public.playlists
  for each row execute function public.set_updated_at();
create trigger channels_set_updated_at before update on public.channels
  for each row execute function public.set_updated_at();
create trigger movies_set_updated_at before update on public.movie_metadata
  for each row execute function public.set_updated_at();
create trigger favorites_set_updated_at before update on public.favorites
  for each row execute function public.set_updated_at();
create trigger watch_progress_set_updated_at before update on public.watch_progress
  for each row execute function public.set_updated_at();
create trigger announcements_set_updated_at before update on public.app_announcements
  for each row execute function public.set_updated_at();
create trigger bug_reports_set_updated_at before update on public.bug_reports
  for each row execute function public.set_updated_at();

create or replace function public.json_contains_forbidden_sync_key(value jsonb)
returns boolean
language plpgsql
immutable
set search_path = pg_catalog
as $$
declare
  item record;
begin
  if jsonb_typeof(value) = 'object' then
    for item in select key, val from jsonb_each(value) as e(key, val) loop
      if lower(item.key) = any(array[
        'password', 'username', 'token', 'access_token', 'refresh_token',
        'api_key', 'service_role_key', 'authorization', 'stream_url',
        'source_url', 'playlist_url', 'epg_url', 'credentials'
      ]) or public.json_contains_forbidden_sync_key(item.val) then
        return true;
      end if;
    end loop;
  elsif jsonb_typeof(value) = 'array' then
    for item in select val from jsonb_array_elements(value) as e(val) loop
      if public.json_contains_forbidden_sync_key(item.val) then
        return true;
      end if;
    end loop;
  end if;
  return false;
end;
$$;

create or replace function public.consume_rate_limit(
  p_subject_id uuid,
  p_action text,
  p_limit integer,
  p_window_seconds integer
)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_start timestamptz;
  v_count integer;
begin
  if p_subject_id is null or p_limit < 1 or p_window_seconds < 1 or p_window_seconds > 86400
     or p_action is null or char_length(p_action) > 80 then
    return false;
  end if;

  v_start := to_timestamp(
    floor(extract(epoch from clock_timestamp()) / p_window_seconds) * p_window_seconds
  );
  insert into public.rate_limit_buckets(subject_id, action, window_start, request_count)
  values (p_subject_id, p_action, v_start, 1)
  on conflict (subject_id, action, window_start) do update
    set request_count = public.rate_limit_buckets.request_count + 1
  returning request_count into v_count;

  return v_count <= p_limit;
end;
$$;

create or replace function public.register_device(
  p_installation_id_hash text,
  p_device_name text,
  p_platform text,
  p_app_version text default null
)
returns public.devices
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_device public.devices;
begin
  if v_user_id is null then
    raise exception using errcode = '28000', message = 'unauthorized';
  end if;
  if p_installation_id_hash !~ '^[0-9a-f]{64}$'
     or p_device_name is null or char_length(trim(p_device_name)) not between 1 and 80
    or p_platform not in ('android', 'ios', 'windows', 'macos', 'linux', 'web') then
    raise exception using errcode = '22023', message = 'invalid_device';
  end if;

  if not exists (
    select 1 from public.devices d
    where d.user_id = v_user_id
      and d.installation_id_hash = p_installation_id_hash
      and d.revoked_at is null
  ) and (select count(*) from public.devices d
         where d.user_id = v_user_id and d.revoked_at is null) >= 10 then
    raise exception using errcode = '54000', message = 'device_limit';
  end if;

  insert into public.devices(user_id, installation_id_hash, device_name, platform, app_version)
  values (v_user_id, p_installation_id_hash, trim(p_device_name), p_platform, left(p_app_version, 40))
  on conflict (user_id, installation_id_hash) do update
    set device_name = excluded.device_name,
        platform = excluded.platform,
        app_version = excluded.app_version,
        last_seen_at = now(),
        revoked_at = null
  returning * into v_device;
  return v_device;
end;
$$;

create or replace function public.revoke_device(p_device_id uuid)
returns timestamptz
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_revoked_at timestamptz;
begin
  if auth.uid() is null then
    raise exception using errcode = '28000', message = 'unauthorized';
  end if;
  update public.devices
     set revoked_at = coalesce(revoked_at, now())
   where id = p_device_id and user_id = auth.uid()
   returning revoked_at into v_revoked_at;
  if v_revoked_at is null then
    raise exception using errcode = 'P0002', message = 'device_not_found';
  end if;
  return v_revoked_at;
end;
$$;

create or replace function public.submit_bug_report(
  p_client_idempotency_key uuid,
  p_category text,
  p_summary text,
  p_description text,
  p_app_version text,
  p_platform text,
  p_diagnostics_opt_in boolean default false,
  p_diagnostics jsonb default '{}'::jsonb
)
returns public.bug_reports
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_report public.bug_reports;
begin
  if v_user_id is null then
    raise exception using errcode = '28000', message = 'unauthorized';
  end if;
  if p_client_idempotency_key is null
     or p_category not in ('playback', 'playlist', 'account', 'sync', 'accessibility', 'other')
     or char_length(trim(coalesce(p_summary, ''))) not between 1 and 160
     or char_length(trim(coalesce(p_description, ''))) not between 1 and 8000
     or p_platform not in ('android', 'windows', 'macos', 'linux', 'web')
     or jsonb_typeof(coalesce(p_diagnostics, '{}'::jsonb)) <> 'object'
     or octet_length(coalesce(p_diagnostics, '{}'::jsonb)::text) > 16384
     or public.json_contains_forbidden_sync_key(coalesce(p_diagnostics, '{}'::jsonb)) then
    raise exception using errcode = '22023', message = 'invalid_bug_report';
  end if;

  insert into public.bug_reports(
    owner_id, client_idempotency_key, category, summary, description,
    app_version, platform, diagnostics_opt_in, diagnostics
  ) values (
    v_user_id, p_client_idempotency_key, p_category, trim(p_summary), trim(p_description),
    left(p_app_version, 40), p_platform, coalesce(p_diagnostics_opt_in, false),
    case when p_diagnostics_opt_in then coalesce(p_diagnostics, '{}'::jsonb) else '{}'::jsonb end
  )
  on conflict (owner_id, client_idempotency_key) do update
    set client_idempotency_key = excluded.client_idempotency_key
  returning * into v_report;
  return v_report;
end;
$$;

alter table public.profiles enable row level security;
alter table public.devices enable row level security;
alter table public.user_settings enable row level security;
alter table public.playlists enable row level security;
alter table public.channels enable row level security;
alter table public.movie_metadata enable row level security;
alter table public.favorites enable row level security;
alter table public.watch_history enable row level security;
alter table public.watch_progress enable row level security;
alter table public.epg_programs enable row level security;
alter table public.saved_youtube_links enable row level security;
alter table public.sync_jobs enable row level security;
alter table public.sync_events enable row level security;
alter table public.app_announcements enable row level security;
alter table public.bug_reports enable row level security;
alter table public.feature_config enable row level security;
alter table public.rate_limit_buckets enable row level security;
alter table public.admin_audit_log enable row level security;

create policy profiles_select_own on public.profiles for select to authenticated using (id = (select auth.uid()));
create policy profiles_update_own on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy devices_select_own on public.devices for select to authenticated using (user_id = (select auth.uid()));
create policy settings_select_own on public.user_settings for select to authenticated using (user_id = (select auth.uid()));
create policy settings_update_own on public.user_settings for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy playlists_select_own on public.playlists for select to authenticated using (owner_id = (select auth.uid()));
create policy channels_select_own on public.channels for select to authenticated using (owner_id = (select auth.uid()));
create policy movies_select_own on public.movie_metadata for select to authenticated using (owner_id = (select auth.uid()));
create policy favorites_select_own on public.favorites for select to authenticated using (owner_id = (select auth.uid()));
create policy history_select_own on public.watch_history for select to authenticated using (owner_id = (select auth.uid()));
create policy progress_select_own on public.watch_progress for select to authenticated using (owner_id = (select auth.uid()));
create policy epg_select_own on public.epg_programs for select to authenticated using (owner_id = (select auth.uid()));
create policy youtube_select_own on public.saved_youtube_links for select to authenticated using (owner_id = (select auth.uid()));
create policy sync_jobs_select_own on public.sync_jobs for select to authenticated using (user_id = (select auth.uid()));
create policy sync_events_select_own on public.sync_events for select to authenticated using (owner_id = (select auth.uid()));
create policy announcements_read_active on public.app_announcements for select to anon, authenticated
  using (published and starts_at <= now() and (ends_at is null or ends_at > now()));
create policy bug_reports_select_own on public.bug_reports for select to authenticated using (owner_id = (select auth.uid()));
create policy feature_config_read_enabled on public.feature_config for select to authenticated using (enabled);
create policy feature_config_admin_write on public.feature_config for all to authenticated
  using (public.is_app_admin()) with check (public.is_app_admin());
create policy admin_audit_admin_read on public.admin_audit_log for select to authenticated using (public.is_app_admin());

revoke all on public.profiles, public.devices, public.user_settings, public.playlists,
  public.channels, public.movie_metadata, public.favorites, public.watch_history,
  public.watch_progress, public.epg_programs, public.saved_youtube_links, public.sync_jobs,
  public.sync_events, public.app_announcements, public.bug_reports, public.feature_config,
  public.rate_limit_buckets, public.admin_audit_log from anon, authenticated;

grant select on public.profiles, public.devices, public.user_settings, public.playlists,
  public.channels, public.movie_metadata, public.favorites, public.watch_history,
  public.watch_progress, public.epg_programs, public.saved_youtube_links, public.sync_jobs,
  public.sync_events, public.bug_reports to authenticated;
grant select on public.app_announcements to anon, authenticated;
grant select on public.feature_config to authenticated;
grant update (display_name, avatar_url, locale) on public.profiles to authenticated;
grant update (theme, locale, settings, schema_version, revision) on public.user_settings to authenticated;
grant update, insert, delete on public.feature_config to authenticated;
grant select on public.admin_audit_log to authenticated;

grant execute on function public.register_device(text, text, text, text) to authenticated;
grant execute on function public.revoke_device(uuid) to authenticated;
grant execute on function public.submit_bug_report(uuid, text, text, text, text, text, boolean, jsonb) to authenticated;
revoke all on function public.consume_rate_limit(uuid, text, integer, integer) from public, anon, authenticated;
grant execute on function public.consume_rate_limit(uuid, text, integer, integer) to service_role;
revoke all on function public.json_contains_forbidden_sync_key(jsonb) from public, anon, authenticated;

commit;
