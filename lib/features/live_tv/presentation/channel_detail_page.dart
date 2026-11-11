import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/components/channel_card.dart';
import '../../../shared/widgets/tv_focus_wrapper.dart';

class ChannelDetailPage extends StatefulWidget {
  const ChannelDetailPage({required this.channelId, super.key});

  final String channelId;

  @override
  State<ChannelDetailPage> createState() => _ChannelDetailPageState();
}

class _ChannelDetailPageState extends State<ChannelDetailPage> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Channel Details'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _isFavorite ? AppColors.tertiary : null,
            ),
            tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isFavorite
                      ? 'Added to Favorites'
                      : 'Removed from Favorites'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 60),
        children: [
          // Channel Hero Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2420) : const Color(0xFFE8EFEA),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Channel Logo
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: const Color(0xFF273830),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.tv_rounded, size: 44, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'CH 101 â€¢ News & Info',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Al Jazeera English HD',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Global live news, in-depth reports, and investigative documentaries broadcasting 24/7.',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildMetadataTag('1080p 60fps', Icons.hd_rounded),
                          _buildMetadataTag('AAC 5.1', Icons.audiotrack_rounded),
                          _buildMetadataTag('H.264 / AVC', Icons.code_rounded),
                          _buildMetadataTag('Low Latency', Icons.speed_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Button
          TvFocusWrapper(
            onTap: () => context.push(RouteNames.player),
            child: FilledButton.icon(
              onPressed: () => context.push(RouteNames.player),
              icon: const Icon(Icons.play_arrow_rounded, size: 24),
              label: const Text(
                'Play Channel Fullscreen',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // EPG Schedule
          Text('Today\'s Schedule', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _buildEpgScheduleList(),
          const SizedBox(height: 32),

          // Similar Channels
          Text('Related Channels', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ChannelCard(
                  channelNumber: 102,
                  channelName: 'BBC News HD',
                  groupTitle: 'News',
                  currentProgram: 'World News Report',
                  onTap: () => context.push(RouteNames.player),
                ),
                const SizedBox(width: 12),
                ChannelCard(
                  channelNumber: 103,
                  channelName: 'CNN International',
                  groupTitle: 'News',
                  currentProgram: 'Connect the World',
                  onTap: () => context.push(RouteNames.player),
                ),
                const SizedBox(width: 12),
                ChannelCard(
                  channelNumber: 104,
                  channelName: 'EuroNews HD',
                  groupTitle: 'News',
                  currentProgram: 'Raw Politics',
                  onTap: () => context.push(RouteNames.player),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildEpgScheduleList() {
    final schedule = [
      {'time': '21:00 - 22:00', 'title': 'Newshour Live', 'current': true, 'desc': 'Comprehensive international news coverage and live field reports.'},
      {'time': '22:00 - 22:30', 'title': 'Counting the Cost', 'current': false, 'desc': 'Global economy and markets weekly analysis.'},
      {'time': '22:30 - 23:00', 'title': 'Inside Story', 'current': false, 'desc': 'In-depth debate on the top trending story of the day.'},
      {'time': '23:00 - 00:00', 'title': 'The Stream', 'current': false, 'desc': 'Social media and global citizen journalism roundup.'},
    ];

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: schedule.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = schedule[index];
          final isCurrent = item['current'] as bool;

          return ListTile(
            leading: isCurrent
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'NOW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : const Icon(Icons.schedule_rounded, size: 20, color: Colors.white38),
            title: Text(
              item['title'] as String,
              style: TextStyle(
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                color: isCurrent ? AppColors.primaryLight : null,
              ),
            ),
            subtitle: Text(
              '${item['time']} â€¢ ${item['desc']}',
              style: const TextStyle(fontSize: 12),
            ),
          );
        },
      ),
    );
  }
}

