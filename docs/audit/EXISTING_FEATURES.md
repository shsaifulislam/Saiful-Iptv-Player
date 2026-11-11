# Existing Features and Product Inventory

**Audit date:** 2026-11-11  
**Verification rule:** A declaration, route constant, model, dependency, or feature flag is not proof of working behavior. No Flutter runtime/build/test was available. No item below is classified “Working and verified.”

## Product Requirement Inventory

| # | Product capability | Current evidence | Audit classification |
|---:|---|---|---|
| 1 | Home dashboard | Root `MaterialApp` has a centered loading message only | UI only |
| 2 | Live TV and IPTV | No channel screen, stream repository, or player; channel model declaration exists | Missing; legal/provider authorization required for sources |
| 3 | M3U/M3U8 playlist management | Playlist model and feature flag exist; no parser/import flow | Partially implemented (model only); authorization required |
| 4 | Electronic Program Guide | EPG model, URL config and flags exist; no parser, matcher, schedule UI or refresh | Partially implemented (model/config only) |
| 5 | Movies and licensed VOD | Movie/series models and route constants exist; no VOD flow | Missing; licensed/provider-authorized content only |
| 6 | Local video player | `file_picker` dependency declared; no local media feature or playback engine | Missing |
| 7 | Audio player | Feature flag/route name only; no audio implementation | Missing |
| 8 | Photo gallery | Feature flag/route name only; no gallery implementation | Missing |
| 9 | YouTube official integration | API-key getter and feature flag only; no API integration or UI | Missing; official APIs/policies required |
| 10 | Favorites | Channel model has `isFavorite`; storage key/analytics event exist; no mutation/repository/UI | Partially implemented (data declarations only) |
| 11 | Watch history | History model/key/analytics event exist; no persistence or playback instrumentation | Partially implemented (data declarations only) |
| 12 | Continue watching | History model has a position, but no resume policy/UI/playback linkage | Missing |
| 13 | Subtitles and audio tracks | Feature flags/platform capability labels only; no player implementation | Missing |
| 14 | Multi-view playback | Flag/capability declarations only; no engine/session management | Missing; unsupported on several declared platforms pending proof |
| 15 | Picture-in-Picture | Flag/capability declarations only; no platform configuration or implementation | Missing; platform-dependent |
| 16 | Chromecast/DLNA | Chromecast flag is off by default; no dependency/adapter/receiver; no DLNA evidence | Missing; platform/provider constraints apply |
| 17 | User authentication | Supabase Auth wrapper/provider source exists, but required imports/generated code are missing; no auth UI | Broken source dependencies; partially implemented; runtime unverified |
| 18 | Cloud synchronization | Sync-state model, keys and flags exist; no repositories, schema, RLS or sync engine | Partially implemented (declarations only) |
| 19 | User profiles/device management | User model declaration only; no profile/device flows or server policy | Partially implemented (model only) |
| 20 | Settings and diagnostics | Settings keys/config constants exist; no settings screen, diagnostics UI or support export | Partially implemented (constants only) |
| 21 | Admin dashboard | No admin feature or server-side admin surface | Missing |
| 22 | Parental control | Flag and storage key exist; default flag is disabled; no secure PIN/policy/lock flow | Partially implemented (declarations only) |
| 23 | TV remote and keyboard navigation | Key-code constants and `tvMode` flag exist; no focus/remote interaction implementation | Missing; Tizen/webOS also unsupported pending adapters |

## Other Existing Source

- `main.dart` delegates to `bootstrap()`.
- `bootstrap.dart` initializes Flutter, logging, dotenv, Hive, optional Supabase and MediaKit, then runs the app.
- `app.dart` configures Material 3 themes but shows a loading placeholder.
- `route_names.dart`, `feature_flags.dart`, `platform_config.dart`, breakpoints and theme constants are declarations, not connected application flows.
- Eleven model files declare Freezed/JSON data structures. Their generated parts are absent.
- Auth has email/password, OAuth, reset and sign-out wrapper methods in source. Runtime behavior is unverified, and local imports/generated part are absent.
- Analytics has an abstract interface and console-only implementation. No production analytics backend is configured.

## Legal/Provider Boundaries

- Playlist import, Xtream-style connection, live TV, catch-up, recording, and VOD must operate only on user-owned, licensed, or explicitly authorized streams/content. Provider contracts and local law govern availability.
- YouTube work must use official supported APIs/player paths and honor YouTube terms, advertisements, authentication and DRM. No scraping or bypass.
- Downloading, timeshift and multi-view can be restricted by provider rights and platform capabilities; do not expose them as universally available.
