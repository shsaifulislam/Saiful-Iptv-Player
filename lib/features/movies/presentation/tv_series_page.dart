import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/components/category_chips.dart';
import '../../../shared/components/empty_state_view.dart';
import '../../../shared/components/poster_card.dart';

class TvSeriesPage extends StatefulWidget {
  const TvSeriesPage({super.key});

  @override
  State<TvSeriesPage> createState() => _TvSeriesPageState();
}

class _TvSeriesPageState extends State<TvSeriesPage> {
  String _selectedGenre = 'All';

  static const _sampleSeries = [
    {
      'id': 's1',
      'title': 'Chronicles of Earth',
      'genre': 'Sci-Fi',
      'seasons': 3,
      'episodes': 24,
      'rating': 9.2,
    },
    {
      'id': 's2',
      'title': 'The Northern Realm',
      'genre': 'Drama',
      'seasons': 5,
      'episodes': 48,
      'rating': 8.9,
    },
    {
      'id': 's3',
      'title': 'Detectives of Bengal',
      'genre': 'Mystery',
      'seasons': 2,
      'episodes': 16,
      'rating': 9.0,
    },
    {
      'id': 's4',
      'title': 'Cyber Protocol',
      'genre': 'Thriller',
      'seasons': 1,
      'episodes': 8,
      'rating': 8.5,
    },
    {
      'id': 's5',
      'title': 'Laugh Track Stories',
      'genre': 'Comedy',
      'seasons': 4,
      'episodes': 40,
      'rating': 7.8,
    },
    {
      'id': 's6',
      'title': 'Wild Frontiers',
      'genre': 'Documentary',
      'seasons': 2,
      'episodes': 12,
      'rating': 9.4,
    },
  ];

  static const _genres = [
    'All',
    'Sci-Fi',
    'Drama',
    'Mystery',
    'Thriller',
    'Comedy',
    'Documentary',
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _sampleSeries.where((s) {
      return _selectedGenre == 'All' || s['genre'] == _selectedGenre;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('TV Series'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push(RouteNames.search),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          CategoryChips(
            categories: _genres,
            selectedCategory: _selectedGenre,
            onCategorySelected: (genre) => setState(() => _selectedGenre = genre),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyStateView(
                    title: 'No Series Found',
                    message: 'No TV series matching the selected category.',
                    icon: Icons.tv_off_rounded,
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 1200
                          ? 6
                          : (constraints.maxWidth > 900
                              ? 5
                              : (constraints.maxWidth > 680 ? 4 : (constraints.maxWidth > 450 ? 3 : 2)));

                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 2 / 3,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return PosterCard(
                            title: item['title'] as String,
                            subtitle: '${item['seasons']} Seasons â€¢ ${item['episodes']} Ep',
                            badgeText: 'SERIES',
                            rating: item['rating'] as double,
                            onTap: () {
                              _showEpisodesModal(context, item['title'] as String, item['seasons'] as int);
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showEpisodesModal(BuildContext context, String title, int seasons) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Season 1 â€¢ 8 Episodes available',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.onSurfaceVariantDark
                          : AppColors.onSurfaceVariantLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: 8,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final epNumber = index + 1;
                        return ListTile(
                          leading: Text(
                            'E$epNumber',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text('Episode $epNumber: The Discovery'),
                          subtitle: const Text('48 min â€¢ 1080p â€¢ English 5.1'),
                          trailing: const Icon(Icons.play_circle_fill_rounded,
                              color: AppColors.primary, size: 28),
                          onTap: () {
                            Navigator.of(context).pop();
                            context.push(RouteNames.player);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

