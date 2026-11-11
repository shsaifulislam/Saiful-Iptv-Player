import 'package:freezed_annotation/freezed_annotation.dart';

part 'download_model.freezed.dart';
part 'download_model.g.dart';

/// Status of a download task.
enum DownloadStatus {
  @JsonValue('queued')
  queued,
  @JsonValue('downloading')
  downloading,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('paused')
  paused,
  @JsonValue('cancelled')
  cancelled,
}

/// A download task for offline playback.
@freezed
class Download with _$Download {
  const Download._();

  const factory Download({
    required String id,
    required String channelId,
    String? channelName,
    String? filePath,
    @Default(0.0) double progress,
    @Default(DownloadStatus.queued) DownloadStatus status,
    @Default(0) int fileSize,
    @Default(0) int downloadedBytes,
    String? error,
    required DateTime createdAt,
    DateTime? completedAt,
    String? streamUrl,
  }) = _Download;

  factory Download.fromJson(Map<String, dynamic> json) =>
      _$DownloadFromJson(json);

  /// Whether the download is actively running.
  bool get isActive =>
      status == DownloadStatus.downloading || status == DownloadStatus.queued;

  /// Whether the download completed successfully.
  bool get isCompleted => status == DownloadStatus.completed;

  /// Human-readable file size.
  String get fileSizeDisplay {
    if (fileSize <= 0) return 'Unknown';
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
