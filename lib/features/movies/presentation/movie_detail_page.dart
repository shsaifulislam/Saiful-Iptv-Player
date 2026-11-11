import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/tv_focus_wrapper.dart';
import '../models/vod_movie.dart';
import '../services/vod_service.dart';

class MovieDetailPage extends StatefulWidget {
  const MovieDetailPage({required this.movieId, super.key});

  final String movieId;

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  final VodService _vodService = VodService.instance;

  @override
  void initState() {
    super.initState();
    _vodService.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _vodService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final movie = _vodService.getMovieById(widget.movieId) ??
        VodMovie(
          id: widget.movieId,
          title: 'Tears of Steel',
          synopsis: 'In a dystopian future, scientists explore alternate realities and synthetic cybernetic enhancements.',
          posterUrl: '',
          backdropUrl: '',
          genre: 'Sci-Fi',
          releaseYear: 2024,
          durationMinutes: 114,
          streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
        );

    final isWatchlisted = _vodService.isWatchlisted(movie.id);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Collapsible Backdrop App Bar
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            leading: TvFocusWrapper(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isWatchlisted ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                  color: isWatchlisted ? AppColors.tertiary : Colors.white,
                ),
                tooltip: isWatchlisted ? 'Remove from Watchlist' : 'Add to Watchlist',
                onPressed: () {
                  _vodService.toggleWatchlist(movie.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isWatchlisted ? 'Removed from Watchlist' : 'Saved to Watchlist'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: const Color(0xFF141923),
                    child: Center(
                      child: Icon(
                        Icons.movie_filter_rounded,
                        size: 90,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x99111815), Color(0xFF0B0E14)],
                        stops: [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Movie Details Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          movie.genre.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white38),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          movie.ageRating,
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        movie.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    movie.title,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${movie.releaseYear} • ${movie.durationMinutes} min • ${movie.language} • 4K HDR',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons (Play / Resume)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            context.push(RouteNames.player);
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 24),
                          label: Text(
                            movie.hasProgress
                                ? 'Resume Playback (${movie.watchProgressSeconds ~/ 60}m)'
                                : 'Play Movie',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                        onPressed: () => _vodService.toggleWatchlist(movie.id),
                        icon: Icon(isWatchlisted ? Icons.check_rounded : Icons.add_rounded),
                        label: Text(isWatchlisted ? 'In Watchlist' : 'Watchlist'),
                      ),
                    ],
                  ),

                  if (movie.hasProgress) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: movie.progressRatio,
                      color: AppColors.primary,
                      backgroundColor: Colors.white12,
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Text('Synopsis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    movie.synopsis,
                    style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.white70),
                  ),

                  // TV Series Episodes
                  if (movie.isSeries && movie.episodes.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text('Episodes (${movie.episodes.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    for (final ep in movie.episodes)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                'E${ep.episodeNumber}',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                          title: Text(ep.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text('${ep.durationMinutes} min', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          trailing: const Icon(Icons.play_circle_outline_rounded, color: Colors.white70),
                          onTap: () => context.push(RouteNames.player),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
