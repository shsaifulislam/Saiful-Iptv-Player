import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Platform-specific configuration and capability declarations.
///
/// Each [PlatformType] can declare which features it supports,
/// e.g. whether downloads or multi-view are available.
enum PlatformType {
  android,
  ios,
  windows,
  macOS,
  linux,
  web,
  androidTV,
  tizen,
  webOS,
}

/// Resolves the current platform and exposes its capabilities.
class PlatformConfig {
  PlatformConfig._();

  static final PlatformConfig _instance = PlatformConfig._();
  static PlatformConfig get instance => _instance;

  /// Manually overridden platform for testing.
  PlatformType? _overridePlatform;

  /// The resolved [PlatformType] for the current device.
  PlatformType get currentPlatform {
    if (_overridePlatform != null) return _overridePlatform!;
    return _detectPlatform();
  }

  /// Override the detected platform (useful for testing).
  void overridePlatform(PlatformType type) {
    _overridePlatform = type;
  }

  /// Clear platform override.
  void clearOverride() {
    _overridePlatform = null;
  }

  // ── Detection ────────────────────────────────────────────────
  static PlatformType _detectPlatform() {
    if (kIsWeb) return PlatformType.web;
    if (Platform.isAndroid) return PlatformType.android;
    if (Platform.isIOS) return PlatformType.ios;
    if (Platform.isWindows) return PlatformType.windows;
    if (Platform.isMacOS) return PlatformType.macOS;
    if (Platform.isLinux) return PlatformType.linux;
    return PlatformType.android; // fallback
  }

  // ── Convenience booleans ─────────────────────────────────────
  bool get isMobile =>
      currentPlatform == PlatformType.android ||
      currentPlatform == PlatformType.ios;

  bool get isDesktop =>
      currentPlatform == PlatformType.windows ||
      currentPlatform == PlatformType.macOS ||
      currentPlatform == PlatformType.linux;

  bool get isTV =>
      currentPlatform == PlatformType.androidTV ||
      currentPlatform == PlatformType.tizen ||
      currentPlatform == PlatformType.webOS;

  bool get isWeb => currentPlatform == PlatformType.web;

  // ── Feature Support ──────────────────────────────────────────
  static const Map<PlatformType, Set<String>> _supportedFeatures = {
    PlatformType.android: {
      'downloads',
      'local_media',
      'picture_in_picture',
      'chromecast',
      'multi_view',
      'notifications',
      'background_playback',
      'subtitles',
    },
    PlatformType.ios: {
      'downloads',
      'local_media',
      'picture_in_picture',
      'chromecast',
      'notifications',
      'subtitles',
    },
    PlatformType.windows: {
      'downloads',
      'local_media',
      'multi_view',
      'subtitles',
    },
    PlatformType.macOS: {
      'downloads',
      'local_media',
      'multi_view',
      'picture_in_picture',
      'subtitles',
    },
    PlatformType.linux: {
      'downloads',
      'local_media',
      'multi_view',
      'subtitles',
    },
    PlatformType.web: {
      'chromecast',
      'subtitles',
    },
    PlatformType.androidTV: {
      'tv_mode',
      'subtitles',
    },
    PlatformType.tizen: {
      'tv_mode',
      'subtitles',
    },
    PlatformType.webOS: {
      'tv_mode',
      'subtitles',
    },
  };

  /// Whether the current platform supports a given feature key.
  bool supportsFeature(String feature) {
    return _supportedFeatures[currentPlatform]?.contains(feature) ?? false;
  }

  /// All feature keys supported on the current platform.
  Set<String> get supportedFeatures =>
      _supportedFeatures[currentPlatform] ?? {};
}
