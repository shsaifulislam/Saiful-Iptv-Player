# Saiful IPTV Player: Platform Playback Adapters

## 1. Architectural Strategy

To guarantee optimum playback performance without vendor lock-in, Saiful IPTV Player implements a decoupled adapter pattern via the `PlayerEngine` contract. This document outlines the technical design, lifecycle management, and hardware surface bindings for each adapter.

---

## 2. Adapter Specifications

### 2.1 MediaKit Adapter (`MediaKitAdapter`)
- **Target Platforms**: Windows 10/11, macOS, Linux, and universal desktop fallback.
- **Engine Core**: `libmpv 0.38+` client API with C-FFI / dynamic bindings.
- **Source Location**: [`lib/playback/media_kit/media_kit_adapter.dart`](file:///d:/Saiful%20iptv%20player/lib/playback/media_kit/media_kit_adapter.dart)
- **Hardware Acceleration Pipeline**:
  - **Windows**: `hwdec=d3d11va`, Direct3D 11 rendering pipeline with ANGLE support.
  - **macOS**: `hwdec=videotoolbox`, Metal surface rendering.
  - **Linux**: `hwdec=vaapi` or `nvdec` via OpenGL/Vulkan surface.
- **Features**:
  - Complete demuxing and decoding support for `.mkv`, `.mp4`, `.avi`, `.mov`, `.webm`, and `.ts`.
  - Seamless external subtitle rendering (`.srt`, `.vtt`, `.ass`).
  - High-precision audio resampler (libswresample) for 24-bit 192kHz audiophile FLAC and PCM WAV.

### 2.2 Android Media3 Adapter (`Media3Adapter`)
- **Target Platforms**: Android Mobile (API 26+), Android Tablets, Android TV, Google TV.
- **Engine Core**: Android Media3 ExoPlayer 1.4+.
- **Source Location**: [`lib/playback/android_media3/media3_adapter.dart`](file:///d:/Saiful%20iptv%20player/lib/playback/android_media3/media3_adapter.dart)
- **Hardware Acceleration Pipeline**:
  - `DefaultRenderersFactory` utilizing Android `MediaCodec` hardware decoders (`c2.android.avc.decoder`, `c2.android.hevc.decoder`).
  - **Audio Tunneling**: Enabled on Android TV devices for synchronized multi-channel passthrough (Dolby Digital Plus / Atmos) directly to connected soundbars without CPU overhead.
  - **Load Control**: `DefaultLoadControl` custom-tuned for IPTV:
    - Minimum buffer: 15,000 ms.
    - Maximum buffer: 50,000 ms.
    - Buffer for playback: 2,500 ms.
    - Buffer for playback after rebuffer: 5,000 ms.
- **Storage Compatibility**: Full integration with Android Scoped Storage and Storage Access Framework (`content://` URIs).

### 2.3 Samsung Tizen Native Adapter (`TizenPlayerAdapter`)
- **Target Platforms**: Samsung Smart TV running Tizen OS 4.0+.
- **Engine Core**: Samsung `webapis.avplay` hardware multimedia framework.
- **Source Location**: [`lib/playback/tizen_adapter/tizen_player_adapter.dart`](file:///d:/Saiful%20iptv%20player/lib/playback/tizen_adapter/tizen_player_adapter.dart)
- **Hardware Pipeline**:
  - Direct hardware video hole surface rendering configured via `avplay.setDisplayRect(x, y, width, height)`.
  - Native 4K UHD 60fps hardware decoding for H.264, HEVC, and VP9.
  - Hardware audio passthrough for AC-3 and E-AC-3 over HDMI eARC.
- **Remote Integration**: D-Pad navigation keys (Enter, Return, Play, Pause, Rewind, FastForward, Color buttons) mapped directly to player actions.

### 2.4 LG webOS Native Adapter (`WebOSPlayerAdapter`)
- **Target Platforms**: LG Smart TV running webOS 4.0+.
- **Engine Core**: webOS Luna Media Pipeline (`luna://com.webos.media`).
- **Source Location**: [`lib/playback/webos_adapter/webos_player_adapter.dart`](file:///d:/Saiful%20iptv%20player/lib/playback/webos_adapter/webos_player_adapter.dart)
- **Hardware Pipeline**:
  - WebOS media service pipeline integration managing video surface pipeline allocation.
  - Hardware decoding supporting Dolby Vision Profile 5/8 and Dolby Atmos.
  - Native Magic Remote pointer and D-Pad focus synchronization.

---

## 3. Adapter Selection Factory (`PlayerAdapterFactory`)

Located in [`lib/playback/player_adapter_factory.dart`](file:///d:/Saiful%20iptv%20player/lib/playback/player_adapter_factory.dart).

The factory provides intelligent auto-detection based on the runtime operating system:
1. **Runtime Detection Logic**:
   - `Platform.isAndroid`: Instantiates `Media3Adapter`.
   - `Platform.isWindows`, `isMacOS`, `isLinux`: Instantiates `MediaKitAdapter`.
   - Tizen / webOS: When running on smart TV embedded runtimes, instantiates `TizenPlayerAdapter` or `WebOSPlayerAdapter`.
2. **Manual Override Support**:
   - Power users can configure the active engine in **Player Settings** (`forcedAdapter: 'mediakit'` or `forcedAdapter: 'media3'`), allowing software decoding on older Android TV boxes with buggy hardware decoders.

---

## 4. Resource & Memory Management

Every adapter guarantees deterministic lifecycle cleanup:
1. **On `open()`**: Resets position counters, cancels existing tickers, reallocates media pipeline surface.
2. **On `dispose()`**:
   - Cancels all timers and polling loops.
   - Closes all Dart broadcast StreamControllers (`stateController`, `positionController`, `durationController`, etc.).
   - Releases native hardware decoder surfaces (`MediaCodec`, `avplay.close()`, `mpv_destroy()`).
   - Sets `isInitialized = false` to prevent dangling references or memory leaks.

