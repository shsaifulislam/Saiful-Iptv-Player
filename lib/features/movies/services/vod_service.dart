import 'package:flutter/foundation.dart';
import '../models/vod_movie.dart';

/// Central VOD and Movie Catalog Service
class VodService extends ChangeNotifier {
  static final VodService instance = VodService._internal();

  VodService._internal() {
    _initLicensedCatalog();
  }

  final List<VodMovie> _catalog = [];
  final Set<String> _watchlistIds = {};
  final Map<String, int> _watchProgress = {}; // movieId -> seconds

  List<VodMovie> get allMovies => _catalog.map(_enrichMovie).toList();

  List<VodMovie> get continueWatching => _catalog
      .map(_enrichMovie)
      .where((m) => m.hasProgress)
      .toList()
    ..sort((a, b) => b.watchProgressSeconds.compareTo(a.watchProgressSeconds));

  List<VodMovie> get watchlist =>
      _catalog.map(_enrichMovie).where((m) => m.isWatchlisted).toList();

  List<String> get genres => [
        'All',
        'Sci-Fi',
        'Animation',
        'Action',
        'Documentary',
        'Drama',
        'Series',
      ];

  void _initLicensedCatalog() {
    _catalog.addAll([
      const VodMovie(
        id: 'vod_tears_of_steel',
        title: 'Tears of Steel',
        synopsis: 'In a dystopian future, a group of scientists and soldiers gather in Amsterdam to stage an alternate reality experiment with robotics and cybernetic memories.',
        posterUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=500&auto=format&fit=crop&q=60',
        backdropUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1200&auto=format&fit=crop&q=80',
        genre: 'Sci-Fi',
        language: 'English',
        releaseYear: 2024,
        rating: 8.6,
        durationMinutes: 114,
        streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
        ageRating: 'PG-13',
      ),
      const VodMovie(
        id: 'vod_big_buck_bunny',
        title: 'Big Buck Bunny',
        synopsis: 'A large, gentle rabbit is bullied by three mischievous woodland forest critters, leading to an inventive, comedic woodland showdown.',
        posterUrl: 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=500&auto=format&fit=crop&q=60',
        backdropUrl: 'https://images.unsplash.com/photo-1511447333015-45b65e60f6d5?w=1200&auto=format&fit=crop&q=80',
        genre: 'Animation',
        language: 'English',
        releaseYear: 2023,
        rating: 8.2,
        durationMinutes: 92,
        streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        ageRating: 'G',
      ),
      const VodMovie(
        id: 'vod_cosmos_odyssey',
        title: 'Cosmos: Infinite Odyssey',
        synopsis: 'A high-definition cinematic exploration into stellar nurseries, gravitational lensing, and black hole event horizons across the observable universe.',
        posterUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=500&auto=format&fit=crop&q=60',
        backdropUrl: 'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?w=1200&auto=format&fit=crop&q=80',
        genre: 'Documentary',
        language: 'English',
        releaseYear: 2024,
        rating: 9.1,
        durationMinutes: 130,
        streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
        ageRating: 'PG',
      ),
      const VodMovie(
        id: 'vod_cyber_horizon',
        title: 'Cyber Horizon 2049',
        synopsis: 'Tactical cyber operatives battle against rogue corporate autonomous neural nets in high-altitude Tokyo megastructures.',
        posterUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=500&auto=format&fit=crop&q=60',
        backdropUrl: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=1200&auto=format&fit=crop&q=80',
        genre: 'Action',
        language: 'English',
        releaseYear: 2023,
        rating: 7.9,
        durationMinutes: 125,
        streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
        ageRating: 'R',
      ),
      const VodMovie(
        id: 'vod_series_chronicles',
        title: 'Chronicles of Deep Space',
        synopsis: 'An intergalactic scientific vessel explores anomalies near the Perseus arm of the Milky Way.',
        posterUrl: 'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?w=500&auto=format&fit=crop&q=60',
        backdropUrl: 'https://images.unsplash.com/photo-1447433589675-4aaa569f3e05?w=1200&auto=format&fit=crop&q=80',
        genre: 'Series',
        language: 'English',
        releaseYear: 2025,
        rating: 8.8,
        durationMinutes: 50,
        streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
        isSeries: true,
        ageRating: 'PG-13',
        episodes: [
          VodEpisode(
            id: 'ep_1',
            seasonNumber: 1,
            episodeNumber: 1,
            title: 'Episode 1: The Singularity Signal',
            synopsis: 'First contact telemetry is received from an abandoned orbital relay.',
            durationMinutes: 48,
            streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
          ),
          VodEpisode(
            id: 'ep_2',
            seasonNumber: 1,
            episodeNumber: 2,
            title: 'Episode 2: Event Horizon',
            synopsis: 'The crew enters the gravity well of a dormant micro-quasar.',
            durationMinutes: 52,
            streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          ),
        ],
      ),
    ]);

    // Initial continue watching seed
    _watchProgress['vod_tears_of_steel'] = 1450; // 24m 10s
    _watchlistIds.add('vod_cosmos_odyssey');
  }

  VodMovie _enrichMovie(VodMovie base) {
    return base.copyWith(
      isWatchlisted: _watchlistIds.contains(base.id),
      watchProgressSeconds: _watchProgress[base.id] ?? 0,
    );
  }

  /// Toggle Watchlist membership
  void toggleWatchlist(String movieId) {
    if (_watchlistIds.contains(movieId)) {
      _watchlistIds.remove(movieId);
    } else {
      _watchlistIds.add(movieId);
    }
    notifyListeners();
  }

  bool isWatchlisted(String movieId) => _watchlistIds.contains(movieId);

  /// Save playback resume progress in seconds
  void updateProgress(String movieId, int positionSeconds) {
    _watchProgress[movieId] = positionSeconds;
    notifyListeners();
  }

  /// Find movie by ID
  VodMovie? getMovieById(String id) {
    final match = _catalog.where((m) => m.id == id);
    if (match.isEmpty) return null;
    return _enrichMovie(match.first);
  }

  /// Filter catalog by Genre and Query
  List<VodMovie> filterCatalog({String genre = 'All', String query = ''}) {
    var result = allMovies;

    if (genre == 'Series') {
      result = result.where((m) => m.isSeries).toList();
    } else if (genre != 'All') {
      result = result.where((m) => m.genre.toLowerCase() == genre.toLowerCase()).toList();
    }

    if (query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((m) => m.title.toLowerCase().contains(q) || m.synopsis.toLowerCase().contains(q)).toList();
    }

    return result;
  }
}

