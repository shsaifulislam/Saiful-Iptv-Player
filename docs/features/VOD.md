# Saiful IPTV Player: Movies and VOD Specification

## 1. Overview and Architecture

The Video-on-Demand (VOD) subsystem delivers a Netflix-inspired cinema experience for licensed feature films, documentaries, and episodic television series. It provides continuous playback progress tracking, personalized watchlists, genre filters, and episodic navigation.

Source code implementation:
- Service: [`lib/features/movies/services/vod_service.dart`](file:///d:/Saiful%20iptv%20player/lib/features/movies/services/vod_service.dart)
- Model: [`lib/features/movies/models/vod_movie.dart`](file:///d:/Saiful%20iptv%20player/lib/features/movies/models/vod_movie.dart)
- UI Presentation:
  - Catalog: [`lib/features/movies/presentation/movies_page.dart`](file:///d:/Saiful%20iptv%20player/lib/features/movies/presentation/movies_page.dart)
  - Details: [`lib/features/movies/presentation/movie_detail_page.dart`](file:///d:/Saiful%20iptv%20player/lib/features/movies/presentation/movie_detail_page.dart)
  - Series: [`lib/features/movies/presentation/tv_series_page.dart`](file:///d:/Saiful%20iptv%20player/lib/features/movies/presentation/tv_series_page.dart)

---

## 2. Licensed Content Integration

In strict adherence to international copyright standards and the project's zero-unauthorized-streaming policy, Saiful IPTV Player only ingests content from authorized, licensed, or open-licensed repositories (such as the Blender Open Movie Foundation, public archives, and authenticated provider VOD feeds).

### 2.1 Default Licensed Seed Catalog
- **Tears of Steel** (Sci-Fi, 4K HDR, 114 min)
- **Big Buck Bunny** (Animation, 1080p 60fps, 92 min)
- **Cosmos: Infinite Odyssey** (Documentary, 4K UHD, 130 min)
- **Cyber Horizon 2049** (Action, 4K HDR, 125 min)
- **Chronicles of Deep Space** (Episodic Sci-Fi Series with multi-episode support)

---

## 3. Core Features

### 3.1 Continue Watching & Playback Resumption
- Playback position is recorded continuously in the local database and synchronized to the cloud backend.
- Any title with more than 10 seconds of watch history appears in the **Continue Watching** horizontal carousel on the Movies and Home dashboard.
- Clicking "Resume Playback" launches the universal player engine positioned precisely at the last watched timestamp.

### 3.2 Personalized Watchlist
- Users can bookmark any title to their watchlist via the bookmark button.
- Watchlist changes synchronize bidirectionally across connected user devices.

### 3.3 Episodic Television Series
- Series titles support structured `seasonNumber` and `episodeNumber` attributes.
- The episode picker displays individual episode runtimes, synopses, and quick play buttons.

### 3.4 Metadata & Classification
- High-resolution poster (2:3 aspect ratio) and backdrop banner (16:9 aspect ratio).
- Standardized genre tagging: `Sci-Fi`, `Animation`, `Action`, `Documentary`, `Drama`, `Series`.
- Age ratings (`G`, `PG`, `PG-13`, `R`, `NC-17`) for Parental Control enforcement.


---

## 4. Movie Web Portals & Offline Downloads Integration

### 4.1 Movie Web Portals Hub
To empower users to discover external media and direct download links from web portals, Saiful IPTV Player includes a dedicated **Movie Web Portals Hub**:
- Service: [`MoviePortalService`](file:///d:/Saiful%20iptv%20player/lib/features/movies/services/movie_portal_service.dart)
- Model: [`MoviePortalBookmark`](file:///d:/Saiful%20iptv%20player/lib/features/movies/models/movie_portal_bookmark.dart)
- Dialog / Viewer: [`MoviePortalDialog`](file:///d:/Saiful%20iptv%20player/lib/features/movies/presentation/movie_portal_dialog.dart)

#### Pre-Configured Movie Portals:
1. **MovieLink BD**: `https://4vyu23.movielinkbd.at/` — Bangla & South Asian Movie Downloads & Web Portal.
2. **HDHub4u**: `https://new12.hdhub4u.cl/?utm=mn1` — Dual Audio & HD Movies, Series & Direct Download Links.
3. **Internet Archive Feature Films**: `https://archive.org/details/feature_films` — Free public domain cinema archive.
4. **Blender Open Movies**: `https://studio.blender.org/films/` — 4K animated open films & media downloads.

Users can add custom movie portals via the **+ Add Portal** dialog and inspect SSL and safety status before visiting or downloading.

### 4.2 Offline Media Download Manager
- Service: [`DownloadManagerService`](file:///d:/Saiful%20iptv%20player/lib/features/downloads/services/download_manager_service.dart)
- Screen: [`DownloadsPage`](file:///d:/Saiful%20iptv%20player/lib/features/downloads/presentation/downloads_page.dart)
- Capabilities:
  - Download media by direct HTTP/HTTPS URL from any portal or cloud CDN.
  - Live progress bar, downloaded bytes vs total size, and transfer speed (e.g. `2.4 MB/s`).
  - Pause, resume, and cancel download controls.
  - One-tap "Play Now" button that routes completed video files directly into the Universal Player Engine.
