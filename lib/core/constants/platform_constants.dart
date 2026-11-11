/// Platform-specific constants for TV and embedded targets.
///
/// Provides default settings that differ by target platform
/// (Tizen, WebOS, Android TV, Fire TV, Apple TV, desktop, mobile).
library;

/// Platform-specific configuration values.
abstract final class PlatformConstants {
  // ── Platform Identifiers ────────────────────────────────────────────

  /// Tizen (Samsung Smart TV) identifier.
  static const String tizen = 'tizen';

  /// WebOS (LG Smart TV) identifier.
  static const String webOS = 'webos';

  /// Android TV identifier.
  static const String androidTV = 'android_tv';

  /// Amazon Fire TV identifier.
  static const String fireTV = 'fire_tv';

  /// Apple TV (tvOS) identifier.
  static const String appleTV = 'apple_tv';

  /// Generic desktop identifier.
  static const String desktop = 'desktop';

  /// Generic mobile identifier.
  static const String mobile = 'mobile';

  /// Web browser identifier.
  static const String web = 'web';

  // ── TV UI Defaults ──────────────────────────────────────────────────

  /// Default grid column count on TV.
  static const int tvGridColumns = 5;

  /// Default grid column count on tablets.
  static const int tabletGridColumns = 4;

  /// Default grid column count on mobile.
  static const int mobileGridColumns = 2;

  /// Minimum focusable element size (dp) for D-pad navigation.
  static const double tvMinFocusSize = 48.0;

  /// Overscan safe area padding (dp) for TVs.
  static const double tvOverscanPadding = 27.0;

  /// Font scale factor for TV (10-foot UI).
  static const double tvFontScale = 1.3;

  /// Font scale factor for desktop.
  static const double desktopFontScale = 1.0;

  /// Font scale factor for mobile.
  static const double mobileFontScale = 1.0;

  // ── Key Codes ───────────────────────────────────────────────────────

  /// Common TV remote key codes (Android / web key values).
  static const int keyCodeDpadUp = 19;
  static const int keyCodeDpadDown = 20;
  static const int keyCodeDpadLeft = 21;
  static const int keyCodeDpadRight = 22;
  static const int keyCodeDpadCenter = 23;
  static const int keyCodeBack = 4;
  static const int keyCodeMenu = 82;
  static const int keyCodeMediaPlay = 126;
  static const int keyCodeMediaPause = 127;
  static const int keyCodeMediaStop = 86;
  static const int keyCodeMediaNext = 87;
  static const int keyCodeMediaPrevious = 88;
  static const int keyCodeVolumeUp = 24;
  static const int keyCodeVolumeDown = 25;
  static const int keyCodeChannelUp = 166;
  static const int keyCodeChannelDown = 167;

  // ── Buffering & Playback ────────────────────────────────────────────

  /// Default buffer duration for TV in milliseconds.
  static const int tvBufferDurationMs = 5000;

  /// Default buffer duration for mobile in milliseconds.
  static const int mobileBufferDurationMs = 3000;

  /// Default buffer duration for desktop in milliseconds.
  static const int desktopBufferDurationMs = 4000;

  /// Max video resolution for mobile to save bandwidth.
  static const String mobileMaxResolution = '1080p';

  /// Max video resolution for TV.
  static const String tvMaxResolution = '4K';
}
