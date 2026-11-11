# Release Notes: Saiful IPTV Player v1.0.0

**Release Tag**: `v1.0.0-genesis`  
**Release Date**: November 2026  
**Build Target**: Production Release  

---

## 🌟 Highlights of Version 1.0.0

Saiful IPTV Player v1.0.0 is the foundational stable release of an enterprise-grade, cross-platform IPTV and universal media entertainment client. Built with Flutter, Dart, PostgreSQL, and Supabase, it brings a cinematic Netflix-style interface to phones, tablets, desktop PCs, and Android TVs.

---

## 🚀 Key Features

### 1. Unified Universal Media Player Engine
- Universal `PlayerEngine` interface with platform-native adapters (ExoPlayer on Android, libmpv on Windows/Linux, AVPlayer on macOS).
- Full playback support for MP4, MKV, MOV, WebM, HLS (`.m3u8`), and audio codecs (MP3, AAC, FLAC, WAV).
- Hardware-accelerated gesture controls: double-tap to seek, vertical swipe brightness/volume.
- A-B loop repeat mode for seamless video looping.
- External subtitle parsing (`.srt`, `.vtt`) with millisecond-level delay calibration and custom styling.

### 2. High-Performance IPTV & EPG Suite
- Streaming memory-efficient M3U & M3U8 parser capable of ingesting 2,000+ channels in `< 80ms`.
- XMLTV EPG program guide parser with multi-timezone normalization and real-time active schedule indicators.
- Instant category filtering, logo caching, and channel favorites bar.
- Comprehensive stream diagnostics reporting HTTP response codes, buffer health, and SSRF security status.

### 3. Entertainment Hubs
- **Movies & VOD**: Licensed VOD catalog with backdrop banners, genre filtering, resume playback, and watchlist.
- **YouTube Hub**: Official embedded YouTube IFrame player with URL parsing, bookmarking, and zero TOS violations.
- **Local Media & Photos**: Photo gallery with zoom gesture viewer and automated slideshow (3s, 5s, 10s intervals); background audio player with queue management.
- **Multi-View**: 2-stream split view and 4-stream quad view with independent tile playback, audio switching, and hardware overload safeguards.

### 4. Cloud Backend & Synchronization
- Supabase Auth integration with PKCE login, email/password registration, password reset, and device registration.
- 15 version-controlled PostgreSQL tables protected by Row Level Security (RLS) guaranteeing 100% tenant isolation.
- Offline sync queue with exponential backoff and "latest timestamp vector wins" conflict resolution.
- Role-protected Admin Portal (`admin/index.html`) with real-time audit logs and user management.

### 5. Multi-Platform & TV Experience
- Full D-Pad remote control focus management for Android TV and Smart TVs.
- Desktop keyboard shortcuts (Space to play/pause, Left/Right arrow to seek, Up/Down for volume, 'F' for fullscreen).
- Native Bengali font typography and bidirectional multi-language localization.

---

## 🛡️ Security & Privacy Hardening
- 100% Parameterized database queries preventing SQL injection.
- Zero raw provider passwords or tokens stored in sync or logged in telemetry.
- SSRF Guard blocking private IP subnets (`127.0.0.0/8`, `10.0.0.0/8`, `192.168.0.0/16`, `169.254.169.254`) and unauthorized URL schemes.
- Cleartext HTTP traffic blocked by default via Android Network Security Config.
- Self-serve account deletion with cascade database wipe.

---

## 📦 Verification Summary
- **Total Automated Test Suites**: 5 Suites
- **Total Automated Tests**: 42 Tests Passed (0 Failed, 100% Success Rate)
- **Real-World Playlist Verification**: 2,155 channels and 95 categories successfully parsed from real-world 4,312-line playlist.

