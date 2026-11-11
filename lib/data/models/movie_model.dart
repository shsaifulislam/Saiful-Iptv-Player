import 'package:freezed_annotation/freezed_annotation.dart';

part 'movie_model.freezed.dart';
part 'movie_model.g.dart';

/// A Movie / Video-On-Demand entry.
@freezed
class Movie with _$Movie {
  const Movie._();

  const factory Movie({
    required String id,
    required String name,
    required String streamUrl,
    String? containerExtension,
    double? rating,
    String? plot,
    String? cast,
    String? director,
    int? year,
    String? genre,
    String? posterUrl,
    String? backdropUrl,
    String? trailerUrl,
    int? duration,
    String? playlistId,
    int? streamId,
    String? categoryId,
    DateTime? addedAt,
  }) = _Movie;

  factory Movie.fromJson(Map<String, dynamic> json) => _$MovieFromJson(json);

  /// Human-readable rating string.
  String get ratingDisplay =>
      rating != null ? rating!.toStringAsFixed(1) : 'N/A';

  /// Full stream URL including container extension.
  String get fullStreamUrl {
    if (containerExtension != null && containerExtension!.isNotEmpty) {
      return '$streamUrl.$containerExtension';
    }
    return streamUrl;
  }
}
