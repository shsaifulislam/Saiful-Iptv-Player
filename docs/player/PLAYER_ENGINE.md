# Saiful IPTV Player: Universal Media Player Engine Architecture

## 1. Executive Architecture Overview

The **Universal Media Player Engine** in Saiful IPTV Player is designed from first principles to provide uniform, high-fidelity media playback across diverse operating systems and form factors:
- **Mobile Platforms**: Android Phone & Tablet, iOS.
- **Living Room / TV Platforms**: Android TV / Google TV, Samsung Smart TV (Tizen), LG Smart TV (webOS).
- **Desktop Platforms**: Windows 10/11, macOS, and Linux.

Rather than forcing a single media backend across disparate platforms with incompatible hardware decoders, Saiful IPTV Player implements an **Adapter Architecture** powered by the abstract `PlayerEngine` interface.

```
+-----------------------------------------------------------------------------------+
|                            Saiful IPTV Player UI                                  |
|  (FullscreenPlayerPage, LocalVideoPage, MusicPage, MultiViewPage, PictureInPicture) |
+-----------------------------------------------------------------------------------+
                                         │
                                         ▼
+-----------------------------------------------------------------------------------+
|                               PlayerController                                    |
|   • Play / Pause / Seek / Speed (0.25x-2.0x)      • Gesture Recognition (Vol/Bri) |
|   • Subtitle Synchronization & Rendering           • Sleep Timer & A-B Repeat     |
|   • Technical Diagnostics Collection              • D-Pad & Keyboard Shortcuts    |
+-----------------------------------------------------------------------------------+
                                         │
                                         ▼
+-----------------------------------------------------------------------------------+
|                        PlayerAdapterFactory & Engine Contract                     |
|                                (PlayerEngine)                                     |
+-----------------------------------------------------------------------------------+
        │                       │                        │                   │
        ▼                       ▼                        ▼                   ▼
+-----------------+   +--------------------+   +-------------------+   +--------------------+
| MediaKitAdapter |   |   Media3Adapter    |   | TizenPlayerAdapter|   | WebOSPlayerAdapter |
| (libmpv 0.38+)  |   | (ExoPlayer 1.4+)   |   | (Samsung AVPlay)  |   | (LG Luna Media Bus)|
| Windows/macOS/  |   | Android Mobile &   |   | Samsung Smart TV  |   | LG Smart TV        |
| Linux Desktop   |   | Android TV         |   | (Tizen 4.0+)      |   | (webOS 4.0+)       |
+-----------------+   +--------------------+   +-------------------+   +--------------------+
```

---

## 2. Core Player Engine Contract (`PlayerEngine`)

Located in [`lib/playback/player_engine.dart`](file:///d:/Saiful%20iptv%20player/lib/playback/player_engine.dart).

### 2.1 State Lifecycle State Machine
```
            +-------------+
            |    Idle     |
            +-------------+
                   │ open(MediaSource)
                   ▼
            +-------------+
            |   Loading   |
            +-------------+
                   │
                   ▼
            +-------------+  network stall / seek
            |  Buffering  | <────────────────────+
            +-------------+                      │
                   │                             │
                   ▼ (buffer filled)             │
            +-------------+                      │
  +───────> |   Playing   | ─────────────────────+
  │ pause() +-------------+
  │                │
  │ play()         ▼ pause()
  │         +-------------+
  +──────── |   Paused    |
            +-------------+
                   │ stream ends
                   ▼
            +-------------+
            |  Completed  |
            +-------------+
                   ▲
                   │ fatal error
            +-------------+
            |    Error    |
            +-------------+
```

### 2.2 Reactive Stream Architecture
The engine exposes decoupled broadcast streams so UI elements re-render independently without unnecessary rebuilds:
- `Stream<PlaybackState> get stateStream`: Emits state transitions.
- `Stream<Duration> get positionStream`: Emits 1 Hz continuous time updates.
- `Stream<Duration> get durationStream`: Emits stream duration (or `Duration.zero` for live channels).
- `Stream<Duration> get bufferPositionStream`: Emits high-water mark for buffered content.
- `Stream<PlaybackDiagnostics> get diagnosticsStream`: Real-time streaming bitrate, FPS, dropped frame counters.
- `Stream<List<AudioTrack>> get audioTracksStream`: Dynamic audio stream track changes.
- `Stream<List<SubtitleTrack>> get subtitleTracksStream`: Active and available subtitle tracks.
- `Stream<EngineError?> get errorStream`: Structured error notifications with recovery recommendations.

---

## 3. High-Level Controller (`PlayerController`)

Located in [`lib/playback/player_controller.dart`](file:///d:/Saiful%20iptv%20player/lib/playback/player_controller.dart).

The `PlayerController` wraps the underlying engine and manages interactive features:
1. **Double-Tap Seek**:
   - Double-tapping left side seeks backward 10s.
   - Double-tapping right side seeks forward 10s.
   - Rapid successive taps accumulate (+20s, +30s) with an animated visual feedback ripple.
2. **Vertical Swipe Gestures**:
   - Left half swipe vertically: Adjusts screen brightness (0.05 to 1.0) with an on-screen HUD.
   - Right half swipe vertically: Adjusts playback volume (0.0 to 1.0) with an on-screen HUD.
3. **Lock Controls Mode**:
   - Tapping the Lock icon disables all HUD controls and gestures, preventing accidental input.
   - A persistent unlock button allows the user to disengage lock mode at any time.
4. **Sleep Timer**:
   - Configurable for 15 min, 30 min, 45 min, 60 min, or custom durations.
   - Real-time countdown ticker with auto-pause/stop upon completion.
5. **A-B Repeat Mode**:
   - Tap to set **Point A** (start boundary).
   - Tap to set **Point B** (end boundary).
   - Automatically and seamlessly loops playback between Point A and Point B until cleared.
6. **Aspect Ratio Switching**:
   - Cycles through: `16:9`, `4:3`, `Fill`, `Fit`, `Stretch`, and `Original`.
7. **Keyboard & TV Remote Bindings**:
   - `Space`: Play/Pause.
   - `Arrow Left` / `Arrow Right`: Seek -/+ 10 seconds.
   - `Arrow Up` / `Arrow Down`: Volume +5% / -5%.
   - `M`: Toggle Mute.
   - `L`: Toggle Controls Lock.
   - `D`: Open Real-Time Technical Diagnostics Drawer.
   - `S`: Open Audio & Subtitle Selection Sheet.
   - `Escape`: Exit Fullscreen Player.

---

## 4. Subtitle Subsystem

Located in [`lib/playback/subtitles/subtitle_parser.dart`](file:///d:/Saiful%20iptv%20player/lib/playback/subtitles/subtitle_parser.dart).

- **Format Support**: SubRip (`.srt`) and WebVTT (`.vtt`).
- **Parsing**:
  - Handles millisecond timestamps with comma (`,`) or period (`.`) separators.
  - Strips inline formatting tags (`<i>`, `<b>`, `<font color="...">`) to maintain typographic consistency.
- **Dynamic Delay Sync**: Supports adjusting subtitle delay in +/- 50ms, 100ms, and 500ms increments.
- **Styling Configuration**: Customizable text color, font size, background container opacity, and bottom margin.

---

## 5. Audio Subsystem (`AudioQueueManager`)

Located in [`lib/playback/audio/audio_queue_manager.dart`](file:///d:/Saiful%20iptv%20player/lib/playback/audio/audio_queue_manager.dart).

- **Queue Management**: Enqueue, reorder, play at index, skip next, skip previous.
- **Repeat Modes**:
  - `AudioRepeatMode.off`: Stops when the queue finishes.
  - `AudioRepeatMode.all`: Loops back to the first track when the queue reaches the end.
  - `AudioRepeatMode.one`: Repeatedly loops the current track indefinitely.
- **Shuffle**: Non-destructive shuffle maintaining track history and current track continuity.
- **Speed Multiplier**: Supports variable speed from 0.5x to 2.0x with pitch correction.

---

## 6. Security and Credential Redaction

A strict security constraint of Saiful IPTV Player is that **sensitive credentials must never be leaked** into log files, error messages, or diagnostic overlays.

The engine applies automated redaction in [`MediaSource.sanitizeMediaUri`](file:///d:/Saiful%20iptv%20player/lib/playback/player_engine.dart#L49):
1. **User Info**: `http://admin:secret@stream.host/` -> `http://***:***@stream.host/`
2. **Xtream Codes Routes**: `.../live/myuser/mypass/channel.m3u8` -> `.../live/****/****/channel.m3u8`
3. **Query Parameters**: Any `token`, `key`, `password`, `auth`, `hash`, or `secret` parameters are sanitized to `[REDACTED]`.

