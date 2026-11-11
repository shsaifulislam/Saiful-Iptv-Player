import 'package:flutter/material.dart';
import 'app_text_styles.dart';

/// Application typography definitions with Bengali and multi-script fallback support.
abstract final class AppTypography {
  static const List<String> fontFallbacks = [
    'Hind Siliguri',
    'Noto Sans Bengali',
    'Aptos',
    'Segoe UI',
    'Roboto',
    'sans-serif',
  ];

  static const TextStyle displayLarge = AppTextStyles.displayLarge;
  static const TextStyle displayMedium = AppTextStyles.displayMedium;
  static const TextStyle displaySmall = AppTextStyles.displaySmall;

  static const TextStyle headlineLarge = AppTextStyles.headlineLarge;
  static const TextStyle headlineMedium = AppTextStyles.headlineMedium;
  static const TextStyle headlineSmall = AppTextStyles.headlineSmall;

  static const TextStyle titleLarge = AppTextStyles.titleLarge;
  static const TextStyle titleMedium = AppTextStyles.titleMedium;
  static const TextStyle titleSmall = AppTextStyles.titleSmall;

  static const TextStyle bodyLarge = AppTextStyles.bodyLarge;
  static const TextStyle bodyMedium = AppTextStyles.bodyMedium;
  static const TextStyle bodySmall = AppTextStyles.bodySmall;

  static const TextStyle labelLarge = AppTextStyles.labelLarge;
  static const TextStyle labelMedium = AppTextStyles.labelMedium;
  static const TextStyle labelSmall = AppTextStyles.labelSmall;
}

