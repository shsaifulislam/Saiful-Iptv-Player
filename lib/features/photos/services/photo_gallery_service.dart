import 'dart:async';
import 'package:flutter/foundation.dart';

/// Supported image formats
enum PhotoFormat {
  jpg,
  png,
  webp,
  gif,
  bmp,
}

/// Photo metadata item
class PhotoItem {
  final String id;
  final String title;
  final String album;
  final String path;
  final PhotoFormat format;
  final int sizeBytes;
  final int width;
  final int height;
  final DateTime dateModified;

  const PhotoItem({
    required this.id,
    required this.title,
    required this.album,
    required this.path,
    required this.format,
    required this.sizeBytes,
    required this.width,
    required this.height,
    required this.dateModified,
  });

  String get resolution => '${width}x$height';

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

/// Service managing Photo Gallery, Albums, and Slideshow Loop
class PhotoGalleryService extends ChangeNotifier {
  static final PhotoGalleryService instance = PhotoGalleryService._internal();

  PhotoGalleryService._internal() {
    _initSamplePhotos();
  }

  final List<PhotoItem> _photos = [];

  // Slideshow state
  bool _isSlideshowPlaying = false;
  int _slideshowIndex = 0;
  int _slideshowIntervalSeconds = 5;
  Timer? _slideshowTimer;

  bool get isSlideshowPlaying => _isSlideshowPlaying;
  int get slideshowIndex => _slideshowIndex;
  int get slideshowIntervalSeconds => _slideshowIntervalSeconds;
  List<PhotoItem> get allPhotos => List.unmodifiable(_photos);

  List<String> get albums {
    final set = <String>{'All'};
    for (final p in _photos) {
      set.add(p.album);
    }
    return set.toList();
  }

  void _initSamplePhotos() {
    _photos.addAll([
      PhotoItem(
        id: 'p1',
        title: 'Sunset over Saint Martin Island',
        album: 'Vacations',
        path: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&auto=format&fit=crop&q=80',
        format: PhotoFormat.jpg,
        sizeBytes: 2450000,
        width: 3840,
        height: 2160,
        dateModified: DateTime(2026, 4, 12),
      ),
      PhotoItem(
        id: 'p2',
        title: 'Dhaka National Monument at Dusk',
        album: 'Heritage',
        path: 'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800&auto=format&fit=crop&q=80',
        format: PhotoFormat.png,
        sizeBytes: 3100000,
        width: 1920,
        height: 1080,
        dateModified: DateTime(2026, 5, 20),
      ),
      PhotoItem(
        id: 'p3',
        title: 'High Altitude Himalayan Ridge',
        album: 'Mountains',
        path: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800&auto=format&fit=crop&q=80',
        format: PhotoFormat.webp,
        sizeBytes: 1850000,
        width: 4096,
        height: 2160,
        dateModified: DateTime(2026, 6, 1),
      ),
      PhotoItem(
        id: 'p4',
        title: 'Cyberpunk Neon Alleyway',
        album: 'Wallpapers',
        path: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=800&auto=format&fit=crop&q=80',
        format: PhotoFormat.jpg,
        sizeBytes: 2900000,
        width: 2560,
        height: 1440,
        dateModified: DateTime(2026, 7, 15),
      ),
      PhotoItem(
        id: 'p5',
        title: 'Animated City Lights Loop',
        album: 'Wallpapers',
        path: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=800&auto=format&fit=crop&q=80',
        format: PhotoFormat.gif,
        sizeBytes: 4200000,
        width: 1280,
        height: 720,
        dateModified: DateTime(2026, 8, 10),
      ),
    ]);
  }

  /// Start Slideshow loop
  void startSlideshow({int startIndex = 0, int intervalSec = 5}) {
    if (_photos.isEmpty) return;
    _slideshowIndex = startIndex.clamp(0, _photos.length - 1);
    _slideshowIntervalSeconds = intervalSec;
    _isSlideshowPlaying = true;
    _scheduleNextSlide();
    notifyListeners();
  }

  void _scheduleNextSlide() {
    _slideshowTimer?.cancel();
    _slideshowTimer = Timer(Duration(seconds: _slideshowIntervalSeconds), () {
      if (!_isSlideshowPlaying) return;
      _slideshowIndex = (_slideshowIndex + 1) % _photos.length;
      notifyListeners();
      _scheduleNextSlide();
    });
  }

  /// Pause Slideshow loop
  void pauseSlideshow() {
    _slideshowTimer?.cancel();
    _isSlideshowPlaying = false;
    notifyListeners();
  }

  /// Toggle Slideshow play/pause
  void toggleSlideshow() {
    if (_isSlideshowPlaying) {
      pauseSlideshow();
    } else {
      _isSlideshowPlaying = true;
      _scheduleNextSlide();
      notifyListeners();
    }
  }

  /// Filter photos by album or search query
  List<PhotoItem> filterPhotos({String album = 'All', String query = ''}) {
    var result = _photos;
    if (album != 'All') {
      result = result.where((p) => p.album.toLowerCase() == album.toLowerCase()).toList();
    }
    if (query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((p) => p.title.toLowerCase().contains(q) || p.album.toLowerCase().contains(q)).toList();
    }
    return result;
  }
}

