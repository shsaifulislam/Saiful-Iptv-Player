# Platform Compatibility Audit

**Audit date:** 2026-11-11  
**Evidence limit:** Platform directories are empty; no Flutter SDK, native project configuration, devices, emulators, or builds were available. Compatibility below separates dependency intent from verified support.

## Target Matrix

| Target | Current evidence | Status |
|---|---|---|
| Android phone | `media_kit` Android video dependency declared; `android/` empty; no Android manifest/Gradle project or app flow | Unsupported in current workspace; dependency intent only |
| Android tablet | Same Android target; breakpoints constants exist, but no responsive screen implementation | Unsupported/unverified |
| Android TV / Google TV | Platform enum, capability map, key-code/focus constants exist; no TV project/build, remote navigation, 10-foot UI or playback proof | Unsupported/unverified |
| Windows PC | `media_kit` Windows library declared; `windows/` empty; no runner/plugin registration | Unsupported/unverified |
| macOS | `media_kit` macOS library declared; `macos/` empty; no runner/entitlements | Unsupported/unverified |
| Linux | `media_kit` Linux library declared; `linux/` empty; no runner/system package validation | Unsupported/unverified |
| Samsung Tizen TV | Empty `tizen/` directory and empty `tizen_adapter/`; no Flutter embedder, native package, player bridge or device test found | Unsupported on target platform |
| LG webOS TV | Empty `webos/` directory and empty `webos_adapter/`; no Flutter embedder, native package, player bridge or device test found | Unsupported on target platform |

## Scope Mismatches

- README advertises Android, iOS, Windows, macOS, Linux and Web. The current product requirement instead calls for Android phone/TV/tablet, Windows, macOS, Linux, Tizen and webOS.
- There is no `ios/` directory and iOS is not in the current product target list, although iOS media-kit packages are declared.
- `web/` exists but is empty; Web is not a current target and no web player implementation is present.
- Platform feature support is hard-coded in `PlatformConfig`; it is not backed by runtime capability detection or integration tests. `androidTV`/Tizen/webOS enum values are not automatically detected by the current detector.

## Playback and TV Risks

- `player_engine.dart` and `player_controller.dart` are empty. UI/business logic is not decoupled from a working engine because no engine contract exists yet.
- Android/desktop media-kit package declarations do not establish codec, DRM, stream, PiP, track selection, hardware decoding, or remote-control compatibility.
- Tizen and webOS must have independent feasibility spikes; Android plugin support cannot be assumed. Verify available SDK/embedder, codec/container support, hardware decoding, DRM/provider requirements, app lifecycle, remote key handling, packaging and store certification on representative hardware.
- Android TV requires D-pad/keyboard focus, back behavior, overscan-safe layout, readable 10-foot typography and remote media controls. Constants alone do not satisfy these requirements.
- Casting requires receiver/discovery/transport support and provider authorization; Chromecast and DLNA should be separate capability-gated integrations.

## Platform Acceptance Gate

For each target, require a reproducible CI build plus device/emulator acceptance for launch, navigation/input, authorized test stream playback, seek/live behavior where applicable, subtitles/audio selection, lifecycle/background behavior, error recovery, secure storage, and release packaging. Tizen/webOS remain out of release scope until their own gates pass.
