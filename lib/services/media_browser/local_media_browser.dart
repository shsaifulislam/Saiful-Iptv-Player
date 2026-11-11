import 'dart:io';
import 'package:flutter/foundation.dart';

/// Supported media categories
enum MediaCategory {
  video,
  audio,
  subtitle,
  other,
}

/// Sort criteria for media browsing
enum MediaSortOption {
  nameAsc,
  nameDesc,
  dateModifiedDesc,
  sizeDesc,
}

/// Metadata model for a local media file
class LocalMediaFile {
  final String path;
  final String name;
  final int sizeBytes;
  final DateTime dateModified;
  final String extension;
  final MediaCategory category;
  final Duration? duration;
  final String? resolution;

  const LocalMediaFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.dateModified,
    required this.extension,
    required this.category,
    this.duration,
    this.resolution,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Map<String, dynamic> toJson() => {
    'path': path,
    'name': name,
    'sizeBytes': sizeBytes,
    'dateModified': dateModified.toIso8601String(),
    'extension': extension,
    'category': category.name,
    'durationMs': duration?.inMilliseconds,
    'resolution': resolution,
  };

  factory LocalMediaFile.fromJson(Map<String, dynamic> json) => LocalMediaFile(
    path: json['path'] as String,
    name: json['name'] as String,
    sizeBytes: json['sizeBytes'] as int? ?? 0,
    dateModified: DateTime.tryParse(json['dateModified'] as String? ?? '') ?? DateTime.now(),
    extension: json['extension'] as String? ?? '',
    category: MediaCategory.values.firstWhere(
      (c) => c.name == json['category'],
      orElse: () => MediaCategory.video,
    ),
    duration: json['durationMs'] != null ? Duration(milliseconds: json['durationMs'] as int) : null,
    resolution: json['resolution'] as String?,
  );
}

/// Abstract contract for local media access (Scoped Storage / SAF on Android, FileSystem on Desktop)
class LocalMediaBrowser {
  static const List<String> videoExtensions = ['mp4', 'mkv', 'mov', 'avi', 'webm', 'ts', 'm4v'];
  static const List<String> audioExtensions = ['mp3', 'aac', 'flac', 'wav', 'ogg', 'm4a', 'opus'];
  static const List<String> subtitleExtensions = ['srt', 'vtt', 'ass', 'sub'];

  final List<LocalMediaFile> _recentFiles = [];

  List<LocalMediaFile> get recentFiles => List.unmodifiable(_recentFiles);

  /// Check whether media access permission is granted
  Future<bool> checkPermission() async {
    // In production Flutter Android: invokes Permission.storage or Permission.videos/audio
    // On Desktop: always granted
    return true;
  }

  /// Request media access permission
  Future<bool> requestPermission() async {
    return true;
  }

  /// Categorize file by its extension
  static MediaCategory categorize(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    if (videoExtensions.contains(ext)) return MediaCategory.video;
    if (audioExtensions.contains(ext)) return MediaCategory.audio;
    if (subtitleExtensions.contains(ext)) return MediaCategory.subtitle;
    return MediaCategory.other;
  }

  /// Scan directory for media files
  Future<List<LocalMediaFile>> scanDirectory(String directoryPath, {
    MediaCategory? filterCategory,
    bool recursive = false,
  }) async {
    final results = <LocalMediaFile>[];

    try {
      final dir = Directory(directoryPath);
      if (!await dir.exists()) return results;

      final entities = dir.listSync(recursive: recursive);
      for (final entity in entities) {
        if (entity is File) {
          final ext = entity.path.split('.').last.toLowerCase();
          final category = categorize(ext);

          if (filterCategory != null && category != filterCategory) {
            continue;
          }

          if (category == MediaCategory.other) continue;

          final stat = entity.statSync();
          final name = entity.uri.pathSegments.last;

          results.add(LocalMediaFile(
            path: entity.path,
            name: name,
            sizeBytes: stat.size,
            dateModified: stat.modified,
            extension: ext,
            category: category,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error scanning directory $directoryPath: $e');
    }

    return results;
  }

  /// Filter and sort media file list
  List<LocalMediaFile> filterAndSort(
    List<LocalMediaFile> files, {
    String? query,
    MediaSortOption sortOption = MediaSortOption.nameAsc,
  }) {
    var filtered = files;
    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      filtered = filtered.where((f) => f.name.toLowerCase().contains(q)).toList();
    }

    switch (sortOption) {
      case MediaSortOption.nameAsc:
        filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case MediaSortOption.nameDesc:
        filtered.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case MediaSortOption.dateModifiedDesc:
        filtered.sort((a, b) => b.dateModified.compareTo(a.dateModified));
        break;
      case MediaSortOption.sizeDesc:
        filtered.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
        break;
    }

    return filtered;
  }

  /// Record a file to recent items
  void recordRecentFile(LocalMediaFile file) {
    _recentFiles.removeWhere((f) => f.path == file.path);
    _recentFiles.insert(0, file);
    if (_recentFiles.length > 30) {
      _recentFiles.removeLast();
    }
  }
}

