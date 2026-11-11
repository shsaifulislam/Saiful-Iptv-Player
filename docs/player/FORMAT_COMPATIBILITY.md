# Saiful IPTV Player: Format and Codec Compatibility Matrix

## 1. Overview & Architectural Principles

Saiful IPTV Player supports a wide range of broadcast streaming protocols, local video containers, and audio formats. Because hardware decoding capabilities, patent pools, and system decoders differ across host operating systems, this matrix documents the verified, realistic support status for each target platform.

> [!IMPORTANT]
> Saiful IPTV Player does not claim universal hardware acceleration for proprietary or patented codecs on platforms where the OS vendor omits native licensing. Where hardware decoding is unavailable, the player provides graceful software fallback or clear diagnostic guidance.

---

## 2. Container and Video Format Matrix

| Container / Format | File Extension | Android (Phone/TV) | Windows (10/11) | macOS | Linux | Samsung Tizen TV | LG webOS TV |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **MP4 (MPEG-4 Part 14)** | `.mp4`, `.m4v` | Native (HW) | Native (HW) | Native (HW) | Native (HW/SW) | Native (HW) | Native (HW) |
| **Matroska Video** | `.mkv` | Native (Media3 / Extractor) | Native (libmpv) | Native (libmpv) | Native (libmpv) | Native (AVPlay) | Native (Luna) |
| **QuickTime File** | `.mov` | Native (HW) | Native (libmpv) | Native (HW) | Native (libmpv) | Conditional (H.264/HEVC) | Conditional |
| **Audio Video Interleave** | `.avi` | SW Fallback | Native (libmpv) | Native (libmpv) | Native (libmpv) | Legacy Only | Legacy Only |
| **WebM** | `.webm` | Native (VP8/VP9/AV1) | Native (libmpv) | Native (libmpv) | Native (libmpv) | Native (VP9/AV1) | Native (VP9/AV1) |
| **MPEG-2 Transport Stream**| `.ts`, `.m2ts` | Native (HW) | Native (HW) | Native (HW) | Native (HW) | Native (HW) | Native (HW) |

---

## 3. Video Codec Support

| Codec | Standards Profile | Hardware Surface | Recommended Resolution & Bitrate | Platform Support Notes |
| :--- | :--- | :--- | :--- | :--- |
| **AVC / H.264** | Baseline, Main, High (up to L5.2) | MediaCodec, D3D11VA, VideoToolbox, VAAPI | Up to 4K UHD 60fps (30 Mbps) | Globally supported across 100% of target devices. Primary format for IPTV streams. |
| **HEVC / H.265** | Main, Main 10 (10-bit HDR10) | MediaCodec, D3D11VA, VideoToolbox, AVPlay | Up to 4K UHD 60fps / 8K TV (60 Mbps) | Supported in hardware on modern Android, Smart TVs, and Desktop GPUs (Intel Gen 7+, AMD RX, Nvidia GTX 950+). Windows requires HEVC Video Extensions. |
| **AV1 (AOMedia Video 1)** | Main Profile | MediaCodec (Android 10+), libgav1, D3D11VA | Up to 4K UHD 60fps (25 Mbps) | Modern chipsets (Tensor, Snapdragon 8 Gen 2+, Dimensity 9000+, Intel Arc, RTX 30+). Software fallback enabled for legacy devices. |
| **VP9** | Profile 0, Profile 2 (10-bit HDR) | MediaCodec, libvpx, libmpv | Up to 4K UHD 60fps (30 Mbps) | Native on YouTube content, Android TV, and all desktop platforms. |
| **Apple ProRes** | Standard, HQ, 4444 | VideoToolbox, libmpv | Up to 4K UHD 60fps (150 Mbps) | Native on macOS; decoded via libmpv on Windows/Linux; not recommended on mobile or low-power TV chipsets. |

---

## 4. Audio Format and Codec Matrix

| Audio Format | Extension | Bit Depth & Sample Rate | Supported Platforms | Features & Notes |
| :--- | :--- | :--- | :--- | :--- |
| **MP3 (MPEG Audio Layer III)** | `.mp3` | Up to 320 kbps, 48 kHz | All Platforms | Full background playback, ID3 metadata tags, album art. |
| **AAC (Advanced Audio Coding)** | `.aac`, `.m4a` | LC, HE-AAC v1/v2 up to 5.1 | All Platforms | Standard broadcast audio for HLS and DASH IPTV channels. |
| **FLAC (Free Lossless Audio)** | `.flac` | 16/24-bit up to 192 kHz | All Platforms | Audiophile playback with zero compression loss. |
| **WAV (Waveform Audio)** | `.wav` | Uncompressed PCM | All Platforms | Low latency, uncompressed studio recordings. |
| **OGG Vorbis / Opus** | `.ogg`, `.opus` | Variable bitrate, 48 kHz | All Platforms | Ultra-low latency voice and stream audio. |
| **Dolby Digital / AC-3** | `.ac3`, `.eac3` | 5.1 / 7.1 Atmos | Android TV, Tizen, webOS, Desktop | Native hardware pass-through over HDMI ARC/eARC to AV receivers. |

---

## 5. Streaming Protocol Compatibility

| Protocol | Container | Supported Platforms | Adaptive Bitrate (ABR) | Latency Profile |
| :--- | :--- | :--- | :--- | :--- |
| **HTTP Live Streaming (HLS)** | `.m3u8` (TS & fMP4) | All Platforms | Yes (Auto & Manual Quality Picker) | Low-latency HLS (LL-HLS) 2-4s, Standard 6-12s |
| **Dynamic Adaptive Streaming (DASH)** | `.mpd` (fMP4) | All Platforms | Yes (Multi-period support) | 3-8s latency |
| **Progressive HTTP/HTTPS** | `.mp4`, `.mkv` | All Platforms | No (Direct seek over HTTP range requests) | Instant buffer start |
| **RTSP / RTMP** | Raw Network Stream | Desktop & Android | No | Live surveillance / personal broadcast feeds |

---

## 6. Real-Time Compatibility Diagnostics

When an incompatible codec or corrupted container is encountered, the player engine surfaces diagnostic details in the **Diagnostics Drawer (Key 'D')**:
1. **Container Demux Error**:
   - `Error Code`: `ERROR_CODE_PARSING_CONTAINER_UNSUPPORTED`
   - `Suggestion`: Container header is unrecognized. Check if file is incomplete or try opening with MediaKit software adapter.
2. **Codec Initialization Error**:
   - `Error Code`: `ERROR_CODE_DECODER_INIT_FAILED`
   - `Suggestion`: Hardware decoder failed to allocate memory or device lacks native profile. Switch to software decoding in Player Settings.
3. **HTTP 401/403 Token Expiration**:
   - `Error Code`: `ERROR_CODE_IO_HTTP_UNAUTHORIZED`
   - `Suggestion`: IPTV provider credentials or token expired. Re-authenticate playlist in Playlist Manager.

