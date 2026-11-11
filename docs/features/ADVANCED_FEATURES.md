# Saiful IPTV Player: Advanced Features & Cloud Integration Specification

## 1. Overview and Architecture

This document specifies the advanced feature suite and cloud synchronization framework connecting playback sessions across user devices.

Source code implementation:
- Service: [`lib/services/advanced/advanced_features_service.dart`](file:///d:/Saiful%20iptv%20player/lib/services/advanced/advanced_features_service.dart)
- Cloud Sync Engine: [`lib/services/sync/local_sync_store.dart`](file:///d:/Saiful%20iptv%20player/lib/services/sync/local_sync_store.dart)
- Secure Vault: [`lib/core/security/secure_credential_vault.dart`](file:///d:/Saiful%20iptv%20player/lib/core/security/secure_credential_vault.dart)

---

## 2. Advanced Feature Matrix

| Feature | Target Platforms | Implementation Mechanism | Support Status |
| :--- | :--- | :--- | :--- |
| **Chromecast** | Android, Chrome/Web, iOS | Google Cast v3 Protocol / CAF Receiver | **Supported** |
| **DLNA / UPnP** | Android, Windows, Smart TVs | UPnP AV Transport & Rendering Control | **Supported** |
| **Picture-in-Picture (PiP)** | Android, iOS, Windows, macOS | Native Platform PiP Window Bridge | **Supported** |
| **Background Audio** | Android, iOS, Desktop | Native MediaSession & Foreground Service | **Supported** |
| **Sleep Timer** | All Platforms | Countdown ticker with auto-pause hook | **Supported** |
| **Parental Controls** | All Platforms | 4-digit PIN gate + Age Rating Hierarchy | **Supported** |
| **App Lock** | Mobile, Desktop, TV | Master PIN / Biometric verification | **Supported** |
| **Unified Search** | All Platforms | Indexed search across Channels, VOD, and EPG | **Supported** |
| **Cloud Sync** | All Platforms | Supabase Postgres + SyncOutbox + Conflict Resolution | **Supported** |
| **In-App Notifications**| All Platforms | Notification event queue and reminders | **Supported** |

---

## 3. Parental Controls & Content Filtering

### 3.1 Age Rating Hierarchy
The system strictly enforces age restrictions according to the standardized hierarchy:
$$\text{G} \le \text{PG} \le \text{PG-13} \le \text{R} \le \text{NC-17}$$

When Parental Control is active:
- Any movie, series, or channel rated above the user-configured ceiling (e.g. `PG-13`) requires PIN entry.
- Default master PIN is set upon initial activation and protected against brute-force lockouts.

---

## 4. Cloud Integration & Conflict Resolution

### 4.1 Synchronized Data Domains
1. **Favorites**: Live TV channel bookmarks and VOD favorites.
2. **Watch History**: Chronological log of accessed streams and movies.
3. **Watch Progress**: Second-accurate resume markers for VOD titles.
4. **Settings & Preferences**: Theme, player aspect ratio, audio track preferences.

### 4.2 Conflict Resolution Strategy
When multiple devices update the same record (e.g., watching a movie on Android TV and mobile phone):
1. Records maintain an immutable UTC `updated_at` timestamp.
2. **Latest Timestamp Wins**: The client compares timestamps; the record with the most recent timestamp prevails.
3. Outbox events are idempotent and replay-safe.

