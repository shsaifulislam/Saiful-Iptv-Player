# PostgreSQL Database Schema Blueprint

**Status:** Design only. This is not a migration and has not been applied to Supabase. Review with the product/security owner before deployment. All user tables use UUIDs, UTC timestamps, owner-scoped RLS, and server-side validation. `auth.uid()` is the source of user ownership; clients cannot choose another owner.

## Data and Secret Rules

- Never store raw provider passwords, Xtream credentials, API secrets, service-role keys, or signed playback URLs in ordinary PostgreSQL columns.
- Playlist cloud sync stores metadata only. Full source locators (which may themselves contain credentials/tokens) remain in device-local protected storage; users re-enter credentials on a new device unless a separately approved secret-vault service is designed.
- `channels` and `movie_metadata` contain catalog metadata and provider item identifiers, not playable stream URLs.
- Do not persist hardware identifiers. `installation_id_hash` is an app-generated opaque identifier, not IMEI/serial/MAC.
- `user_settings.settings`, `sync_jobs.payload`, and `bug_reports.diagnostics` are allow-listed, bounded JSON objects. Reject secrets, URLs containing credentials, and unbounded arbitrary data at API/RPC boundaries.
- No client-writable role/admin field. Admin writes use server-controlled Edge Functions and audited authorization.

## Tables and Required/Optional Fields

`NOT NULL` and `PRIMARY KEY` in the proposed DDL mean required. Nullable fields are optional. `gen_random_uuid()` assumes the Supabase/PostgreSQL UUID function is available.

### `profiles`

```sql
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  locale text not null default 'en',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_display_name_len check (display_name is null or char_length(display_name) between 1 and 80),
  constraint profiles_locale_len check (char_length(locale) between 2 and 20)
);
```

Required: `id`, `locale`, timestamps. Optional: display name, avatar URL. Owner: `id = auth.uid()`. Index: primary key; add `updated_at` index only if admin operations need it. RLS: owner select/update; insert only via trusted signup trigger or owner-safe RPC; no role/entitlement field. Retention: account lifetime; deletion follows approved account-erasure and legal-retention workflow.

### `devices`

```sql
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
  constraint devices_install_hash_len check (char_length(installation_id_hash) between 32 and 128),
  constraint devices_name_len check (char_length(device_name) between 1 and 80),
  constraint devices_platform_check check (platform in ('android_phone', 'android_tablet', 'android_tv', 'windows', 'macos', 'linux', 'tizen', 'webos')),
  constraint devices_revoked_after_create check (revoked_at is null or revoked_at >= created_at),
  constraint devices_user_install_unique unique (user_id, installation_id_hash)
);
create index devices_user_seen_idx on public.devices(user_id, last_seen_at desc);
```

Required: id, user, opaque installation hash, name, platform, timestamps. Optional: version, revocation time. Owner: `user_id`. RLS: owner read; create/rename/revoke through validated RPC; do not allow changing ownership or installation hash. Retention: retain active devices; purge revoked devices after 30 days unless needed for abuse/security audit.

### `user_settings`

```sql
create table public.user_settings (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  theme text not null default 'system',
  locale text not null default 'en',
  settings jsonb not null default '{}'::jsonb,
  schema_version integer not null default 1,
  updated_at timestamptz not null default now(),
  constraint user_settings_theme_check check (theme in ('dark', 'system', 'light')),
  constraint user_settings_json_object check (jsonb_typeof(settings) = 'object'),
  constraint user_settings_schema_positive check (schema_version > 0),
  constraint user_settings_locale_len check (char_length(locale) between 2 and 20)
);
```

Required: user id, theme, locale, settings object, schema version, timestamp. Optional: none. Owner: `user_id`. Index: PK. RLS: owner select/insert/update; validate allow-listed JSON keys in RPC. Never put passwords, PINs, permissions or device-only secrets in `settings`. Retention: account lifetime; delete with account.

### `playlists`

```sql
create table public.playlists (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  source_kind text not null,
  source_host text,
  credentials_required boolean not null default false,
  enabled boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint playlists_id_owner_unique unique (id, owner_id),
  constraint playlists_name_len check (char_length(name) between 1 and 120),
  constraint playlists_kind_check check (source_kind in ('m3u_url', 'm3u_file', 'authorized_provider')),
  constraint playlists_host_len check (source_host is null or char_length(source_host) <= 253)
);
create index playlists_owner_sort_idx on public.playlists(owner_id, sort_order, created_at);
```

Required: id, owner, name, source kind, credentials-required flag, enabled, sort order, timestamps. Optional: normalized host only. Owner: `owner_id`. The API must normalize `source_host` to a hostname with no scheme, userinfo, path, query or fragment; SQL length checks alone do not validate URL safety. RLS: owner CRUD. Retention: until user deletion; metadata deletion should cascade to channels/EPG/favorites/progress where appropriate. Credential references are local-only and are deleted from the OS vault on playlist deletion.

### `channels`

```sql
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
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint channels_owner_id_unique unique (id, owner_id),
  constraint channels_playlist_owner_fk foreign key (playlist_id, owner_id)
    references public.playlists(id, owner_id) on delete cascade,
  constraint channels_name_len check (char_length(name) between 1 and 240),
  constraint channels_kind_check check (stream_kind in ('live', 'movie', 'series')),
  constraint channels_logo_https check (logo_url is null or logo_url like 'https://%')
);
create index channels_playlist_order_idx on public.channels(owner_id, playlist_id, sort_order);
create index channels_group_idx on public.channels(owner_id, playlist_id, group_title);
create unique index channels_provider_item_unique on public.channels(playlist_id, provider_item_id) where provider_item_id is not null;
```

Required: id, owner, playlist, name, stream kind, order and timestamps. Optional: provider item id, group, HTTPS logo, EPG id. Owner: `owner_id`, cross-checked against playlist owner. No raw stream locator. RLS: owner read/delete; inserts/updates through validated import/sync RPC. Retention: cascade with playlist/account; stale provider metadata can be pruned after refresh.

### `movie_metadata`

```sql
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
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint movie_metadata_id_owner_unique unique (id, owner_id),
  constraint movie_metadata_playlist_owner_fk foreign key (playlist_id, owner_id)
    references public.playlists(id, owner_id) on delete cascade,
  constraint movie_title_len check (char_length(title) between 1 and 240),
  constraint movie_year_check check (release_year is null or release_year between 1888 and 2200),
  constraint movie_rating_check check (rating is null or rating between 0 and 10),
  constraint movie_duration_check check (duration_seconds is null or duration_seconds >= 0),
  constraint movie_poster_https check (poster_url is null or poster_url like 'https://%'),
  constraint movie_backdrop_https check (backdrop_url is null or backdrop_url like 'https://%')
);
create index movie_metadata_owner_title_idx on public.movie_metadata(owner_id, lower(title));
create unique index movie_metadata_provider_item_unique on public.movie_metadata(playlist_id, provider_item_id)
  where playlist_id is not null and provider_item_id is not null;
```

Required: id, owner, title, genres array and timestamps. Optional: playlist/provider id, synopsis, year, rating, duration, HTTPS art URLs. Owner: `owner_id`, and playlist ownership is composite-FK checked. No playback URL. RLS: owner read; provider refresh writes through import RPC. Retention: cascade with playlist/account. Licensed catalog metadata must follow source/provider retention rules.

### `favorites`

```sql
create table public.favorites (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  channel_id uuid,
  movie_id uuid,
  created_at timestamptz not null default now(),
  constraint favorites_one_target check (num_nonnulls(channel_id, movie_id) = 1),
  constraint favorites_channel_owner_fk foreign key (channel_id, owner_id)
    references public.channels(id, owner_id) on delete cascade,
  constraint favorites_movie_owner_fk foreign key (movie_id, owner_id)
    references public.movie_metadata(id, owner_id) on delete cascade
);
create unique index favorites_channel_unique on public.favorites(owner_id, channel_id) where channel_id is not null;
create unique index favorites_movie_unique on public.favorites(owner_id, movie_id) where movie_id is not null;
create index favorites_owner_created_idx on public.favorites(owner_id, created_at desc);
```

Required: id, owner, exactly one target, creation time. Optional: either channel or movie target, but not both. Owner: `owner_id`; composite FKs prevent cross-owner references. RLS: owner CRUD. Retention: cascade with target/account; retain no deleted target tombstone beyond sync acknowledgement window.

### `watch_history`

```sql
create table public.watch_history (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  event_id uuid not null,
  channel_id uuid,
  movie_id uuid,
  watched_at timestamptz not null default now(),
  position_seconds bigint not null default 0,
  duration_seconds bigint,
  constraint watch_history_one_target check (num_nonnulls(channel_id, movie_id) = 1),
  constraint watch_history_position_nonnegative check (position_seconds >= 0),
  constraint watch_history_duration_nonnegative check (duration_seconds is null or duration_seconds >= 0),
  constraint watch_history_event_unique unique (owner_id, event_id),
  constraint watch_history_channel_owner_fk foreign key (channel_id, owner_id)
    references public.channels(id, owner_id) on delete cascade,
  constraint watch_history_movie_owner_fk foreign key (movie_id, owner_id)
    references public.movie_metadata(id, owner_id) on delete cascade
);
create index watch_history_owner_time_idx on public.watch_history(owner_id, watched_at desc);
create index watch_history_channel_idx on public.watch_history(owner_id, channel_id, watched_at desc) where channel_id is not null;
create index watch_history_movie_idx on public.watch_history(owner_id, movie_id, watched_at desc) where movie_id is not null;
```

Required: id, owner, idempotent event id, exactly one target, watched time, position. Optional: duration. Owner: `owner_id`; target FK is owner-bound. RLS: owner select/insert/delete, with bounded retention. Retention: default 365 days, user-clearable; account deletion removes records. Series history requires a future `series/episodes` schema extension and is not represented by this initial schema.

### `watch_progress`

```sql
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
  constraint watch_progress_one_target check (num_nonnulls(channel_id, movie_id) = 1),
  constraint watch_progress_position_nonnegative check (position_seconds >= 0),
  constraint watch_progress_duration_nonnegative check (duration_seconds is null or duration_seconds >= 0),
  constraint watch_progress_revision_positive check (revision > 0),
  constraint watch_progress_channel_owner_fk foreign key (channel_id, owner_id)
    references public.channels(id, owner_id) on delete cascade,
  constraint watch_progress_movie_owner_fk foreign key (movie_id, owner_id)
    references public.movie_metadata(id, owner_id) on delete cascade
);
create unique index watch_progress_channel_unique on public.watch_progress(owner_id, channel_id) where channel_id is not null;
create unique index watch_progress_movie_unique on public.watch_progress(owner_id, movie_id) where movie_id is not null;
create index watch_progress_updated_idx on public.watch_progress(owner_id, updated_at desc);
```

Required: id, owner, exactly one target, position, completion flag, revision and update time. Optional: duration. Owner: `owner_id`; target FK is owner-bound. RLS: owner read/write through a revision-aware RPC to prevent stale overwrite. Retention: retain until completion plus 90 days, then prune by policy; user can clear earlier.

### `epg_programs`

```sql
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
```

Required: id, owner, channel, title, start/end, creation time. Optional: provider id, description, category, language. Owner: `owner_id`; channel FK is owner-bound. RLS: owner read; importer/sync worker writes validated records. Retention: prune ended programs after 14 days and reject/expire excessive future horizon (default max 30 days).

### `saved_youtube_links`

```sql
create table public.saved_youtube_links (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  youtube_video_id text not null,
  title text,
  thumbnail_url text,
  saved_at timestamptz not null default now(),
  constraint saved_youtube_id_check check (youtube_video_id ~ '^[A-Za-z0-9_-]{11}$'),
  constraint saved_youtube_title_len check (title is null or char_length(title) <= 300),
  constraint saved_youtube_thumbnail_https check (thumbnail_url is null or thumbnail_url like 'https://%'),
  constraint saved_youtube_owner_video_unique unique (owner_id, youtube_video_id)
);
create index saved_youtube_owner_saved_idx on public.saved_youtube_links(owner_id, saved_at desc);
```

Required: id, owner, 11-character video ID, save time. Optional: title and HTTPS thumbnail. Owner: `owner_id`. RLS: owner CRUD. Retention: until user deletes/account closes. Store no API key or authentication token; use official YouTube API/player policies.

### `sync_jobs`

```sql
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
  constraint sync_device_owner_fk foreign key (device_id, user_id)
    references public.devices(id, user_id) on delete cascade,
  constraint sync_idempotency_unique unique (user_id, idempotency_key),
  constraint sync_entity_check check (entity_type in ('playlist', 'channel', 'favorite', 'watch_history', 'watch_progress', 'setting')),
  constraint sync_operation_check check (operation in ('upsert', 'delete')),
  constraint sync_status_check check (status in ('queued', 'processing', 'completed', 'retry', 'rejected')),
  constraint sync_attempts_nonnegative check (attempts >= 0),
  constraint sync_payload_object check (jsonb_typeof(payload) = 'object' and octet_length(payload::text) <= 32768)
);
create index sync_jobs_user_status_idx on public.sync_jobs(user_id, status, created_at);
create index sync_jobs_due_idx on public.sync_jobs(status, next_attempt_at) where status in ('queued', 'retry');
```

Required: id, user, idempotency key, entity type/id, operation, bounded payload, status, attempts, creation time. Optional: device, next attempt, completion time, error code. Owner: `user_id`; device FK must belong to same user. RLS: owner may read own status; enqueue through RPC that validates payload and strips/rejects secrets; only trusted worker changes status/attempts/errors. Retention: purge completed/rejected jobs after 30 days; retain sanitized aggregate metrics only if approved.

### `app_announcements`

```sql
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
```

Required: id, title, body, severity, locale, platforms, publish state, start and timestamps. Optional: end time and creator. Owner: no end-user owner; service/admin-owned. RLS: clients read only published and currently active rows; only server-side admin operation may write. Retention: archive 1 year after expiry, then delete unless audit/legal policy requires longer.

### `bug_reports`

```sql
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
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint bug_report_idempotency_unique unique (owner_id, client_idempotency_key),
  constraint bug_report_category_check check (category in ('playback', 'playlist', 'account', 'sync', 'accessibility', 'other')),
  constraint bug_report_summary_len check (char_length(summary) between 1 and 160),
  constraint bug_report_description_len check (char_length(description) between 1 and 8000),
  constraint bug_report_diagnostics_object check (jsonb_typeof(diagnostics) = 'object' and octet_length(diagnostics::text) <= 16384),
  constraint bug_report_status_check check (status in ('new', 'triaged', 'resolved', 'closed'))
);
create index bug_reports_owner_created_idx on public.bug_reports(owner_id, created_at desc);
create index bug_reports_admin_status_idx on public.bug_reports(status, created_at desc);
```

Required: id, owner, idempotency key, category, summary, description, app version, platform, opt-in, bounded diagnostics, status and timestamps. Optional: none (diagnostics object may be empty). Owner: `owner_id`. RLS: owner may insert via sanitizing RPC and read own report status; no client updates; admin status changes server-side only. Retention: 180 days after closure, then delete or irreversibly aggregate; honor account deletion and legal requirements.

## RLS and Ownership Matrix

Enable RLS on every table. All user policies compare the authenticated UID to the owner column and never accept ownership from request JSON. Composite foreign keys are used where a child must reference a parent owned by the same user.

| Table | Read policy | Client write policy | Trusted/server write |
|---|---|---|---|
| `profiles` | `id = auth.uid()` | Own profile fields only; no role/email entitlement mutation | Signup trigger creates row |
| `devices` | `user_id = auth.uid()` | RPC only for register/rename/revoke | Session enforcement/revocation |
| `user_settings` | `user_id = auth.uid()` | Own allow-listed settings | Migration/repair |
| `playlists` | `owner_id = auth.uid()` | Own metadata CRUD; no locators/secrets | Optional import validation |
| `channels` | `owner_id = auth.uid()` | Import/sync RPC only | Provider metadata refresh |
| `favorites` | `owner_id = auth.uid()` | Own upsert/delete | Sync merge |
| `watch_history` | `owner_id = auth.uid()` | Own bounded insert/delete | Retention worker |
| `watch_progress` | `owner_id = auth.uid()` | Revision-aware own RPC | Conflict merge/retention |
| `movie_metadata` | `owner_id = auth.uid()` | Import RPC only | Authorized catalog refresh |
| `epg_programs` | `owner_id = auth.uid()` | Validated import/sync RPC | Retention worker |
| `saved_youtube_links` | `owner_id = auth.uid()` | Own CRUD | Optional official metadata refresh |
| `sync_jobs` | `user_id = auth.uid()` | Enqueue RPC; no status writes | Sync worker owns transitions |
| `app_announcements` | Public active rows only (or authenticated if policy requires) | None | Admin Edge Function only |
| `bug_reports` | `owner_id = auth.uid()` | Sanitizing insert RPC; no status update | Admin triage/retention |

Never grant `service_role` or bypass-RLS credentials to the app. Add negative tests proving anonymous access is denied where expected and one user's token cannot read/write another user's rows. Admin identity must be enforced by trusted server claims/policies, not a mutable profile field.

## Retention Summary

- Profiles and user settings: account lifetime; delete/cascade after verified account-deletion flow, subject to legal hold.
- Devices: active until revoked; revoked metadata purged after 30 days.
- Playlist/channel/movie metadata: until user deletes source/account; prune stale imported items after confirmed refresh and sync tombstone acknowledgement.
- Favorites: until user removes target; sync tombstones expire after all active devices acknowledge or 30 days.
- Watch history: default 365 days, user-clearable. Progress: until completion + 90 days, user-clearable.
- EPG: ended programs 14 days; future schedule capped at 30 days.
- YouTube links: until user removes or closes account.
- Sync jobs: completed/rejected jobs 30 days; errors retain only stable codes.
- Announcements: archive 1 year after expiry, then delete absent audit requirements.
- Bug reports: 180 days after closure, then delete or irreversibly aggregate; diagnostics are opt-in and sanitized.

## Schema Gaps and Release Gates

- The requested tables do not include series/episode tables. Add them before cloud favorites/history/progress for series content; do not encode cross-table polymorphic IDs without enforceable ownership FKs.
- Decide whether playlists/channels are cloud-synced metadata or device-local. This blueprint chooses metadata-only cloud sync and requires source re-entry on another device.
- Review JSON allow-lists, deletion law, audit retention, indexes at expected scale, and all RLS policies with tests before creating migrations.
- Convert this blueprint into ordered migrations only after approval. No SQL in this document has been executed.
