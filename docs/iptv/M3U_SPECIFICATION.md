# Saiful IPTV Player: M3U & M3U8 Playlist Specification

## 1. Overview and Architecture

Saiful IPTV Player provides an enterprise-grade, memory-efficient playlist ingestion engine designed to parse standard and extended M3U/M3U8 playlists. It safely handles large carrier playlists (50,000+ entries) without memory exhaustion, applies zero-trust SSRF validation, and redacts sensitive credentials.

Source code implementation:
- Parser: [`lib/features/iptv/parsers/m3u_parser.dart`](file:///d:/Saiful%20iptv%20player/lib/features/iptv/parsers/m3u_parser.dart)
- Security Guard: [`lib/core/security/ssrf_protection.dart`](file:///d:/Saiful%20iptv%20player/lib/core/security/ssrf_protection.dart)
- Model: [`lib/features/iptv/models/iptv_playlist.dart`](file:///d:/Saiful%20iptv%20player/lib/features/iptv/models/iptv_playlist.dart)

---

## 2. Supported Extended M3U Tags and Attributes

### 2.1 File Header
Every compliant playlist begins with the `#EXTM3U` tag:
```m3u
#EXTM3U url-tvg="https://epg.provider.com/epg.xml.gz" x-tvg-url="https://epg.backup.com/epg.xml"
```

### 2.2 Extended Info Directive (`#EXTINF`)
The parser accepts both standard and quoted attribute syntax:
```m3u
#EXTINF:-1 tvg-id="channel.id" tvg-name="Channel Name" tvg-logo="https://..." group-title="Category" tvg-chno="101" tvg-shift="0", Channel Display Title
https://stream.server.com/live/channel.m3u8
```

| Attribute | Meaning | Example | Fallback Behavior |
| :--- | :--- | :--- | :--- |
| **Duration** | Target track length in seconds (-1 for live streams) | `-1` | Defaults to `-1` (Live) |
| **`tvg-id`** | EPG XMLTV channel identification key | `aljazeera.en` | Falls back to internal generated channel UUID |
| **`tvg-name`** | Canonical channel identifier | `Al Jazeera English` | Falls back to display title after comma |
| **`tvg-logo`** | URL of channel station logo | `https://logos.com/aje.png` | Defaults to null (system displays standard category icon) |
| **`group-title`**| Channel genre or category folder | `News`, `Sports`, `Movies` | Defaults to `'General'` |
| **`tvg-chno`** | Channel number / LCN sorting index | `101` | Incremental index assigned based on position |
| **`tvg-shift`**| EPG time shift in hours | `+1`, `-2` | Defaults to `0` (no shift) |
| **Channel Title**| Text following comma delimiter `,` | `Al Jazeera English HD` | Extracted as the primary UI display title |

---

## 3. Streaming and Memory Protection

To avoid Out-Of-Memory (OOM) crashes on constrained mobile and TV hardware:
1. **Line-by-Line Tokenization**: The parser streams lines through `LineSplitter` without buffering the entire dataset in full string arrays.
2. **Preview Mode**: The `generatePreview()` method evaluates playlist size and extracts sample items and category lists without allocating memory for all channel objects.
3. **Deduplication**: Repeated channel stream URLs are deduplicated via a normalized URL hash set.

---

## 4. Malformed Entry Resilience

The parser gracefully recovers from common playlist defects:
- **Missing Commas**: If a provider omits the `,` delimiter, attributes are parsed and the trailing text is utilized as the channel title.
- **Unclosed Quotes**: Malformed attribute values with missing closing quotes (`group-title="News`) are parsed using non-greedy boundary expressions.
- **Intermediate Comments**: Directives like `#EXTVLCOPT`, `#EXTGRP`, and `#KODIPROP` are inspected for metadata without discarding the pending stream URL.
- **Whitespace / Blank Lines**: Empty lines and irregular line breaks (`\r\n` or `\n`) are stripped automatically.

---

## 5. Security & SSRF Protection

Remote playlists and stream URLs undergo mandatory security validation:
1. **Blocked Loopback and Private Networks**: `127.0.0.0/8`, `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `169.254.0.0/16`, `::1`.
2. **Blocked Cloud Metadata Endpoints**: `169.254.169.254`, `metadata.google.internal`.
3. **Protocol Restriction**: Only `http://` and `https://` schemes are permitted. Schemes such as `file://`, `ftp://`, or `gopher://` are rejected.
4. **Credential Redaction**: Passwords and session keys in URLs (`/live/user/pass/` and `?token=...`) are masked before being displayed in UI or logged.

