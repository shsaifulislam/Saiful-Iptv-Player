# Dependency Audit

**Audit date:** 2026-11-11  
**Source:** `pubspec.yaml`. Exact resolved versions and advisory status could not be established.

## Verification Status

- `pubspec.lock` is absent, so there is no recorded dependency resolution.
- Flutter/Dart CLIs are unavailable; `flutter pub get`, `flutter pub outdated`, `flutter analyze`, and package-level audit commands could not be run.
- No package vulnerability/advisory or license database scan was run. This report does not certify dependencies as current or safe.
- The manifest uses caret constraints, so a future resolution can differ from another developer's resolution until a lockfile is generated and committed.

## Declared Direct Dependencies

| Concern | Declared packages | Audit note |
|---|---|---|
| Framework/localization | `flutter`, `flutter_localizations` | Flutter SDK baseline claims Flutter >=3.10; no toolchain test. |
| State/codegen | `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator` (dev) | Riverpod is used in bootstrap/Auth source; no feature state flows or generated provider artifacts observed. |
| Routing | `go_router` | Dependency and route constants exist; no GoRouter configuration found. |
| Playback | `media_kit`, `media_kit_video`, Android/iOS/Windows/macOS/Linux media-kit libraries | No player implementation; declared native libraries do not provide Tizen/webOS adapters. Actual ABI/build/runtime compatibility unverified. |
| Cloud | `supabase_flutter` | Client/Auth declarations exist; no schema/migrations/RLS/functions. |
| Networking | `dio` | No remote repository/client implementation observed. |
| Local persistence | `hive_flutter`, `isar`, `isar_flutter_libs` | Hive initialization exists; no adapters/repositories. Two local DB choices are declared with no ownership/migration strategy. |
| Serialization | `freezed_annotation`, `json_annotation`; `freezed`, `json_serializable`, `build_runner` (dev) | Model source references generated files, but generated artifacts are absent. |
| Secure storage | `flutter_secure_storage` | Declared but no usage found. |
| Media/platform utilities | `cached_network_image`, `shimmer`, `permission_handler`, `connectivity_plus`, `path_provider`, `share_plus`, `file_picker`, `workmanager`, `flutter_local_notifications` | No corresponding feature implementations or platform build verification found. Plugin compatibility must be assessed per target. |
| Parsing | `xml` | Declared, but no M3U/XML parser found. |
| Utilities/config | `intl`, `logging`, `equatable`, `uuid`, `collection`, `flutter_dotenv` | `logging` and dotenv are used; usage of the remainder is not established from current flows. |
| Tests/tooling | `flutter_test`, `integration_test`, `mockito`, `build_runner_core`, `flutter_lints`, `riverpod_lint`, `custom_lint`, `isar_generator` | No test source or generated output; analyzer/lint execution blocked. |

## Manifest and Resolution Risks

- Declared Flutter asset `.env` is absent. A Flutter packaging check is required; startup also calls `dotenv.load` without an observed recovery path.
- Asset declarations cover `assets/images/`, `assets/icons/`, and `assets/fonts/`; `assets/animations/` and `assets/placeholders/` are not declared. No assets currently exist in the inventory.
- SDK lower bounds and package constraints must be resolved together on the selected Flutter stable channel. Do not infer compatibility from the manifest alone.
- `media_kit` has no app-owned platform abstraction in use. Do not infer Tizen/webOS support from feature flags or empty adapter directories.
- The product target list excludes iOS/Web, while the README and manifest mention iOS/Web-adjacent support; reconcile scope before retaining unnecessary platform packages.
- Both Hive and Isar increase migration, serialization and test surface. Select one primary database unless a documented, measured use case justifies both.

## Required Dependency Gate

1. Install and pin the supported Flutter channel/version in developer docs and CI.
2. Run `flutter pub get`; review and commit `pubspec.lock` for the application.
3. Run `flutter pub outdated` and a vulnerability/license scan against the resolved graph; triage results instead of auto-upgrading blindly.
4. Run analyze/tests and debug/release builds for each claimed platform.
5. Validate every plugin's platform support and required native setup, especially background tasks, notifications, secure storage, file access and playback.
6. Remove unused dependencies only after usage, platform setup and generated code have been checked.
