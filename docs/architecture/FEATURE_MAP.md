# Feature Map and Module Contracts

This is the target module contract, not evidence that the features exist. Current source has no functional feature screens. Common rules: application use cases depend on domain repository ports; repositories own API/local mapping; credentials and raw playable URLs are never sent to analytics or ordinary cloud rows. Platform states are detailed in [../platform/COMPATIBILITY_MATRIX.md](../platform/COMPATIBILITY_MATRIX.md).

## Home
- **Screens:** Home dashboard; first-run empty home; offline home.
- **Components:** Continue-watching rail, recently added, favorites shortcuts, playlist/source status, announcement banner.
- **Models:** `HomeSnapshot`, `WatchProgress`, `PlaylistSummary`, `Announcement`.
- **Business logic:** Aggregate local repositories; show stale/offline markers; do not fetch until consent/config exists.
- **API:** Optional sync delta and active announcements; local aggregation is primary.
- **Permissions:** None.
- **Errors:** Partial data, offline, expired session; retain usable local content and show retry.
- **Platforms:** Responsive phone/tablet/desktop; 10-foot TV shell needs platform testing; separate Tizen/webOS implementation.
- **Tests:** Unit aggregation/sorting; widget loading/empty/offline; integration with seeded local repositories.

## Live TV
- **Screens:** Channel browser, categories, channel details, guide-linked live view, fullscreen player.
- **Components:** Channel row/tile, logo fallback, now/next badge, category filter, favorite action, mini-player.
- **Models:** `Channel`, `Category`, `EpgProgram`, `PlaybackSession`.
- **Business logic:** Resolve channel from an authorized playlist; select adapter; preserve last channel; expose error/retry states.
- **API:** Local channel repository; optional EPG/sync API. Stream request is provider-authorized and never sent to a public proxy.
- **Permissions:** Network; no broad media-library access.
- **Errors:** Expired link, unauthorized, offline, unsupported codec, timeout, provider restriction.
- **Platforms:** Candidate Android/desktop adapters require tests; Tizen/webOS require separate playback bridges.
- **Tests:** Unit URL/authorization boundary and channel selection; adapter contract tests; device integration on licensed fixture.

## Playlist Manager
- **Screens:** Playlist list, add/import, edit metadata, refresh status, source detail, remove confirmation.
- **Components:** Source type selector, URL/file import, masked credential fields, validation summary, sync badge.
- **Models:** `Playlist`, `PlaylistSourceLocalRef`, `PlaylistImportReport`, `CredentialHandle` (handle only; secret remains in OS vault).
- **Business logic:** Parse M3U safely, cap size/time, reject malformed rows, deduplicate, redact secrets, require rights acknowledgment.
- **API:** Cloud metadata CRUD only; remote URL fetching is client/provider controlled unless a reviewed backend fetch design exists.
- **Permissions:** User-selected file access; network for a user-entered source.
- **Errors:** Invalid/oversized file, unsupported scheme, network/CORS, bad auth, zero playable entries, partial parse.
- **Platforms:** Android/desktop file APIs need native validation; TV import via remote typing/QR or companion flow is separate.
- **Tests:** Parser fuzz/size limits/redaction; import/export round-trip using synthetic authorized fixtures; secure-store integration.

## EPG
- **Screens:** Grid guide, channel schedule, program detail, refresh/source settings.
- **Components:** Time ruler, now line, program tile, timezone label, catch-up affordance only when authorized.
- **Models:** `EpgProgram`, `EpgSource`, `EpgSyncState`.
- **Business logic:** Parse XMLTV, normalize timezone, map provider IDs to channels, update windows incrementally, detect duplicate/invalid periods.
- **API:** Optional EPG source retrieval and metadata sync; no bundled third-party guide data.
- **Permissions:** Network only for a configured source.
- **Errors:** Parse failure, channel mismatch, stale data, clock/timezone inconsistency.
- **Platforms:** Core logic cross-platform; large timeline performance and focus require phone/TV-specific tests.
- **Tests:** Parser fixtures, timezone/DST/matching tests; guide rendering and refresh integration tests.

## Movies and VOD
- **Screens:** Movie library, filters, movie details, player handoff; series detail/season/episode list when licensed.
- **Components:** Poster/backdrop, metadata chips, play/resume actions, content-rights availability badge.
- **Models:** `MovieMetadata`, `Series`, `Season`, `Episode`, `WatchProgress`.
- **Business logic:** Browse only authorized catalog metadata; resolve playback source through owning provider; resume and history policy.
- **API:** Licensed provider/catalog API or user-owned playlist; Supabase stores only approved metadata.
- **Permissions:** Network; media permission only for local catalog assets if needed.
- **Errors:** Unavailable title, entitlement/provider auth failure, playback unsupported, metadata mismatch.
- **Platforms:** Same as playback adapter matrix; smart TVs need separate implementation.
- **Tests:** Catalog mapping/entitlement tests; resume behavior; player integration on authorized test content.

## Local Video
- **Screens:** Local library, folders/recents, file detail, player, permission explanation.
- **Components:** File picker, media row, storage source badge, resume marker, subtitle/track picker.
- **Models:** `LocalMediaItem`, `PlaybackSession`, `SubtitleTrack`.
- **Business logic:** Use scoped system pickers, persist only granted references, index only user-selected locations, keep offline.
- **API:** None for media bytes; optional user-approved metadata sync only.
- **Permissions:** Platform document picker/media library; request least privilege at point of use.
- **Errors:** Permission denied/revoked, file moved, unsupported container/codec, corrupt file.
- **Platforms:** Native file adapters on Android/desktop; TV browsing differs; Tizen/webOS separate.
- **Tests:** Permission adapter contract, file-reference restart tests, local playback integration by codec matrix.

## Music
- **Screens:** Music library, album/artist, now playing, queue.
- **Components:** Album tile, queue, transport, metadata/lyrics slot (licensed source only).
- **Models:** `AudioItem`, `PlaybackQueue`, `PlaybackSession`.
- **Business logic:** Local scan by permission; queue/shuffle/repeat; background controls only where adapter supports.
- **API:** None for local files; approved metadata services only.
- **Permissions:** User-selected files or OS media permission; background audio permission where required.
- **Errors:** Missing file, unsupported codec, output route failure, background restriction.
- **Platforms:** Native audio/session adapters require per-target test; smart TV separate.
- **Tests:** Queue and repeat unit tests; lifecycle/headphone/background integration tests.

## Photos
- **Screens:** Albums, grid, viewer/slideshow, item details.
- **Components:** Responsive thumbnail grid, zoom/pan viewer, metadata and share action.
- **Models:** `PhotoAsset`, `Album`, `PhotoPermissionState`.
- **Business logic:** Browse user-selected images; avoid implicit cloud uploads; manage thumbnail cache.
- **API:** None by default; cloud backup requires explicit opt-in.
- **Permissions:** Photo picker or scoped media permission.
- **Errors:** Permission denied, inaccessible URI, decode/memory limit, cache failure.
- **Platforms:** Native picker and large-screen viewer need validation; TV has a distinct gallery layout.
- **Tests:** Permission and cache unit tests; image decode and zoom widget tests; device picker integration.

## YouTube (Official)
- **Screens:** YouTube hub, search/discovery, saved links, official player handoff/embed.
- **Components:** Search field, video metadata card, official player surface, attribution/actions.
- **Models:** `SavedYouTubeLink`, `YouTubeVideoSummary`.
- **Business logic:** Use official supported APIs/player; honor auth, ads, DRM, age/region and terms; API keys are not secrets but quota/auth policies still apply.
- **API:** Official YouTube Data API where permitted; official embedded/player SDK path for playback.
- **Permissions:** Network; account auth only where the official flow requires it.
- **Errors:** Quota, disabled embed, age/region restriction, invalid ID, offline.
- **Platforms:** Each official SDK/embed flow must be tested on Android, desktop and TV; smart TV may require official web/runtime support.
- **Tests:** ID parsing/allowlist tests; mock API contract/quota tests; playback policy and platform integration tests.

## Search
- **Screens:** Global search, suggestions, results by content type, no-results.
- **Components:** Debounced input, filter tabs, result rows, clear/recent query actions.
- **Models:** `SearchQuery`, `SearchResult`.
- **Business logic:** Search local catalog first; normalize Bengali/Latin text; never send raw query unless an explicitly approved remote catalog requires it.
- **API:** Local index; optional authorized catalog search.
- **Permissions:** None.
- **Errors:** Offline remote search, malformed index, empty result; retain local results.
- **Platforms:** Keyboard, touch and D-pad input require distinct focus behavior.
- **Tests:** Unicode/Bengali normalization, ranking and debounce units; search navigation widget/integration tests.

## Favorites
- **Screens:** Favorite channels/movies, category filters, reorder/remove.
- **Components:** Favorite toggle with semantic state, content row, offline indicator.
- **Models:** `Favorite`, `FavoriteTarget`.
- **Business logic:** Optimistic local toggle, idempotent sync, tombstone delete.
- **API:** Favorite upsert/delete; RLS owner scoped.
- **Permissions:** Auth only for cloud sync; local favorites usable signed out.
- **Errors:** Sync conflict, missing/deleted target, auth expired.
- **Platforms:** Cross-platform UI; TV remote toggle and focus restore require testing.
- **Tests:** Idempotency/merge units; offline toggle-sync integration and focus tests.

## Watch History
- **Screens:** Recent history, history item detail, clear history/retention controls.
- **Components:** Watched-at label, progress preview, clear confirmation.
- **Models:** `WatchHistory`, `WatchProgress`.
- **Business logic:** Record only after actual playback, configurable retention, clear locally and sync deletion.
- **API:** Append/update user-scoped history and progress.
- **Permissions:** Auth only for cloud sync.
- **Errors:** Stale progress, sync failure, media deleted; do not block playback.
- **Platforms:** Cross-platform; cross-device merge needs tests.
- **Tests:** Position clamping/completion, retention/clear semantics; offline sync and resume integration.

## Downloads
- **Screens:** Download queue, item progress/detail, storage usage, retry/cancel.
- **Components:** Progress row, storage warning, license/offline availability label.
- **Models:** `DownloadTask`, `DownloadEntitlement`, `DownloadStatus`.
- **Business logic:** Queue only content with explicit download rights; encrypted/managed file handling where required; pause/resume and cleanup.
- **API:** Licensed provider download API only; sync metadata, not media bytes.
- **Permissions:** Storage/document access and background execution per OS.
- **Errors:** No space, rights denied, token expired, interrupted task, checksum mismatch.
- **Platforms:** Native background/storage adapters required; unsupported until per-target validation, especially TVs.
- **Tests:** Queue/state/retry units; process restart, permission, storage and rights integration tests.

## Multi-view
- **Screens:** Layout chooser, 2/4 pane workspace, pane picker, focus/audio-source control.
- **Components:** Fixed-aspect panes, active-pane focus, per-pane controls, bandwidth warning.
- **Models:** `MultiViewSession`, `PlaybackPane`.
- **Business logic:** Enforce engine/session limits, single audio focus, explicit resource budget and provider limits.
- **API:** Local session only; no server stream aggregation.
- **Permissions:** Network for each authorized stream.
- **Errors:** Decoder exhaustion, stream failure, provider limit, unsupported platform.
- **Platforms:** Requires testing on high-memory desktop/Android; smart TVs require separate implementation and may be unsupported.
- **Tests:** Pane lifecycle/resource limits; multi-session device load tests and focus/navigation integration.

## User Accounts
- **Screens:** Sign-in, sign-up, password recovery, consent, account details, sign-out/delete.
- **Components:** Validated form, password reveal, error/status banners, destructive-action confirmation.
- **Models:** `AuthSession`, `Profile`, `AccountDeletionState`.
- **Business logic:** Supabase Auth lifecycle, secure token handling, re-auth for sensitive operations, account deletion policy.
- **API:** Supabase Auth endpoints and profile API; never store user password.
- **Permissions:** Network; platform browser/deep-link callback for supported OAuth.
- **Errors:** Invalid credentials, rate limit, email verification, OAuth callback mismatch, offline.
- **Platforms:** Native/web OAuth redirect handling must be configured/tested per platform; Tizen/webOS separate.
- **Tests:** Auth state transition units; mocked provider flows; redirect/session restore integration.

## Device Management
- **Screens:** Device list, current device detail, rename/revoke, active-session status.
- **Components:** Device card, last-seen label, revoke confirmation.
- **Models:** `Device`, `DeviceSession`.
- **Business logic:** Register opaque installation ID, rotate/revoke session, enforce server-side device limits.
- **API:** Register/list/revoke through owner-scoped endpoint/RPC.
- **Permissions:** Network; do not read hardware identifiers.
- **Errors:** Device limit, revoked session, stale registration, auth expired.
- **Platforms:** All app targets require platform identifiers; smart-TV registration is separate adapter work.
- **Tests:** Ownership/limit unit tests; cross-user RLS and revocation integration tests.

## Settings
- **Screens:** General, playback, privacy, sync, accessibility, parental controls, diagnostics.
- **Components:** Accessible toggles/selectors/sliders, reset, export sanitized diagnostics.
- **Models:** `UserSettings`, `PlaybackPreferences`, `PrivacyPreferences`.
- **Business logic:** Validate values, persist locally, sync allow-listed preferences; parental PIN remains in secure local storage.
- **API:** Optional settings sync; no secrets or device-only permissions in cloud JSON.
- **Permissions:** Only when user activates a feature.
- **Errors:** Invalid setting, migration failure, unsupported capability; revert safely.
- **Platforms:** Layout adapts to touch, pointer and remote; device-specific controls are capability-gated.
- **Tests:** Validation/migration units; persistence and platform capability integration.

## Notifications
- **Screens:** Notification preferences, reminder list, in-app announcement details.
- **Components:** Permission prompt, reminder editor, dismissible announcement.
- **Models:** `NotificationPreference`, `ProgramReminder`, `Announcement`.
- **Business logic:** Schedule local reminders; avoid transmitting viewing details unless opt-in; respect quiet hours.
- **API:** Announcement read and optional reminder sync.
- **Permissions:** Notifications requested at point of use; background scheduling varies by OS.
- **Errors:** Denied permission, stale schedule/timezone shift, service unavailable.
- **Platforms:** Native notification adapters required; Tizen/webOS support not assumed.
- **Tests:** Scheduling/timezone units; permission-denial and delivery integration tests per target.

## Admin Dashboard
- **Screens:** Separate secure web console for announcements, bug triage, feature operations and audit logs.
- **Components:** Role-gated tables, filters, detail drawer, confirmation and audit trail.
- **Models:** `Announcement`, `BugReport`, `AdminAuditEvent`.
- **Business logic:** Server-side role authorization, least privilege, immutable audit records; no admin powers in Flutter client.
- **API:** Edge Functions/admin service only; privileged keys never reach clients.
- **Permissions:** Staff identity, MFA and server-side role checks.
- **Errors:** Forbidden, stale update, rate limit, validation failure.
- **Platforms:** Separate responsive web implementation; not a TV/mobile app screen.
- **Tests:** Policy tests and authorization-negative tests; admin API integration and audit-event tests.
