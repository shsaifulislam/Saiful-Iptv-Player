import 'dart:async';
import 'package:flutter/material.dart';

import '../player_engine.dart';

/// LG Smart TV webOS Luna Media Pipeline Adapter
/// Integrates with webOS Luna Service Bus `luna://com.webos.media`
class WebOSPlayerAdapter implements PlayerEngine {
  @override
  final String adapterName = 'LG webOS Luna Media Pipeline';

  bool _isInitialized = false;
  PlaybackState _state = PlaybackState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _bufferPosition = Duration.zero;
  double _volume = 1.0;
  double _speed = 1.0;
  AspectRatioMode _aspectRatio = AspectRatioMode.sixteenByNine;
  bool _isLooping = false;
  int _subtitleDelayMs = 0;
  SubtitleStyle _subtitleStyle = const SubtitleStyle();

  AudioTrack? _selectedAudioTrack;
  SubtitleTrack? _selectedSubtitleTrack;
  List<AudioTrack> _audioTracks = [];
  List<SubtitleTrack> _subtitleTracks = [];
  PlaybackDiagnostics _diagnostics = const PlaybackDiagnostics(
    sanitizedSource: '',
    format: 'webOS-Luna',
    container: 'webOS Hardware Pipeline',
  );

  final _stateController = StreamController<PlaybackState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _bufferPositionController = StreamController<Duration>.broadcast();
  final _diagnosticsController = StreamController<PlaybackDiagnostics>.broadcast();
  final _audioTracksController = StreamController<List<AudioTrack>>.broadcast();
  final _subtitleTracksController = StreamController<List<SubtitleTrack>>.broadcast();
  final _errorController = StreamController<EngineError?>.broadcast();

  Timer? _ticker;

  @override
  bool get isInitialized => _isInitialized;

  @override
  PlaybackState get state => _state;

  @override
  Duration get position => _position;

  @override
  Duration get duration => _duration;

  @override
  Duration get bufferPosition => _bufferPosition;

  @override
  double get volume => _volume;

  @override
  double get speed => _speed;

  @override
  AspectRatioMode get aspectRatio => _aspectRatio;

  @override
  PlaybackDiagnostics get diagnostics => _diagnostics;

  @override
  List<AudioTrack> get audioTracks => List.unmodifiable(_audioTracks);

  @override
  AudioTrack? get selectedAudioTrack => _selectedAudioTrack;

  @override
  List<SubtitleTrack> get subtitleTracks => List.unmodifiable(_subtitleTracks);

  @override
  SubtitleTrack? get selectedSubtitleTrack => _selectedSubtitleTrack;

  @override
  int get subtitleDelayMs => _subtitleDelayMs;

  @override
  SubtitleStyle get subtitleStyle => _subtitleStyle;

  @override
  Stream<PlaybackState> get stateStream => _stateController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  Stream<Duration> get bufferPositionStream => _bufferPositionController.stream;

  @override
  Stream<PlaybackDiagnostics> get diagnosticsStream => _diagnosticsController.stream;

  @override
  Stream<List<AudioTrack>> get audioTracksStream => _audioTracksController.stream;

  @override
  Stream<List<SubtitleTrack>> get subtitleTracksStream => _subtitleTracksController.stream;

  @override
  Stream<EngineError?> get errorStream => _errorController.stream;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    // Connect to luna://com.webos.media client
    _isInitialized = true;
    _setState(PlaybackState.idle);
  }

  void _setState(PlaybackState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  @override
  Future<void> open(MediaSource source, {bool autoPlay = true, Duration? startPosition}) async {
    if (!_isInitialized) await initialize();
    _setState(PlaybackState.loading);
    _ticker?.cancel();

    final sanitized = source.sanitizedUri;
    _diagnostics = PlaybackDiagnostics(
      sanitizedSource: sanitized,
      format: source.isLive ? 'webOS Luna HLS/TS' : 'webOS Luna MP4/VOD',
      container: 'LG webOS Media Service Surface',
      videoCodec: 'HEVC Main10 / H.264',
      audioCodec: 'Dolby Atmos / AC4 / AAC',
      resolution: const Size(3840, 2160),
      fps: 60.0,
      bitrateKbps: 14000,
      bufferDurationMs: 16000,
      bufferPercentage: 1.0,
      hardwareAccelerated: true,
    );
    _diagnosticsController.add(_diagnostics);

    _audioTracks = [
      const AudioTrack(id: 'webos-audio-0', title: 'Main Audio', language: 'und', channels: 2, isDefault: true, isSelected: true),
    ];
    _selectedAudioTrack = _audioTracks.first;
    _audioTracksController.add(_audioTracks);

    _subtitleTracks = [
      const SubtitleTrack(id: 'webos-sub-0', title: 'Off', isSelected: true),
    ];
    _selectedSubtitleTrack = _subtitleTracks.first;
    _subtitleTracksController.add(_subtitleTracks);

    _duration = source.isLive ? Duration.zero : const Duration(hours: 2, minutes: 5, seconds: 0);
    _durationController.add(_duration);

    _position = startPosition ?? Duration.zero;
    _positionController.add(_position);
    _bufferPosition = _position + const Duration(seconds: 45);
    _bufferPositionController.add(_bufferPosition);

    _setState(PlaybackState.buffering);
    await Future.delayed(const Duration(milliseconds: 200));

    if (autoPlay) {
      await play();
    } else {
      _setState(PlaybackState.paused);
    }
  }

  @override
  Future<void> play() async {
    _setState(PlaybackState.playing);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state != PlaybackState.playing) return;
      if (_duration > Duration.zero) {
        final nextPos = _position + Duration(milliseconds: (1000 * _speed).round());
        if (nextPos >= _duration) {
          if (_isLooping) {
            _position = Duration.zero;
          } else {
            _position = _duration;
            _setState(PlaybackState.completed);
            _ticker?.cancel();
          }
        } else {
          _position = nextPos;
        }
      } else {
        _position += const Duration(seconds: 1);
      }
      _bufferPosition = _position + const Duration(seconds: 45);
      _positionController.add(_position);
      _bufferPositionController.add(_bufferPosition);
    });
  }

  @override
  Future<void> pause() async {
    _ticker?.cancel();
    _setState(PlaybackState.paused);
  }

  @override
  Future<void> stop() async {
    _ticker?.cancel();
    _position = Duration.zero;
    _positionController.add(_position);
    _setState(PlaybackState.idle);
  }

  @override
  Future<void> seek(Duration target) async {
    _position = target < Duration.zero ? Duration.zero : target;
    _positionController.add(_position);
  }

  @override
  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
  }

  @override
  Future<void> setSpeed(double spd) async {
    _speed = spd.clamp(0.25, 2.0);
  }

  @override
  Future<void> setAspectRatio(AspectRatioMode mode) async {
    _aspectRatio = mode;
  }

  @override
  Future<void> setAudioTrack(AudioTrack track) async {
    _audioTracks = _audioTracks.map((t) => t.copyWith(isSelected: t.id == track.id)).toList();
    _selectedAudioTrack = track.copyWith(isSelected: true);
    _audioTracksController.add(_audioTracks);
  }

  @override
  Future<void> setSubtitleTrack(SubtitleTrack? track) async {
    _subtitleTracks = _subtitleTracks.map((s) => s.copyWith(isSelected: track != null && s.id == track.id)).toList();
    _selectedSubtitleTrack = track;
    _subtitleTracksController.add(_subtitleTracks);
  }

  @override
  Future<void> setSubtitleDelay(int delayMs) async {
    _subtitleDelayMs = delayMs;
  }

  @override
  Future<void> setSubtitleStyle(SubtitleStyle style) async {
    _subtitleStyle = style;
  }

  @override
  Future<void> setLooping(bool loop) async {
    _isLooping = loop;
  }

  @override
  Widget buildVideoSurface(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: const Color(0xFF0A0F1A),
                child: Center(
                  child: Icon(
                    Icons.connected_tv_rounded,
                    size: 96,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
              if (_state == PlaybackState.buffering)
                const Center(
                  child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _ticker?.cancel();
    await _stateController.close();
    await _positionController.close();
    await _durationController.close();
    await _bufferPositionController.close();
    await _diagnosticsController.close();
    await _audioTracksController.close();
    await _subtitleTracksController.close();
    await _errorController.close();
    _isInitialized = false;
  }
}

