# Figma-Ready Design Specification

**File status:** Figma was not accessible from this environment; no Figma file or component library has been created. This document and [DESIGN_TOKENS.md](DESIGN_TOKENS.md) are ready to translate into Figma.

## Product Visual Direction

Use the supplied Dark Premium tokens: deep ink canvas, layered blue-gray surfaces, restrained signal-red primary actions, and cyan keyboard/D-pad focus. The reference HTML's useful layout idea is a player paired with a browsable channel directory, responsive modes, and direct search/category controls. It is an unverified browser prototype, not a component source of truth. Do not carry over its tokenized sample streams, public CORS proxy, third-party player branding, embedded logo, or feature claims.

Use first-party, licensed or synthetic artwork only. No Netflix artwork, wordmark, logo, or copied screen composition. Avoid default hero art from unauthorized streams. For product catalog placeholders, use neutral local placeholders until licensed assets exist.

## Figma File Organization

Create these pages in the future Figma file:

1. `00 - Foundations`: color, type, spacing, radius, elevation, icon grid, accessibility.
2. `01 - Components`: component set and all state variants.
3. `02 - Mobile`: 390x844 baseline; include 360x800 compact and 430x932 stress frames.
4. `03 - Tablet`: 834x1194 baseline; landscape 1194x834.
5. `04 - Desktop`: 1440x900 baseline; 1280x800 dense and 1920x1080 wide.
6. `05 - Android TV`: 1920x1080 baseline, 10-foot grid and remote flow.
7. `06 - Samsung Tizen`: platform-specific screen proposal, explicitly marked `Feasibility / not supported yet`.
8. `07 - LG webOS`: platform-specific screen proposal, explicitly marked `Feasibility / not supported yet`.
9. `08 - Prototype Review`: screenshots/notes only if the HTML is safely opened and behavior checked; tag all unverified states.

Frame naming: `<platform>/<feature>/<screen>/<state>` such as `Mobile/LiveTV/ChannelBrowser/Loaded` and `AndroidTV/Player/Controls/FocusedPause`.

## Grids and Responsive Rules

- Phone: 4-column grid, 16 px side margin, 8 px gutters; safe areas for status/navigation system UI.
- Tablet: 8-column grid, 24 px margin, 16 px gutters; split browsing only when content retains readable width.
- Desktop: 12-column grid, 32 px margin, 24 px gutters; fixed sidebar and flexible content region.
- TV: 12-column reference grid, 48 px safe inset; focusable items at least 64x64 px, TV body text >=20 px, no hover-only action.
- Use stable image aspect ratios and fixed control geometry. Avoid layout shift from loading, labels, focus borders or title length.

## Component Set

Build components as Figma variants matching the token names and Flutter implementation contracts:

- `Button`: primary, secondary, quiet, destructive; enabled, pressed, focused, disabled, busy.
- `IconButton`: default, focused, pressed, disabled; tooltip/label for unfamiliar actions.
- `NavigationItem`: selected, unselected, focused, disabled; sidebar, bottom bar and TV rail variants.
- `SearchField`: empty, typing, clear, voice only if platform/service exists, error.
- `FilterChip` / `SegmentedControl`: selected, unselected, focused, disabled.
- `ChannelRow` / `ChannelTile`: default, playing, favorite, unavailable, loading, focused; logo fallback.
- `PosterCard`: default, focused, selected, unavailable; stable 2:3 ratio.
- `ProgramTile`: upcoming, live, ended, recording-disabled; progress and timezone.
- `PlayerSurface`: idle, loading, playing, paused, buffering, error, unsupported; overlays and control visibility.
- `PlayerControlBar`: transport, volume, seek, track selector, fullscreen; touch, keyboard and remote variants.
- `PlaylistCard`: active, offline, needs-auth, parsing, error.
- `ProgressIndicator`, `Skeleton`, `EmptyState`, `InlineError`, `Dialog`, `BottomSheet`, `Toast`, `PermissionPrompt`, `FocusRing`.

Use Auto Layout, component properties, semantic layer names, and variables bound to `DESIGN_TOKENS.md`. Provide a state page for each interactive component. Do not flatten text or use screenshots as final UI components.

## Global Interaction and State Specification

- **Loading:** Reserve geometry and show skeletons for cards/lists, not a blocking spinner for all data. Keep local cached content visible while cloud sync loads.
- **Empty:** State what is empty and offer one relevant action, e.g. add an authorized playlist, choose local files, or clear a filter. Do not show demo channels by default.
- **Error:** Use inline errors for item-level failures and a retryable page state for blocking failures. Show concise human text plus a stable error category; never show raw URLs, tokens, stack traces or provider payloads.
- **Accessibility:** Text/icon contrast checked against WCAG AA targets; semantic labels and roles; logical tab/D-pad order; visible 2 px focus ring; reduced motion; text scaling; minimum 48x48 dp touch targets; focus restoration after dialogs/player return; Bengali strings tested for shaping and clipping.
- **Forms:** Labels remain visible while typing; errors are adjacent and announced; password fields are masked; no credentials in screenshots, clipboard history or diagnostic exports.
- **Player:** Controls fade only during playback and return on input; errors do not hide back/exit. Include captions/audio track selection only when the engine reports those capabilities.

## Prototype Reuse Boundary

The attached HTML can inform relative layout and interaction discovery only. It loads Tailwind, HLS.js, MPEG-TS.js and fonts from CDNs, stores favorites/recent locally, embeds external sample streams (including tokenized query strings), and offers a public CORS-proxy retry. Do not port these dependencies, URLs, tokens, proxy behavior, or claims directly. Verify every interaction with lawful fixtures before approving a Figma state as implemented behavior.

## Approval Checklist Before Visual Build

- Product owner signs off on navigation hierarchy and feature MVP.
- Legal/content owner approves all demo and catalog assets.
- Every screen has loading, empty, error, focused and disabled states where applicable.
- Mobile/tablet/desktop/TV layouts are separately annotated; Tizen/webOS are marked non-supported until feasibility tests pass.
- Token contrast and Bengali text fit checks are complete.
- Design components have matching semantic Flutter component names and testable state contracts.
