# Saiful IPTV Player — Database Migration Report

## 1. Migration Inventory

The cloud backend database schema is managed through numbered, version-controlled SQL migration scripts located in `supabase/migrations/`:

| Migration File | Description | Execution Gate | Status |
|---|---|---|---|
| `202611110001_backend_foundation.sql` | Base schema, 17 relational tables, primary/foreign keys, check constraints, RLS policies, indexes, rate limiting, and core functions. | Pre-sync baseline | COMPLETE |
| `202611110002_sync_rpc.sql` | Sync entity validation trigger, `apply_sync_changes()` transactional security definer RPC function, conflict detection, and event generation. | Core sync engine | COMPLETE |
| `202611110003_storage_and_execute_privileges.sql` | Storage bucket configuration (`profile-avatars`), RLS storage object policies, RPC grant and revoke security lockdown. | Storage & privileges | COMPLETE |
| `202611110004_admin_release_metadata.sql` | Version control & remote force-update table (`app_release_info`), singleton constraint, public read RLS policy, admin write policy. | Client version gating | COMPLETE |

---

## 2. Table Schema Specification

### 2.1 User & Identity Tables
1. **`profiles`**
   - **Primary Key**: `id uuid references auth.users(id) on delete cascade`
   - **Columns**: `display_name text`, `avatar_url text`, `locale text default 'en'`, `created_at timestamptz`, `updated_at timestamptz`
   - **Constraints**: Display name length (1-80), locale length (2-20), avatar HTTPS regex validation.
   - **Trigger**: Profile auto-creation on `auth.users` insert (`create_profile_for_new_user()`).

2. **`devices`**
   - **Primary Key**: `id uuid default gen_random_uuid()`
   - **Foreign Keys**: `user_id references public.profiles(id) on delete cascade`
   - **Constraints**: Unique `(id, user_id)`, unique `(user_id, installation_id_hash)`.
   - **Validation**: Installation hash matches `^[0-9a-f]{64}$`, platform in `('android', 'ios', 'windows', 'macos', 'linux', 'web')`.
   - **Indexes**: `devices_user_seen_idx (user_id, last_seen_at desc)`.

3. **`user_settings`**
   - **Primary Key**: `user_id references public.profiles(id) on delete cascade`
   - **Columns**: `theme text default 'system'`, `locale text default 'en'`, `settings jsonb default '{}'`, `schema_version integer default 1`, `revision bigint default 1`
   - **Constraints**: Theme check `('dark', 'system', 'light')`, JSON size check `<= 8192 bytes`.
   - **Trigger**: `user_settings_secret_guard` strictly prevents storing password or token keys.

### 2.2 Content & Library Tables
4. **`playlists`**
   - **Primary Key**: `id uuid default gen_random_uuid()`
   - **Foreign Keys**: `owner_id references public.profiles(id) on delete cascade`
   - **Columns**: `name text`, `source_kind text ('m3u_url', 'm3u_file', 'authorized_provider')`, `source_host text`, `credentials_required boolean default false`, `enabled boolean default true`, `sort_order integer default 0`, `revision bigint default 1`
   - **Constraints**: Unique `(id, owner_id)`.
   - **Indexes**: `playlists_owner_sort_idx (owner_id, sort_order, created_at)`.

5. **`channels`**
   - **Primary Key**: `id uuid default gen_random_uuid()`
   - **Foreign Keys**: `owner_id references public.profiles(id) on delete cascade`, `(playlist_id, owner_id) references public.playlists(id, owner_id) on delete cascade`
   - **Columns**: `provider_item_id text`, `name text`, `group_title text`, `logo_url text`, `tvg_id text`, `stream_kind text ('live', 'movie', 'series')`, `sort_order integer`, `revision bigint default 1`
   - **Indexes**: `channels_owner_playlist_idx (owner_id, playlist_id, sort_order)`.

6. **`favorites`**
   - **Primary Key**: `id uuid default gen_random_uuid()`
   - **Foreign Keys**: `owner_id references public.profiles(id) on delete cascade`, `channel_id references public.channels(id) on delete cascade`, `movie_id references public.movie_metadata(id) on delete cascade`
   - **Constraints**: Exactly one target (`(channel_id is not null and movie_id is null) or (channel_id is null and movie_id is not null)`), partial unique index per channel and movie per owner.

7. **`watch_history`**
   - **Primary Key**: `id uuid default gen_random_uuid()`
   - **Foreign Keys**: `owner_id references public.profiles(id) on delete cascade`, optional `channel_id`, optional `movie_id`.
   - **Columns**: `position_seconds bigint`, `duration_seconds bigint`, `completed boolean`, `last_watched_at timestamptz`, `revision bigint default 1`.

8. **`watch_progress`**
   - **Primary Key**: `id uuid default gen_random_uuid()`
   - **Foreign Keys**: `owner_id references public.profiles(id) on delete cascade`.
   - **Constraints**: Unique per owner and target channel/movie. Non-negative positions.

9. **`movie_metadata`**
   - Stores user movie catalog cache: title, overview, release_date, poster_url, backdrop_url, tmdb_id, genres, duration_seconds.

10. **`epg_programs`**
    - Stores cached EPG program guide schedules tied to user channels: `channel_id`, `title`, `start_time`, `end_time`, `description`.

11. **`saved_youtube_links`**
    - Stores saved YouTube stream URLs and video titles with owner verification.

### 2.3 Synchronization & Operational Tables
12. **`sync_jobs`** & **`sync_events`**
    - **`sync_jobs`**: Client idempotency ledger tracking per-device sync batches (`idempotency_key`, `device_id`, `entity_type`, `entity_id`, `operation`, `status`).
    - **`sync_events`**: Event stream for pulling changes (`id bigint generated always as identity`, `owner_id`, `entity_type`, `entity_id`, `operation`, `revision`, `payload`, `created_at`).

13. **`app_announcements`**
    - Broadcast messages from administrators: `title`, `body`, `locale`, `severity ('info', 'warning', 'maintenance')`, `published boolean`, `starts_at`, `ends_at`.

14. **`bug_reports`**
    - User submitted diagnostic reports: `client_idempotency_key`, `category`, `summary`, `description`, `app_version`, `platform`, `diagnostics_opt_in`, `diagnostics jsonb`, `status`, `support_status`.

15. **`feature_config`**
    - Server-controlled feature flags: `feature_key primary key`, `enabled boolean`, `config jsonb`.

16. **`rate_limit_buckets`**
    - Token-bucket rate limiting tracking by `subject_id` and `action`.

17. **`admin_audit_log`**
    - Immutable audit trail for all admin operations: `actor_id`, `target_user_id`, `action`, `request_id`, `metadata`, `created_at`.

18. **`app_release_info`**
    - Version enforcement metadata: `latest_version`, `minimum_supported_version`, `force_update`, `update_url`.

---

## 3. Database Integrity & Constraints Verification

- **Foreign Key Cascades**: Tested and verified. When a user account is deleted via `auth.users`, all linked rows in `profiles`, `devices`, `user_settings`, `playlists`, `channels`, `favorites`, `watch_history`, `watch_progress`, `movie_metadata`, and `epg_programs` are automatically and cleanly deleted.
- **Data Types & Sanitization**: Validated strictly via regex patterns for UUIDs, SHA-256 hashes, HTTPS URLs, and platform enums.
- **Multi-Tenant Partitioning**: All tables include compound unique constraints `(id, owner_id)` preventing foreign key attacks across tenant boundaries.

