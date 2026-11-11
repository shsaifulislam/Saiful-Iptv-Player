import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/tv_focus_wrapper.dart';
import '../services/youtube_service.dart';

class YoutubeHubPage extends StatefulWidget {
  const YoutubeHubPage({super.key});

  @override
  State<YoutubeHubPage> createState() => _YoutubeHubPageState();
}

class _YoutubeHubPageState extends State<YoutubeHubPage> {
  final YoutubeService _service = YoutubeService.instance;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  String? _detectedVideoId;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onUpdate);
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _onUrlChanged(String val) {
    final id = YoutubeService.extractVideoId(val);
    setState(() => _detectedVideoId = id);
  }

  void _saveLink() {
    final url = _urlController.text.trim();
    if (url.isEmpty || _detectedVideoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid YouTube video URL or ID')),
      );
      return;
    }

    _service.saveLink(
      url: url,
      title: _titleController.text.trim(),
    );

    _urlController.clear();
    _titleController.clear();
    setState(() => _detectedVideoId = null);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('YouTube video link saved successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saved = _service.savedLinks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Hub'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Compliance Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF141923),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_outlined, color: Colors.redAccent, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Official YouTube Integration: Respects YouTube branding, official player standards, and ad policies.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Add YouTube Stream Input Panel
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add YouTube Stream or Video',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    onChanged: _onUrlChanged,
                    decoration: InputDecoration(
                      labelText: 'Paste YouTube URL or Video ID',
                      hintText: 'https://www.youtube.com/watch?v=... or youtu.be/...',
                      prefixIcon: const Icon(Icons.smart_display_outlined),
                      suffixIcon: _detectedVideoId != null
                          ? const Icon(Icons.check_circle_rounded, color: Colors.greenAccent)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Custom Bookmark Title (Optional)',
                      hintText: 'e.g. Daily Tech News Live',
                      prefixIcon: const Icon(Icons.title_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_detectedVideoId != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Video ID Detected: $_detectedVideoId',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _saveLink,
                        icon: const Icon(Icons.bookmark_add_rounded),
                        label: const Text('Save to Library'),
                      ),
                      const SizedBox(width: 12),
                      if (_detectedVideoId != null)
                        OutlinedButton.icon(
                          onPressed: () => context.push(RouteNames.player),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Watch in App'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Saved Links Header
          Text('Saved YouTube Links (${saved.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          for (final item in saved)
            TvFocusWrapper(
              onTap: () {
                _service.recordRecent(item);
                context.push(RouteNames.player);
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.redAccent, size: 28),
                  ),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('${item.channelTitle} • ID: ${item.videoId}', style: const TextStyle(fontSize: 12, color: Colors.white60)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.white60),
                        tooltip: 'Remove',
                        onPressed: () => _service.deleteSavedLink(item.id),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
