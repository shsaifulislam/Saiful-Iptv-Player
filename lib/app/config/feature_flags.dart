/// Feature-flag system for toggling capabilities at runtime.
///
/// Flags can be overridden programmatically for A/B testing,
/// gradual rollouts, or per-platform disabling.
class FeatureFlags {
  FeatureFlags._();

  static final FeatureFlags _instance = FeatureFlags._();

  /// Singleton access.
  static FeatureFlags get instance => _instance;

  // ── Backing store ────────────────────────────────────────────
  final Map<String, bool> _overrides = {};

  // ── Flag keys ────────────────────────────────────────────────
  static const String kMultiView = 'multi_view';
  static const String kYouTube = 'youtube';
  static const String kCloudSync = 'cloud_sync';
  static const String kDownloads = 'downloads';
  static const String kEpg = 'epg';
  static const String kLocalMedia = 'local_media';
  static const String kMusic = 'music';
  static const String kPhotos = 'photos';
  static const String kChromecast = 'chromecast';
  static const String kPictureInPicture = 'picture_in_picture';
  static const String kParentalControls = 'parental_controls';
  static const String kRecording = 'recording';
  static const String kSubtitles = 'subtitles';
  static const String kTvMode = 'tv_mode';

  // ── Default values ───────────────────────────────────────────
  static const Map<String, bool> _defaults = {
    kMultiView: true,
    kYouTube: true,
    kCloudSync: true,
    kDownloads: true,
    kEpg: true,
    kLocalMedia: true,
    kMusic: true,
    kPhotos: true,
    kChromecast: false,
    kPictureInPicture: true,
    kParentalControls: false,
    kRecording: false,
    kSubtitles: true,
    kTvMode: true,
  };

  /// Whether the given [flag] is enabled.
  bool isEnabled(String flag) {
    return _overrides[flag] ?? _defaults[flag] ?? false;
  }

  /// Convenience getters ──────────────────────────────────────────
  bool get multiView => isEnabled(kMultiView);
  bool get youtube => isEnabled(kYouTube);
  bool get cloudSync => isEnabled(kCloudSync);
  bool get downloads => isEnabled(kDownloads);
  bool get epg => isEnabled(kEpg);
  bool get localMedia => isEnabled(kLocalMedia);
  bool get music => isEnabled(kMusic);
  bool get photos => isEnabled(kPhotos);
  bool get chromecast => isEnabled(kChromecast);
  bool get pictureInPicture => isEnabled(kPictureInPicture);
  bool get parentalControls => isEnabled(kParentalControls);
  bool get recording => isEnabled(kRecording);
  bool get subtitles => isEnabled(kSubtitles);
  bool get tvMode => isEnabled(kTvMode);

  /// Override a single flag.
  void setOverride(String flag, bool value) {
    _overrides[flag] = value;
  }

  /// Bulk-override flags from a map (e.g., remote config).
  void applyOverrides(Map<String, bool> overrides) {
    _overrides.addAll(overrides);
  }

  /// Clear all overrides, reverting to defaults.
  void clearOverrides() {
    _overrides.clear();
  }
}
