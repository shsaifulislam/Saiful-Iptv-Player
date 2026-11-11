/// Application-wide constant values.
///
/// Contains app identity, default configuration values,
/// and supported media formats for the IPTV player.
library;

/// Core application constants.
abstract final class AppConstants {
  /// Application display name.
  static const String appName = 'Saiful IPTV Player';

  /// Current application version string.
  static const String appVersion = '1.0.0';

  /// Current application build number.
  static const int appBuildNumber = 1;

  /// Package / bundle identifier.
  static const String packageName = 'com.saiful.iptv_player';

  // ── Default Values ──────────────────────────────────────────────────

  /// Default number of channels shown per page.
  static const int defaultPageSize = 50;

  /// Default search debounce duration in milliseconds.
  static const int defaultDebounceDurationMs = 400;

  /// Maximum number of recently watched channels to remember.
  static const int maxRecentChannels = 50;

  /// Maximum number of favorite channels allowed.
  static const int maxFavorites = 500;

  /// Default volume level (0.0 – 1.0).
  static const double defaultVolume = 0.8;

  /// Default aspect ratio for the video player.
  static const String defaultAspectRatio = '16:9';

  /// Auto-hide controls timeout in seconds.
  static const int controlsAutoHideSeconds = 5;

  /// EPG refresh interval in minutes.
  static const int epgRefreshIntervalMinutes = 60;

  /// Playlist auto-update interval in hours.
  static const int playlistAutoUpdateHours = 24;

  // ── Supported Formats ───────────────────────────────────────────────

  /// Supported playlist file extensions.
  static const List<String> supportedPlaylistFormats = [
    '.m3u',
    '.m3u8',
    '.xspf',
    '.pls',
  ];

  /// Supported video stream protocols.
  static const List<String> supportedStreamProtocols = [
    'http',
    'https',
    'rtsp',
    'rtmp',
    'mms',
    'udp',
    'rtp',
  ];

  /// Supported video container formats.
  static const List<String> supportedVideoFormats = [
    'mp4',
    'mkv',
    'avi',
    'ts',
    'flv',
    'webm',
    'm3u8',
    'mpd',
  ];

  /// Supported audio formats for radio streams.
  static const List<String> supportedAudioFormats = [
    'mp3',
    'aac',
    'ogg',
    'flac',
    'wav',
    'wma',
  ];

  /// Supported EPG file formats.
  static const List<String> supportedEpgFormats = [
    '.xml',
    '.xml.gz',
    '.xmltv',
  ];

  /// Supported image formats for channel logos.
  static const List<String> supportedImageFormats = [
    'png',
    'jpg',
    'jpeg',
    'webp',
    'svg',
    'gif',
  ];
}
