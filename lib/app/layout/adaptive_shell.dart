import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import '../../app/theme/app_colors.dart';
import '../responsive/breakpoints.dart';

class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  static const _destinations = <_Destination>[
    _Destination('Home', Icons.home_outlined, Icons.home_rounded, RouteNames.home),
    _Destination(
      'Live TV',
      Icons.live_tv_outlined,
      Icons.live_tv_rounded,
      RouteNames.liveTV,
    ),
    _Destination(
      'Playlists',
      Icons.video_library_outlined,
      Icons.video_library_rounded,
      RouteNames.playlists,
    ),
    _Destination(
      'Movies',
      Icons.movie_outlined,
      Icons.movie_rounded,
      RouteNames.movies,
    ),
    _Destination(
      'Settings',
      Icons.settings_outlined,
      Icons.settings_rounded,
      RouteNames.settings,
    ),
  ];

  int get _selectedIndex {
    final index = _destinations.indexWhere(
      (destination) =>
          location == destination.path ||
          (destination.path != RouteNames.home &&
              location.startsWith('${destination.path}/')),
    );
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < Breakpoints.tablet;
          return compact
              ? _buildCompact(context)
              : _buildExpanded(context, constraints.maxWidth);
        },
      );

  Widget _buildCompact(BuildContext context) => Scaffold(
        appBar: _buildAppBar(context),
        body: SafeArea(top: false, child: child),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              context.go(_destinations[index].path),
          destinations: [
            for (final destination in _destinations)
              NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: destination.label,
              ),
          ],
        ),
      );

  Widget _buildExpanded(BuildContext context, double width) => Scaffold(
        appBar: _buildAppBar(context),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              extended: width >= Breakpoints.desktop,
              minExtendedWidth: 216,
              labelType: width >= Breakpoints.desktop
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              onDestinationSelected: (index) =>
                  context.go(_destinations[index].path),
              leading: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Icon(
                  Icons.graphic_eq_rounded,
                  size: 30,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              destinations: [
                for (final destination in _destinations)
                  NavigationRailDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: Text(destination.label),
                  ),
              ],
            ),
            VerticalDivider(
              width: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Expanded(child: SafeArea(top: false, child: child)),
          ],
        ),
      );

  PreferredSizeWidget _buildAppBar(BuildContext context) => AppBar(
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.graphic_eq_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('SAIFUL'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () => context.go(RouteNames.search),
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.go(RouteNames.profile),
            icon: const Icon(Icons.person_outline_rounded),
          ),
          const SizedBox(width: 8),
        ],
      );
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon, this.path);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
}
