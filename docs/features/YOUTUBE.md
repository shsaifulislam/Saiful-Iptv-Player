# Saiful IPTV Player: Official YouTube Integration Specification

## 1. Overview and Architectural Compliance

The YouTube Hub subsystem allows users to bookmark, organize, and view authorized YouTube livestreams, news feeds, and video playlists within Saiful IPTV Player.

Source code implementation:
- Service: [`lib/features/youtube/services/youtube_service.dart`](file:///d:/Saiful%20iptv%20player/lib/features/youtube/services/youtube_service.dart)
- UI Presentation: [`lib/features/youtube/presentation/youtube_hub_page.dart`](file:///d:/Saiful%20iptv%20player/lib/features/youtube/presentation/youtube_hub_page.dart)

---

## 2. YouTube Terms of Service Compliance Guarantee

Saiful IPTV Player strictly adheres to the official **YouTube Developer Terms of Service**:
1. **No Ad-Blocking**: Advertisements served by YouTube are never suppressed, intercepted, or blocked.
2. **Official Embedded Player**: Video playback utilizes the official YouTube IFrame Player API (`youtube-nocookie.com/embed/VIDEO_ID?enablejsapi=1&rel=0&modestbranding=1`).
3. **No Stream Extraction**: The application does not reverse-engineer YouTube DASH/HLS cipher streams or bypass YouTube DRM.
4. **Attribution**: Video titles, channel names, and official YouTube branding are preserved.

---

## 3. Supported URL Ingestion Patterns

The `YoutubeService.extractVideoId()` function reliably parses all common YouTube URL formats:

| Format Type | URL Example | Extracted Video ID |
| :--- | :--- | :--- |
| **Standard Watch** | `https://www.youtube.com/watch?v=21X5lGlDOfg` | `21X5lGlDOfg` |
| **Shortened Link** | `https://youtu.be/21X5lGlDOfg` | `21X5lGlDOfg` |
| **Official Embed** | `https://www.youtube.com/embed/21X5lGlDOfg` | `21X5lGlDOfg` |
| **YouTube Shorts** | `https://www.youtube.com/shorts/21X5lGlDOfg` | `21X5lGlDOfg` |
| **Direct 11-char ID**| `21X5lGlDOfg` | `21X5lGlDOfg` |
| **Playlist Link** | `https://www.youtube.com/watch?v=...&list=PL12345` | Playlist ID: `PL12345` |

---

## 4. Playback Routing and Options

Users have three playback options for each saved video or live stream:
1. **Embedded Player**: Plays inside the app surface via the official YouTube IFrame Embed API.
2. **Open in YouTube App**: Invokes the native platform intent (`vnd.youtube:VIDEO_ID` on Android / Smart TV) for a native app experience.
3. **Open in Browser**: Launches the default operating system web browser targeting `https://www.youtube.com/watch?v=VIDEO_ID`.

