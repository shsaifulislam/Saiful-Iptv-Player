import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/components/empty_state_view.dart';
import '../../../shared/widgets/tv_focus_wrapper.dart';

class WatchHistoryPage extends StatefulWidget {
  const WatchHistoryPage({super.key});

  @override
  State<WatchHistoryPage> createState() => _WatchHistoryPageState();
}

class _WatchHistoryPageState extends State<WatchHistoryPage> {
  final List<Map<String, dynamic>> _historyItems = [
    {
      'title': 'Tears of Steel',
      'type': 'Movie',
      'progress': 0.45,
      'time': 'Resumed at 52:10 (1h 54m total)',
      'watchedAt': 'Today, 20:15',
    },
    {
      'title': 'Al Jazeera English HD',
      'type': 'Live TV',
      'progress': 1.0,
      'time': 'Watched for 35 min',
      'watchedAt': 'Today, 18:40',
    },
    {
      'title': 'Cosmos: Infinite Odyssey',
      'type': 'Documentary',
      'progress': 0.85,
      'time': 'Resumed at 1:45:20 (2h 10m total)',
      'watchedAt': 'Yesterday, 21:00',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch History'),
        actions: [
          if (_historyItems.isNotEmpty)
            TvFocusWrapper(
              onTap: _confirmClearHistory,
              child: TextButton.icon(
                onPressed: _confirmClearHistory,
                icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                label: const Text('Clear All'),
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: _historyItems.isEmpty
          ? EmptyStateView(
              title: 'History is Empty',
              message: 'Your watched channels, movies, and series will appear here so you can easily resume playback.',
              icon: Icons.history_rounded,
              actionLabel: 'Browse Content',
              onActionTap: () => context.push(RouteNames.home),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _historyItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _historyItems[index];

                return TvFocusWrapper(
                  onTap: () => context.push(RouteNames.player),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  child: Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.15),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(
                            item['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${item['type']} â€¢ ${item['time']} â€¢ ${item['watchedAt']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            tooltip: 'Remove from history',
                            onPressed: () {
                              setState(() => _historyItems.removeAt(index));
                            },
                          ),
                        ),
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(AppSpacing.cardRadius)),
                          child: LinearProgressIndicator(
                            value: (item['progress'] as double).clamp(0.0, 1.0),
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                            minHeight: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _confirmClearHistory() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Watch History?'),
        content: const Text(
            'This will clear your viewing history across local storage and cloud sync.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _historyItems.clear());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Watch history cleared.')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

