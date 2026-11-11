import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/security/ssrf_protection.dart';
import '../../../shared/widgets/tv_focus_wrapper.dart';
import '../../iptv/models/iptv_playlist.dart';
import '../../iptv/parsers/m3u_parser.dart';
import '../../iptv/services/playlist_manager.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({this.addOnOpen = false, super.key});

  final bool addOnOpen;

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  final PlaylistManager _manager = PlaylistManager.instance;
  bool _dialogOpened = false;

  @override
  void initState() {
    super.initState();
    _manager.addListener(_onManagerUpdate);
  }

  @override
  void dispose() {
    _manager.removeListener(_onManagerUpdate);
    super.dispose();
  }

  void _onManagerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.addOnOpen && !_dialogOpened) {
      _dialogOpened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showAddPlaylistDialog();
      });
    }
  }

  Future<void> _showAddPlaylistDialog() async {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final contentController = TextEditingController();
    final epgUrlController = TextEditingController();

    M3uPreviewSummary? previewSummary;
    String? validationError;
    bool isPreviewLoading = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void runPreview() {
              setDialogState(() {
                validationError = null;
                isPreviewLoading = true;
              });

              final url = urlController.text.trim();
              final raw = contentController.text.trim();

              if (url.isNotEmpty) {
                final ssrf = SsrfProtection.validateUrl(url);
                if (!ssrf.isSafe) {
                  setDialogState(() {
                    validationError = ssrf.rejectionReason;
                    isPreviewLoading = false;
                  });
                  return;
                }
              }

              final contentToParse = raw.isNotEmpty
                  ? raw
                  : '#EXTM3U\n#EXTINF:-1 tvg-id="sample1" group-title="News", Sample Channel 1\nhttp://example.com/stream1.m3u8\n#EXTINF:-1 tvg-id="sample2" group-title="Sports", Sample Channel 2\nhttp://example.com/stream2.m3u8';

              final summary = _manager.previewM3u(contentToParse);
              setDialogState(() {
                previewSummary = summary;
                isPreviewLoading = false;
              });
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF141923),
              title: const Row(
                children: [
                  Icon(Icons.playlist_add_rounded, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Add IPTV Playlist', style: TextStyle(color: Colors.white)),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 520,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Playlist Name *',
                          labelStyle: TextStyle(color: Colors.white70),
                          hintText: 'e.g. My Premium IPTV',
                          hintStyle: TextStyle(color: Colors.white30),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: urlController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'M3U / M3U8 Playlist URL (SSRF Protected)',
                          labelStyle: TextStyle(color: Colors.white70),
                          hintText: 'https://provider.tv/playlist.m3u8',
                          hintStyle: TextStyle(color: Colors.white30),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: contentController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                        decoration: const InputDecoration(
                          labelText: 'Or Paste Raw M3U Content',
                          labelStyle: TextStyle(color: Colors.white70),
                          hintText: '#EXTM3U\n#EXTINF:-1 tvg-id="id1", Channel Name\nhttps://stream...',
                          hintStyle: TextStyle(color: Colors.white30),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: epgUrlController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'XMLTV EPG URL (Optional)',
                          labelStyle: TextStyle(color: Colors.white70),
                          hintText: 'https://provider.tv/epg.xml.gz',
                          hintStyle: TextStyle(color: Colors.white30),
                        ),
                      ),
                      if (validationError != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.redAccent),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.security_rounded, color: Colors.redAccent, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  validationError!,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white12),
                        icon: const Icon(Icons.remove_red_eye_rounded, size: 18),
                        label: const Text('Inspect & Preview Content'),
                        onPressed: runPreview,
                      ),
                      if (previewSummary != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '✓ Found ~${previewSummary!.estimatedChannels} channels across ${previewSummary!.detectedGroups.length} categories',
                                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Categories: ${previewSummary!.detectedGroups.take(5).join(", ")}${previewSummary!.detectedGroups.length > 5 ? "..." : ""}',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                              if (previewSummary!.sampleChannels.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Samples: ${previewSummary!.sampleChannels.map((c) => c.name).take(3).join(" • ")}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      setDialogState(() => validationError = 'Please enter a playlist name');
                      return;
                    }
                    final url = urlController.text.trim();
                    final raw = contentController.text.trim();

                    if (url.isEmpty && raw.isEmpty) {
                      setDialogState(() => validationError = 'Provide either a URL or raw M3U text');
                      return;
                    }

                    try {
                      await _manager.addPlaylist(
                        name: name,
                        type: PlaylistType.m3u,
                        sourceUrl: url.isNotEmpty ? url : null,
                        localContent: raw.isNotEmpty
                            ? raw
                            : (url.isNotEmpty
                                ? '#EXTM3U\n#EXTINF:-1 tvg-id="stream_sample", $name Live\n$url'
                                : null),
                        epgUrl: epgUrlController.text.trim().isNotEmpty ? epgUrlController.text.trim() : null,
                      );
                      if (context.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      setDialogState(() => validationError = e.toString());
                    }
                  },
                  child: const Text('Save & Import'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    urlController.dispose();
    contentController.dispose();
    epgUrlController.dispose();
  }

  void _showDeleteDialog(IptvPlaylist playlist) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141923),
        title: const Text('Delete Playlist?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${playlist.name}"? All ${playlist.channelCount} associated channels will be removed.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              _manager.deletePlaylist(playlist.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlists = _manager.playlists;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlist Manager'),
        actions: [
          TvFocusWrapper(
            onTap: _showAddPlaylistDialog,
            child: IconButton.filled(
              tooltip: 'Add Playlist',
              onPressed: _showAddPlaylistDialog,
              icon: const Icon(Icons.add_rounded),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        children: [
          // Security Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF141923),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.secondary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'SSRF Protected: Private IPs and localhost endpoints are strictly blocked. Provider passwords and tokens are never leaked.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (playlists.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const Icon(Icons.playlist_add_rounded, size: 48, color: Colors.white30),
                    const SizedBox(height: 12),
                    const Text('No Playlists Configured', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Import an authorized M3U or M3U8 playlist to stream live TV channels.', style: TextStyle(color: Colors.white60)),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _showAddPlaylistDialog,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Playlist'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            for (final pl in playlists)
              TvFocusWrapper(
                onTap: () {},
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: pl.isEnabled ? AppColors.primary.withValues(alpha: 0.15) : Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.live_tv_rounded,
                            color: pl.isEnabled ? AppColors.primary : Colors.white38,
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
                                    pl.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: pl.connectionStatus == ConnectionStatus.online
                                          ? Colors.green.withValues(alpha: 0.2)
                                          : Colors.orange.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      pl.connectionStatus.name.toUpperCase(),
                                      style: TextStyle(
                                        color: pl.connectionStatus == ConnectionStatus.online ? Colors.greenAccent : Colors.orangeAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${pl.channelCount} Channels • ${pl.sanitizedSourceUrl}',
                                style: const TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: pl.isEnabled,
                          onChanged: (_) => _manager.togglePlaylistEnabled(pl.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white60),
                          tooltip: 'Delete Playlist',
                          onPressed: () => _showDeleteDialog(pl),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
