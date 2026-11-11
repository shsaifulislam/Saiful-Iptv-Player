/// Spacing, padding, radius, icon sizes, and card dimensions.
///
/// Centralises all "magic numbers" so the UI stays consistent
/// and changes propagate everywhere at once.
abstract final class AppDimensions {
  // ── Spacing ────────────────────────────────────────────────────
  static const double spacingXxs = 2;
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 24;
  static const double spacingXxl = 32;
  static const double spacingXxxl = 48;

  // ── Padding ────────────────────────────────────────────────────
  static const double paddingXs = 4;
  static const double paddingSm = 8;
  static const double paddingMd = 12;
  static const double paddingLg = 16;
  static const double paddingXl = 24;
  static const double paddingXxl = 32;

  /// Default screen-level horizontal padding.
  static const double screenPaddingH = 16;

  /// Default screen-level vertical padding.
  static const double screenPaddingV = 16;

  // ── Border Radius ──────────────────────────────────────────────
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusRound = 999;

  // ── Icon Sizes ─────────────────────────────────────────────────
  static const double iconXs = 12;
  static const double iconSm = 16;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 48;
  static const double iconXxl = 64;

  // ── Card Dimensions ────────────────────────────────────────────
  static const double channelCardWidth = 160;
  static const double channelCardHeight = 120;
  static const double movieCardWidth = 140;
  static const double movieCardHeight = 210;
  static const double categoryCardHeight = 80;
  static const double epgRowHeight = 60;
  static const double playlistCardHeight = 72;

  // ── Navigation ─────────────────────────────────────────────────
  static const double bottomNavHeight = 64;
  static const double sideNavWidth = 72;
  static const double sideNavExpandedWidth = 256;
  static const double appBarHeight = 56;
  static const double tabBarHeight = 48;

  // ── Player ─────────────────────────────────────────────────────
  static const double playerControlSize = 48;
  static const double playerProgressHeight = 4;
  static const double playerProgressActiveHeight = 6;
  static const double playerMiniHeight = 72;
  static const double playerOverlayOpacity = 0.6;

  // ── TV-specific ────────────────────────────────────────────────
  static const double tvFocusBorderWidth = 3;
  static const double tvCardScale = 1.05;
  static const double tvIconSize = 36;
  static const double tvFontScaleFactor = 1.25;

  // ── Misc ───────────────────────────────────────────────────────
  static const double avatarSm = 32;
  static const double avatarMd = 48;
  static const double avatarLg = 72;
  static const double thumbnailAspectRatio = 16 / 9;
  static const double posterAspectRatio = 2 / 3;
  static const double shimmerBaseOpacity = 0.3;
  static const double shimmerHighlightOpacity = 0.6;
}
