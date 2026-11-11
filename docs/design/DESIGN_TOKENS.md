# Design Tokens

**Product direction:** Dark Premium entertainment UI; original Saiful IPTV Player identity. Netflix is a mood reference only. Do not reproduce its logo, wordmark, key art, navigation, or proprietary assets.

## Color

| Token | Value | Use |
|---|---|---|
| `color.background` | `#090D16` | App canvas and player surround |
| `color.surface` | `#171F2D` | Navigation, panels, form surfaces |
| `color.surface.elevated` | `#202B3C` | Menus, dialogs, popovers |
| `color.primary` | `#E50914` | Primary play/confirm/destructive emphasis; use sparingly |
| `color.focus` | `#06B6D4` | Keyboard/D-pad focus, selected control outline |
| `color.text.primary` | `#F4F6FA` | Main titles and readable values |
| `color.text.secondary` | `#AAB4C5` | Supporting labels |
| `color.text.muted` | `#77849A` | Disabled/low-priority metadata only |
| `color.border` | `#2B3749` | Dividers and quiet outlines |
| `color.success` | `#34C98A` | Success and connected state |
| `color.warning` | `#F4B942` | Warnings and expiring source state |
| `color.error` | `#F04452` | Errors; keep distinct from primary action by icon/text |
| `color.overlay.scrim` | `#000000B8` | Modal/player scrim |

Semantic colors must not be used as the only signal. Add icon, label, and/or shape. Check contrast for each text/background pairing in Figma; the values are design inputs, not an asserted WCAG result. Charts, EPG category colors and content artwork use separate limited palettes and should not overpower the dark neutral surfaces.

## Typography

- **Latin:** Inter, weights 400/500/600/700. Bundle licensed font assets; do not depend on network fonts at runtime.
- **Bengali:** Noto Sans Bengali, weights 400/500/600/700. Verify glyph coverage, shaping, line height and truncation with real Bengali strings.
- **Fallback:** `Inter, Noto Sans Bengali, sans-serif`, with locale-aware family selection in Flutter. Never shrink type solely to force a long label on one line; wrap or truncate with an accessible full label.

| Token | Size / line height | Weight | Use |
|---|---|---|---|
| `type.display` | 32 / 40 px | 700 | TV/desktop hero title only |
| `type.h1` | 28 / 36 px | 700 | Page title |
| `type.h2` | 24 / 32 px | 600 | Section heading |
| `type.h3` | 20 / 28 px | 600 | Panel/card heading |
| `type.body.large` | 18 / 28 px | 400 | Player details, TV body |
| `type.body` | 16 / 24 px | 400 | Default readable content |
| `type.label` | 14 / 20 px | 500 | Form labels and controls |
| `type.caption` | 12 / 16 px | 500 | Metadata; do not use for essential actions |
| `type.tv.minimum` | 20 / 28 px | 500 | TV minimum body/action label |

Sizes remain fixed across viewports; use different tokens per form factor, not viewport-based font scaling. Respect user/system text scaling and test overflow at 200%.

## Spacing and Layout

Base unit: 4 px. Tokens: `space.0=0`, `space.1=4`, `space.2=8`, `space.3=12`, `space.4=16`, `space.5=20`, `space.6=24`, `space.8=32`, `space.10=40`, `space.12=48`, `space.16=64`.

- Content inset: 16 px phone, 24 px tablet, 32 px desktop, 48 px TV safe area (validate per device overscan).
- Dense channel rows may use 8-12 px internal gaps but never reduce touch targets below 48x48 dp.
- Use 8 px grid gutters on compact screens, 16 px tablet, 20-24 px desktop/TV.
- Poster frames use stable 2:3 aspect ratio; landscape media banners use stable 16:9. Reserve dimensions before image load.

## Radius

`radius.none=0`, `radius.xs=4`, `radius.sm=8`, `radius.md=12`, `radius.lg=16`, `radius.xl=24`, `radius.pill=999` (pills only for compact filter/status chips). Prefer 8 px or less for utility controls; use larger radii only for media artwork, sheets and full-bleed imagery.

## Elevation and Shadows

Dark surfaces rely on tonal separation and borders first. `elevation.0`: none; `elevation.1`: 0 2px 8px `#00000040`; `elevation.2`: 0 8px 24px `#00000055`; `elevation.3`: 0 16px 40px `#00000070`. Focus ring: 2 px `color.focus` plus 2 px offset; never communicate focus with glow alone. Avoid neon outlines on every card.

## Motion

- Transitions: 120 ms for control feedback, 180 ms for tabs/sheets, 240 ms for screen-level transitions.
- Use motion to indicate state changes and focus movement, not as decoration. Respect reduced-motion settings; disable parallax and nonessential reveal effects.
- Do not animate layout dimensions of player panes or controls in a way that changes hit targets.

## Icons

Use one consistent, licensed outlined icon set (Lucide-style geometry) with 24 px default, 20 px compact and 32 px TV sizes. Use familiar play, pause, search, settings, back and volume symbols; pair unfamiliar actions with visible labels or tooltips. Avoid emoji, third-party player logos, platform logos as decoration, and hand-drawn inconsistent glyphs. Verify license and filled/outlined state consistency before adding a Flutter icon dependency.

## Responsive Breakpoints

| Token | Width | Layout |
|---|---:|---|
| `breakpoint.compact` | < 600 px | Phone; bottom navigation; one content column |
| `breakpoint.tablet` | 600-1023 px | Adaptive navigation; two-column browsing where useful |
| `breakpoint.desktop` | 1024-1439 px | Persistent sidebar; player/library split |
| `breakpoint.tv` | >= 1440 px | 10-foot spacing, large focus states and safe area |

Breakpoints describe layout decisions, not device detection. Android TV uses actual platform/input capability in addition to width. Tizen/webOS require separate platform designs and implementation proofs.
