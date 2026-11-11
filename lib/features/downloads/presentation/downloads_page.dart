import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/components/empty_state_view.dart';
import '../../../shared/widgets/tv_focus_wrapper.dart';
import '../services/download_manager_service.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  final DownloadManagerService _dlService = DownloadManagerService.instance;

  @override
  void initState() {
    super.initState();
    _dlService.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _dlService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _showAddDownloadDialog() {
    final urlController = TextEditingController();
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Movie / Media Download'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Movie / Episode Title',
                  hintText: 'e.g. Inception 1080p, Bengali Cinema',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Direct Media URL',
                  hintText: 'https://.../movie.mp4 or .mkv',
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline_rounded, color: Colors.blueAccent, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Supports direct HTTP/HTTPS download links from MovieLink BD, HDHub4u, or cloud CDNs.',
                        style: TextStyle(fontSize: 11, color: Colors.blueAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final url = urlController.text.trim();
              final title = titleController.text.trim();
              if (url.isNotEmpty) {
                _dlService.startDownload(
                  url: url,
                  title: title.isNotEmpty ? title : 'Direct Video Download',
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Starting download for: ${title.isNotEmpty ? title : url}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Start Download'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tasks = _dlService.tasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Downloads & Media'),
        actions: [
          TvFocusWrapper(
            onTap: _showAddDownloadDialog,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _showAddDownloadDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Download URL'),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Storage Usage Bar Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2420) : const Color(0xFFE8EFEA),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Internal Device Storage',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '1.47 GB Used / 28.5 GB Free',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.onSurfaceVariantDark
                            : AppColors.onSurfaceVariantLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: 0.18,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Downloaded Items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Media Downloads (${tasks.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                'Auto Wi-Fi Sync Enabled',
                style: TextStyle(fontSize: 12, color: Colors.greenAccent),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (tasks.isEmpty)
            EmptyStateView(
              title: 'No Downloads Yet',
              message: 'Download movies or TV episodes while connected to Wi-Fi to watch them offline on the go.',
              icon: Icons.download_done_rounded,
              actionLabel: 'Explore Movies & Portals',
              onActionTap: () => context.push(RouteNames.movies),
            )
          else
            ...tasks.map((task) {
              final isCompleted = task.status == DownloadItemStatus.completed;
              final isDownloading = task.status == DownloadItemStatus.downloading;
              final isPaused = task.status == DownloadItemStatus.paused;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141923) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green.withOpacity(0.3)
                        : Colors.white12,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green.withOpacity(0.15)
                                : AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isCompleted ? Icons.play_arrow_rounded : Icons.downloading_rounded,
                            color: isCompleted ? Colors.greenAccent : AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${task.sizeDisplay} • ${task.status.name.toUpperCase()} ${isDownloading ? "(${task.speed})" : ""}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isCompleted ? Colors.greenAccent : Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Action Controls
                        if (isCompleted) ...[
                          TvFocusWrapper(
                            onTap: () => context.push(RouteNames.player),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              onPressed: () => context.push(RouteNames.player),
                              icon: const Icon(Icons.play_circle_filled_rounded, size: 16),
                              label: const Text('Play'),
                            ),
                          ),
                        ] else ...[
                          IconButton(
                            icon: Icon(
                              isDownloading ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              if (isDownloading) {
                                _dlService.pauseDownload(task.id);
                              } else if (isPaused) {
                                _dlService.resumeDownload(task.id);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                            onPressed: () => _dlService.cancelDownload(task.id),
                          ),
                        ],
                      ],
                    ),

                    if (!isCompleted) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: task.progress,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          task.progressPercentage,
                          style: const TextStyle(fontSize: 11, color: Colors.white60),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
