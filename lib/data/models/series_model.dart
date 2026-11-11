import 'package:freezed_annotation/freezed_annotation.dart';

part 'series_model.freezed.dart';
part 'series_model.g.dart';

/// A single episode within a season.
@freezed
class Episode with _$Episode {
  const factory Episode({
    required String id,
    required String title,
    required int episodeNumber,
    required int seasonNumber,
    String? streamUrl,
    String? containerExtension,
    String? plot,
    int? duration,
    double? rating,
    String? posterUrl,
    DateTime? airDate,
  }) = _Episode;

  factory Episode.fromJson(Map<String, dynamic> json) =>
      _$EpisodeFromJson(json);
}

/// A season containing episodes.
@freezed
class Season with _$Season {
  const factory Season({
    required int seasonNumber,
    required String name,
    String? coverUrl,
    @Default([]) List<Episode> episodes,
    int? episodeCount,
    DateTime? airDate,
  }) = _Season;

  factory Season.fromJson(Map<String, dynamic> json) =>
      _$SeasonFromJson(json);
}

/// A TV series with seasons and episodes.
@freezed
class Series with _$Series {
  const Series._();

  const factory Series({
    required String id,
    required String name,
    @Default([]) List<Season> seasons,
    String? plot,
    String? cast,
    String? genre,
    String? posterUrl,
    String? backdropUrl,
    double? rating,
    String? director,
    int? year,
    String? playlistId,
    String? categoryId,
    DateTime? lastModified,
  }) = _Series;

  factory Series.fromJson(Map<String, dynamic> json) =>
      _$SeriesFromJson(json);

  /// Total number of episodes across all seasons.
  int get totalEpisodes =>
      seasons.fold(0, (sum, s) => sum + s.episodes.length);

  /// Total number of seasons.
  int get seasonCount => seasons.length;
}
