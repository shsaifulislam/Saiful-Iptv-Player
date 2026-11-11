# Saiful IPTV Player: Photo Gallery & Slideshow Specification

## 1. Overview and Architecture

The Photo Gallery subsystem enables users to view, manage, and present personal high-resolution photos and graphic collections on mobile devices, desktop monitors, and living room smart TVs.

Source code implementation:
- Service: [`lib/features/photos/services/photo_gallery_service.dart`](file:///d:/Saiful%20iptv%20player/lib/features/photos/services/photo_gallery_service.dart)
- UI Presentation: [`lib/features/photos/presentation/photos_page.dart`](file:///d:/Saiful%20iptv%20player/lib/features/photos/presentation/photos_page.dart)

---

## 2. Supported Formats

| Format | Extension | Capabilities | Notes |
| :--- | :--- | :--- | :--- |
| **JPEG** | `.jpg`, `.jpeg` | Baseline, Progressive, EXIF metadata | Universal format for digital cameras and mobile phones. |
| **PNG** | `.png` | 24-bit RGB, 8-bit Alpha transparency | Lossless screenshots and digital graphics. |
| **WebP** | `.webp` | Lossy, Lossless, and Animated | Modern high-efficiency web image format. |
| **GIF** | `.gif` | Multi-frame animated loops | Animated graphics and meme loops. |
| **BMP** | `.bmp` | 24/32-bit Uncompressed bitmaps | Supported across desktop file systems. |

---

## 3. Core Capabilities

### 3.1 Album & Folder Browsing
- Automatically groups images by album directory name (e.g. `Vacations`, `Heritage`, `Mountains`, `Wallpapers`).
- Instant category chip navigation to switch between album folders.

### 3.2 Interactive Zoom & Viewer
- Built using Flutter's `InteractiveViewer` with multi-touch pinch-to-zoom and pan support (0.8x to 4.0x zoom scale).
- Double-tap to reset or zoom into high-resolution details.

### 3.3 Automated Slideshow Engine
- Automated carousel loop that transitions through photos sequentially.
- Configurable intervals: 3 seconds, 5 seconds, or 10 seconds.
- Play, Pause, and Skip controls with TV remote support.

### 3.4 Image Technical Details
- Displays resolution dimensions (e.g. `3840x2160`), file size (KB / MB), date modified, and encoding format.

### 3.5 Permissions & Scoped Storage
- Uses Android 13+ `READ_MEDIA_IMAGES` and Scoped Storage APIs.
- Operates locally without uploading private user photos to external servers.

