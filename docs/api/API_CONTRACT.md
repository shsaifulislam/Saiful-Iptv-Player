# API Contracts

**Status:** Logical contract blueprint; no endpoints are deployed by this document. The current Supabase project configuration/schema is absent. Implement either through owner-scoped Supabase PostgREST/RPC/Edge Functions or a versioned API gateway, but keep the same authorization and field rules. All timestamps are RFC 3339 UTC. JSON uses `snake_case` in transport DTOs.

## Shared Contract

- Base path: `/v1` for app-owned operations. Supabase Auth retains its official `/auth/v1/*` contract.
- App requests use `Authorization: Bearer <user_access_token>` and the public client key header required by the Supabase deployment. Never send a service-role key.
- Server derives `user_id` from the validated token. Ignore/reject client-supplied ownership fields.
- JSON response: `{ "data": ..., "request_id": "..." }` on success; paginated lists add `next_cursor`.
- Error response: `{ "error": { "code": "...", "message": "...", "retryable": false, "field_errors": {} }, "request_id": "..." }`. Messages are sanitized and contain no provider response, credential, stream URL, or stack trace.
- Support `Idempotency-Key` for create/sync/bug report mutations. Return the original result for a duplicate key.
- Validation limits: bounded page size (default 50, max 100), bounded request body, allow-listed enum values, strict ownership, and request rate limits.
- Any stream URL, Xtream password, API secret, signed URL or authorization token is forbidden in cloud metadata payloads. Playlist source metadata contains only source type, display name and optionally normalized host. Playback locators stay local/secure or in an approved provider flow.

## Authentication

Use Supabase Auth's official endpoints and SDK. Client passwords are transmitted only over TLS to Auth and are never stored in app database tables or logs.

| Operation | Request | Success | Authorization and errors |
|---|---|---|---|
| Sign up | `POST /auth/v1/signup` `{email,password,options:{email_redirect_to?}}` | Provider session/user or verification-required response | Anonymous allowed; `400` invalid, `409` duplicate, `429` rate limit |
| Sign in | `POST /auth/v1/token?grant_type=password` `{email,password}` | Session with access/refresh tokens and expiry | Anonymous allowed; `400/401` invalid, `429` rate limit |
| Refresh | `POST /auth/v1/token?grant_type=refresh_token` `{refresh_token}` | Rotated session | Refresh token required; `400/401` invalid/reused |
| Sign out | `POST /auth/v1/logout` | `204` | Bearer required; client clears local session even if offline, then retries revocation if needed |
| Password recovery | `POST /auth/v1/recover` `{email,redirect_to?}` | Generic accepted response | Anonymous allowed; avoid account enumeration |

Store session tokens using supported OS-backed SDK storage. Configure platform OAuth redirect allowlists before enabling OAuth. Account deletion must re-authenticate, run server-side cascade/retention policy, and return a deletion request ID.

## Profile

- `GET /v1/profile` -> `{id,display_name,avatar_url,locale,created_at,updated_at}`.
- `PATCH /v1/profile` request `{display_name?,avatar_url?,locale?}` -> canonical profile.
- Auth: user bearer; server maps `id=auth.uid()`. Never accept email, role, subscription entitlement or `user_id` changes from this endpoint.
- Errors: `401` expired; `403` forbidden; `422` invalid name/URL/locale; `429`; `5xx` retryable.

## Playlist Metadata

- `GET /v1/playlists?cursor=&limit=` -> `{items:[{id,name,source_kind,source_host?,enabled,created_at,updated_at}],next_cursor}`.
- `POST /v1/playlists` request `{name,source_kind,source_host?,client_idempotency_key}` -> `201` metadata.
- `PATCH /v1/playlists/{id}` request `{name?,enabled?}` -> canonical metadata.
- `DELETE /v1/playlists/{id}` -> `204`; client also deletes local protected source/credential references.
- Auth: owner bearer; RLS scope from token. `source_host` must be a normalized host only, no userinfo, path, query or fragment. Raw locator/credential fields are rejected (`422 secret_field_forbidden`).
- Errors: `404` not found or not owned; `409` duplicate/client conflict; `422` invalid type/host; `429`; retryable `5xx`.

## Favorites

- `GET /v1/favorites?cursor=&limit=` -> `{items:[{id,target_type,target_id,created_at}],next_cursor}`.
- `PUT /v1/favorites/{target_type}/{target_id}` -> `200` existing or `201` created `{id,target_type,target_id,created_at}`; idempotent.
- `DELETE /v1/favorites/{target_type}/{target_id}` -> `204`; idempotent.
- Auth: owner bearer; valid target and ownership checked by policy/RPC.
- Errors: `401`, `404` target missing/not owned, `409` invalid target, `429`, retryable `5xx`.

## Watch History and Progress

- `POST /v1/watch-history` request `{event_id,content_type,content_id,started_at,ended_at?,position_seconds,duration_seconds?}` -> `202` accepted.
- `PUT /v1/watch-progress/{content_type}/{content_id}` request `{position_seconds,duration_seconds?,updated_at,revision?}` -> `{content_type,content_id,position_seconds,duration_seconds,completed,updated_at,revision}`.
- `GET /v1/watch-progress?cursor=&limit=` -> user-owned items and cursor.
- Auth: owner bearer. Values are clamped/validated; server rejects negative or implausible duration. `event_id` makes history idempotent.
- Conflict: `409 revision_conflict` returns current revision; client applies the documented latest-valid-progress merge, not blind overwrite.
- Errors: `401`, `404`, `409`, `422`, `429`, retryable `5xx`.

## Device Registration

- `POST /v1/devices` request `{installation_id_hash,device_name,platform,app_version}` -> `{id,device_name,platform,last_seen_at,revoked_at}`.
- `GET /v1/devices` -> user's devices only.
- `POST /v1/devices/{id}/revoke` -> `{id,revoked_at}` and server invalidates eligible sessions.
- Auth: owner bearer; installation identifier is an app-generated opaque/hash value, never IMEI/serial/MAC.
- Errors: `401`, `404`, `409 device_limit`, `422 invalid_platform`, `429`.

## Cloud Sync

- `POST /v1/sync/changes` request `{device_id,cursor?,changes:[{idempotency_key,entity_type,entity_id,operation,revision?,fields:{...}}]}`; maximum 100 allow-listed metadata changes per batch.
- Response `{accepted:[{idempotency_key,server_revision}],conflicts:[{idempotency_key,server_revision,fields}],rejected:[{idempotency_key,code}],next_cursor}`.
- `GET /v1/sync/changes?cursor=&limit=` returns changes after cursor and a new cursor.
- Auth: device and user must match token; server applies RLS and per-entity validation. Arbitrary SQL, raw credentials, media URLs, and unrestricted JSON payloads are forbidden.
- Retry only retryable errors with same idempotency keys. `409` is a conflict response, not an automatic overwrite. `413` oversized; `422` invalid change; `429`; `5xx` retryable.

## Announcements

- `GET /v1/announcements?platform=&locale=&cursor=` -> active, published `{id,title,body,severity,starts_at,ends_at,updated_at}`.
- Read may be public if announcement text is explicitly public; server filters by time, platform and locale. Create/update/publish is admin-only through server-side authorization, never direct client table writes.
- Errors: `400` invalid filters, `429`, retryable `5xx`.

## Bug Reports

- `POST /v1/bug-reports` request `{client_idempotency_key,category,summary,description,app_version,platform,diagnostics_opt_in,diagnostics?}` -> `202` `{id,status,created_at}`.
- `GET /v1/bug-reports/{id}` -> own report's non-sensitive status only.
- Auth: signed-in user required by default. If anonymous intake is later approved, rate-limit and abuse controls are required. Server strips/validates diagnostics and rejects raw URLs/tokens/passwords.
- Errors: `401`, `404`, `413`, `422`, `429`; no raw backend exception returned.
- Retention and deletion follow the database policy; support/admin access is audited.

## Error Mapping and Authorization Tests

- `401 unauthenticated`: clear/refresh session as appropriate; no infinite retry.
- `403 forbidden`: do not retry or disclose record existence where policy requires concealment.
- `404 not_found`: missing or not owned.
- `409 conflict`: surface merge state and retain local pending changes.
- `413 payload_too_large`, `422 validation_error`: actionable local correction.
- `429 rate_limited`: respect `Retry-After`.
- `5xx service_unavailable`: bounded backoff; local-first actions remain available.

Before release, test anonymous/owner/other-user/admin access for every table and endpoint; test idempotency, rate limits, credential field rejection, cursor replay and offline retries.
