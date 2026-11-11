import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/components/category_chips.dart';
import '../../../shared/components/channel_card.dart';
import '../../../shared/components/empty_state_view.dart';
import '../../../shared/components/poster_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  String _query = '';
  String _filter = 'All';

  static const _filters = ['All', 'Live TV', 'Movies', 'Series', 'Sections'];

  static const _searchIndex = [
    {'title': 'Al Jazeera English HD', 'type': 'Live TV', 'group': 'News', 'path': '/channels/c1'},
    {'title': 'BBC News HD', 'type': 'Live TV', 'group': 'News', 'path': '/channels/c2'},
    {'title': 'Sky Sports Main Event', 'type': 'Live TV', 'group': 'Sports', 'path': '/channels/c3'},
    {'title': 'Tears of Steel', 'type': 'Movies', 'group': 'Sci-Fi', 'path': '/movies/m1'},
    {'title': 'Big Buck Bunny', 'type': 'Movies', 'group': 'Animation', 'path': '/movies/m2'},
    {'title': 'Cosmos: Infinite Odyssey', 'type': 'Movies', 'group': 'Documentary', 'path': '/movies/m3'},
    {'title': 'Chronicles of Earth', 'type': 'Series', 'group': 'Sci-Fi', 'path': RouteNames.series},
    {'title': 'Detectives of Bengal', 'type': 'Series', 'group': 'Mystery', 'path': RouteNames.series},
    {'title': 'EPG Program Guide', 'type': 'Sections', 'group': 'Navigation', 'path': RouteNames.epg},
    {'title': 'Playlists Manager', 'type': 'Sections', 'group': 'Navigation', 'path': RouteNames.playlists},
    {'title': 'Offline Downloads', 'type': 'Sections', 'group': 'Navigation', 'path': RouteNames.downloads},
    {'title': 'Multi-View 4-Screen', 'type': 'Sections', 'group': 'Navigation', 'path': RouteNames.multiView},
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _searchIndex.where((item) {
      final matchesFilter = _filter == 'All' || item['type'] == _filter;
      final matchesQuery = _query.isEmpty ||
          item['title']!.toLowerCase().contains(_query.toLowerCase()) ||
          item['group']!.toLowerCase().contains(_query.toLowerCase());
      return matchesFilter && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Everything'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (val) => setState(() => _query = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search channels, movies, series, or sections...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          CategoryChips(
            categories: _filters,
            selectedCategory: _filter,
            onCategorySelected: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: results.isEmpty
                ? EmptyStateView(
                    title: 'No Results Found',
                    message: 'We could not find anything matching "$_query". Try another keyword.',
                    icon: Icons.search_off_rounded,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = results[index];
                      final type = item['type']!;

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: type == 'Live TV'
                                ? AppColors.primary.withOpacity(0.15)
                                : (type == 'Movies'
                                    ? AppColors.secondary.withOpacity(0.15)
                                    : Colors.white12),
                            child: Icon(
                              type == 'Live TV'
                                  ? Icons.live_tv_rounded
                                  : (type == 'Movies'
                                      ? Icons.movie_outlined
                                      : (type == 'Series'
                                          ? Icons.tv_rounded
                                          : Icons.arrow_outward_rounded)),
                              color: type == 'Live TV'
                                  ? AppColors.primary
                                  : (type == 'Movies'
                                      ? AppColors.secondary
                                      : Colors.white70),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item['title']!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '$type â€¢ ${item['group']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push(item['path']!),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
