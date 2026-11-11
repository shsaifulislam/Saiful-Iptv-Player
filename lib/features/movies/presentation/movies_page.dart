import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/components/category_chips.dart';
import '../../../shared/components/empty_state_view.dart';
import '../../../shared/components/poster_card.dart';
import '../../../shared/widgets/tv_focus_wrapper.dart';
import '../models/movie_portal_bookmark.dart';
import '../models/vod_movie.dart';
import '../services/movie_portal_service.dart';
import '../services/vod_service.dart';
import 'movie_portal_dialog.dart';

class MoviesPage extends StatefulWidget {
  const MoviesPage({super.key});

  @override
  State<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends State<MoviesPage> {
  final VodService _vodService = VodService.instance;
  final MoviePortalService _portalService = MoviePortalService.instance;
  String _selectedGenre = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vodService.addListener(_onUpdate);
    _portalService.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _vodService.removeListener(_onUpdate);
    _portalService.removeListener(_onUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final movies = _vodService.filterCatalog(genre: _selectedGenre, query: _searchQuery);
    final continueWatching = _vodService.continueWatching;
    final portals = _portalService.portals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movies & VOD Hub'),
        actions: [
          TvFocusWrapper(
            onTap: () => context.push(RouteNames.downloads),
            child: TextButton.icon(
              onPressed: () => context.push(RouteNames.downloads),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Downloads'),
            ),
          ),
          const SizedBox(width: 8),
          TvFocusWrapper(
            onTap: () => context.push(RouteNames.tvSeries),
            child: TextButton.icon(
              onPressed: () => context.push(RouteNames.tvSeries),
              icon: const Icon(Icons.video_library_rounded, size: 18),
              label: const Text('TV Series'),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search movies by title, actor, or genre...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  isDense: true,
                ),
              ),
            ),
          ),

          // Genre Selector
          SliverToBoxAdapter(
            child: CategoryChips(
              categories: _vodService.genres,
              selectedCategory: _selectedGenre,
              onCategorySelected: (cat) => setState(() => _selectedGenre = cat),
            ),
          ),

          // Movie Web Portals & Download Sites Section
          if (_searchQuery.isEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.language_rounded, color: Colors.cyanAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Movie Web Portals & Download Hub',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => AddMoviePortalDialog.show(context),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Portal'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: Colors.cyanAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  scrollDirection: Axis.horizontal,
                  itemCount: portals.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final portal = portals[index];
                    return TvFocusWrapper(
                      onTap: () => MoviePortalDialog.show(context, portal),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 250,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: index == 0
                                ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
                                : index == 1
                                    ? [const Color(0xFF831843), const Color(0xFF0F172A)]
                                    : [const Color(0xFF14241E), const Color(0xFF0F172A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: index == 0
                                ? Colors.blue.withOpacity(0.4)
                                : index == 1
                                    ? Colors.pink.withOpacity(0.4)
                                    : Colors.cyan.withOpacity(0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.open_in_new_rounded,
                                      size: 16,
                                      color: index == 0 ? Colors.lightBlueAccent : Colors.pinkAccent,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      portal.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    portal.category,
                                    style: const TextStyle(fontSize: 9, color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              portal.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  portal.url.replaceFirst('https://', ''),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white60),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // Continue Watching Section
          if (_searchQuery.isEmpty && continueWatching.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Row(
                  children: const [
                    Icon(Icons.play_circle_outline_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Continue Watching',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                  scrollDirection: Axis.horizontal,
                  itemCount: continueWatching.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final item = continueWatching[index];
                    return TvFocusWrapper(
                      onTap: () => context.push('/movies/${item.id}'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 220,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141923),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.durationMinutes} min • Resume ${(item.watchProgressSeconds ~/ 60)}m',
                              style: const TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: item.progressRatio,
                              color: AppColors.primary,
                              backgroundColor: Colors.white24,
                              minHeight: 4,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // Movie Catalog Grid Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Text(
                '$_selectedGenre Movies (${movies.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Movie Catalog Grid
          if (movies.isEmpty)
            SliverFillRemaining(
              child: EmptyStateView(
                title: 'No Movies Found',
                message: _searchQuery.isNotEmpty
                    ? 'No licensed title matched "$_searchQuery".'
                    : 'No movies available in category "$_selectedGenre".',
                icon: Icons.movie_filter_outlined,
                actionLabel: 'Reset Filters',
                onActionTap: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedGenre = 'All';
                  });
                },
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final movie = movies[index];
                    return TvFocusWrapper(
                      onTap: () => context.push('/movies/${movie.id}'),
                      borderRadius: BorderRadius.circular(8),
                      child: PosterCard(
                        title: movie.title,
                        subtitle: '${movie.releaseYear} • ${movie.genre}',
                        rating: movie.rating,
                        isWatchlisted: movie.isWatchlisted,
                        onWatchlistTap: () => _vodService.toggleWatchlist(movie.id),
                        onTap: () => context.push('/movies/${movie.id}'),
                      ),
                    );
                  },
                  childCount: movies.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
