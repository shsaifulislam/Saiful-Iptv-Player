import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_page.dart';
import '../../features/downloads/presentation/downloads_page.dart';
import '../../features/epg/presentation/epg_guide_page.dart';
import '../../features/favorites/presentation/favorites_page.dart';
import '../../features/foundation/presentation/section_page.dart';
import '../../features/history/presentation/watch_history_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/live_tv/presentation/channel_categories_page.dart';
import '../../features/live_tv/presentation/channel_detail_page.dart';
import '../../features/live_tv/presentation/live_tv_page.dart';
import '../../features/local_video/presentation/local_video_page.dart';
import '../../features/movies/presentation/movie_detail_page.dart';
import '../../features/movies/presentation/movies_page.dart';
import '../../features/movies/presentation/tv_series_page.dart';
import '../../features/multi_view/presentation/multi_view_page.dart';
import '../../features/music/presentation/music_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/photos/presentation/photos_page.dart';
import '../../features/playback/presentation/fullscreen_player_page.dart';
import '../../features/playlists/presentation/playlists_page.dart';
import '../../features/profile/presentation/device_management_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/search/presentation/search_page.dart';
import '../../features/settings/presentation/about_support_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/youtube/presentation/youtube_hub_page.dart';
import '../layout/adaptive_shell.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: RouteNames.home,
    routes: [
      // Standalone Fullscreen Player route (no navigation shell)
      GoRoute(
        path: RouteNames.player,
        name: RouteNames.playerName,
        builder: (context, state) => const FullscreenPlayerPage(),
      ),

      // Adaptive Shell Navigation Routes
      ShellRoute(
        builder: (context, state, child) => AdaptiveShell(
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: RouteNames.home,
            name: RouteNames.homeName,
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: RouteNames.liveTV,
            name: RouteNames.liveTVName,
            builder: (context, state) => const LiveTvPage(),
          ),
          GoRoute(
            path: RouteNames.channelCategories,
            name: RouteNames.channelCategoriesName,
            builder: (context, state) => const ChannelCategoriesPage(),
          ),
          GoRoute(
            path: RouteNames.channelDetail,
            name: RouteNames.channelDetailName,
            builder: (context, state) => ChannelDetailPage(
              channelId: state.pathParameters['id'] ?? '',
            ),
          ),
          GoRoute(
            path: RouteNames.playlists,
            name: RouteNames.playlistsName,
            builder: (context, state) => const PlaylistsPage(),
          ),
          GoRoute(
            path: '/playlists/add',
            name: 'addPlaylist',
            builder: (context, state) => const PlaylistsPage(addOnOpen: true),
          ),
          GoRoute(
            path: RouteNames.playlistDetail,
            name: RouteNames.playlistDetailName,
            builder: (context, state) => const PlaylistsPage(),
          ),
          GoRoute(
            path: RouteNames.epg,
            name: RouteNames.epgName,
            builder: (context, state) => const EpgGuidePage(),
          ),
          GoRoute(
            path: RouteNames.movies,
            name: RouteNames.moviesName,
            builder: (context, state) => const MoviesPage(),
          ),
          GoRoute(
            path: RouteNames.movieDetail,
            name: RouteNames.movieDetailName,
            builder: (context, state) => MovieDetailPage(
              movieId: state.pathParameters['id'] ?? '',
            ),
          ),
          GoRoute(
            path: RouteNames.series,
            name: RouteNames.seriesName,
            builder: (context, state) => const TvSeriesPage(),
          ),
          GoRoute(
            path: RouteNames.localVideo,
            name: RouteNames.localVideoName,
            builder: (context, state) => const LocalVideoPage(),
          ),
          GoRoute(
            path: RouteNames.music,
            name: RouteNames.musicName,
            builder: (context, state) => const MusicPage(),
          ),
          GoRoute(
            path: RouteNames.photos,
            name: RouteNames.photosName,
            builder: (context, state) => const PhotosPage(),
          ),
          GoRoute(
            path: RouteNames.youtube,
            name: RouteNames.youtubeName,
            builder: (context, state) => const YoutubeHubPage(),
          ),
          GoRoute(
            path: RouteNames.favorites,
            name: RouteNames.favoritesName,
            builder: (context, state) => const FavoritesPage(),
          ),
          GoRoute(
            path: RouteNames.history,
            name: RouteNames.historyName,
            builder: (context, state) => const WatchHistoryPage(),
          ),
          GoRoute(
            path: RouteNames.downloads,
            name: RouteNames.downloadsName,
            builder: (context, state) => const DownloadsPage(),
          ),
          GoRoute(
            path: RouteNames.multiView,
            name: RouteNames.multiViewName,
            builder: (context, state) => const MultiViewPage(),
          ),
          GoRoute(
            path: RouteNames.search,
            name: RouteNames.searchName,
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: RouteNames.profile,
            name: RouteNames.profileName,
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: RouteNames.devices,
            name: RouteNames.devicesName,
            builder: (context, state) => const DeviceManagementPage(),
          ),
          GoRoute(
            path: RouteNames.settings,
            name: RouteNames.settingsName,
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: RouteNames.notifications,
            name: RouteNames.notificationsName,
            builder: (context, state) => const NotificationsPage(),
          ),
          GoRoute(
            path: RouteNames.about,
            name: RouteNames.aboutName,
            builder: (context, state) => const AboutSupportPage(),
          ),
          GoRoute(
            path: RouteNames.login,
            name: RouteNames.loginName,
            builder: (context, state) => const AuthPage(),
          ),
          GoRoute(
            path: RouteNames.onboarding,
            name: RouteNames.onboardingName,
            builder: (context, state) => const SectionPage.onboarding(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.uri.path}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(RouteNames.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );

  return router;
});
