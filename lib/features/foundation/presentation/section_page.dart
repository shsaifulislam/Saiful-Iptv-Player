import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';

class SectionPage extends StatelessWidget {
  const SectionPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.status,
    this.actionLabel,
    this.actionPath,
    this.accent = AppColors.secondary,
    super.key,
  });

  const SectionPage.liveTv({super.key})
      : title = 'Live TV',
        subtitle = 'Your channel lineup will appear here.',
        icon = Icons.live_tv_rounded,
        status = 'PLAYLIST REQUIRED',
        actionLabel = 'Add a playlist',
        actionPath = RouteNames.playlists,
        accent = AppColors.primary;

  const SectionPage.epg({super.key})
      : title = 'Programme guide',
        subtitle = 'The guide is ready to connect to a playlist.',
        icon = Icons.calendar_month_rounded,
        status = 'WAITING FOR SOURCE',
        actionLabel = 'View playlists',
        actionPath = RouteNames.playlists,
        accent = AppColors.tertiary;

  const SectionPage.movies({super.key})
      : title = 'Movies',
        subtitle = 'Movies from your connected sources will be listed here.',
        icon = Icons.movie_rounded,
        status = 'NO CONTENT',
        actionLabel = 'Add a playlist',
        actionPath = RouteNames.playlists,
        accent = AppColors.primary;

  const SectionPage.localVideo({super.key})
      : title = 'Local video',
        subtitle = 'Local media access is not enabled in this foundation.',
        icon = Icons.folder_open_rounded,
        status = 'NOT CONNECTED',
        accent = AppColors.info;

  const SectionPage.music({super.key})
      : title = 'Music',
        subtitle = 'Audio library integration is not enabled yet.',
        icon = Icons.music_note_rounded,
        status = 'NOT CONNECTED',
        accent = AppColors.secondary;

  const SectionPage.photos({super.key})
      : title = 'Photos',
        subtitle = 'Photo library integration is not enabled yet.',
        icon = Icons.photo_library_outlined,
        status = 'NOT CONNECTED',
        accent = AppColors.tertiary;

  const SectionPage.youtube({super.key})
      : title = 'YouTube',
        subtitle = 'Connect a source to browse video content here.',
        icon = Icons.smart_display_outlined,
        status = 'NOT CONNECTED',
        actionLabel = 'Open playlists',
        actionPath = RouteNames.playlists,
        accent = AppColors.primary;

  const SectionPage.favorites({super.key})
      : title = 'Favourites',
        subtitle = 'Favourite channels will be collected here.',
        icon = Icons.favorite_border_rounded,
        status = 'EMPTY',
        actionLabel = 'Browse live TV',
        actionPath = RouteNames.liveTV,
        accent = AppColors.primary;

  const SectionPage.history({super.key})
      : title = 'Recently watched',
        subtitle = 'Your viewing history will show up here.',
        icon = Icons.history_rounded,
        status = 'EMPTY',
        actionLabel = 'Browse live TV',
        actionPath = RouteNames.liveTV,
        accent = AppColors.info;

  const SectionPage.downloads({super.key})
      : title = 'Downloads',
        subtitle = 'Downloads are unavailable until storage is configured.',
        icon = Icons.download_outlined,
        status = 'NOT CONNECTED',
        accent = AppColors.secondary;

  const SectionPage.multiView({super.key})
      : title = 'Multi-view',
        subtitle = 'This stays disabled until the foundation completion gate passes.',
        icon = Icons.grid_view_rounded,
        status = 'DISABLED',
        accent = AppColors.tertiary;

  const SectionPage.player({super.key})
      : title = 'Player',
        subtitle = 'Playback is intentionally out of scope until the foundation passes.',
        icon = Icons.play_circle_outline_rounded,
        status = 'DISABLED',
        accent = AppColors.primary;

  const SectionPage.profile({super.key})
      : title = 'Profile',
        subtitle = 'Sign in is optional; cloud services need build configuration.',
        icon = Icons.person_outline_rounded,
        status = 'SIGNED OUT',
        actionLabel = 'Sign in',
        actionPath = RouteNames.login,
        accent = AppColors.info;

  const SectionPage.login({super.key})
      : title = 'Sign in',
        subtitle = 'Authentication UI is ready for provider configuration.',
        icon = Icons.lock_outline_rounded,
        status = 'CLOUD NOT CONFIGURED',
        accent = AppColors.primary;

  const SectionPage.onboarding({super.key})
      : title = 'Set up your library',
        subtitle = 'Add a playlist to get started.',
        icon = Icons.add_link_rounded,
        status = 'FIRST STEP',
        actionLabel = 'Add a playlist',
        actionPath = RouteNames.playlists,
        accent = AppColors.secondary;

  final String title;
  final String subtitle;
  final IconData icon;
  final String status;
  final String? actionLabel;
  final String? actionPath;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        Container(
          constraints: const BoxConstraints(minHeight: 220, maxHeight: 220),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: accent),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      status,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
              if (actionLabel != null && actionPath != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => context.go(actionPath!),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
