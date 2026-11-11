/// Constants for all analytics event names and parameter keys.
///
/// Centralising event strings prevents typos, makes grep-ability trivial,
/// and keeps the analytics surface area discoverable.
abstract final class AnalyticsEvents {
  // ---------------------------------------------------------------------------
  // App lifecycle
  // ---------------------------------------------------------------------------

  /// Fired when the application finishes cold-start initialisation.
  static const String appOpen = 'app_open';

  /// Fired when the app moves to the background.
  static const String appBackground = 'app_background';

  /// Fired when the app returns to the foreground.
  static const String appForeground = 'app_foreground';

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  /// User completed sign-up.
  static const String signUp = 'sign_up';

  /// User signed in (any method).
  static const String signIn = 'sign_in';

  /// User signed out.
  static const String signOut = 'sign_out';

  /// User initiated password reset.
  static const String passwordReset = 'password_reset';

  // ---------------------------------------------------------------------------
  // Playback
  // ---------------------------------------------------------------------------

  /// Playback started for a channel / VOD / series episode.
  static const String playbackStart = 'playback_start';

  /// Playback paused.
  static const String playbackPause = 'playback_pause';

  /// Playback resumed after a pause.
  static const String playbackResume = 'playback_resume';

  /// Playback stopped (user navigated away or stream ended).
  static const String playbackStop = 'playback_stop';

  /// A playback error occurred (buffering timeout, codec failure, etc.).
  static const String playbackError = 'playback_error';

  /// User changed the playback quality / resolution.
  static const String playbackQualityChange = 'playback_quality_change';

  /// Buffering event (tracks how long the user waited).
  static const String playbackBuffer = 'playback_buffer';

  // ---------------------------------------------------------------------------
  // Content browsing
  // ---------------------------------------------------------------------------

  /// User viewed a screen / page.
  static const String screenView = 'screen_view';

  /// User performed a search.
  static const String search = 'search';

  /// User opened a category filter.
  static const String categoryView = 'category_view';

  /// User opened channel details.
  static const String channelView = 'channel_view';

  // ---------------------------------------------------------------------------
  // Favorites & History
  // ---------------------------------------------------------------------------

  /// User added a channel to favorites.
  static const String favoriteAdd = 'favorite_add';

  /// User removed a channel from favorites.
  static const String favoriteRemove = 'favorite_remove';

  /// User cleared watch history.
  static const String historyClear = 'history_clear';

  // ---------------------------------------------------------------------------
  // Playlist management
  // ---------------------------------------------------------------------------

  /// User added a new playlist (M3U / Xtream).
  static const String playlistAdd = 'playlist_add';

  /// User removed a playlist.
  static const String playlistRemove = 'playlist_remove';

  /// User refreshed / re-parsed a playlist.
  static const String playlistRefresh = 'playlist_refresh';

  // ---------------------------------------------------------------------------
  // Downloads
  // ---------------------------------------------------------------------------

  /// User initiated a download.
  static const String downloadStart = 'download_start';

  /// Download completed successfully.
  static const String downloadComplete = 'download_complete';

  /// Download failed.
  static const String downloadError = 'download_error';

  /// User cancelled an in-progress download.
  static const String downloadCancel = 'download_cancel';

  // ---------------------------------------------------------------------------
  // Sync & Cloud
  // ---------------------------------------------------------------------------

  /// Cloud sync started.
  static const String syncStart = 'sync_start';

  /// Cloud sync completed.
  static const String syncComplete = 'sync_complete';

  /// Cloud sync encountered an error.
  static const String syncError = 'sync_error';

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  /// User changed a setting value.
  static const String settingChange = 'setting_change';

  /// User changed the application theme.
  static const String themeChange = 'theme_change';

  /// User changed the application language.
  static const String languageChange = 'language_change';

  // ---------------------------------------------------------------------------
  // Errors
  // ---------------------------------------------------------------------------

  /// A non-fatal application error was captured.
  static const String appError = 'app_error';

  /// A fatal crash was captured.
  static const String appCrash = 'app_crash';
}

/// Common parameter keys shared across multiple events.
abstract final class AnalyticsParams {
  /// The authentication method used (email, google, apple).
  static const String method = 'method';

  /// An identifier for the content being interacted with.
  static const String contentId = 'content_id';

  /// The type of content (live, vod, series, radio).
  static const String contentType = 'content_type';

  /// Human-readable name of the content.
  static const String contentName = 'content_name';

  /// Name of the screen / page.
  static const String screenName = 'screen_name';

  /// Category or group name.
  static const String category = 'category';

  /// Duration in seconds (playback, buffering, etc.).
  static const String durationSeconds = 'duration_seconds';

  /// Playback quality label (e.g. "720p", "1080p").
  static const String quality = 'quality';

  /// Search query string.
  static const String searchQuery = 'search_query';

  /// Number of search results returned.
  static const String searchResults = 'search_results';

  /// Playlist identifier.
  static const String playlistId = 'playlist_id';

  /// Playlist type (m3u, xtream).
  static const String playlistType = 'playlist_type';

  /// Error message string.
  static const String errorMessage = 'error_message';

  /// Error code (HTTP status, player error code, etc.).
  static const String errorCode = 'error_code';

  /// The setting key that was changed.
  static const String settingKey = 'setting_key';

  /// The new value of the setting.
  static const String settingValue = 'setting_value';

  /// Boolean indicating success or failure.
  static const String success = 'success';

  /// Platform identifier (android, ios, web, windows, macos, linux).
  static const String platform = 'platform';

  /// File size in bytes.
  static const String fileSize = 'file_size';
}
