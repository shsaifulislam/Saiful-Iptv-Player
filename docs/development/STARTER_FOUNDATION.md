# Starter Foundation

## Status

The application source foundation is implemented. The completion gate is **blocked**, not passed: Flutter/Dart are not installed on the current Windows host, so package resolution, code generation, Flutter tests, and platform builds could not be run.

## App Structure

- `main.dart` enters `bootstrap()`; bootstrap configures framework error handling and launches a `ProviderScope`.
- `app/app.dart` owns Material 3 themes, router binding, and the live theme-mode provider.
- `app/router/app_router.dart` registers the application routes and error page.
- `app/layout/adaptive_shell.dart` switches between bottom navigation and a navigation rail at the tablet breakpoint.
- `features/` contains the home, playlist, search, settings, and explicit foundation-state pages.
- `core/network/api_client.dart` creates a Dio client from typed app configuration.
- `services/auth/auth_service.dart` wraps Supabase Auth and returns typed `Result` values.

## Available Flows

- Home opens Live TV, the programme guide, favourites, history, and playlist setup.
- The five primary destinations work in both compact and wide layouts.
- Search filters and opens every non-player section.
- Playlist setup validates a name and HTTP(S) URL. Entries are held in memory only; fetching, import, persistence, and removal across restarts are not implemented.
- Settings switches the global theme between system, light, and dark modes.
- Profile, login, local media, downloads, EPG, and other not-yet-integrated sections communicate their connection state.
- Player and multi-view routes are explicitly disabled. No playback engine is initialized.

## Configuration

`AppConfig` reads compile-time `--dart-define` values: `APP_ENV`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_BASE_URL`, `API_TIMEOUT_MS`, and `ENABLE_ANALYTICS`. `.env.example` is documentation only; the app does not load it. Only client-safe Supabase project URL and public anon key may be supplied. Provider credentials and service-role secrets must not be embedded in the application.

## Platform And SDK

The target SDK baseline is Flutter 3.47.9 and Dart 3.13.7, selected from the official Flutter stable archive metadata. This is not a claim that either SDK is installed locally. Android and Windows platform directories are empty; Tizen and webOS are placeholders, not supported targets.

## Gate To Pass

1. Install the target Flutter SDK and complete `flutter doctor -v` on a Windows machine with Android and Windows build prerequisites.
2. Resolve dependencies and commit the generated `pubspec.lock` after review.
3. Run code generation, formatting, `flutter analyze`, and the widget test suite.
4. Generate/review Android and Windows platform scaffolds, then produce a debug APK and Windows build.
5. Fix all failures and update [the test report](../testing/FOUNDATION_TEST_REPORT.md) with command output and artifact locations.

Until all items pass, full player implementation remains out of scope.
