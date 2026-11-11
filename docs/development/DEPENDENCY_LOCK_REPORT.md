# Dependency Lock Report

## Outcome

Direct dependencies are exact-pinned in `pubspec.yaml`. No `pubspec.lock` is present because `flutter pub get` could not run: neither `flutter` nor `dart` is installed or available on `PATH`. Therefore this is a reviewed dependency selection, not a resolved or reproducible lockfile.

## Direct Dependencies

| Package | Pin | Role |
|---|---:|---|
| `flutter_riverpod` | 3.5.0 | State and dependency scope |
| `go_router` | 18.1.4 | Application routing |
| `dio` | 5.11.1 | HTTP client foundation |
| `logging` | 1.3.0 | Structured logging |
| `supabase_flutter` | 2.18.3 | Optional Auth client |
| `freezed_annotation` | 3.1.0 | Immutable model annotations |
| `json_annotation` | 4.12.0 | JSON model annotations |

| Development package | Pin | Role |
|---|---:|---|
| `flutter_lints` | 6.0.0 | Flutter lint baseline |
| `build_runner` | 2.16.2 | Code generation |
| `freezed` | 4.0.3 | Freezed generator |
| `json_serializable` | 6.15.2 | JSON generator |

Flutter SDK dependencies `flutter`, `flutter_test`, and `integration_test` are SDK-provided and are not pub.dev pins.

## Compatibility Evidence

Metadata was checked against the official Flutter archive and pub.dev package metadata. Flutter 3.47.9 bundles Dart 3.13.7. `freezed 4.0.3` requires Dart >=3.13 and accepts `build >=3 <5`; `build_runner 2.16.2` uses the compatible build 4 generation line. The newer `build_runner 2.17.1` requires build >=5, which conflicts with Freezed 4.0.3, so that pair is intentionally not selected. `json_serializable 6.15.2` requires Dart ^3.12 and `json_annotation >=4.12 <4.13`. `supabase_flutter 2.18.3` requires Dart >=3.9 and Flutter >=3.35.

Sources: [Flutter releases](https://docs.flutter.dev/release/archive), [pub.dev package metadata](https://pub.dev).

## Lockfile And Supply-Chain State

- Direct versions are exact pins; transitive versions remain unresolved.
- No package archive hashes or transitive dependency graph have been recorded.
- No `flutter pub get`, `pub deps`, or lockfile validation was possible.
- Next action after installing Flutter 3.47.9: run `flutter pub get`, review `pubspec.lock`, then preserve that lockfile in source control.
