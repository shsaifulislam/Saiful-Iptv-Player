# Saiful IPTV Player — Row Level Security (RLS) & Security Audit Report

## 1. Security Architecture Summary

The Saiful IPTV Player backend enforces strict tenant isolation, role-based access control, and defense-in-depth sanitization:
1. **Default Deny**: All permissions are revoked from `anon` and `authenticated` roles prior to granting minimal required privileges.
2. **Mandatory RLS**: Row Level Security is explicitly enabled on all tables without exception.
3. **No Service-Role Key in Client**: The client binary only contains the public `SUPABASE_ANON_KEY`. The `SUPABASE_SERVICE_ROLE_KEY` is restricted strictly to backend Edge Functions.
4. **No Plaintext Passwords or Tokens in Database**: Enforced by client vault, Edge Function validators, and database triggers.
5. **No Password Access for Admins**: Admin endpoints have zero ability to query or view user provider passwords.

---

## 2. Row Level Security Policy Matrix

| Table | Policy Name | Command | Roles | Using / With Check Clause | Purpose |
|---|---|---|---|---|---|
| `profiles` | `profiles_select_own` | SELECT | `authenticated` | `id = (select auth.uid())` | Users only see their own profile |
| `profiles` | `profiles_update_own` | UPDATE | `authenticated` | `id = (select auth.uid())` | Users only update safe fields in own profile |
| `devices` | `devices_select_own` | SELECT | `authenticated` | `user_id = (select auth.uid())` | Prevents device enumeration across users |
| `user_settings` | `settings_select_own` | SELECT | `authenticated` | `user_id = (select auth.uid())` | Isolated settings view |
| `user_settings` | `settings_update_own` | UPDATE | `authenticated` | `user_id = (select auth.uid())` | Enforces self-update + secret validation trigger |
| `playlists` | `playlists_select_own` | SELECT | `authenticated` | `owner_id = (select auth.uid())` | Full playlist isolation |
| `channels` | `channels_select_own` | SELECT | `authenticated` | `owner_id = (select auth.uid())` | Full channel isolation |
| `movie_metadata` | `movies_select_own` | SELECT | `authenticated` | `owner_id = (select auth.uid())` | Full movie catalog isolation |
| `favorites` | `favorites_select_own` | SELECT | `authenticated` | `owner_id = (select auth.uid())` | Isolated favorites |
| `watch_history` | `history_select_own` | SELECT | `authenticated` | `owner_id = (select auth.uid())` | Viewing history isolation |
| `watch_progress` | `progress_select_own` | SELECT | `authenticated` | `owner_id = (select auth.uid())` | Playback position isolation |
| `epg_programs` | `epg_select_own` | SELECT | `authenticated` | `owner_id = (select auth.uid())` | Program guide cache isolation |
| `saved_youtube_links` | `youtube_select_own` | SELECT | `authenticated` | `owner_id = (select auth.uid())` | Saved link isolation |
| `sync_jobs` | `sync_jobs_select_own` | SELECT | `authenticated` | `user_id = (select auth.uid())` | Sync ledger isolation |
| `sync_events` | `sync_events_select_own`| SELECT | `authenticated` | `owner_id = (select auth.uid())` | Event stream cursor isolation |
| `app_announcements` | `announcements_read_active` | SELECT | `anon`, `authenticated` | `published and starts_at <= now() and (ends_at is null or ends_at > now())` | Only active published announcements readable |
| `bug_reports` | `bug_reports_select_own` | SELECT | `authenticated` | `owner_id = (select auth.uid())` | Bug report privacy |
| `feature_config` | `feature_config_read_enabled` | SELECT | `authenticated` | `enabled = true` | Only active flags exposed |
| `feature_config` | `feature_config_admin_write` | ALL | `authenticated` | `public.is_app_admin()` | Admin-only write access |
| `admin_audit_log` | `admin_audit_admin_read` | SELECT | `authenticated` | `public.is_app_admin()` | Admin-only audit access |
| `app_release_info`| `release_info_read` | SELECT | `anon`, `authenticated` | `true` | Public version check |
| `app_release_info`| `release_info_admin_write`| ALL | `authenticated` | `public.is_app_admin()` | Admin-only version configuration |

---

## 3. Storage Security (`profile-avatars`)

The `profile-avatars` bucket is private (`public = false`) and capped at 5 MB:
- Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`.
- **Read Policy**: `bucket_id = 'profile-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text`.
- **Upload / Update / Delete Policy**: Strictly restricted to folder matching user's own `auth.uid()`.
- Users cannot read, overwrite, or delete avatars uploaded by other accounts.

---

## 4. Edge Function Security & Rate Limiting

All Edge Functions run on Deno with JWT verification enabled:
- **Rate Limiting via `consume_rate_limit` RPC**:
  - `account_delete`: 2 requests / 24 hours.
  - `device_register`: 10 requests / hour.
  - `device_revoke`: 10 requests / hour.
  - `sync_post` / `sync_get`: 120 requests / minute.
  - `bug_report`: 5 requests / hour.
  - `admin_api`: 120 requests / minute.
- **Payload Size Caps**:
  - `account-delete`: 4 KB max.
  - `device-register`: 4 KB max.
  - `device-revoke`: 2 KB max.
  - `bug-report`: 24 KB max.
  - `sync`: 1 MB max (100 items per batch).
- **Sanitization Checks**:
  - Regular expressions reject embedded passwords or basic auth syntax in stream URLs.
  - Key filtering drops or rejects requests with `password`, `token`, `api_key`, `credentials`.

---

## 5. Admin Panel Security & Separation of Duties

The Admin Panel (`admin/index.html`) requires authentication with `app_metadata.role = 'admin'`:
- Protected server-side via `is_app_admin()` which queries `auth.users.raw_app_meta_data ->> 'role' = 'admin'`. Client-provided `user_metadata` cannot elevate privileges.
- Admin APIs return only user identity metadata (`email`, `created_at`, `last_sign_in_at`, `banned_until`).
- Admins cannot query user playlist sources, Xtream Codes credentials, or video URLs.

