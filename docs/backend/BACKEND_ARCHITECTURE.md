# Saiful IPTV Player — Cloud Backend Architecture

## 1. System Overview

The Saiful IPTV Player backend is built on **Supabase** (PostgreSQL 15, GoTrue Auth, Storage, Edge Runtime) with a **Zero-Trust Client** security model. The architecture provides multi-device synchronization for user library metadata and viewing progress while strictly enforcing client-side secrecy for user IPTV provider credentials and local media files.

```
+-----------------------------------------------------------------------------------+
|                                 CLIENT DEVICES                                    |
|  (Android / Android TV / Windows / macOS / Linux / iOS / Web / Tizen / webOS)     |
+----------------------------------------+------------------------------------------+
                                         |
               +-------------------------+-------------------------+
               | HTTPS (TLS 1.3)                                   | HTTPS (TLS 1.3)
               | Supabase Anon Key                                 | Supabase Anon Key
               v                                                   v
+-------------------------------+                 +---------------------------------+
|     SUPABASE GO-TRUE AUTH     |                 |     DENO EDGE FUNCTIONS         |
|  - Email/Password Sign-up     |                 |  - device-register              |
|  - Password Reset via Email   |                 |  - device-revoke                |
|  - PKCE Session Restoration   |                 |  - sync (push / pull)           |
|  - JWT Issuance & Refresh     |                 |  - bug-report                   |
+---------------+---------------+                 |  - account-delete               |
                |                                 |  - admin-api (RBAC protected)   |
                | auth.uid()                      +----------------+----------------+
                v                                                  | Service Role /
+------------------------------------------------------------------+ RPC Calls
|                    POSTGRESQL 15 DATABASE ENGINE                                  |
|  +-----------------------------------------------------------------------------+  |
|  | ROW LEVEL SECURITY (RLS) LAYER (Default: REVOKE ALL, ENABLE RLS ON ALL)     |  |
|  | - profiles              - devices               - user_settings             |  |
|  | - playlists             - channels              - favorites                 |  |
|  | - watch_history         - watch_progress        - movie_metadata            |  |
|  | - epg_programs          - saved_youtube_links   - sync_jobs                 |  |
|  | - sync_events           - app_announcements     - bug_reports               |  |
|  | - feature_config        - rate_limit_buckets    - admin_audit_log           |  |
|  | - app_release_info                                                          |  |
|  +-----------------------------------------------------------------------------+  |
|  | STORED PROCEDURES & TRIGGERS                                                |  |
|  | - apply_sync_changes() (Transactional batch processing & conflict check)    |  |
|  | - register_device()     - revoke_device()       - submit_bug_report()       |  |
|  | - consume_rate_limit()  - is_app_admin()        - validate_user_settings()  |  |
|  +-----------------------------------------------------------------------------+  |
|  | SUPABASE SECURE STORAGE                                                     |  |
|  | - Bucket 'profile-avatars' (Private, isolated by auth.uid(), max 5MB)      |  |
|  +-----------------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------------+
```

---

## 2. Core Architectural Pillars

### 2.1 Zero-Knowledge Provider Credential Architecture
Under no circumstances are Xtream Codes credentials, M3U username/password query parameters, or raw private streaming URLs stored in PostgreSQL or passed to Edge Functions.
- **Client Vault**: Credentials are saved exclusively on the device using platform secure hardware keystores (`flutter_secure_storage`: Android KeyStore, Windows Credential Manager, macOS Keychain, Linux Secret Service).
- **Sanitization Triggers**: Both database triggers (`user_settings_secret_guard`) and Edge Function validators reject any sync batch or bug report containing forbidden keys (`password`, `token`, `credentials`, `stream_url`) or URL patterns matching `scheme://user:pass@host`.

### 2.2 Local Media Exemption
Local storage features (offline video, photos, audio) remain purely local on the host device. The cloud backend synchronizes only lightweight playlist metadata, channel identifiers, watch history timestamps, and application settings.

### 2.3 Row Level Security by Default
Every user-owned table has Row Level Security strictly enforced:
- Default `REVOKE ALL ON ALL TABLES FROM anon, authenticated;`
- Fine-grained explicit `GRANT SELECT, UPDATE` only on safe columns.
- Policies verify `id = (select auth.uid())` or `owner_id = (select auth.uid())`.
- Direct SQL inserts and deletes on sync tables from the client are forbidden; all state changes flow through the transactional `apply_sync_changes` security-definer RPC function.

---

## 3. Component Breakdown

### 3.1 Supabase Auth & Session Management
- **Registration**: Email and password account creation. Password requirements configured in `supabase/config.toml` (minimum 12 chars, upper/lower/digits/symbols).
- **Session Persistence**: Sessions are encrypted in `SecureSessionStorage` implementing `LocalStorage` and `GotrueAsyncStorage` with PKCE code challenge verification.
- **Session Expiration**: Expired tokens fail with HTTP 401; the client auto-refreshes using refresh tokens or gracefully degrades to offline mode.
- **Account Deletion Flow**: Invokes `account-delete` edge function with password re-authentication. Purges user avatar storage objects, records audit log, and cascades user deletion in PostgreSQL auth schema.

### 3.2 Cloud Sync Architecture
- **Protocol**: Transactional batch synchronization (`apply_sync_changes`) with cursor-based event streaming (`sync_events`).
- **Idempotency**: Every mutation has a unique client-generated UUID `idempotency_key`. Re-submitted items are acknowledged without duplicating database records or re-triggering revisions.
- **Revision Tracking**: Monotonic integer revisions (`revision bigint not null default 1`). Stale base revisions are detected and returned as conflicts to the client.
- **Conflict Resolution**: Client-side Last-Write-Wins (LWW) based on verified timestamps, with automatic rebase capability.
- **Offline Queue**: `SyncOutbox` and `LocalSyncStore` maintain pending operations in persistent client storage, featuring exponential backoff (5s up to 3600s clamp) on network or server interruptions.

### 3.3 Admin Control Room
A dedicated HTML/ES-module control panel located in `admin/index.html` operates against the `admin-api` Edge Function:
- **RBAC**: Protected by server-side `app_metadata.role = 'admin'` (`is_app_admin()`).
- **Zero Exposure**: Admin API lists users, devices, and reports without exposing playlist URLs, provider passwords, or client streams.
- **Capabilities**:
  1. Service health monitoring
  2. User ban/unban and deletion
  3. Device inventory overview and remote device revocation
  4. Global announcements publishing with scheduling and severity
  5. Bug report triage and support status lifecycle tracking
  6. Feature flags toggle
  7. Client version and force-update configuration

---

## 4. Key Endpoints & Edge Functions

| Function | Method | Auth Required | Rate Limit | Purpose |
|---|---|---|---|---|
| `device-register` | POST | Authenticated (JWT) | 10 / hour | Registers or updates device installation hash and platform |
| `device-revoke` | POST | Authenticated (JWT) | 10 / hour | Revokes device token access |
| `sync` | GET | Authenticated (JWT) | 120 / min | Pulls remote events since cursor |
| `sync` | POST | Authenticated (JWT) | 120 / min | Pushes batch mutations (up to 100 items) to `apply_sync_changes` |
| `bug-report` | POST | Authenticated (JWT) | 5 / hour | Submits sanitized client bug reports |
| `account-delete` | POST | Authenticated (JWT) | 2 / day | Re-authenticates password and permanently purges user account |
| `admin-api` | POST | Admin (Role check) | 120 / min | Administrative management operations |

