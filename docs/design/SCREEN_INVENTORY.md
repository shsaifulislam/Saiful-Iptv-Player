# Screen Inventory and Flow Specification

This is a Figma-ready inventory, not implemented screens. Common states on every data screen: initial loading, cached/offline, empty, filtered-empty, permission-denied where relevant, retryable error, and focused/selected/disabled action states. Player errors must retain an exit route. No external stream URL or provider secret is shown in UI or diagnostics.

## Mobile

| Screen | Layout and key components | Primary actions / states |
|---|---|---|
| Splash | Brand wordmark (first-party), progress indicator, dark canvas | Initialize; safe startup error screen if config fails; no fake autoplay |
| Onboarding | 2-3 short pages: local media, authorized playlists, privacy/sync choice | Skip/continue; permissions only when needed; persisted completion |
| Login | Email/password, OAuth only when configured, recovery link | Sign in/up/reset; validation, rate limit, offline and verification states |
| Home | Greeting, source status, continue-watching, favorites and recently added rails | Resume, browse feature, add source; offline cache badge and truly empty state |
| Live TV | Search/filter/category rail plus channel rows; compact preview optional | Select channel, favorite, open guide; loading/authorization/unavailable states |
| EPG Guide | Time grid, timezone, now marker, channel rail | Select program, return to channel; stale/mapping/empty states |
| Fullscreen player | Full-bleed video, accessible transport overlay, track picker and error overlay | Play/pause, seek only when supported, channel up/down, tracks, back; controls reappear on input |
| Movies | Poster grid, filter/sort controls | Open title, favorite; metadata skeleton and no-results states |
| Movie details | Artwork, title and licensed metadata, play/resume | Play only when authorized; unavailable/entitlement state |
| Local files | Picker action, recents and selected folders/files | Open video/audio; permissions, missing file and unsupported codec states |
| Photos | Album selector and stable thumbnail grid | Open viewer, zoom/share; permission and decode failures |
| YouTube Hub | Search/saved links, official player surface and attribution | Open official content; no ad/DRM bypass; unavailable embed/quota states |
| Playlist Manager | Playlist cards, add/import sheet, parse summary | Add file/URL, refresh, re-auth, remove; secret fields masked and never echoed |
| Search | Search field, content-type segments and result rows | Search local first, clear, open item; offline and no-results states |
| Favorites | Unified favorites list with type filters | Open, reorder/remove; empty and stale target states |
| History | Recent activity, progress and retention controls | Resume, clear; confirm deletion and sync status |
| Settings | Grouped playback, privacy, sync, accessibility, parental controls, diagnostics | Change/reset; capability-gated controls and sanitized export |
| Profile | Identity, subscription only if real, sign-out/delete account | Edit, manage devices, delete; re-auth and irreversible-action confirmation |
| Music Library | Albums/artists/local tracks and mini-player | Queue, shuffle/repeat; permission and playback states |

## Tablet

- **Adaptive home:** Navigation rail, wider content rails, up to 3 poster columns depending on available width; avoid stretching cards.
- **Two-column media browsing:** Filters/sidebar on left; results grid on right. Collapse to sheet below minimum content width. Keep search and sort visible.
- **Live TV with side panel:** Player/preview on one side and channel list/EPG details on the other; allow list collapse. Preserve channel selection and focus on orientation changes.
- Provide portrait and landscape frames; test split-screen and text scaling.

## Desktop

- **Sidebar navigation:** Persistent, collapsible rail with labeled destinations, account state and keyboard shortcuts. Do not hide destinations behind hover.
- **Main dashboard:** 12-column content grid, fixed artwork aspect ratios, source/sync status, search and continue-watching sections.
- **Player + playlist split view:** Resizable but bounded player and channel/queue pane; keyboard transport shortcuts, focus order and accessible resize controls.
- **Library management:** Table/list with sort, filter, multi-select, import status and explicit delete confirmation.
- **Settings:** Left section list and bounded form area; visible save/apply state and reset confirmation.
- **Window states:** Minimum supported width, narrow-window fallback, maximize, keyboard focus and platform title-bar safe area.

## TV / Android TV / Google TV

- **Ten-foot home:** Large type, 48 px safe inset baseline, 64 px focus targets, horizontal content rails and persistent back path.
- **D-pad navigation:** Deterministic next-focus graph; no hover dependency; selected and focused are visually distinct. Focus ring is cyan with sufficient contrast.
- **Focus restoration:** Returning from player/dialog restores the originating item and scroll position; removed items choose a predictable neighbor.
- **Back behavior:** Player overlay -> player exit confirmation only if needed -> previous screen -> home; do not trap focus or exit unexpectedly.
- **Player controls:** Large play/pause, channel up/down, info, captions/audio only if supported, explicit focus order and timeout reset on remote input.
- **Remote shortcuts:** Play/pause/seek/channel keys only when platform reports them. Show an accessible help panel and allow remapping only if OS permits.

## Samsung Tizen TV (Separate Feasibility Specification)

**Status:** Design proposal only; current repository has no Tizen runtime/adapter. Do not label supported until device proof passes.

- Home: 10-foot rails, source status, favorites and continue-watching; Tizen system/back behavior preserved.
- Live TV/guide: D-pad-first channel list and time grid; no pointer-only controls.
- Player: Tizen-specific engine surface/remote key bridge; show unsupported codec/provider states; no Android plugin assumption.
- Playlist/account: remote-friendly text entry, QR/companion handoff only after secure pairing design; never display saved passwords.
- Settings: app version, network status, permission/support diagnostics with redaction.
- Validate packaging, lifecycle, video/audio codecs, DRM/provider policy, remote key codes, focus recovery and app-store review on supported hardware/SDK.

## LG webOS TV (Separate Feasibility Specification)

**Status:** Design proposal only; current repository has no webOS runtime/adapter. Do not label supported until device proof passes.

- Home: webOS-appropriate 10-foot layout and system navigation conventions; D-pad focus and pointer/remote hybrid where available.
- Live TV/guide: focusable channel rail and schedule panel, with stable selected channel on return.
- Player: webOS-native/browser bridge only if approved and tested; expose real engine capabilities and provider errors.
- Playlist/account: remote text-entry pattern or secure QR/companion pairing; no credential display or URL leakage.
- Settings/diagnostics: platform/version, connection and sanitized error report; respect lifecycle and permissions.
- Validate webOS SDK/package, supported playback formats, remote/back behavior, focus handling, app suspend/resume and store certification on representative TVs.

## Design QA Checklist

- All states above have Figma frames; nothing is marked implemented without app evidence.
- Test 360 px width, 200% text scaling, Bengali/English mixed text, long names and missing artwork.
- Test pointer, keyboard, touch and D-pad separately.
- Verify no overlapping labels, clipped hit targets, layout shift, or focus-only-by-color affordance.
- Use synthetic content or assets with documented rights only.
