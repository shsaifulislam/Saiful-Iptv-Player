import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/components/empty_state_view.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<Map<String, dynamic>> _announcements = [
    {
      'title': 'Scheduled Cloud Maintenance',
      'body': 'Cloud synchronization services will undergo routine maintenance on Sunday from 02:00 to 03:00 UTC. Local playback remains unaffected.',
      'severity': 'maintenance',
      'date': 'Yesterday',
    },
    {
      'title': 'Saiful IPTV Player 1.0 Released!',
      'body': 'Welcome to Saiful IPTV Player. Enjoy native hardware-accelerated streaming, EPG guide, offline downloads, and multi-view across all your devices.',
      'severity': 'info',
      'date': 'Nov 11, 2026',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications & Alerts'),
      ),
      body: _announcements.isEmpty
          ? const EmptyStateView(
              title: 'No Notifications',
              message: 'You are all caught up! System announcements and release updates will appear here.',
              icon: Icons.notifications_none_rounded,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _announcements.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _announcements[index];
                final severity = item['severity'] as String;

                final badgeColor = severity == 'maintenance'
                    ? AppColors.warning
                    : (severity == 'warning' ? AppColors.error : AppColors.secondary);

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                severity.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              item['date'] as String,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['body'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            height: 1.4,
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
}

