import 'package:flutter_test/flutter_test.dart';
import '../../lib/features/youtube/services/youtube_service.dart';
import '../../lib/services/advanced/advanced_features_service.dart';
import '../../lib/features/movies/services/vod_service.dart';

void main() {
  group('Entertainment Features Unit Tests', () {
    test('YouTube Video ID extraction handles various URL formats', () {
      expect(
        YoutubeService.extractVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
      expect(
        YoutubeService.extractVideoId('https://youtu.be/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
      expect(
        YoutubeService.extractVideoId('https://www.youtube.com/shorts/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('Parental control age rating hierarchy checks', () {
      final service = AdvancedFeaturesService.instance;
      service.setParentalControl(enabled: true, maxRating: 'PG-13');

      expect(service.isContentAllowed('G'), isTrue);
      expect(service.isContentAllowed('PG'), isTrue);
      expect(service.isContentAllowed('PG-13'), isTrue);
      expect(service.isContentAllowed('R'), isFalse);
      expect(service.isContentAllowed('NC-17'), isFalse);
    });

    test('VOD Service watchlist and continue watching calculation', () {
      final vod = VodService.instance;
      expect(vod.allMovies.isNotEmpty, isTrue);
      expect(vod.continueWatching.isNotEmpty, isTrue);

      final firstMovie = vod.allMovies.first;
      vod.toggleWatchlist(firstMovie.id);
      expect(vod.isWatchlisted(firstMovie.id), isTrue);
    });
  });
}

