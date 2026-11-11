import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:saiful_iptv_player/data/models/channel_model.dart';
import 'package:saiful_iptv_player/data/models/movie_model.dart';
import 'package:saiful_iptv_player/data/models/series_model.dart';

part 'search_result_model.freezed.dart';
part 'search_result_model.g.dart';

/// Type of content in a search result.
enum SearchResultType {
  @JsonValue('channel')
  channel,
  @JsonValue('movie')
  movie,
  @JsonValue('series')
  series,
}

/// A unified search result wrapping different content types.
@freezed
class SearchResult with _$SearchResult {
  const SearchResult._();

  const factory SearchResult({
    required String id,
    required String title,
    required SearchResultType type,
    String? imageUrl,
    String? description,
    String? groupTitle,
    double? relevanceScore,
    /// The original channel data, if type is channel.
    Channel? channel,
    /// The original movie data, if type is movie.
    Movie? movie,
    /// The original series data, if type is series.
    Series? series,
  }) = _SearchResult;

  factory SearchResult.fromJson(Map<String, dynamic> json) =>
      _$SearchResultFromJson(json);

  /// Create a search result from a Channel.
  factory SearchResult.fromChannel(Channel channel, {double? score}) {
    return SearchResult(
      id: channel.id,
      title: channel.name,
      type: SearchResultType.channel,
      imageUrl: channel.effectiveLogo,
      groupTitle: channel.groupTitle,
      relevanceScore: score,
      channel: channel,
    );
  }

  /// Create a search result from a Movie.
  factory SearchResult.fromMovie(Movie movie, {double? score}) {
    return SearchResult(
      id: movie.id,
      title: movie.name,
      type: SearchResultType.movie,
      imageUrl: movie.posterUrl,
      description: movie.plot,
      relevanceScore: score,
      movie: movie,
    );
  }

  /// Create a search result from a Series.
  factory SearchResult.fromSeries(Series series, {double? score}) {
    return SearchResult(
      id: series.id,
      title: series.name,
      type: SearchResultType.series,
      imageUrl: series.posterUrl,
      description: series.plot,
      relevanceScore: score,
      series: series,
    );
  }
}
