# Platform Capability Matrix

**Status:** Target capability plan, not present support. Prompt 01 found empty native project directories and no completed feature flows. No platform is currently classified Fully supported. `N` and `S` describe required architecture work, not verified support.

## Classification

- **Fully supported:** Implemented and passed documented target tests. None currently qualify.
- **Supported with native adapter:** Feature depends on a platform-specific plugin/bridge which must be implemented and tested.
- **Requires testing:** Cross-platform logic/UI is plausible, but implementation/build/device validation is still required.
- **Unsupported:** No supported implementation planned for that platform or dependency/policy blocks the feature.
- **Requires separate implementation:** A distinct app host, engine bridge, admin console, or vendor-specific work is required; current Flutter code cannot be assumed to run there.

Legend: `T` Requires testing; `N` Supported with native adapter; `S` Requires separate implementation; `U` Unsupported. No `F` Fully supported entries exist.

| Feature | Android phone/tablet | Android TV | Windows | macOS | Linux | Samsung Tizen | LG webOS |
|---|---|---|---|---|---|---|---|
| Home | T | T | T | T | T | S | S |
| Live TV | N | N | N | N | N | S | S |
| Playlist Manager | N | N | T | T | T | S | S |
| EPG | T | T | T | T | T | S | S |
| Movies/VOD | N | N | N | N | N | S | S |
| Local Video | N | N | N | N | N | S | S |
| Music | N | N | N | N | N | S | S |
| Photos | N | N | N | N | N | S | S |
| YouTube official | T | T | T | T | T | S | S |
| Search | T | T | T | T | T | S | S |
| Favorites | T | T | T | T | T | S | S |
| Watch History/Progress | T | T | T | T | T | S | S |
| Downloads | N | N | N | N | N | U | U |
| Multi-view | N | T | N | N | N | U | U |
| User Accounts | T | T | T | T | T | S | S |
| Device Management | T | T | T | T | T | S | S |
| Settings | T | T | T | T | T | S | S |
| Notifications | N | N | N | N | N | U | U |
| Admin Dashboard | S | S | S | S | S | S | S |

## Interpretation and Gates

- Android phone and tablet share an app target but still require permission, storage, lifecycle and layout tests for each form factor.
- Android TV needs remote focus, system back, 10-foot typography, playback key handling and certification checks; width alone does not detect TV capability.
- Windows/macOS/Linux playback, local file access, keyboard control, PiP, notifications and codec behavior need separate release builds and device tests.
- Tizen and webOS are not Flutter targets by assumption. `S` means a platform-specific host/bridge/engine must be investigated and built; until then these targets are not supported.
- Downloads and multi-view are capability- and rights-gated. `U` on Tizen/webOS is current scope status, not a permanent technical assertion.
- Admin is a separate secure web console/server application, not an admin mode hidden in the media client.
- YouTube requires official API/player support and platform policy validation. Do not scrape, bypass ads, DRM or authentication.
- M3U, VOD, catch-up and recording require user-owned, licensed or explicitly authorized sources; availability is provider-specific.

## Required Evidence to Change a Cell

A cell can move to Fully supported only after: reproducible build; unit/widget/contract tests; device/emulator acceptance for core flow; permissions/lifecycle/error tests; accessibility/input tests; authorized media fixture playback where relevant; and documented store/provider approval. A feature flag or dependency declaration is insufficient.
