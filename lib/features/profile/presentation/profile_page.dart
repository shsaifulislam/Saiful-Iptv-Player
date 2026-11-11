import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/app_config.dart';
import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/repositories/cloud_sync_repository.dart';
import '../../../services/auth/auth_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _displayNameController = TextEditingController();
  String _selectedLocale = 'en';

  bool _isLoadingProfile = false;
  bool _isSavingProfile = false;
  bool _isSyncing = false;
  String? _profileError;
  String? _syncStatusMessage;
  SyncReport? _lastSyncReport;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final repo = ref.read(profileRepositoryProvider);
    if (repo == null) return;

    setState(() {
      _isLoadingProfile = true;
      _profileError = null;
    });

    try {
      final profile = await repo.getProfile();
      if (mounted) {
        setState(() {
          _displayNameController.text =
              (profile['display_name'] as String?) ?? '';
          _selectedLocale = (profile['locale'] as String?) ?? 'en';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _profileError = 'Could not load profile from server.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final repo = ref.read(profileRepositoryProvider);
    if (repo == null) return;

    setState(() {
      _isSavingProfile = true;
      _profileError = null;
    });

    try {
      await repo.updateProfile(
        displayName: _displayNameController.text.trim(),
        locale: _selectedLocale,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _profileError = 'Failed to update profile: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProfile = false;
        });
      }
    }
  }

  Future<void> _triggerManualSync() async {
    final syncRepo = ref.read(cloudSyncRepositoryProvider);
    if (syncRepo == null) return;

    setState(() {
      _isSyncing = true;
      _syncStatusMessage = 'Synchronizing with cloud...';
    });

    try {
      final report = await syncRepo.syncNow();
      if (mounted) {
        setState(() {
          _lastSyncReport = report;
          if (report.succeeded) {
            _syncStatusMessage =
                'Sync successful! Accepted: ${report.accepted}, Conflicts resolved: ${report.conflictsResolved}.';
          } else {
            _syncStatusMessage =
                'Sync completed with warnings. Rejected: ${report.rejected}. Error code: ${report.errorCode ?? "none"}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _syncStatusMessage = 'Sync failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your local playlists and playback history remain saved on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authService = ref.read(authServiceProvider);
      if (authService != null) {
        await authService.signOut();
      }
      if (mounted) {
        context.go(RouteNames.home);
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final passwordController = TextEditingController();
    final deleteFormKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var isDeleting = false;
        String? deleteError;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Delete Account Permanently',
                style: TextStyle(color: AppColors.error),
              ),
              content: Form(
                key: deleteFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This action cannot be undone. All your cloud data, synced playlists, and avatars will be permanently deleted from the servers.',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Please enter your password to confirm account deletion:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required to confirm deletion.';
                        }
                        return null;
                      },
                    ),
                    if (deleteError != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        deleteError!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          if (!deleteFormKey.currentState!.validate()) return;
                          setDialogState(() {
                            isDeleting = true;
                            deleteError = null;
                          });

                          final authService = ref.read(authServiceProvider);
                          if (authService == null) {
                            setDialogState(() {
                              isDeleting = false;
                              deleteError = 'Cloud services not configured.';
                            });
                            return;
                          }

                          final result = await authService.deleteAccount(
                            currentPassword: passwordController.text,
                          );

                          result.when(
                            success: (_) {
                              Navigator.of(context).pop();
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Account successfully deleted.'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                                this.context.go(RouteNames.home);
                              }
                            },
                            failure: (error) {
                              setDialogState(() {
                                isDeleting = false;
                                deleteError = error.message;
                              });
                            },
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Permanently Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                side: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.dividerDark
                      : AppColors.dividerLight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Account & Cloud Sync',
                      style: AppTypography.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Sign in to synchronize your playlists, channel favorites, watch history, and progress seamlessly across all your devices.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton.icon(
                      onPressed: () => context.push(RouteNames.login),
                      icon: const Icon(Icons.login),
                      label: const Text('Sign In or Register'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Playback and local playlists work offline without an account.',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final email = currentUser.email ?? 'No email associated';
    final userId = currentUser.id;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 60),
      children: [
        // Page Title
        Text('Account & Profile', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Manage your cloud profile and cross-device sync status.',
          style: TextStyle(
            color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // User Identity Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: Text(
                    email.isNotEmpty ? email[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayNameController.text.isNotEmpty
                            ? _displayNameController.text
                            : 'Saiful IPTV User',
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.onSurfaceVariantDark
                              : AppColors.onSurfaceVariantLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: userId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User ID copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ID: ${userId.substring(0, 8)}...${userId.substring(userId.length - 4)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy, size: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _confirmSignOut,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Profile Details Form
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile Settings', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.md),
                if (_profileError != null) ...[
                  Text(
                    _profileError!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                TextField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    prefixIcon: Icon(Icons.badge_outlined),
                    hintText: 'Enter your preferred name',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: _selectedLocale,
                  decoration: const InputDecoration(
                    labelText: 'Preferred Language / Locale',
                    prefixIcon: Icon(Icons.language_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English (en)')),
                    DropdownMenuItem(value: 'bn', child: Text('বাংলা (bn)')),
                    DropdownMenuItem(value: 'ar', child: Text('العربية (ar)')),
                    DropdownMenuItem(value: 'es', child: Text('Español (es)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedLocale = val);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _isSavingProfile ? null : _saveProfile,
                    child: _isSavingProfile
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Profile'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Cloud Synchronization Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sync_rounded, color: AppColors.secondary),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Cloud Synchronization',
                            style: AppTypography.titleMedium),
                      ],
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _isSyncing ? null : _triggerManualSync,
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 18),
                      label: const Text('Sync Now'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined,
                              size: 18, color: AppColors.secondary),
                          const SizedBox(width: AppSpacing.sm),
                          const Expanded(
                            child: Text(
                              'Security Note: Provider credentials and local media are never synced to the cloud.',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Only non-sensitive metadata (playlist titles, channel names, favorites, and watch progress timestamps) are synced.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (_syncStatusMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _syncStatusMessage!,
                    style: TextStyle(
                      fontSize: 13,
                      color: _lastSyncReport?.succeeded == false
                          ? AppColors.warning
                          : AppColors.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xxl),

        // Danger Zone: Account Deletion
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            side: const BorderSide(color: AppColors.error, width: 0.8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Danger Zone',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Permanently delete your user profile, stored cloud settings, and cloud sync history.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: _confirmDeleteAccount,
                  icon: const Icon(Icons.delete_forever, color: AppColors.error),
                  label: const Text(
                    'Delete Account',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

