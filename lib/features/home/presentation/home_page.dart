import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/components/category_chips.dart';
import '../../../shared/components/channel_card.dart';
import '../../../shared/components/hero_banner.dart';
import '../../../shared/components/horizontal_carousel.dart';
import '../../../shared/components/poster_card.dart';
import '../../../shared/widgets/tv_focus_wrapper.dart';
import '../../playlists/presentation/playlists_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _selectedCategory = 'All';

  static const _categories = [
    'All',
    'Live TV',
    'Movies',
    'Series',
    'Sports',
    'News',
    'Music',
    'Documentary',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Top Bar with Search & Profile actions
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'SAIFUL IPTV',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TvFocusWrapper(
                    onTap: () => context.push(RouteNames.search),
                    borderRadius: BorderRadius.circular(20),
                    child: IconButton(
                      onPressed: () => context.push(RouteNames.search),
                      icon: const Icon(Icons.search_rounded),
                      tooltip: 'Search channels, movies and shows',
                    ),
                  ),
                  const SizedBox(width: 8),
                  TvFocusWrapper(
                    onTap: () => context.push(RouteNames.notifications),
                    borderRadius: BorderRadius.circular(20),
                    child: IconButton(
                      onPressed: () => context.push(RouteNames.notifications),
                      icon: const Icon(Icons.notifications_none_rounded),
                      tooltip: 'Announcements and notifications',
                    ),
                  ),
                  const SizedBox(width: 8),
                  TvFocusWrapper(
                    onTap: () => context.push(RouteNames.profile),
                    borderRadius: BorderRadius.circular(20),
                    child: IconButton(
                      onPressed: () => context.push(RouteNames.profile),
                      icon: const Icon(Icons.account_circle_outlined),
                      tooltip: 'Account profile and cloud sync',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Category Chips
          SliverToBoxAdapter(
            child: CategoryChips(
              categories: _categories,
              selectedCategory: _selectedCategory,
              onCategorySelected: (cat) {
                setState(() => _selectedCategory = cat);
                if (cat == 'Live TV') context.push(RouteNames.liveTV);
                if (cat == 'Movies') context.push(RouteNames.movies);
                if (cat == 'Series') context.push(RouteNames.series);
                if (cat == 'Music') context.push(RouteNames.music);
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

          // Hero Banner
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: HeroBanner(
                title: 'Welcome to Saiful IPTV Player',
                synopsis:
                    'Connect your M3U playlist, Xtream Codes portal, or local media folders to enjoy live streaming, movie catalogs, and cloud-synced playback across all your devices.',
                badgeText: 'ENTERTAINMENT HUB',
                genres: const ['4K UHD', 'Multi-Audio', 'EPG Guide'],
                onPlayTap: () => context.push(RouteNames.liveTV),
                onInfoTap: () => context.push(RouteNames.playlists),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

          // Continue Watching Carousel
          SliverToBoxAdapter(
            child: HorizontalCarousel(
              title: 'Continue Watching',
              subtitle: 'Pick up right where you left off',
              height: 230,
              itemCount: 2,
              onSeeAllTap: () => context.push(RouteNames.history),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return PosterCard(
                    title: 'Sample Stream #1',
                    subtitle: 'Resume from 24:15',
                    badgeText: 'HD',
                    progressPercentage: 0.45,
                    onTap: () => context.push(RouteNames.player),
                  );
                }
                return PosterCard(
                  title: 'Sports Highlight Reel',
                  subtitle: 'Resume from 52:10',
                  badgeText: 'FHD',
                  progressPercentage: 0.78,
                  onTap: () => context.push(RouteNames.player),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

          // Live TV Channels Carousel
          SliverToBoxAdapter(
            child: HorizontalCarousel(
              title: 'Live TV Channels',
              subtitle: 'Top channels from your active playlist',
              height: 145,
              itemCount: 4,
              onSeeAllTap: () => context.push(RouteNames.liveTV),
              itemBuilder: (context, index) {
                final names = [
                  'Al Jazeera English',
                  'BBC News HD',
                  'Sky Sports Main Event',
                  'Discovery Science'
                ];
                final programs = [
                  'Newshour Live',
                  'Global Business Report',
                  'Premier League Preview',
                  'How the Universe Works'
                ];
                return ChannelCard(
                  channelNumber: 101 + index,
                  channelName: names[index],
                  groupTitle: index < 2 ? 'News' : (index == 2 ? 'Sports' : 'Documentary'),
                  currentProgram: programs[index],
                  programProgress: 0.35 + (index * 0.15),
                  onTap: () => context.push(RouteNames.player),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

          // My Favorites Carousel
          SliverToBoxAdapter(
            child: HorizontalCarousel(
              title: 'My Favorites',
              subtitle: 'Quick access to your pinned streams and movies',
              height: 230,
              itemCount: 3,
              onSeeAllTap: () => context.push(RouteNames.favorites),
              itemBuilder: (context, index) {
                final titles = [
                  'Tears of Steel (Sci-Fi)',
                  'Big Buck Bunny (Animation)',
                  'Cosmos Odysseys (Documentary)'
                ];
                return PosterCard(
                  title: titles[index],
                  subtitle: 'Licensed Open Content',
                  badgeText: '4K',
                  rating: 8.5 + (index * 0.4),
                  onTap: () => context.push(RouteNames.player),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

          // Recently Watched Carousel
          SliverToBoxAdapter(
            child: HorizontalCarousel(
              title: 'Recently Watched',
              subtitle: 'Viewing history recorded locally and on cloud',
              height: 145,
              itemCount: 2,
              onSeeAllTap: () => context.push(RouteNames.history),
              itemBuilder: (context, index) {
                return ChannelCard(
                  channelNumber: 204 + index,
                  channelName: index == 0 ? 'Bloomberg TV' : 'EuroNews HD',
                  groupTitle: 'International News',
                  currentProgram: 'Market Movers Live',
                  onTap: () => context.push(RouteNames.player),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

          // Playlist Setup Callout (If no playlists loaded)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1D2824)
                      : const Color(0xFFE6EFEA),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.playlist_add_check_circle_outlined,
                        color: AppColors.secondary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Manage Your Playlists',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add M3U URLs, upload local playlist files, or configure Xtream Codes credentials.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.onSurfaceVariantDark
                                  : AppColors.onSurfaceVariantLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    TvFocusWrapper(
                      onTap: () => context.push(RouteNames.playlists),
                      child: FilledButton(
                        onPressed: () => context.push(RouteNames.playlists),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Add Playlist'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }
}
