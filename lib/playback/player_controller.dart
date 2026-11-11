import 'dart:async';
import 'package:flutter/material.dart';

import 'player_engine.dart';
import 'player_adapter_factory.dart';
import 'subtitles/subtitle_parser.dart';

/// Controller coordinating the PlayerEngine with gestures, sleep timer,
/// A-B repeat, subtitle rendering, and keyboard/TV shortcuts
class PlayerController extends ChangeNotifier {
  final PlayerEngine engine;

  // Subtitle state
  List<SubtitleCue> _parsedSubtitles = [];
  String _currentSubtitleText = '';
  int _subtitleDelayMs = 0;

  // Gestures & controls lock
  bool _isControlsLocked = false;
  double _brightness = 0.8; // 0.0 to 1.0
  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;
  Timer? _indicatorHideTimer;

  // Sleep Timer
  Timer? _sleepTimer;
  Duration? _sleepTimerRemaining;
  Timer? _sleepCountdownTicker;

  // A-B Repeat Mode
  Duration? _pointA;
  Duration? _pointB;
  bool _isAbRepeatEnabled = false;

  // Double-tap seek indicator
  int _doubleTapSeekDelta = 0; // seconds
  Timer? _doubleTapTimer;

  // Subscriptions
  StreamSubscription? _stateSub;
  StreamSubscription? _posSub;
  StreamSubscription? _diagSub;

  PlayerController({PlayerEngine? engine})
      : engine = engine ?? PlayerAdapterFactory.create() {
    _initEngineListeners();
  }

  // Getters
  bool get isControlsLocked => _isControlsLocked;
  double get brightness => _brightness;
  double get volume => engine.volume;
  double get speed => engine.speed;
  Duration get position => engine.position;
  Duration get duration => engine.duration;
  Duration get bufferPosition => engine.bufferPosition;
  PlaybackState get state => engine.state;
  bool get isPlaying => engine.state == PlaybackState.playing;
  bool get isBuffering => engine.state == PlaybackState.buffering;
  AspectRatioMode get aspectRatio => engine.aspectRatio;
  PlaybackDiagnostics get diagnostics => engine.diagnostics;
  List<AudioTrack> get audioTracks => engine.audioTracks;
  AudioTrack? get selectedAudioTrack => engine.selectedAudioTrack;
  List<SubtitleTrack> get subtitleTracks => engine.subtitleTracks;
  SubtitleTrack? get selectedSubtitleTrack => engine.selectedSubtitleTrack;
  String get currentSubtitleText => _currentSubtitleText;
  int get subtitleDelayMs => _subtitleDelayMs;
  SubtitleStyle get subtitleStyle => engine.subtitleStyle;

  bool get showVolumeIndicator => _showVolumeIndicator;
  bool get showBrightnessIndicator => _showBrightnessIndicator;
  int get doubleTapSeekDelta => _doubleTapSeekDelta;

  Duration? get pointA => _pointA;
  Duration? get pointB => _pointB;
  bool get isAbRepeatEnabled => _isAbRepeatEnabled;
  Duration? get sleepTimerRemaining => _sleepTimerRemaining;

  void _initEngineListeners() {
    _stateSub = engine.stateStream.listen((_) => notifyListeners());
    _posSub = engine.positionStream.listen((pos) {
      _checkAbRepeat(pos);
      _updateActiveSubtitle(pos);
      notifyListeners();
    });
    _diagSub = engine.diagnosticsStream.listen((_) => notifyListeners());
  }

  /// Initialize engine
  Future<void> initialize() async {
    await engine.initialize();
    notifyListeners();
  }

  /// Open media source and start playback
  Future<void> open(MediaSource source, {bool autoPlay = true, Duration? startPosition}) async {
    _pointA = null;
    _pointB = null;
    _isAbRepeatEnabled = false;
    _parsedSubtitles = [];
    _currentSubtitleText = '';

    await engine.open(source, autoPlay: autoPlay, startPosition: startPosition);
    notifyListeners();
  }

  /// Play
  Future<void> play() async {
    await engine.play();
    notifyListeners();
  }

  /// Pause
  Future<void> pause() async {
    await engine.pause();
    notifyListeners();
  }

  /// Toggle play / pause
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Stop
  Future<void> stop() async {
    await engine.stop();
    notifyListeners();
  }

  /// Seek
  Future<void> seek(Duration target) async {
    await engine.seek(target);
    notifyListeners();
  }

  /// Relative seek (e.g. +10s or -10s)
  Future<void> seekRelative(int seconds) async {
    final target = engine.position + Duration(seconds: seconds);
    await seek(target);
  }

  /// Double tap seek trigger (+10 or -10 with cumulative delta)
  void onDoubleTapSeek(bool isForward) {
    if (_isControlsLocked) return;

    final step = isForward ? 10 : -10;
    _doubleTapSeekDelta += step;
    seekRelative(step);
    notifyListeners();

    _doubleTapTimer?.cancel();
    _doubleTapTimer = Timer(const Duration(milliseconds: 900), () {
      _doubleTapSeekDelta = 0;
      notifyListeners();
    });
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double vol) async {
    await engine.setVolume(vol);
    _showVolumeIndicator = true;
    _resetIndicatorTimer();
    notifyListeners();
  }

  /// Adjust volume relatively with vertical swipe delta
  void adjustVolume(double delta) {
    if (_isControlsLocked) return;
    final newVol = (engine.volume + delta).clamp(0.0, 1.0);
    setVolume(newVol);
  }

  /// Adjust screen brightness relatively with vertical swipe delta
  void adjustBrightness(double delta) {
    if (_isControlsLocked) return;
    _brightness = (_brightness + delta).clamp(0.05, 1.0);
    _showBrightnessIndicator = true;
    _resetIndicatorTimer();
    notifyListeners();
  }

  void _resetIndicatorTimer() {
    _indicatorHideTimer?.cancel();
    _indicatorHideTimer = Timer(const Duration(seconds: 2), () {
      _showVolumeIndicator = false;
      _showBrightnessIndicator = false;
      notifyListeners();
    });
  }

  /// Set playback speed
  Future<void> setSpeed(double spd) async {
    await engine.setSpeed(spd);
    notifyListeners();
  }

  /// Cycle aspect ratio
  Future<void> cycleAspectRatio() async {
    const modes = [
      AspectRatioMode.sixteenByNine,
      AspectRatioMode.fourByThree,
      AspectRatioMode.fill,
      AspectRatioMode.fit,
      AspectRatioMode.stretch,
      AspectRatioMode.original,
    ];
    final currentIndex = modes.indexOf(engine.aspectRatio);
    final nextMode = modes[(currentIndex + 1) % modes.length];
    await engine.setAspectRatio(nextMode);
    notifyListeners();
  }

  /// Set aspect ratio directly
  Future<void> setAspectRatio(AspectRatioMode mode) async {
    await engine.setAspectRatio(mode);
    notifyListeners();
  }

  /// Lock or unlock on-screen player controls
  void toggleControlsLock() {
    _isControlsLocked = !_isControlsLocked;
    notifyListeners();
  }

  /// Set Point A for A-B repeat
  void setPointA() {
    _pointA = engine.position;
    _pointB = null;
    _isAbRepeatEnabled = false;
    notifyListeners();
  }

  /// Set Point B and activate A-B repeat
  void setPointB() {
    if (_pointA == null) {
      _pointA = Duration.zero;
    }
    if (engine.position > _pointA!) {
      _pointB = engine.position;
      _isAbRepeatEnabled = true;
    }
    notifyListeners();
  }

  /// Clear A-B repeat
  void clearAbRepeat() {
    _pointA = null;
    _pointB = null;
    _isAbRepeatEnabled = false;
    notifyListeners();
  }

  void _checkAbRepeat(Duration currentPos) {
    if (_isAbRepeatEnabled && _pointA != null && _pointB != null) {
      if (currentPos >= _pointB!) {
        seek(_pointA!);
      }
    }
  }

  /// Load external subtitle text (SRT or WebVTT content)
  void loadExternalSubtitle(String rawSubtitleContent, {String title = 'External Subtitle'}) {
    _parsedSubtitles = SubtitleParser.parse(rawSubtitleContent);
    _subtitleDelayMs = 0;
    _currentSubtitleText = '';
    notifyListeners();
  }

  /// Adjust subtitle delay offset in milliseconds
  void adjustSubtitleDelay(int deltaMs) {
    _subtitleDelayMs += deltaMs;
    engine.setSubtitleDelay(_subtitleDelayMs);
    _updateActiveSubtitle(engine.position);
    notifyListeners();
  }

  void _updateActiveSubtitle(Duration pos) {
    if (_parsedSubtitles.isEmpty) {
      if (_currentSubtitleText.isNotEmpty) {
        _currentSubtitleText = '';
        notifyListeners();
      }
      return;
    }

    String matchingText = '';
    for (final cue in _parsedSubtitles) {
      if (cue.isActiveAt(pos, delayMs: _subtitleDelayMs)) {
        matchingText = cue.text;
        break;
      }
    }

    if (_currentSubtitleText != matchingText) {
      _currentSubtitleText = matchingText;
      notifyListeners();
    }
  }

  /// Start sleep timer (e.g. 15, 30, 45, 60 minutes)
  void setSleepTimer(Duration duration) {
    cancelSleepTimer();
    _sleepTimerRemaining = duration;
    _sleepTimer = Timer(duration, () {
      pause();
      cancelSleepTimer();
    });

    _sleepCountdownTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sleepTimerRemaining != null && _sleepTimerRemaining! > Duration.zero) {
        _sleepTimerRemaining = _sleepTimerRemaining! - const Duration(seconds: 1);
        notifyListeners();
      } else {
        cancelSleepTimer();
      }
    });
    notifyListeners();
  }

  /// Cancel sleep timer
  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepCountdownTicker?.cancel();
    _sleepTimer = null;
    _sleepCountdownTicker = null;
    _sleepTimerRemaining = null;
    notifyListeners();
  }

  /// Picture in Picture trigger
  Future<bool> enterPictureInPicture() async {
    // Platform-specific PiP triggering
    return true;
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _diagSub?.cancel();
    _indicatorHideTimer?.cancel();
    _doubleTapTimer?.cancel();
    cancelSleepTimer();
    engine.dispose();
    super.dispose();
  }
}

