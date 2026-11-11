import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/tv_focus_wrapper.dart';

class DeviceManagementPage extends StatefulWidget {
  const DeviceManagementPage({super.key});

  @override
  State<DeviceManagementPage> createState() => _DeviceManagementPageState();
}

class _DeviceManagementPageState extends State<DeviceManagementPage> {
  final List<Map<String, dynamic>> _devices = [
    {
      'id': 'd1',
      'name': 'Current Device',
      'platform': 'Windows',
      'icon': Icons.desktop_windows_rounded,
      'isCurrent': true,
      'lastSeen': 'Active now',
      'hash': '4a8f9c...b12e',
    },
    {
      'id': 'd2',
      'name': 'Living Room Sony Bravia TV',
      'platform': 'Android TV',
      'icon': Icons.tv_rounded,
      'isCurrent': false,
      'lastSeen': '2 hours ago',
      'hash': 'c812ef...903a',
    },
    {
      'id': 'd3',
      'name': 'Samsung Galaxy Tab S9',
      'platform': 'Android Tablet',
      'icon': Icons.tablet_android_rounded,
      'isCurrent': false,
      'lastSeen': 'Yesterday, 19:30',
      'hash': '71b30a...55f2',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Devices'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Authorized Installations',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'These devices can synchronize your playlists, channel favorites, and watch progress. You can revoke access at any time.',
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _devices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final dev = _devices[index];
              final isCurrent = dev['isCurrent'] as bool;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  side: BorderSide(
                    color: isCurrent ? AppColors.secondary : Colors.white12,
                    width: isCurrent ? 1.5 : 1.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.secondary.withOpacity(0.2)
                              : Colors.white12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          dev['icon'] as IconData,
                          color: isCurrent ? AppColors.secondary : Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  dev['name'] as String,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                if (isCurrent) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'THIS DEVICE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${dev['platform']} â€¢ ${dev['lastSeen']} â€¢ Fingerprint: ${dev['hash']}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                      if (!isCurrent)
                        TvFocusWrapper(
                          onTap: () => _confirmRevoke(context, dev['name'] as String, index),
                          child: OutlinedButton(
                            onPressed: () => _confirmRevoke(context, dev['name'] as String, index),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.error),
                              foregroundColor: AppColors.error,
                            ),
                            child: const Text('Revoke'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmRevoke(BuildContext context, String name, int index) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Device Access?'),
        content: Text('Are you sure you want to revoke access for "$name"? It will be logged out of cloud sync immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _devices.removeAt(index));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Device access revoked.')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Revoke Device'),
          ),
        ],
      ),
    );
  }
}

