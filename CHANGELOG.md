# Changelog

All notable changes to **Saiful IPTV Player** are documented in this file in accordance with [Semantic Versioning](https://semver.org/).

---

## [1.0.0] - 2026-11-12

### Initial Stable Production Release ("Genesis")

#### Added
- **Cloud Backend & Authentication**:
  - Full Supabase Auth lifecycle: Email/password signup, login, session restore, password reset, and self-serve cascade account deletion.
  - 15 version-controlled PostgreSQL tables with Row Level Security (RLS) guaranteeing strict tenant data isolation.
  - Multi-device registration and conflict-resolved cloud synchronization ("latest timestamp vector wins").
  - Role-protected Admin Portal (`admin/index.html`) with real-time audit logging and user management.
- **Universal Media Player Engine**:
  - Pluggable `PlayerEngine` interface with platform adapters (ExoPlayer on Android, libmpv on Windows/Linux, AVPlayer on macOS).
  - Video support for MP4, MKV, MOV, WebM, HLS (`.m3u8`); audio support for MP3, AAC, FLAC, WAV, OGG.
  - Multi-touch gesture controls: vertical swipe brightness/volume, double-tap seek.
  - Subtitle parser for `.srt` and `.vtt` cues with millisecond-accuracy delay compensation and styling.
  - A-B loop repeat mode for seamless video looping between defined markers.
  - Local media browser with folder navigation, sorting, and format categorization.
- **High-Performance IPTV & EPG Suite**:
  - Memory-efficient streaming M3U & M3U8 parser supporting 2,000+ channels without memory spikes.
  - Ingestion and validation of real-world 4,312-line playlist with 2,155 channels across 95 categories.
  - XMLTV EPG parser with timezone normalization and live schedule calculation.
  - SSRF Protection Guard blocking private IP subnets (`127.0.0.0/8`, `10.0.0.0/8`, `192.168.0.0/16`, `169.254.169.254`) and unauthorized schemes.
  - Real-time stream diagnostics with automated URL credential masking.
- **Entertainment Hubs**:
  - Licensed VOD movie and series catalog with watchlist and resume playback.
  - Official YouTube Hub supporting URL parsing, official IFrame embed player, and zero ad-blocking.
  - Local Photo Gallery with zoom gesture viewer and automated slideshow (3s, 5s, 10s intervals).
  - Multi-View split and quad player with independent tile playback and exclusive audio focus.
  - Parental Controls with 4-digit PIN verification and age rating hierarchy ($G \le PG \le PG\text{-}13 \le R$).
- **UI & Multi-Platform Adaptation**:
  - 24 responsive Netflix-inspired screens built with Material 3 design tokens.
  - Full D-Pad remote control focus management for Android TV / Google TV.
  - Desktop keyboard shortcuts (Space, Arrow keys, 'F' for Fullscreen, 'M' for Mute).
  - Native Bengali typography and bidirectional localization support.
- **Platform Release Configurations**:
  - Android & Android TV release configurations (`AndroidManifest.xml`, `build.gradle`, `proguard-rules.pro`).
  - Windows release configuration (`CMakeLists.txt`, `windows/runner/main.cpp`).
  - Linux release package (`CMakeLists.txt`, `saiful_iptv_player.desktop`).
  - macOS release entitlements (`Runner/Release.entitlements`).
  - Samsung Tizen & LG webOS web application packaging manifests.

#### Security
- Strict PostgreSQL RLS on all user-owned tables.
- SSRF network guard prevents internal port scanning and cloud metadata access.
- Redacting logger automatically sanitizes query tokens and credentials from logs.
- Cleartext HTTP traffic blocked by default via Android Network Security Config.
- Private signing keys, keystores, and production `.env` files strictly excluded in `.gitignore`.

