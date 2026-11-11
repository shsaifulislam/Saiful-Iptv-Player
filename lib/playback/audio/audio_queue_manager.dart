import 'dart:math';
import 'package:flutter/foundation.dart';

import '../player_engine.dart';

/// Repeat modes for audio playback
enum AudioRepeatMode {
  off,
  all,
  one,
}

/// Represents an audio track item with rich metadata
class AudioTrackItem {
  final String id;
  final String uri;
  final String title;
  final String artist;
  final String? album;
  final String? artworkUri;
  final Duration duration;
  final String format; // MP3, AAC, FLAC, WAV, OGG
  final Map<String, dynamic>? extra;

  const AudioTrackItem({
    required this.id,
    required this.uri,
    required this.title,
    this.artist = 'Unknown Artist',
    this.album,
    this.artworkUri,
    this.duration = Duration.zero,
    this.format = 'MP3',
    this.extra,
  });

  MediaSource toMediaSource() {
    return MediaSource(
      uri: uri,
      title: title,
      subtitle: artist,
      mediaType: MediaType.audio,
      metadata: {
        'album': album,
        'artwork': artworkUri,
        'format': format,
      },
    );
  }
}

/// Audio Queue and Background Playback Coordinator
class AudioQueueManager extends ChangeNotifier {
  final PlayerEngine engine;

  final List<AudioTrackItem> _originalQueue = [];
  List<AudioTrackItem> _activeQueue = [];
  int _currentIndex = -1;

  AudioRepeatMode _repeatMode = AudioRepeatMode.off;
  bool _isShuffled = false;
  double _playbackSpeed = 1.0;

  AudioQueueManager({required this.engine}) {
    engine.stateStream.listen((state) {
      if (state == PlaybackState.completed) {
        _handleTrackCompletion();
      }
      notifyListeners();
    });
  }

  // Getters
  List<AudioTrackItem> get queue => List.unmodifiable(_activeQueue);
  int get currentIndex => _currentIndex;
  AudioTrackItem? get currentTrack =>
      (_currentIndex >= 0 && _currentIndex < _activeQueue.length)
          ? _activeQueue[_currentIndex]
          : null;
  bool get hasNext => _repeatMode != AudioRepeatMode.off || _currentIndex < _activeQueue.length - 1;
  bool get hasPrevious => _currentIndex > 0;
  AudioRepeatMode get repeatMode => _repeatMode;
  bool get isShuffled => _isShuffled;
  double get playbackSpeed => _playbackSpeed;
  bool get isPlaying => engine.state == PlaybackState.playing;
  Duration get position => engine.position;
  Duration get duration => engine.duration;

  /// Set new playlist queue
  Future<void> setQueue(List<AudioTrackItem> tracks, {int startIndex = 0, bool autoPlay = true}) async {
    _originalQueue.clear();
    _originalQueue.addAll(tracks);

    if (_isShuffled) {
      _shuffleQueue();
    } else {
      _activeQueue = List.from(_originalQueue);
    }

    if (_activeQueue.isNotEmpty) {
      _currentIndex = startIndex.clamp(0, _activeQueue.length - 1);
      await _loadCurrentTrack(autoPlay: autoPlay);
    } else {
      _currentIndex = -1;
      await engine.stop();
    }
    notifyListeners();
  }

  /// Add track to end of queue
  void addTrack(AudioTrackItem track) {
    _originalQueue.add(track);
    _activeQueue.add(track);
    if (_currentIndex == -1) {
      _currentIndex = 0;
      _loadCurrentTrack(autoPlay: false);
    }
    notifyListeners();
  }

  /// Play selected track by queue index
  Future<void> playTrackAtIndex(int index) async {
    if (index >= 0 && index < _activeQueue.length) {
      _currentIndex = index;
      await _loadCurrentTrack(autoPlay: true);
      notifyListeners();
    }
  }

  /// Skip to next track
  Future<void> next() async {
    if (_activeQueue.isEmpty) return;

    if (_repeatMode == AudioRepeatMode.one) {
      await engine.seek(Duration.zero);
      await engine.play();
      return;
    }

    if (_currentIndex < _activeQueue.length - 1) {
      _currentIndex++;
      await _loadCurrentTrack(autoPlay: true);
    } else if (_repeatMode == AudioRepeatMode.all) {
      _currentIndex = 0;
      await _loadCurrentTrack(autoPlay: true);
    }
    notifyListeners();
  }

  /// Skip to previous track
  Future<void> previous() async {
    if (_activeQueue.isEmpty) return;

    // If more than 3 seconds in, seek to beginning first
    if (engine.position > const Duration(seconds: 3)) {
      await engine.seek(Duration.zero);
      return;
    }

    if (_currentIndex > 0) {
      _currentIndex--;
      await _loadCurrentTrack(autoPlay: true);
    } else if (_repeatMode == AudioRepeatMode.all) {
      _currentIndex = _activeQueue.length - 1;
      await _loadCurrentTrack(autoPlay: true);
    }
    notifyListeners();
  }

  /// Toggle play / pause
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await engine.pause();
    } else {
      if (_currentIndex == -1 && _activeQueue.isNotEmpty) {
        _currentIndex = 0;
        await _loadCurrentTrack(autoPlay: true);
      } else {
        await engine.play();
      }
    }
    notifyListeners();
  }

  /// Seek position
  Future<void> seek(Duration pos) async {
    await engine.seek(pos);
    notifyListeners();
  }

  /// Cycle repeat mode: Off -> All -> One -> Off
  void cycleRepeatMode() {
    switch (_repeatMode) {
      case AudioRepeatMode.off:
        _repeatMode = AudioRepeatMode.all;
        break;
      case AudioRepeatMode.all:
        _repeatMode = AudioRepeatMode.one;
        break;
      case AudioRepeatMode.one:
        _repeatMode = AudioRepeatMode.off;
        break;
    }
    notifyListeners();
  }

  /// Toggle shuffle
  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    final current = currentTrack;

    if (_isShuffled) {
      _shuffleQueue();
      if (current != null) {
        _currentIndex = _activeQueue.indexOf(current);
      }
    } else {
      _activeQueue = List.from(_originalQueue);
      if (current != null) {
        _currentIndex = _activeQueue.indexOf(current);
      }
    }
    notifyListeners();
  }

  void _shuffleQueue() {
    final current = currentTrack;
    final remaining = List<AudioTrackItem>.from(_originalQueue);
    if (current != null) {
      remaining.remove(current);
    }
    remaining.shuffle(Random());
    if (current != null) {
      _activeQueue = [current, ...remaining];
      _currentIndex = 0;
    } else {
      _activeQueue = remaining;
    }
  }

  /// Set audio speed (0.5x to 2.0x)
  Future<void> setSpeed(double speed) async {
    _playbackSpeed = speed.clamp(0.5, 2.0);
    await engine.setSpeed(_playbackSpeed);
    notifyListeners();
  }

  Future<void> _loadCurrentTrack({required bool autoPlay}) async {
    final track = currentTrack;
    if (track == null) return;

    final mediaSource = track.toMediaSource();
    await engine.open(mediaSource, autoPlay: autoPlay);
    await engine.setSpeed(_playbackSpeed);
  }

  void _handleTrackCompletion() {
    if (_repeatMode == AudioRepeatMode.one) {
      engine.seek(Duration.zero);
      engine.play();
    } else {
      next();
    }
  }
}

