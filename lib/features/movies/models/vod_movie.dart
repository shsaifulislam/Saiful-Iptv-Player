/// Represents a licensed Movie or VOD title
class VodMovie {
  final String id;
  final String title;
  final String? originalTitle;
  final String synopsis;
  final String posterUrl;
  final String backdropUrl;
  final String genre;
  final String language;
  final int releaseYear;
  final double rating; // 0.0 to 10.0
  final int durationMinutes;
  final String streamUrl;
  final bool isSeries;
  final List<VodEpisode> episodes;
  final String ageRating; // G, PG, PG-13, R, NC-17
  final bool isWatchlisted;
  final int watchProgressSeconds;

  const VodMovie({
    required this.id,
    required this.title,
    this.originalTitle,
    required this.synopsis,
    required this.posterUrl,
    required this.backdropUrl,
    required this.genre,
    this.language = 'English',
    required this.releaseYear,
    this.rating = 8.0,
    required this.durationMinutes,
    required this.streamUrl,
    this.isSeries = false,
    this.episodes = const [],
    this.ageRating = 'PG-13',
    this.isWatchlisted = false,
    this.watchProgressSeconds = 0,
  });

  bool get hasProgress => watchProgressSeconds > 10;
  double get progressRatio => durationMinutes > 0
      ? (watchProgressSeconds / (durationMinutes * 60)).clamp(0.0, 1.0)
      : 0.0;

  VodMovie copyWith({
    bool? isWatchlisted,
    int? watchProgressSeconds,
  }) {
    return VodMovie(
      id: id,
      title: title,
      originalTitle: originalTitle,
      synopsis: synopsis,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      genre: genre,
      language: language,
      releaseYear: releaseYear,
      rating: rating,
      durationMinutes: durationMinutes,
      streamUrl: streamUrl,
      isSeries: isSeries,
      episodes: episodes,
      ageRating: ageRating,
      isWatchlisted: isWatchlisted ?? this.isWatchlisted,
      watchProgressSeconds: watchProgressSeconds ?? this.watchProgressSeconds,
    );
  }
}

/// Represents an episode of a TV Series
class VodEpisode {
  final String id;
  final int seasonNumber;
  final int episodeNumber;
  final String title;
  final String? synopsis;
  final int durationMinutes;
  final String streamUrl;

  const VodEpisode({
    required this.id,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    this.synopsis,
    required this.durationMinutes,
    required this.streamUrl,
  });
}

