import 'package:freezed_annotation/freezed_annotation.dart';

part 'history_model.freezed.dart';
part 'history_model.g.dart';

/// A watch history entry.
@freezed
class WatchHistory with _$WatchHistory {
  const WatchHistory._();

  const factory WatchHistory({
    required String id,
    required String channelId,
    String? channelName,
    required DateTime watchedAt,
    @Default(0) int duration,
    @Default(0) int position,
    String? thumbnail,
    String? channelLogo,
    String? groupTitle,
  }) = _WatchHistory;

  factory WatchHistory.fromJson(Map<String, dynamic> json) =>
      _$WatchHistoryFromJson(json);

  /// Progress of playback as a fraction (0.0 to 1.0).
  double get progress {
    if (duration <= 0) return 0.0;
    return (position / duration).clamp(0.0, 1.0);
  }

  /// Whether the content was fully watched (>= 90%).
  bool get isCompleted => progress >= 0.9;

  /// Remaining duration in seconds.
  int get remaining => (duration - position).clamp(0, duration);
}
