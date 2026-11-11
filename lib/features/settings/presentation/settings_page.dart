import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../services/auth/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMode = ref.watch(themeModeProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 60),
        children: [
          // Account & Cloud Sync Section
          Text('Account & Cloud', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    currentUser != null
                        ? Icons.account_circle_rounded
                        : Icons.account_circle_outlined,
                    size: 32,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    currentUser != null
                        ? (currentUser.email ?? 'Signed in')
                        : 'Sign In / Register',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    currentUser != null
                        ? 'Cloud sync active â€¢ Manage profile'
                        : 'Sign in to synchronize playlists, progress, and favorites',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    if (currentUser != null) {
                      context.push(RouteNames.profile);
                    } else {
                      context.push(RouteNames.login);
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.devices_rounded),
                  title: const Text('Authorized Devices'),
                  subtitle: const Text('Review and revoke registered devices'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(RouteNames.devices),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Appearance & Theme Section
          Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_rounded),
                label: Text('System'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_rounded),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_rounded),
                label: Text('Dark'),
              ),
            ],
            selected: {selectedMode},
            onSelectionChanged: (selection) => ref
                .read(themeModeProvider.notifier)
                .setThemeMode(selection.first),
          ),
          const SizedBox(height: 24),

          // General & Navigation Section
          Text('General & Information', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_none_rounded),
                  title: const Text('Announcements & Notifications'),
                  subtitle: const Text('Service alerts and broadcast updates'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(RouteNames.notifications),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('About & Support'),
                  subtitle: const Text('Version 1.0.0 â€¢ Report bugs & feedback'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(RouteNames.about),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
