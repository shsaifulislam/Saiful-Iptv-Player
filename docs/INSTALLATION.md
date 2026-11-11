# Installation & Setup Guide

**Saiful IPTV Player**  
**Version**: 1.0.0  
**Target Environments**: Android Mobile / Android TV, Windows 10/11, Linux, macOS, Web  

---

## 1. System Requirements & Prerequisites

To build and compile Saiful IPTV Player from source, install the following toolchain dependencies:

| Tool | Minimum Version | Recommended | Notes |
| :--- | :--- | :--- | :--- |
| **Flutter SDK** | `>= 3.24.0` | `3.47.9` | Channel `stable` |
| **Dart SDK** | `>= 3.5.0` | `3.13.7` | Bundled with Flutter SDK |
| **Node.js** | `>= 18.0.0` | `20.x LTS` | For test runners and verification tools |
| **Git** | `>= 2.30.0` | Latest | Source control |
| **Android Studio / SDK** | API 34 | Android SDK 34 | Required for Android & Android TV builds |
| **Visual Studio** | 2022 | Community or higher | Required for Windows desktop compilation |
| **CMake & Ninja** | 3.14+ | Latest | Required for Windows/Linux native builds |
| **Xcode** | 15.0+ | Latest | Required for macOS & iOS builds |

---

## 2. Environment Configuration

1. Clone or extract the repository:
   ```bash
   git clone https://github.com/saiful/saiful-iptv-player.git
   cd "saiful-iptv-player"
   ```

2. Copy the environment template:
   ```bash
   cp .env.example .env
   ```

3. Configure your compile-time client settings in `.env`:
   ```ini
   APP_ENV=production
   SUPABASE_URL=https://your-supabase-project.supabase.co
   SUPABASE_ANON_KEY=sb_publishable_your_public_anon_key
   ```
   *(Note: Never place service-role keys or production database passwords in client `.env` files).*

4. Install Flutter package dependencies:
   ```bash
   flutter pub get
   ```

---

## 3. Platform Build Instructions

### A. Android Mobile (APK / App Bundle)
- **Universal Debug APK**:
  ```bash
  flutter build apk --debug
  ```
- **Optimized Release App Bundle (Google Play)**:
  ```bash
  # Ensure android/key.properties has been populated from android/key.properties.example
  flutter build appbundle --release
  # Output: build/app/outputs/bundle/release/app-release.aab
  ```

### B. Android TV (Leanback)
The Android manifest is preconfigured with the Leanback launcher intent filter (`android.intent.category.LEANBACK_LAUNCHER`) and `android.hardware.touchscreen = false`.
- Build the TV release bundle:
  ```bash
  flutter build appbundle --release
  ```

### C. Windows Desktop
Requires Visual Studio 2022 with the "Desktop development with C++" workload installed:
```powershell
flutter build windows --release
# Output: build/windows/x64/runner/Release/saiful_iptv_player.exe
```

### D. Linux Desktop
Requires GTK 3 development headers (`libgtk-3-dev`, `pkg-config`, `ninja-build`):
```bash
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev
flutter build linux --release
# Output: build/linux/x64/release/bundle/saiful_iptv_player
```

### E. macOS Desktop
Requires Xcode command-line tools:
```bash
flutter build macos --release
# Output: build/macos/Build/Products/Release/Saiful IPTV Player.app
```

### F. Web (PWA)
```bash
flutter build web --release --web-renderer canvaskit
# Output: build/web/
```

---

## 4. Running Verification Test Suites

Verify your environment and local build integrity by executing the automated test suites:
```bash
node test/backend_comprehensive_test.mjs
node test/ui_screens_comprehensive_test.mjs
node test/player_engine_comprehensive_test.mjs
node test/iptv_comprehensive_test.mjs
node test/entertainment_comprehensive_test.mjs
node test/verify_uploaded_playlist.mjs
```
Expected output: **All test suites PASS with 100% success rate**.

