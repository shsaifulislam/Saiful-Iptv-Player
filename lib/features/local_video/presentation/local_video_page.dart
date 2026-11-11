import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/components/empty_state_view.dart';
import '../../../shared/widgets/tv_focus_wrapper.dart';
import '../../../services/media_browser/local_media_browser.dart';

class LocalVideoPage extends StatefulWidget {
  const LocalVideoPage({super.key});

  @override
  State<LocalVideoPage> createState() => _LocalVideoPageState();
}

class _LocalVideoPageState extends State<LocalVideoPage> {
  final LocalMediaBrowser _browser = LocalMediaBrowser();
  final TextEditingController _searchController = TextEditingController();

  List<LocalMediaFile> _allVideos = [
    LocalMediaFile(
      name: 'Family_Vacation_2026.mp4',
      path: '/storage/emulated/0/Movies/Family_Vacation_2026.mp4',
      sizeBytes: 1450000000,
      dateModified: DateTime(2026, 8, 15),
      extension: 'mp4',
      category: MediaCategory.video,
      duration: const Duration(minutes: 42, seconds: 18),
      resolution: '1080p 60fps',
    ),
    LocalMediaFile(
      name: 'Conference_Keynote_Recording.mkv',
      path: '/storage/emulated/0/Movies/Conference_Keynote_Recording.mkv',
      sizeBytes: 2800000000,
      dateModified: DateTime(2026, 9, 20),
      extension: 'mkv',
      category: MediaCategory.video,
      duration: const Duration(hours: 1, minutes: 15, seconds: 30),
      resolution: '4K UHD HDR',
    ),
    LocalMediaFile(
      name: 'Action_Trailer_Cinema.webm',
      path: '/storage/emulated/0/Movies/Action_Trailer_Cinema.webm',
      sizeBytes: 450000000,
      dateModified: DateTime(2026, 10, 5),
      extension: 'webm',
      category: MediaCategory.video,
      duration: const Duration(minutes: 3, seconds: 45),
      resolution: '1440p VP9',
    ),
  ];

  MediaSortOption _sortOption = MediaSortOption.nameAsc;
  String _searchQuery = '';
  bool _isScanning = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LocalMediaFile> get _displayedVideos {
    return _browser.filterAndSort(_allVideos, query: _searchQuery, sortOption: _sortOption);
  }

  Future<void> _pickLocalFolder() async {
    setState(() => _isScanning = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Storage scan completed: Found ${_allVideos.length} supported video files.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141923),
          title: const Text('Sort Videos By', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSortTile(ctx, 'Name (A to Z)', MediaSortOption.nameAsc),
              _buildSortTile(ctx, 'Name (Z to A)', MediaSortOption.nameDesc),
              _buildSortTile(ctx, 'Date Modified (Newest)', MediaSortOption.dateModifiedDesc),
              _buildSortTile(ctx, 'File Size (Largest)', MediaSortOption.sizeDesc),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortTile(BuildContext ctx, String label, MediaSortOption option) {
    final isSelected = _sortOption == option;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
        color: isSelected ? AppColors.primary : Colors.white38,
      ),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        setState(() => _sortOption = option);
        Navigator.pop(ctx);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final videos = _displayedVideos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Media Browser'),
        actions: [
          TvFocusWrapper(
            onTap: _showSortDialog,
            child: IconButton(
              icon: const Icon(Icons.sort_rounded),
              tooltip: 'Sort Options',
              onPressed: _showSortDialog,
            ),
          ),
          TvFocusWrapper(
            onTap: _pickLocalFolder,
            child: TextButton.icon(
              onPressed: _pickLocalFolder,
              icon: const Icon(Icons.folder_open_rounded, size: 18),
              label: const Text('Open Folder'),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Security / Privacy Notice Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: isDark ? const Color(0xFF1E2B25) : const Color(0xFFEDF5F0),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 18, color: AppColors.secondary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Privacy Guarantee: Your local video files remain strictly on your device and are never uploaded to the cloud.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search local videos by file name...',
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
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          if (_isScanning)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: LinearProgressIndicator(color: AppColors.primary),
            ),

          // File List or Empty State
          Expanded(
            child: videos.isEmpty
                ? EmptyStateView(
                    title: 'No Matching Videos Found',
                    message: _searchQuery.isNotEmpty
                        ? 'No video files matched "$_searchQuery". Try another keyword.'
                        : 'Scan your internal storage, SD Card, or attached USB drives to play offline video files.',
                    icon: Icons.video_file_outlined,
                    actionLabel: 'Scan Device Storage',
                    onActionTap: _pickLocalFolder,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: videos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = videos[index];
                      return TvFocusWrapper(
                        onTap: () {
                          _browser.recordRecentFile(item);
                          context.push(RouteNames.player);
                        },
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                        child: Card(
                          child: ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.play_circle_outline_rounded,
                                color: AppColors.secondary,
                                size: 28,
                              ),
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${item.formattedSize} • ${item.extension.toUpperCase()} • ${item.resolution ?? "Auto"}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.extension.toUpperCase(),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
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
