import 'package:flutter/foundation.dart';

/// Represents a saved YouTube stream or video bookmark
class YoutubeLinkItem {
  final String id;
  final String videoId;
  final String title;
  final String channelTitle;
  final String originalUrl;
  final String? playlistId;
  final DateTime addedAt;

  const YoutubeLinkItem({
    required this.id,
    required this.videoId,
    required this.title,
    required this.channelTitle,
    required this.originalUrl,
    this.playlistId,
    required this.addedAt,
  });

  String get thumbnailUrl => 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  String get officialWatchUrl => 'https://www.youtube.com/watch?v=$videoId';
  String get officialAppUrl => 'vnd.youtube:$videoId';
  String get officialEmbedUrl =>
      'https://www.youtube-nocookie.com/embed/$videoId?autoplay=1&rel=0&modestbranding=1';
}

/// Official YouTube Integration Service
class YoutubeService extends ChangeNotifier {
  static final YoutubeService instance = YoutubeService._internal();

  YoutubeService._internal() {
    _initDefaultSeedLinks();
  }

  final List<YoutubeLinkItem> _savedLinks = [];
  final List<YoutubeLinkItem> _recentLinks = [];

  List<YoutubeLinkItem> get savedLinks => List.unmodifiable(_savedLinks);
  List<YoutubeLinkItem> get recentLinks => List.unmodifiable(_recentLinks);

  void _initDefaultSeedLinks() {
    _savedLinks.addAll([
      YoutubeLinkItem(
        id: 'yt_1',
        videoId: '21X5lGlDOfg',
        title: 'NASA Live: Earth Views from the Space Station',
        channelTitle: 'NASA Official',
        originalUrl: 'https://www.youtube.com/watch?v=21X5lGlDOfg',
        addedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      YoutubeLinkItem(
        id: 'yt_2',
        videoId: 'jfKfPfyJRdk',
        title: 'Lofi Hip Hop Radio - Beats to Relax/Study to',
        channelTitle: 'Lofi Girl',
        originalUrl: 'https://www.youtube.com/watch?v=jfKfPfyJRdk',
        addedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      YoutubeLinkItem(
        id: 'yt_3',
        videoId: '7eD42xW7Hao',
        title: 'Tokyo Live: Shibuya Crossing 4K Camera',
        channelTitle: 'Tokyo Live Streams',
        originalUrl: 'https://www.youtube.com/watch?v=7eD42xW7Hao',
        addedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);
  }

  /// Extracts standard 11-character YouTube video ID from various URL variants
  static String? extractVideoId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Direct 11-char ID
    if (RegExp(r'^[a-zA-Z0-9_\-]{11}$').hasMatch(trimmed)) {
      return trimmed;
    }

    try {
      final uri = Uri.parse(trimmed);

      // youtu.be/VIDEO_ID
      if (uri.host.contains('youtu.be')) {
        if (uri.pathSegments.isNotEmpty) {
          final id = uri.pathSegments.first;
          if (id.length == 11) return id;
        }
      }

      // youtube.com/watch?v=VIDEO_ID
      if (uri.queryParameters.containsKey('v')) {
        final id = uri.queryParameters['v'];
        if (id != null && id.length == 11) return id;
      }

      // youtube.com/embed/VIDEO_ID
      if (uri.path.contains('/embed/')) {
        final idx = uri.pathSegments.indexOf('embed');
        if (idx != -1 && idx + 1 < uri.pathSegments.length) {
          final id = uri.pathSegments[idx + 1];
          if (id.length == 11) return id;
        }
      }

      // youtube.com/shorts/VIDEO_ID
      if (uri.path.contains('/shorts/')) {
        final idx = uri.pathSegments.indexOf('shorts');
        if (idx != -1 && idx + 1 < uri.pathSegments.length) {
          final id = uri.pathSegments[idx + 1];
          if (id.length == 11) return id;
        }
      }

      // Regex fallback matching v= or /v/ or embed/
      final regex = RegExp(r'(?:v=|\/|youtu\.be\/|embed\/|shorts\/)([a-zA-Z0-9_\-]{11})');
      final match = regex.firstMatch(trimmed);
      if (match != null) {
        return match.group(1);
      }
    } catch (_) {}

    return null;
  }

  /// Extracts playlist ID if present
  static String? extractPlaylistId(String input) {
    try {
      final uri = Uri.parse(input.trim());
      if (uri.queryParameters.containsKey('list')) {
        return uri.queryParameters['list'];
      }
    } catch (_) {}
    return null;
  }

  /// Save a new YouTube link
  void saveLink({
    required String url,
    required String title,
    String channelTitle = 'YouTube Channel',
  }) {
    final videoId = extractVideoId(url);
    if (videoId == null) {
      throw ArgumentError('Invalid YouTube video link or ID');
    }

    final item = YoutubeLinkItem(
      id: 'yt_${DateTime.now().millisecondsSinceEpoch}',
      videoId: videoId,
      title: title.isNotEmpty ? title : 'YouTube Video ($videoId)',
      channelTitle: channelTitle,
      originalUrl: url,
      playlistId: extractPlaylistId(url),
      addedAt: DateTime.now(),
    );

    _savedLinks.insert(0, item);
    recordRecent(item);
    notifyListeners();
  }

  /// Delete a saved link
  void deleteSavedLink(String id) {
    _savedLinks.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  /// Record as recently watched
  void recordRecent(YoutubeLinkItem item) {
    _recentLinks.removeWhere((i) => i.videoId == item.videoId);
    _recentLinks.insert(0, item);
    if (_recentLinks.length > 20) {
      _recentLinks.removeLast();
    }
    notifyListeners();
  }
}

