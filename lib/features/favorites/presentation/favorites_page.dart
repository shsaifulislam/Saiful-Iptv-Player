import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/components/channel_card.dart';
import '../../../shared/components/empty_state_view.dart';
import '../../../shared/components/poster_card.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<Map<String, dynamic>> _favoriteChannels = [
    {
      'num': 101,
      'name': 'Al Jazeera English',
      'group': 'News',
      'program': 'Newshour Live',
    },
    {
      'num': 103,
      'name': 'Sky Sports Main Event',
      'group': 'Sports',
      'program': 'Premier League Live',
    },
  ];

  final List<Map<String, dynamic>> _favoriteMovies = [
    {
      'title': 'Tears of Steel',
      'subtitle': '2024 â€¢ 1h 54m',
      'badge': '4K',
      'rating': 8.6,
    },
    {
      'title': 'Big Buck Bunny',
      'subtitle': '2023 â€¢ 1h 32m',
      'badge': 'HD',
      'rating': 8.2,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Items'),
            Tab(text: 'Live Channels'),
            Tab(text: 'Movies & VOD'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Items
          _buildAllTab(),
          // Channels Tab
          _buildChannelsTab(),
          // Movies Tab
          _buildMoviesTab(),
        ],
      ),
    );
  }

  Widget _buildAllTab() {
    if (_favoriteChannels.isEmpty && _favoriteMovies.isEmpty) {
      return EmptyStateView(
        title: 'No Favorites Yet',
        message: 'Tap the bookmark or star icon on any channel or movie to add it to your favorites.',
        icon: Icons.star_border_rounded,
        actionLabel: 'Browse Live TV',
        onActionTap: () => context.push(RouteNames.liveTV),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (_favoriteChannels.isNotEmpty) ...[
          Text('Favorite Channels (${_favoriteChannels.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _favoriteChannels.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final c = _favoriteChannels[index];
                return ChannelCard(
                  channelNumber: c['num'] as int,
                  channelName: c['name'] as String,
                  groupTitle: c['group'] as String,
                  currentProgram: c['program'] as String,
                  onTap: () => context.push(RouteNames.player),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
        ],
        if (_favoriteMovies.isNotEmpty) ...[
          Text('Favorite Movies (${_favoriteMovies.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _favoriteMovies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final m = _favoriteMovies[index];
                return PosterCard(
                  title: m['title'] as String,
                  subtitle: m['subtitle'] as String,
                  badgeText: m['badge'] as String,
                  rating: m['rating'] as double,
                  onTap: () => context.push(RouteNames.player),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChannelsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        childAspectRatio: 16 / 9,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: _favoriteChannels.length,
      itemBuilder: (context, index) {
        final c = _favoriteChannels[index];
        return ChannelCard(
          channelNumber: c['num'] as int,
          channelName: c['name'] as String,
          groupTitle: c['group'] as String,
          currentProgram: c['program'] as String,
          onTap: () => context.push(RouteNames.player),
        );
      },
    );
  }

  Widget _buildMoviesTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: _favoriteMovies.length,
      itemBuilder: (context, index) {
        final m = _favoriteMovies[index];
        return PosterCard(
          title: m['title'] as String,
          subtitle: m['subtitle'] as String,
          badgeText: m['badge'] as String,
          rating: m['rating'] as double,
          onTap: () => context.push(RouteNames.player),
        );
      },
    );
  }
}

