import 'package:flutter/material.dart';

/// Application color palette.
///
/// A crisp mineral palette with vermilion actions and botanical accents.
abstract final class AppColors {
  // ── Primary ────────────────────────────────────────────────────
  static const Color primary = Color(0xFFD94A3D);
  static const Color primaryLight = Color(0xFFFF7665);
  static const Color primaryDark = Color(0xFFA72C26);
  static const Color onPrimary = Colors.white;

  // ── Secondary ──────────────────────────────────────────────────
  static const Color secondary = Color(0xFF287B61);
  static const Color secondaryLight = Color(0xFF64B895);
  static const Color secondaryDark = Color(0xFF15533F);
  static const Color onSecondary = Colors.white;

  // ── Tertiary ───────────────────────────────────────────────────
  static const Color tertiary = Color(0xFFE4A43A);
  static const Color onTertiary = Color(0xFF241A09);

  // ── Surface / Background (Light) ───────────────────────────────
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFE9EFEC);
  static const Color backgroundLight = Color(0xFFF3F6F4);
  static const Color onSurfaceLight = Color(0xFF17211E);
  static const Color onSurfaceVariantLight = Color(0xFF59645F);

  // ── Surface / Background (Dark) ────────────────────────────────
  static const Color surfaceDark = Color(0xFF202824);
  static const Color surfaceVariantDark = Color(0xFF303A35);
  static const Color backgroundDark = Color(0xFF151B18);
  static const Color onSurfaceDark = Color(0xFFE5EEE9);
  static const Color onSurfaceVariantDark = Color(0xFFB7C4BD);

  // ── Error ──────────────────────────────────────────────────────
  static const Color error = Color(0xFFB3261E);
  static const Color errorLight = Color(0xFFFFB4AB);
  static const Color onError = Colors.white;

  // ── Divider / Outline ──────────────────────────────────────────
  static const Color outlineLight = Color(0xFF78837D);
  static const Color outlineDark = Color(0xFF8A9890);
  static const Color dividerLight = Color(0xFFDCE4DF);
  static const Color dividerDark = Color(0xFF3B4841);

  // ── Status ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF287B61);
  static const Color warning = Color(0xFFD88B16);
  static const Color info = Color(0xFF3C7392);

  // ── Card Gradients ─────────────────────────────────────────────
  static const List<Color> cardGradientPurple = [
    Color(0xFFD94A3D),
    Color(0xFFFF7665),
  ];

  static const List<Color> cardGradientCyan = [
    Color(0xFF287B61),
    Color(0xFF64B895),
  ];

  static const List<Color> cardGradientDark = [
    Color(0xFF303A35),
    Color(0xFF202824),
  ];

  static const List<Color> cardGradientLive = [
    Color(0xFFE91E63),
    Color(0xFFFF5252),
  ];

  static const List<Color> cardGradientGold = [
    Color(0xFFFF8F00),
    Color(0xFFFFC107),
  ];

  // ── Player Overlay ─────────────────────────────────────────────
  static const Color playerOverlay = Color(0x99000000);
  static const Color playerProgressPlayed = secondary;
  static const Color playerProgressBuffered = Color(0x80FFFFFF);
  static const Color playerProgressBackground = Color(0x33FFFFFF);

  // ── TV Focus ───────────────────────────────────────────────────
  static const Color tvFocusBorder = secondary;
  static const Color tvFocusGlow = Color(0x4400BCD4);
}
