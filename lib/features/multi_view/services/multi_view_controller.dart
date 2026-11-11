import 'package:flutter/foundation.dart';

/// Single stream tile state in Multi-View mode
class StreamTile {
  final int index;
  final String channelName;
  final String streamUrl;
  final bool isPlaying;
  final bool isAudioActive;
  final bool isBuffering;
  final String? errorMessage;

  const StreamTile({
    required this.index,
    required this.channelName,
    required this.streamUrl,
    this.isPlaying = true,
    this.isAudioActive = false,
    this.isBuffering = false,
    this.errorMessage,
  });

  StreamTile copyWith({
    String? channelName,
    String? streamUrl,
    bool? isPlaying,
    bool? isAudioActive,
    bool? isBuffering,
    String? errorMessage,
  }) {
    return StreamTile(
      index: index,
      channelName: channelName ?? this.channelName,
      streamUrl: streamUrl ?? this.streamUrl,
      isPlaying: isPlaying ?? this.isPlaying,
      isAudioActive: isAudioActive ?? this.isAudioActive,
      isBuffering: isBuffering ?? this.isBuffering,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Multi-View grid arrangement mode
enum MultiViewLayout {
  twoScreen,
  fourScreen,
}

/// Multi-View Controller managing simultaneous independent streams
class MultiViewController extends ChangeNotifier {
  MultiViewLayout _layout = MultiViewLayout.fourScreen;
  int _focusedAudioTileIndex = 0;
  bool _hardwareWarningDismissed = false;

  final List<StreamTile> _tiles = [];

  MultiViewController() {
    _initDefaultTiles();
  }

  MultiViewLayout get layout => _layout;
  int get activeTileCount => _layout == MultiViewLayout.fourScreen ? 4 : 2;
  int get focusedAudioTileIndex => _focusedAudioTileIndex;
  List<StreamTile> get tiles => List.unmodifiable(_tiles.take(activeTileCount));
  bool get shouldShowHardwareWarning => !_hardwareWarningDismissed && _layout == MultiViewLayout.fourScreen;

  void _initDefaultTiles() {
    _tiles.addAll([
      const StreamTile(
        index: 0,
        channelName: 'Al Jazeera English HD',
        streamUrl: 'https://live-hls-web-aje.getaj.net/AJE/03.m3u8',
        isPlaying: true,
        isAudioActive: true,
      ),
      const StreamTile(
        index: 1,
        channelName: 'Deutsche Welle English (DW)',
        streamUrl: 'https://dwamdstream102.akamaized.net/hls/live/2015525/dwstream102/index.m3u8',
        isPlaying: true,
        isAudioActive: false,
      ),
      const StreamTile(
        index: 2,
        channelName: 'Red Bull TV Live',
        streamUrl: 'https://rbmn-live.akamaized.net/hls/live/590964/geoSTB/master.m3u8',
        isPlaying: true,
        isAudioActive: false,
      ),
      const StreamTile(
        index: 3,
        channelName: 'NASA TV Public HD',
        streamUrl: 'https://ntv1.akamaized.net/hls/live/2014075/NASA-NTV1-HLS/master.m3u8',
        isPlaying: true,
        isAudioActive: false,
      ),
    ]);
  }

  /// Toggle between 2-view and 4-view layouts
  void setLayout(MultiViewLayout newLayout) {
    _layout = newLayout;
    if (_focusedAudioTileIndex >= activeTileCount) {
      setAudioFocus(0);
    }
    notifyListeners();
  }

  /// Select which stream has audio unmuted (exclusive audio focus)
  void setAudioFocus(int tileIndex) {
    if (tileIndex < 0 || tileIndex >= activeTileCount) return;
    _focusedAudioTileIndex = tileIndex;
    for (int i = 0; i < _tiles.length; i++) {
      _tiles[i] = _tiles[i].copyWith(isAudioActive: i == tileIndex);
    }
    notifyListeners();
  }

  /// Toggle play/pause on a specific tile independently
  void toggleTilePlayPause(int tileIndex) {
    if (tileIndex < 0 || tileIndex >= _tiles.length) return;
    final current = _tiles[tileIndex];
    _tiles[tileIndex] = current.copyWith(isPlaying: !current.isPlaying);
    notifyListeners();
  }

  /// Handle isolated stream failure without affecting other tiles
  void reportTileError(int tileIndex, String errorMessage) {
    if (tileIndex < 0 || tileIndex >= _tiles.length) return;
    _tiles[tileIndex] = _tiles[tileIndex].copyWith(
      isPlaying: false,
      errorMessage: errorMessage,
    );
    notifyListeners();
  }

  /// Dismiss hardware warning banner
  void dismissHardwareWarning() {
    _hardwareWarningDismissed = true;
    notifyListeners();
  }
}

