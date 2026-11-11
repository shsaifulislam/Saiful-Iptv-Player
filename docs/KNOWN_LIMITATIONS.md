# Known Limitations & Platform Compatibility Matrix

**Saiful IPTV Player**  
**Version**: 1.0.0  
**Authority**: Principal Systems Engineer & Release Manager  

---

## 1. Hardware & Platform Limitations

| Platform | Production Readiness | Target Engine | Known Limitations & Boundary Constraints |
| :--- | :--- | :--- | :--- |
| **Android Mobile & Tablet** | **PRODUCTION READY** | ExoPlayer / Media3 | Hardware video decoders vary on entry-level chipsets. Scoped storage requires user permission on Android 13+. |
| **Android TV (Google TV)** | **PRODUCTION READY** | ExoPlayer / Leanback | Multi-view quad streaming requires modern SoC (Amlogic S905X4 or higher) with multi-instance hardware decoder. |
| **Windows Desktop** | **PRODUCTION READY** | libmpv / Native C++ | Hardware acceleration depends on installed GPU drivers (DirectX 11/12 or Vulkan). HEVC requires Windows HEVC extension. |
| **macOS Desktop** | **VERIFIED CONFIG** | AVPlayer / libmpv | Native sandbox entitlements restrict arbitrary filesystem access outside user-selected security-scoped bookmarks. |
| **Linux Desktop** | **VERIFIED CONFIG** | libmpv / GStreamer | Requires GTK 3 and PipeWire / PulseAudio sound architecture. Wayland scaling supported. |
| **Web Browser (PWA)** | **VERIFIED CONFIG** | HTML5 Video / CanvasKit | Browser sandbox prohibits direct UDP/RTSP streaming. Cross-Origin Resource Sharing (CORS) required on HLS streams. |
| **Samsung Tizen TV** | **PLATFORM LIMITATION** | Web Application Wrapper | Tizen OS does not officially run native Dart AOT Flutter binaries. Requires packaging via Tizen Web SDK / Tizen WebKit engine. |
| **LG webOS TV** | **PLATFORM LIMITATION** | Web Application Wrapper | LG webOS runs web applications via Chromium engine. Supported as a web-packaged client; native Flutter engine not supported. |

---

## 2. Multi-View Hardware Concurrency Limits

The Multi-View engine (`MultiViewController`) supports 2 simultaneous streams (Split) and 4 simultaneous streams (Quad).
- **SoC Decoding Constraint**: Low-cost streaming sticks (e.g. older Fire TV sticks or 1GB RAM Android boxes) typically have only one hardware video decoder instance. Attempting to decode 4 concurrent 1080p H.265 streams in software may cause thermal throttling or frame drops.
- **Defensive Safeguard**: The UI displays a warning banner when Quad mode is selected, and each stream tile operates in an isolated error boundary so that a single stream crash never crashes the player.

---

## 3. YouTube TOS Compliance Boundaries

In strict compliance with YouTube Developer Policies and Google Brand Guidelines:
- **No Stream Ripping or Ad-Blocking**: The app does **NOT** rip raw video streams or bypass ads. Playback occurs solely through the official YouTube IFrame Embed Player API.
- **Active Internet Requirement**: YouTube playback requires an active internet connection to contact YouTube's infrastructure. Offline caching of YouTube content is expressly disabled.

---

## 4. Third-Party IPTV Stream Reliability

Saiful IPTV Player is a media client software application and does not provide, own, or resell streaming content.
- Stream availability, resolution, bitrate, geographic geoblocking, and uptime are controlled entirely by the user's chosen third-party IPTV provider.
- Network timeouts, DNS failures, or HTTP 403 Forbidden errors triggered by provider servers are surfaced cleanly through the built-in **Stream Diagnostics Service**.

