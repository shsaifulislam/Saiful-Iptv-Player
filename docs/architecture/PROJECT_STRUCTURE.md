# Target Project Structure

This is the proposed complete feature-first structure. It documents the destination only; folders/files listed here are not all implemented or created. Prompt 01 found empty platform/test/backend directories and a smaller partial `lib/` tree. Migrate incrementally; do not move existing code until imports, ownership and tests are understood.

```text
saiful_iptv_player/
|-- android/                         # Flutter-generated Android app; phone/tablet/TV
|-- windows/                         # Flutter-generated Windows runner
|-- macos/                           # Flutter-generated macOS runner
|-- linux/                           # Flutter-generated Linux runner
|-- web/                             # Optional web target, not in current release scope
|-- tizen/                           # Separate Tizen host/bridge; feasibility gated
|-- webos/                           # Separate webOS host/bridge; feasibility gated
|-- assets/
|   |-- images/                       # First-party artwork/placeholders only
|   |-- icons/
|   |-- fonts/                        # Inter and Noto Sans Bengali licensed font assets
|   |-- animations/
|   `-- placeholders/
|-- lib/
|   |-- main.dart
|   |-- bootstrap.dart
|   |-- app/
|   |   |-- app.dart
|   |   |-- config/                   # Environment-safe config and capability flags
|   |   |-- router/                   # Route definitions, guards, deep links
|   |   |-- theme/                    # Tokens, themes, text, dimensions
|   |   `-- responsive/               # Breakpoints and layout policies
|   |-- core/
|   |   |-- constants/
|   |   |-- errors/                   # Typed failures/results
|   |   |-- network/                  # Client config, URL validation, retry policy
|   |   |-- security/                 # Redaction, credential boundaries
|   |   |-- database/                 # Migration/version interfaces
|   |   |-- logging/
|   |   `-- utils/
|   |-- domain/
|   |   |-- entities/                 # Platform-independent product entities
|   |   |-- value_objects/
|   |   |-- repositories/             # Repository ports
|   |   |-- policies/                 # Rights, sync and capability rules
|   |   `-- playback/                 # Player ports/capability values
|   |-- data/
|   |   |-- local/                    # DB adapters, DAOs, outbox, secure-vault bridge
|   |   |-- remote/                   # Supabase DTOs, API clients, Edge Function client
|   |   |-- repositories/             # Repository implementations and mapping
|   |   `-- models/                   # Transport/storage DTOs; not UI/domain entities
|   |-- services/
|   |   |-- auth/
|   |   |-- cloud/
|   |   |-- analytics/                # Redacted, consent-aware events
|   |   |-- notifications/
|   |   |-- sync/                     # Outbox worker, conflict and cursor handling
|   |   `-- diagnostics/
|   |-- playback/
|   |   |-- player_controller.dart    # App-owned session API/state
|   |   |-- player_engine.dart         # Engine port
|   |   |-- adapters/
|   |   |   |-- media_kit/
|   |   |   |-- android_media3/
|   |   |   |-- tizen/
|   |   |   `-- webos/
|   |   `-- models/                   # Playback source, tracks, errors, capabilities
|   |-- platform_adapters/
|   |   |-- android/                  # Pickers, PiP, secure storage, remote keys
|   |   |-- desktop/                  # Files, shortcuts, window lifecycle
|   |   |-- tizen/
|   |   `-- webos/
|   |-- features/
|   |   |-- home/
|   |   |-- live_tv/
|   |   |-- playlists/
|   |   |-- epg/
|   |   |-- movies/
|   |   |-- local_video/
|   |   |-- music/
|   |   |-- photos/
|   |   |-- youtube/
|   |   |-- search/
|   |   |-- favorites/
|   |   |-- history/
|   |   |-- downloads/
|   |   |-- multi_view/
|   |   |-- accounts/
|   |   |-- devices/
|   |   |-- settings/
|   |   |-- notifications/
|   |   `-- admin/                    # Only if a client-facing operator view is needed
|   `-- shared/
|       |-- widgets/
|       |-- components/
|       |-- models/                   # Truly shared presentation-only values
|       `-- extensions/
|-- supabase/
|   |-- config.toml
|   |-- migrations/                   # Versioned schema, constraints and RLS
|   |-- functions/                    # Server-side privileged operations
|   `-- seed.sql                      # Synthetic, non-sensitive fixtures only
|-- test/
|   |-- unit/
|   |-- contract/
|   |-- widget/
|   `-- support/                      # Fakes, fixtures, builders
|-- integration_test/
|   |-- flows/
|   `-- platform/                     # Per-platform adapter checks
|-- docs/
|   |-- architecture/
|   |-- design/
|   |-- database/
|   |-- api/
|   |-- platform/
|   `-- audit/
|-- pubspec.yaml
|-- pubspec.lock
|-- analysis_options.yaml
|-- .env.example                      # Placeholder values only; not a secret store
|-- .gitignore
`-- README.md
```

## Feature Module Convention

A feature may contain `presentation/` (`screens`, `widgets`, `controllers`), `application/` (`use_cases`, `state`), and `domain/` only when the concepts are feature-owned. Shared domain ports remain under `lib/domain`; repository implementations remain in `lib/data`. Avoid a folder-per-file, generic `helpers/` dump, duplicate model ownership, or direct SDK calls from widgets.

## Ownership and Migration Notes

- Existing `lib/data/models/*` are Freezed/JSON declarations with missing generated files. First restore buildability; then decide whether each type is a transport DTO or domain entity before moving it.
- Existing `lib/services/auth` is partial and imports absent core types. Repair behind tests before connecting screens.
- `player_controller.dart` and `player_engine.dart` currently exist as empty scaffolds. Define the contract before selecting adapters.
- Choose one primary local database. Use an OS-backed vault for provider credentials, not an ordinary row or cloud-synced JSON field.
- `android/`, `windows/`, `macos/`, `linux/`, `web/`, `tizen/`, and `webos/` were empty in the audit. Generate/maintain Flutter platform files with the SDK or a reviewed native integration; empty directories are not targets.
- Keep Tizen/webOS implementation and certification separate until SDK, engine, legal playback and device proofs are accepted.
