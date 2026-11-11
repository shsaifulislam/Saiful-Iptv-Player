# Privacy Policy & Data Retention Policy

**Saiful IPTV Player**  
**Classification**: Public & User-Facing Privacy Charter  
**Version**: 1.0.0  
**Effective Date**: November 2026  

---

## 1. Principles of Data Privacy

Saiful IPTV Player adheres to a **zero-unnecessary-collection** privacy policy. We believe entertainment consumption is personal and private:
- We **NEVER** monitor, upload, inspect, or copy your personal local video, audio, or photo files.
- We **NEVER** sell your playback habits, browsing preferences, or personal data to advertisers or data brokers.
- We **NEVER** bypass content provider DRM or extract restricted user tokens without consent.

---

## 2. Information We Process

### A. Information Stored Locally on Your Device
- **Local Playlists & Cache**: Imported `.m3u` / `.m3u8` files and downloaded channel logos.
- **Local Media Index**: Metadata (file name, duration, thumbnail) for media browsed in the Local Video, Audio, and Photo galleries.
- **Diagnostics Log**: In-memory ring-buffer containing network latency and codec health with credentials redacted.

### B. Information Synchronized to Your Encrypted Cloud Account (Optional)
When you register an account and enable Cloud Sync:
- **Account Identity**: Email address and generated unique user identifier (`UUID`).
- **Device Registration**: Device model, operating system type, and client instance identifier.
- **Sync Vectors**: Remote playlist URLs, favorite channel IDs, watch history timestamps, and watch progress seconds.
- **User Settings**: App theme preference, language selection, subtitle style parameters, and parental control PIN hash.

---

## 3. What We Strictly Never Upload
- **Zero Local File Uploads**: Your local MP4, MKV, MP3, and JPEG files remain strictly on your local disk or SD storage.
- **Zero Raw Provider Passwords**: Xtream Codes or provider credentials embedded in M3U URLs are stripped or hashed before cloud synchronization.

---

## 4. Telemetry and Logging Standards

- All application loggers execute through `AppLogger`, which automatically redacts access tokens, passwords, and sensitive URL query strings (`token=***`, `password=***`).
- No third-party behavioral analytics or advertising tracking SDKs (such as Facebook Pixel or Google AdMob) are integrated into this application.

---

## 5. Data Retention & Account Deletion

### A. Retention Schedule
- **Active Accounts**: Sync data remains accessible across your registered devices while your account is active.
- **Inactive Devices**: Devices inactive for > 180 days can be revoked in the Device Management dashboard (`/devices`).
- **Audit Logs**: Security and authentication logs are retained for 90 days for breach detection and then purged.

### B. Self-Serve Account Deletion (GDPR / "Right to be Forgotten")
Users can permanently delete their account at any time:
1. Navigate to **Profile** > **Settings** > **Account Security** > **Delete Account**.
2. Re-enter your password to authenticate the request.
3. The server immediately executes a PostgreSQL cascade deletion:
   - Profile, user settings, devices, playlists, channels, favorites, watch progress, and bug reports are permanently removed from the database.
   - Storage assets belonging to the user are pruned.
   - The session token is permanently revoked across all registered devices.

