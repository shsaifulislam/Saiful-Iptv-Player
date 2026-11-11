# Saiful IPTV Player: Playback Engine Test Report

## 1. Test Execution Summary

| Parameter | Value |
| :--- | :--- |
| **Test Suite** | Universal Media Player Engine Verification Suite |
| **Execution Date** | 2026-11-11 |
| **Environment** | Windows 11 / Cross-Platform Automated Engine Harness (Node.js 24 + Dart Test Runner) |
| **Status** | **ALL TESTS PASSED (8/8 Suites, 100% Success Rate)** |
| **Target Platforms Verified** | Android Mobile & TV, Windows, macOS, Linux, Samsung Tizen, LG webOS |

---

## 2. Test Suite Breakdown and Verification Evidence

### Test Suite 1: MediaSource URL Credential Sanitization
- **Objective**: Verify that sensitive provider credentials, passwords, session tokens, and Xtream Codes path segments are stripped from public diagnostics and error logs.
- **Input Test Vectors**:
  - `http://provider.tv:8080/live/saiful_user/secret_pass_99/12345.m3u8?token=xyz987&other=1`
  - `http://admin:masterkey@stream.iptv.com:8000/movie/user1/pass2/100.mp4`
- **Output Verified**:
  - `http://provider.tv:8080/live/****/****/12345.m3u8?token=[REDACTED]&other=1`
  - `http://***:***@stream.iptv.com:8000/movie/****/****/100.mp4`
- **Assertions**:
  - `assert(!clean.includes('saiful_user'))` -> PASSED
  - `assert(!clean.includes('secret_pass_99'))` -> PASSED
  - `assert(!clean.includes('xyz987'))` -> PASSED
  - `assert(clean.includes('****/****/12345.m3u8'))` -> PASSED
- **Status**: **PASSED**

---

### Test Suite 2: Subtitle Parsing and Dynamic Delay Sync
- **Objective**: Verify that SubRip (`.srt`) and WebVTT (`.vtt`) subtitles parse cue indices, millisecond start/end timestamps, strip HTML styling tags, and adjust to positive/negative millisecond sync delays.
- **Input Test Vector**:
  ```srt
  1
  00:01:20,000 --> 00:01:25,500
  <i>Hello world</i> & welcome to Saiful IPTV!

  2
  00:01:26,000 --> 00:01:30,000
  Enjoy <b>Universal Playback</b> with full subtitles.
  ```
- **Assertions**:
  - `cues.length == 2` -> PASSED
  - `cues[0].start == 80000 ms (1m 20s)` -> PASSED
  - `cues[0].end == 85500 ms` -> PASSED
  - `cues[0].text == "Hello world & welcome to Saiful IPTV!"` (HTML stripped) -> PASSED
  - `isCueActive(cue, 82000 ms)` -> `true` -> PASSED
  - `isCueActive(cue, 79000 ms, delayMs = -2000 ms)` -> `true` -> PASSED
- **Status**: **PASSED**

---

### Test Suite 3: Media Diagnostics & Error Recovery Suggester
- **Objective**: Verify buffer health calculations and actionable troubleshooting messages for common playback failures.
- **Assertions**:
  - Buffer health with 30s lead against 30s target = `1.0` (100% full lead) -> PASSED
  - Buffer health with 10s lead against 30s target = `0.333` -> PASSED
  - Code `ERROR_CODE_DECODER_INIT_FAILED` -> Suggests switching to Software Decoder -> PASSED
  - Code `ERROR_CODE_IO_NETWORK_CONNECTION_TIMEOUT` -> Suggests checking network and stream host -> PASSED
  - Code `ERROR_CODE_IO_HTTP_UNAUTHORIZED` -> Suggests re-authenticating playlist subscription -> PASSED
- **Status**: **PASSED**

---

### Test Suite 4: A-B Repeat Loop Boundary Logic
- **Objective**: Verify that when Point A and Point B are active, reaching or exceeding Point B immediately triggers a seek back to Point A.
- **Assertions**:
  - Set Point A = 10,000 ms; Point B = 25,000 ms.
  - Position at 15,000 ms -> maintains 15,000 ms -> PASSED
  - Position reaching 25,000 ms -> loops position to 10,000 ms, increments seek count -> PASSED
- **Status**: **PASSED**

---

### Test Suite 5: Audio Queue Management and Repeat Modes
- **Objective**: Verify playlist progression, skip next, skip previous, repeat off, repeat all, and repeat one.
- **Assertions**:
  - Queue `[Track 1, Track 2, Track 3]`:
    - `next()` moves to Track 2, then Track 3 -> PASSED
    - With `repeatMode = 'off'`, `next()` stays at Track 3 -> PASSED
    - With `repeatMode = 'all'`, `next()` loops back to Track 1 -> PASSED
    - `previous(positionSec = 1)` loops back to Track 3 -> PASSED
- **Status**: **PASSED**

---

### Test Suite 6: Gesture Delta Scaling and Clamping
- **Objective**: Verify swipe volume and brightness vertical gesture delta clamping.
- **Assertions**:
  - Volume `(0.9 + 0.2)` clamped to `1.0` -> PASSED
  - Volume `(0.1 - 0.3)` clamped to `0.0` -> PASSED
  - Brightness `(0.5 + 0.6)` clamped to `1.0` -> PASSED
  - Brightness `(0.1 - 0.2)` clamped to minimum threshold `0.05` (prevents total black screen lockup) -> PASSED
- **Status**: **PASSED**

---

### Test Suite 7: Local Media Browser Scanning, Sorting, and Search
- **Objective**: Verify file extension categorization, sorting by name, size, and date, search query filtering, and recent file tracking.
- **Assertions**:
  - `categorize('mp4')` -> `video` -> PASSED
  - `categorize('flac')` -> `audio` -> PASSED
  - Sort by name ascending: `Alpha Video.mp4` precedes `Beta Video.mkv` -> PASSED
  - Sort by size descending: `Alpha Video.mp4 (1000)` precedes `Gamma Video.webm (250)` -> PASSED
  - Search query `Beta` matches only `Beta Video.mkv` -> PASSED
- **Status**: **PASSED**

---

### Test Suite 8: Platform Adapter Capability Specifications
- **Objective**: Verify all target platform adapters are registered with their respective hardware surfaces.
- **Assertions**:
  - 4 adapters registered (`mediakit`, `media3`, `tizen`, `webos`) -> PASSED
  - Desktop `mediakit` supports MKV, MP4, AVI, MOV, WebM, TS containers -> PASSED
  - `tizen` engine is mapped to `AVPlay` -> PASSED
  - `webos` engine is mapped to `Luna Media Pipeline` -> PASSED
- **Status**: **PASSED**

---

## 3. Regression Testing

All previous prompt test suites were executed to verify that player engine modifications did not break existing features:
1. `test/backend_comprehensive_test.mjs`: **12/12 PASSED**
2. `test/ui_screens_comprehensive_test.mjs`: **7/7 PASSED**
3. `test/player_engine_comprehensive_test.mjs`: **8/8 PASSED**

**Overall Test Suite Status: 27/27 Tests Passing.**

