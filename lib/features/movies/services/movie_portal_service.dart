import 'package:flutter/foundation.dart';
import '../models/movie_portal_bookmark.dart';

/// Service managing movie download and streaming web portals
class MoviePortalService extends ChangeNotifier {
  static final MoviePortalService instance = MoviePortalService._internal();

  MoviePortalService._internal() {
    _initDefaultPortals();
  }

  final List<MoviePortalBookmark> _portals = [];

  List<MoviePortalBookmark> get portals => List.unmodifiable(_portals);

  void _initDefaultPortals() {
    _portals.addAll([
      MoviePortalBookmark(
        id: 'portal_movielinkbd',
        title: 'MovieLink BD',
        url: 'https://4vyu23.movielinkbd.at/',
        description: 'Bangla & South Asian Movie Downloads & Web Portal',
        category: 'Bangla & International',
        iconUrl: 'https://cdn-icons-png.flaticon.com/512/2503/2503508.png',
        addedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      MoviePortalBookmark(
        id: 'portal_hdhub4u',
        title: 'HDHub4u',
        url: 'https://new12.hdhub4u.cl/?utm=mn1',
        description: 'Dual Audio & HD Movies, Series & Direct Download Links',
        category: 'Dual Audio & HD Hub',
        iconUrl: 'https://cdn-icons-png.flaticon.com/512/3163/3163478.png',
        addedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      MoviePortalBookmark(
        id: 'portal_archive_movies',
        title: 'Internet Archive Feature Films',
        url: 'https://archive.org/details/feature_films',
        description: 'Free public domain & licensed cinema archive',
        category: 'Classic & Public Domain',
        iconUrl: 'https://cdn-icons-png.flaticon.com/512/2991/2991148.png',
        addedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      MoviePortalBookmark(
        id: 'portal_blender_open',
        title: 'Blender Open Movies',
        url: 'https://studio.blender.org/films/',
        description: 'Licensed 4K animated open films & 4K media downloads',
        category: 'Animation & 4K',
        iconUrl: 'https://cdn-icons-png.flaticon.com/512/888/888879.png',
        addedAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ]);
  }

  void addPortal({
    required String title,
    required String url,
    String? description,
    String? category,
  }) {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return;

    final newPortal = MoviePortalBookmark(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim().isEmpty ? 'Custom Portal' : title.trim(),
      url: cleanUrl,
      description: description?.trim() ?? 'User added movie portal',
      category: category?.trim() ?? 'My Bookmarks',
      isUserAdded: true,
      addedAt: DateTime.now(),
    );

    _portals.insert(0, newPortal);
    notifyListeners();
  }

  void removePortal(String id) {
    _portals.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  MoviePortalBookmark? getById(String id) {
    try {
      return _portals.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

