import 'package:freezed_annotation/freezed_annotation.dart';

part 'epg_model.freezed.dart';
part 'epg_model.g.dart';

/// A single EPG (Electronic Program Guide) entry.
@freezed
class EpgProgram with _$EpgProgram {
  const EpgProgram._();

  const factory EpgProgram({
    required String channelId,
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? category,
    String? posterUrl,
    String? language,
    String? episodeNumber,
  }) = _EpgProgram;

  factory EpgProgram.fromJson(Map<String, dynamic> json) =>
      _$EpgProgramFromJson(json);

  /// Whether this program is currently airing.
  bool get isLive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Whether this program has already ended.
  bool get hasEnded => DateTime.now().isAfter(endTime);

  /// Duration of the program.
  Duration get duration => endTime.difference(startTime);

  /// Progress of the program as a fraction (0.0 to 1.0).
  double get progress {
    if (hasEnded) return 1.0;
    if (!isLive) return 0.0;
    final elapsed = DateTime.now().difference(startTime);
    return elapsed.inSeconds / duration.inSeconds;
  }
}
