import 'dart:async';
import 'package:flutter/widgets.dart';

/// Playback lifecycle states
enum PlaybackState {
  idle,
  loading,
  buffering,
  playing,
  paused,
  completed,
  error,
}

/// Aspect ratio display options
enum AspectRatioMode {
  original,
  sixteenByNine,
  fourByThree,
  fill,
  fit,
  stretch,
}

/// Type of media content
enum MediaType {
  liveStream,
  vod,
  audio,
  localVideo,
}

/// Supported subtitle formats
enum SubtitleFormat {
  srt,
  vtt,
  ass,
  embedded,
}

/// Represents a media source for playback
class MediaSource {
  final String uri;
  final String title;
  final String? subtitle;
  final MediaType mediaType;
  final Map<String, String>? httpHeaders;
  final bool isLive;
  final String? localFilePath;
  final List<SubtitleTrack> subtitleTracks;
  final Map<String, dynamic>? metadata;

  const MediaSource({
    required this.uri,
    required this.title,
    this.subtitle,
    this.mediaType = MediaType.vod,
    this.httpHeaders,
    this.isLive = false,
    this.localFilePath,
    this.subtitleTracks = const [],
    this.metadata,
  });

  /// Sanitizes URL by removing sensitive credentials (usernames, passwords, auth tokens)
  String get sanitizedUri {
    return sanitizeMediaUri(uri);
  }

  static String sanitizeMediaUri(String rawUri) {
    if (rawUri.isEmpty) return '';
    try {
      final parsed = Uri.parse(rawUri);
      
      // If user info exists (e.g. http://user:pass@host)
      var clean = parsed;
      if (parsed.userInfo.isNotEmpty) {
        clean = parsed.replace(userInfo: '***:***');
      }

      var result = clean.toString();

      // Redact Xtream Codes style paths: /live/username/password/id or /movie/user/pass/id
      final xtreamRegex = RegExp(r'(/(?:live|movie|series)/)([^/]+)/([^/]+)/([0-9a-zA-Z._]+)');
      result = result.replaceAllMapped(xtreamRegex, (match) {
        return '${match.group(1)}****/****/${match.group(4)}';
      });

      // Redact sensitive query parameters
      final queryRegex = RegExp(r'([?&])(token|key|password|pass|auth|hash|secret|access_token)=([^&]+)', caseSensitive: false);
      result = result.replaceAllMapped(queryRegex, (match) {
        return '${match.group(1)}${match.group(2)}=[REDACTED]';
      });

      return result;
    } catch (_) {
      return '[Invalid URI]';
    }
  }

  MediaSource copyWith({
    String? uri,
    String? title,
    String? subtitle,
    MediaType? mediaType,
    Map<String, String>? httpHeaders,
    bool? isLive,
    String? localFilePath,
    List<SubtitleTrack>? subtitleTracks,
    Map<String, dynamic>? metadata,
  }) {
    return MediaSource(
      uri: uri ?? this.uri,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      mediaType: mediaType ?? this.mediaType,
      httpHeaders: httpHeaders ?? this.httpHeaders,
      isLive: isLive ?? this.isLive,
      localFilePath: localFilePath ?? this.localFilePath,
      subtitleTracks: subtitleTracks ?? this.subtitleTracks,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Represents an audio track stream
class AudioTrack {
  final String id;
  final String title;
  final String? language;
  final int channels;
  final int? sampleRate;
  final String? codec;
  final bool isDefault;
  final bool isSelected;

  const AudioTrack({
    required this.id,
    required this.title,
    this.language,
    this.channels = 2,
    this.sampleRate,
    this.codec,
    this.isDefault = false,
    this.isSelected = false,
  });

  AudioTrack copyWith({bool? isSelected}) {
    return AudioTrack(
      id: id,
      title: title,
      language: language,
      channels: channels,
      sampleRate: sampleRate,
      codec: codec,
      isDefault: isDefault,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// Represents a subtitle track
class SubtitleTrack {
  final String id;
  final String title;
  final String? language;
  final String? sourceUri;
  final SubtitleFormat format;
  final bool isExternal;
  final bool isSelected;

  const SubtitleTrack({
    required this.id,
    required this.title,
    this.language,
    this.sourceUri,
    this.format = SubtitleFormat.embedded,
    this.isExternal = false,
    this.isSelected = false,
  });

  SubtitleTrack copyWith({bool? isSelected}) {
    return SubtitleTrack(
      id: id,
      title: title,
      language: language,
      sourceUri: sourceUri,
      format: format,
      isExternal: isExternal,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// Subtitle styling configuration
class SubtitleStyle {
  final double fontSize;
  final Color textColor;
  final Color backgroundColor;
  final TextAlign textAlignment;
  final double bottomMargin;
  final bool hasOutline;
  final Color outlineColor;

  const SubtitleStyle({
    this.fontSize = 20.0,
    this.textColor = const Color(0xFFFFFFFF),
    this.backgroundColor = const Color(0x99000000),
    this.textAlignment = TextAlign.center,
    this.bottomMargin = 48.0,
    this.hasOutline = true,
    this.outlineColor = const Color(0xFF000000),
  });

  SubtitleStyle copyWith({
    double? fontSize,
    Color? textColor,
    Color? backgroundColor,
    TextAlign? textAlignment,
    double? bottomMargin,
    bool? hasOutline,
    Color? outlineColor,
  }) {
    return SubtitleStyle(
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textAlignment: textAlignment ?? this.textAlignment,
      bottomMargin: bottomMargin ?? this.bottomMargin,
      hasOutline: hasOutline ?? this.hasOutline,
      outlineColor: outlineColor ?? this.outlineColor,
    );
  }
}

/// Playback diagnostics and technical metrics
class PlaybackDiagnostics {
  final String sanitizedSource;
  final String format;
  final String? container;
  final String? videoCodec;
  final String? audioCodec;
  final Size? resolution;
  final double? fps;
  final int? bitrateKbps;
  final int bufferDurationMs;
  final double bufferPercentage;
  final int droppedFrames;
  final bool hardwareAccelerated;
  final String? errorCode;
  final String? recoverySuggestion;

  const PlaybackDiagnostics({
    required this.sanitizedSource,
    required this.format,
    this.container,
    this.videoCodec,
    this.audioCodec,
    this.resolution,
    this.fps,
    this.bitrateKbps,
    this.bufferDurationMs = 0,
    this.bufferPercentage = 0.0,
    this.droppedFrames = 0,
    this.hardwareAccelerated = true,
    this.errorCode,
    this.recoverySuggestion,
  });

  PlaybackDiagnostics copyWith({
    String? sanitizedSource,
    String? format,
    String? container,
    String? videoCodec,
    String? audioCodec,
    Size? resolution,
    double? fps,
    int? bitrateKbps,
    int? bufferDurationMs,
    double? bufferPercentage,
    int? droppedFrames,
    bool? hardwareAccelerated,
    String? errorCode,
    String? recoverySuggestion,
  }) {
    return PlaybackDiagnostics(
      sanitizedSource: sanitizedSource ?? this.sanitizedSource,
      format: format ?? this.format,
      container: container ?? this.container,
      videoCodec: videoCodec ?? this.videoCodec,
      audioCodec: audioCodec ?? this.audioCodec,
      resolution: resolution ?? this.resolution,
      fps: fps ?? this.fps,
      bitrateKbps: bitrateKbps ?? this.bitrateKbps,
      bufferDurationMs: bufferDurationMs ?? this.bufferDurationMs,
      bufferPercentage: bufferPercentage ?? this.bufferPercentage,
      droppedFrames: droppedFrames ?? this.droppedFrames,
      hardwareAccelerated: hardwareAccelerated ?? this.hardwareAccelerated,
      errorCode: errorCode ?? this.errorCode,
      recoverySuggestion: recoverySuggestion ?? this.recoverySuggestion,
    );
  }
}

/// Playback Engine Error representation
class EngineError {
  final String code;
  final String message;
  final bool isRecoverable;
  final String? suggestedAction;
  final dynamic originalError;

  const EngineError({
    required this.code,
    required this.message,
    this.isRecoverable = true,
    this.suggestedAction,
    this.originalError,
  });

  @override
  String toString() => 'EngineError($code: $message, recoverable=$isRecoverable)';
}

/// Core universal player engine interface
abstract class PlayerEngine {
  /// Name and version of this engine adapter
  String get adapterName;

  /// Whether the engine is initialized and ready
  bool get isInitialized;

  /// Current playback state
  PlaybackState get state;

  /// Current playback position
  Duration get position;

  /// Total duration of the media (Duration.zero for live streams)
  Duration get duration;

  /// Current buffered position
  Duration get bufferPosition;

  /// Current playback volume (0.0 to 1.0)
  double get volume;

  /// Current playback speed multiplier (0.25 to 2.0)
  double get speed;

  /// Current aspect ratio mode
  AspectRatioMode get aspectRatio;

  /// Current technical diagnostics
  PlaybackDiagnostics get diagnostics;

  /// Available audio tracks
  List<AudioTrack> get audioTracks;

  /// Currently selected audio track
  AudioTrack? get selectedAudioTrack;

  /// Available subtitle tracks
  List<SubtitleTrack> get subtitleTracks;

  /// Currently selected subtitle track
  SubtitleTrack? get selectedSubtitleTrack;

  /// Subtitle sync delay in milliseconds
  int get subtitleDelayMs;

  /// Subtitle styling parameters
  SubtitleStyle get subtitleStyle;

  // Streams for reactive architecture
  Stream<PlaybackState> get stateStream;
  Stream<Duration> get positionStream;
  Stream<Duration> get durationStream;
  Stream<Duration> get bufferPositionStream;
  Stream<PlaybackDiagnostics> get diagnosticsStream;
  Stream<List<AudioTrack>> get audioTracksStream;
  Stream<List<SubtitleTrack>> get subtitleTracksStream;
  Stream<EngineError?> get errorStream;

  /// Initialize engine resources and platform channels
  Future<void> initialize();

  /// Open media source and prepare for playback
  Future<void> open(MediaSource source, {bool autoPlay = true, Duration? startPosition});

  /// Start or resume playback
  Future<void> play();

  /// Pause playback
  Future<void> pause();

  /// Stop playback and release media session
  Future<void> stop();

  /// Seek to target position
  Future<void> seek(Duration position);

  /// Set volume (clamped between 0.0 and 1.0)
  Future<void> setVolume(double volume);

  /// Set playback speed (clamped between 0.25 and 2.0)
  Future<void> setSpeed(double speed);

  /// Change video aspect ratio mode
  Future<void> setAspectRatio(AspectRatioMode mode);

  /// Select active audio track
  Future<void> setAudioTrack(AudioTrack track);

  /// Select or disable subtitle track (pass null to turn off)
  Future<void> setSubtitleTrack(SubtitleTrack? track);

  /// Adjust subtitle delay in milliseconds (+ advances, - delays)
  Future<void> setSubtitleDelay(int delayMs);

  /// Set subtitle visual style
  Future<void> setSubtitleStyle(SubtitleStyle style);

  /// Set playlist or track looping
  Future<void> setLooping(bool loop);

  /// Build the native or rendered video surface widget
  Widget buildVideoSurface(BuildContext context);

  /// Dispose engine resources
  Future<void> dispose();
}

