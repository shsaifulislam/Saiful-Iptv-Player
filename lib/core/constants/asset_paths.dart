/// Centralised asset path constants.
///
/// All references to images, icons, fonts, and animations should go
/// through this class so paths are easy to update and refactor.
library;

/// Asset path constants for images, icons, fonts, and animations.
abstract final class AssetPaths {
  // ── Root Directories ────────────────────────────────────────────────

  static const String _images = 'assets/images';
  static const String _icons = 'assets/icons';
  static const String _fonts = 'assets/fonts';
  static const String _animations = 'assets/animations';

  // ── Images ──────────────────────────────────────────────────────────

  /// Application logo (full).
  static const String logo = '$_images/logo.png';

  /// Application logo (compact / icon variant).
  static const String logoIcon = '$_images/logo_icon.png';

  /// Splash / launch screen background.
  static const String splashBackground = '$_images/splash_bg.png';

  /// Default channel thumbnail / placeholder.
  static const String channelPlaceholder = '$_images/channel_placeholder.png';

  /// Default category placeholder.
  static const String categoryPlaceholder = '$_images/category_placeholder.png';

  /// Onboarding illustration – step 1.
  static const String onboarding1 = '$_images/onboarding_1.png';

  /// Onboarding illustration – step 2.
  static const String onboarding2 = '$_images/onboarding_2.png';

  /// Onboarding illustration – step 3.
  static const String onboarding3 = '$_images/onboarding_3.png';

  /// Empty state illustration.
  static const String emptyState = '$_images/empty_state.png';

  /// Error state illustration.
  static const String errorState = '$_images/error_state.png';

  /// No network illustration.
  static const String noNetwork = '$_images/no_network.png';

  // ── Icons ───────────────────────────────────────────────────────────

  /// Play icon.
  static const String playIcon = '$_icons/play.svg';

  /// Pause icon.
  static const String pauseIcon = '$_icons/pause.svg';

  /// Stop icon.
  static const String stopIcon = '$_icons/stop.svg';

  /// Fullscreen icon.
  static const String fullscreenIcon = '$_icons/fullscreen.svg';

  /// Favorite (heart) icon.
  static const String favoriteIcon = '$_icons/favorite.svg';

  /// Settings icon.
  static const String settingsIcon = '$_icons/settings.svg';

  /// Search icon.
  static const String searchIcon = '$_icons/search.svg';

  /// EPG / TV guide icon.
  static const String epgIcon = '$_icons/epg.svg';

  /// Playlist icon.
  static const String playlistIcon = '$_icons/playlist.svg';

  // ── Fonts ───────────────────────────────────────────────────────────

  /// Primary font family name.
  static const String primaryFontFamily = 'Poppins';

  /// Path to the primary font directory.
  static const String primaryFontDir = '$_fonts/Poppins';

  // ── Animations ──────────────────────────────────────────────────────

  /// Loading / buffering Lottie animation.
  static const String loadingAnimation = '$_animations/loading.json';

  /// Success check animation.
  static const String successAnimation = '$_animations/success.json';

  /// Error animation.
  static const String errorAnimation = '$_animations/error.json';

  /// Empty state animation.
  static const String emptyAnimation = '$_animations/empty.json';

  /// No internet animation.
  static const String noInternetAnimation = '$_animations/no_internet.json';
}
