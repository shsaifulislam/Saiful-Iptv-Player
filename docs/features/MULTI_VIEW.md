# Saiful IPTV Player: Multi-View Specification

## 1. Overview and Architecture

Multi-View enables sports fans, news monitors, and power users to watch up to four live broadcast channels simultaneously on a single display screen.

Source code implementation:
- Controller: [`lib/features/multi_view/services/multi_view_controller.dart`](file:///d:/Saiful%20iptv%20player/lib/features/multi_view/services/multi_view_controller.dart)
- UI Presentation: [`lib/features/multi_view/presentation/multi_view_page.dart`](file:///d:/Saiful%20iptv%20player/lib/features/multi_view/presentation/multi_view_page.dart)

---

## 2. Multi-View Layout Modes

### 2.1 Two-Screen Mode (Dual-View)
- Two equal 16:9 stream tiles arranged side-by-side (on widescreen/desktop/TV displays) or stacked vertically (on mobile phones in portrait).
- Suitable for mid-range chipsets and devices with dual-decoder limits.

### 2.2 Four-Screen Mode (Quad-View)
- Four independent 16:9 stream tiles arranged in a 2x2 grid.
- Intended for high-performance desktop graphics (D3D11VA / Metal / VAAPI) and modern 4K smart TVs.

---

## 3. Operational Guarantees

### 3.1 Exclusive Audio Focus
Because decoding multiple audio streams concurrently creates chaotic acoustic overlap, the engine enforces **Exclusive Audio Focus**:
- Exactly one stream tile is unmuted at any given moment.
- The active stream displays a prominent highlighted border and an `AUDIO` indicator badge.
- Tapping on any tile immediately transfers audio focus to that channel.

### 3.2 Independent Playback State
- Each stream tile operates with its own isolated playback state.
- Users can pause, resume, or reload tile 1 without interrupting tiles 2, 3, or 4.

### 3.3 Stream Failure Isolation
- Network disconnects, HTTP errors, or stream stalls occurring on one tile are quarantined.
- The affected tile displays an isolated retry banner while other streams continue playing smoothly without crashes.

### 3.4 Hardware Capability Detection & Warnings
- Decoding four simultaneous 1080p 60fps streams consumes substantial GPU memory and decoder instances.
- The UI displays an advisory warning banner informing users to switch to 2-View if their hardware struggles to maintain target frame rates.

