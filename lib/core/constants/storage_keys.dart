/// Local storage key constants for Hive boxes and secure storage.
///
/// Centralises all key names so they are easy to find and refactor.
library;

/// Hive box names and secure-storage keys used throughout the app.
abstract final class StorageKeys {
  // ── Hive Box Names ──────────────────────────────────────────────────

  /// Box for user settings and preferences.
  static const String settingsBox = 'settings_box';

  /// Box for cached playlists.
  static const String playlistsBox = 'playlists_box';

  /// Box for cached channels.
  static const String channelsBox = 'channels_box';

  /// Box for favorite channels.
  static const String favoritesBox = 'favorites_box';

  /// Box for recently watched channels.
  static const String recentBox = 'recent_box';

  /// Box for EPG (Electronic Program Guide) data.
  static const String epgBox = 'epg_box';

  /// Box for cached channel logos / images.
  static const String imagesCacheBox = 'images_cache_box';

  /// Box for search history.
  static const String searchHistoryBox = 'search_history_box';

  /// Box for app metadata (migrations, first-run flags, etc.).
  static const String metadataBox = 'metadata_box';

  /// Box for offline queue (pending sync operations).
  static const String syncQueueBox = 'sync_queue_box';

  // ── Settings Keys ───────────────────────────────────────────────────

  /// Current theme mode (light / dark / system).
  static const String themeMode = 'theme_mode';

  /// Selected language / locale code.
  static const String locale = 'locale';

  /// Preferred video player aspect ratio.
  static const String aspectRatio = 'aspect_ratio';

  /// Default volume level.
  static const String volume = 'volume';

  /// Whether hardware decoding is enabled.
  static const String hardwareDecoding = 'hardware_decoding';

  /// Buffer size in MB.
  static const String bufferSize = 'buffer_size';

  /// Whether to auto-play the last channel on launch.
  static const String autoPlayOnLaunch = 'auto_play_on_launch';

  /// Whether to auto-update playlists on launch.
  static const String autoUpdatePlaylist = 'auto_update_playlist';

  /// EPG auto-refresh toggle.
  static const String epgAutoRefresh = 'epg_auto_refresh';

  /// Parental control enabled flag.
  static const String parentalControlEnabled = 'parental_control_enabled';

  /// Last synced timestamp (ISO-8601).
  static const String lastSyncTimestamp = 'last_sync_timestamp';

  // ── Secure Storage Keys ─────────────────────────────────────────────

  /// Encrypted access token.
  static const String accessToken = 'access_token';

  /// Encrypted refresh token.
  static const String refreshToken = 'refresh_token';

  /// Encrypted user password (for Supabase re-auth).
  static const String userPassword = 'user_password';

  /// Parental control PIN.
  static const String parentalPin = 'parental_pin';

  /// Encryption key for local data.
  static const String encryptionKey = 'encryption_key';

  /// Supabase session JSON blob.
  static const String supabaseSession = 'supabase_session';

  // ── Metadata Keys ──────────────────────────────────────────────────

  /// Current schema version for migration tracking.
  static const String schemaVersion = 'schema_version';

  /// Whether onboarding has been completed.
  static const String onboardingComplete = 'onboarding_complete';

  /// First launch timestamp.
  static const String firstLaunchDate = 'first_launch_date';

  /// Total app launch count.
  static const String launchCount = 'launch_count';
}
