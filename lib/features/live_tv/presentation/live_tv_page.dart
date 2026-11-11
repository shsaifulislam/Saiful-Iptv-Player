import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/components/category_chips.dart';
import '../../../shared/components/channel_card.dart';
import '../../../shared/components/empty_state_view.dart';
import '../../../shared/widgets/tv_focus_wrapper.dart';
import '../../iptv/models/iptv_channel.dart';
import '../../iptv/services/playlist_manager.dart';

class LiveTvPage extends StatefulWidget {
  const LiveTvPage({super.key});

  @override
  State<LiveTvPage> createState() => _LiveTvPageState();
}

class _LiveTvPageState extends State<LiveTvPage> {
  final PlaylistManager _manager = PlaylistManager.instance;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _manager.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _manager.removeListener(_onUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final categories = _manager.categories;
    final channels = _manager.filterChannels(category: _selectedCategory, query: _searchQuery);
    final activeChannel = _manager.activeChannel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live TV'),
        actions: [
          TvFocusWrapper(
            onTap: () => context.push(RouteNames.playlists),
            child: TextButton.icon(
              onPressed: () => context.push(RouteNames.playlists),
              icon: const Icon(Icons.playlist_play_rounded, size: 18),
              label: const Text('Playlists'),
            ),
          ),
          const SizedBox(width: 8),
          TvFocusWrapper(
            onTap: () => context.push(RouteNames.epg),
            child: TextButton.icon(
              onPressed: () => context.push(RouteNames.epg),
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: const Text('EPG Guide'),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search channel name, group, or show...',
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
              ],
            ),
          ),

          // Categories horizontal bar
          CategoryChips(
            categories: categories,
            selectedCategory: _selectedCategory,
            onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
          ),
          const SizedBox(height: 16),

          // Channel Grid
          Expanded(
            child: channels.isEmpty
                ? EmptyStateView(
                    title: 'No Channels Found',
                    message: _searchQuery.isNotEmpty
                        ? 'No channel matches "$_searchQuery".'
                        : 'No channels available in category "$_selectedCategory".',
                    icon: Icons.tv_off_rounded,
                    actionLabel: 'Reset Filters',
                    onActionTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _selectedCategory = 'All';
                      });
                    },
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 1200
                          ? 4
                          : (constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 540 ? 2 : 1));

                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 16 / 9,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: channels.length,
                        itemBuilder: (context, index) {
                          final channel = channels[index];
                          final currentProg = _manager.getCurrentProgram(channel.tvgId);
                          final isFav = _manager.isChannelFavorite(channel.id);

                          return ChannelCard(
                            channelNumber: index + 1,
                            channelName: channel.name,
                            groupTitle: channel.groupTitle,
                            currentProgram: currentProg?.title ?? 'Live Broadcast',
                            programProgress: currentProg?.progressRatio() ?? 0.5,
                            onTap: () {
                              _manager.setActiveChannel(channel);
                              context.push(RouteNames.player);
                            },
                          );
                        },
                      );
                    },
                  ),
          ),

          // Mini Player Dock at Bottom
          if (activeChannel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF141923),
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.live_tv_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                activeChannel.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          Text(
                            _manager.getCurrentProgram(activeChannel.tvgId)?.title ?? 'Live Feed',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
                      tooltip: 'Previous Channel',
                      onPressed: () => _manager.previousChannel(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 38),
                      tooltip: 'Open Fullscreen Player',
                      onPressed: () => context.push(RouteNames.player),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                      tooltip: 'Next Channel',
                      onPressed: () => _manager.nextChannel(),
                    ),
                    IconButton(
                      icon: Icon(
                        _manager.isChannelFavorite(activeChannel.id) ? Icons.star_rounded : Icons.star_border_rounded,
                        color: _manager.isChannelFavorite(activeChannel.id) ? Colors.amber : Colors.white60,
                      ),
                      tooltip: 'Toggle Favorite',
                      onPressed: () => _manager.toggleFavorite(activeChannel.id),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
