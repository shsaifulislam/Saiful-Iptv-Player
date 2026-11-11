import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/tv_focus_wrapper.dart';
import '../services/multi_view_controller.dart';

class MultiViewPage extends StatefulWidget {
  const MultiViewPage({super.key});

  @override
  State<MultiViewPage> createState() => _MultiViewPageState();
}

class _MultiViewPageState extends State<MultiViewPage> {
  late final MultiViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MultiViewController();
    _controller.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tiles = _controller.tiles;
    final isFourScreen = _controller.layout == MultiViewLayout.fourScreen;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Multi-View (${isFourScreen ? "2x2 Quad" : "Dual 2-View"})'),
        actions: [
          IconButton(
            icon: Icon(isFourScreen ? Icons.view_sidebar_rounded : Icons.grid_view_rounded),
            tooltip: isFourScreen ? 'Switch to 2-View' : 'Switch to 4-View',
            onPressed: () {
              _controller.setLayout(
                isFourScreen ? MultiViewLayout.twoScreen : MultiViewLayout.fourScreen,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Hardware Capability Warning Banner
          if (_controller.shouldShowHardwareWarning)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF2A2010),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Multi-View Notice: 4 simultaneous 1080p hardware decoders require a capable GPU/SoC. Switch to 2-View if playback stutters.',
                      style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.amber, size: 16),
                    onPressed: () => _controller.dismissHardwareWarning(),
                  ),
                ],
              ),
            ),

          // Multi-View Tiles Grid
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = isFourScreen ? 2 : (constraints.maxWidth > 800 ? 2 : 1);

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 16 / 9,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: tiles.length,
                  itemBuilder: (context, index) {
                    final tile = tiles[index];
                    final hasAudio = tile.isAudioActive;

                    return TvFocusWrapper(
                      onTap: () => _controller.setAudioFocus(index),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF10141C),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasAudio ? AppColors.primary : Colors.white24,
                            width: hasAudio ? 2.5 : 1.0,
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Stream Surface Mock/Canvas
                            Center(
                              child: Icon(
                                tile.isPlaying ? Icons.live_tv_rounded : Icons.pause_circle_outline_rounded,
                                size: 54,
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),

                            // Top Info Bar
                            Positioned(
                              top: 8,
                              left: 8,
                              right: 8,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Stream #${index + 1}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      tile.channelName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  if (hasAudio)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.volume_up_rounded, color: Colors.white, size: 12),
                                          SizedBox(width: 4),
                                          Text('AUDIO', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Bottom Controls Overlay
                            Positioned(
                              bottom: 6,
                              left: 6,
                              right: 6,
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      tile.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () => _controller.toggleTilePlayPause(index),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      hasAudio ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                                      color: hasAudio ? AppColors.primary : Colors.white60,
                                      size: 20,
                                    ),
                                    tooltip: 'Set Audio Focus',
                                    onPressed: () => _controller.setAudioFocus(index),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.fullscreen_rounded, color: Colors.white70, size: 20),
                                    tooltip: 'Maximize Channel',
                                    onPressed: () => context.push(RouteNames.player),
                                  ),
                                ],
                              ),
                            ),

                            // Error Overlay if tile fails
                            if (tile.errorMessage != null)
                              Container(
                                color: Colors.black87,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 32),
                                      const SizedBox(height: 6),
                                      Text(
                                        tile.errorMessage!,
                                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                      TextButton(
                                        onPressed: () => _controller.toggleTilePlayPause(index),
                                        child: const Text('Retry Stream'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
