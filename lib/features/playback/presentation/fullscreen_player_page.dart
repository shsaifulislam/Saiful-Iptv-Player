import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/tv_focus_wrapper.dart';
import '../../../playback/player_controller.dart';
import '../../../playback/player_engine.dart';

class FullscreenPlayerPage extends StatefulWidget {
  final MediaSource? initialSource;

  const FullscreenPlayerPage({super.key, this.initialSource});

  @override
  State<FullscreenPlayerPage> createState() => _FullscreenPlayerPageState();
}

class _FullscreenPlayerPageState extends State<FullscreenPlayerPage> {
  late final PlayerController _controller;
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = PlayerController();
    _controller.initialize().then((_) {
      final source = widget.initialSource ??
          const MediaSource(
            uri: 'https://stream.iptvprovider.com/live/demouser/pass12345/aljazeera_en.m3u8',
            title: 'Al Jazeera English HD',
            subtitle: 'Newshour Live • Global News Network',
            isLive: true,
            mediaType: MediaType.liveStream,
          );
      _controller.open(source, autoPlay: true);
    });

    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _controller.isPlaying && !_controller.isControlsLocked) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    if (_controller.isControlsLocked) {
      // Keep showing minimal unlock button
      setState(() => _showControls = true);
      _startHideTimer();
      return;
    }
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    }
  }

  String _formatDuration(Duration d) {
    final s = d.inSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void _showDiagnosticsModal() {
    final diag = _controller.diagnostics;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141923),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Real-Time Playback Diagnostics',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 24),
              _buildDiagRow('Adapter Engine', _controller.engine.adapterName),
              _buildDiagRow('Sanitized Stream URL', diag.sanitizedSource),
              _buildDiagRow('Container / Format', '${diag.container ?? "N/A"} (${diag.format})'),
              _buildDiagRow('Video Codec', diag.videoCodec ?? 'Hardware Decoder (Auto)'),
              _buildDiagRow('Audio Codec', diag.audioCodec ?? 'Pass-through'),
              _buildDiagRow('Resolution & FPS', '${diag.resolution?.width.toInt() ?? 1920}x${diag.resolution?.height.toInt() ?? 1080} @ ${diag.fps?.toInt() ?? 60} fps'),
              _buildDiagRow('Bitrate', '${diag.bitrateKbps ?? 0} kbps'),
              _buildDiagRow('Buffer Length', '${diag.bufferDurationMs} ms'),
              _buildDiagRow('Hardware Acceleration', diag.hardwareAccelerated ? 'Active (Direct HW Surface)' : 'Software Decoding'),
              if (diag.errorCode != null) ...[
                const SizedBox(height: 8),
                _buildDiagRow('Error Code', diag.errorCode!, isError: true),
                _buildDiagRow('Suggested Fix', diag.recoverySuggestion ?? 'Retry stream', isError: true),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiagRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: TextStyle(color: isError ? Colors.redAccent : Colors.white60, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.redAccent : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTrackSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141923),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Audio Tracks', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._controller.audioTracks.map((track) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        track.isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                        color: track.isSelected ? AppColors.primary : Colors.white38,
                      ),
                      title: Text(track.title, style: const TextStyle(color: Colors.white)),
                      subtitle: Text('${track.language ?? "Unknown"} • ${track.channels} Channels', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      onTap: () {
                        _controller.engine.setAudioTrack(track);
                        Navigator.pop(ctx);
                      },
                    );
                  }),
                  const Divider(color: Colors.white24, height: 24),
                  const Text('Subtitles', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._controller.subtitleTracks.map((sub) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        sub.isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                        color: sub.isSelected ? AppColors.primary : Colors.white38,
                      ),
                      title: Text(sub.title, style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        _controller.engine.setSubtitleTrack(sub);
                        Navigator.pop(ctx);
                      },
                    );
                  }),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Subtitle Sync Delay:', style: TextStyle(color: Colors.white70)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.white),
                        onPressed: () => _controller.adjustSubtitleDelay(-100),
                      ),
                      Text('${_controller.subtitleDelayMs} ms', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                        onPressed: () => _controller.adjustSubtitleDelay(100),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSleepTimerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141923),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sleep Timer', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildSleepOption(ctx, 'Off / Cancel', null),
              _buildSleepOption(ctx, '15 Minutes', const Duration(minutes: 15)),
              _buildSleepOption(ctx, '30 Minutes', const Duration(minutes: 30)),
              _buildSleepOption(ctx, '45 Minutes', const Duration(minutes: 45)),
              _buildSleepOption(ctx, '60 Minutes (1 Hour)', const Duration(minutes: 60)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSleepOption(BuildContext ctx, String label, Duration? duration) {
    final isSelected = duration == null
        ? _controller.sleepTimerRemaining == null
        : (_controller.sleepTimerRemaining != null && _controller.sleepTimerRemaining!.inMinutes == duration.inMinutes);

    return ListTile(
      leading: Icon(
        isSelected ? Icons.check_circle_rounded : Icons.timer_outlined,
        color: isSelected ? AppColors.primary : Colors.white60,
      ),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        if (duration == null) {
          _controller.cancelSleepTimer();
        } else {
          _controller.setSleepTimer(duration);
        }
        Navigator.pop(ctx);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.space): () {
            _controller.togglePlayPause();
            _startHideTimer();
          },
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
            _controller.seekRelative(-10);
            _startHideTimer();
          },
          const SingleActivator(LogicalKeyboardKey.arrowRight): () {
            _controller.seekRelative(10);
            _startHideTimer();
          },
          const SingleActivator(LogicalKeyboardKey.arrowUp): () {
            _controller.adjustVolume(0.05);
            _startHideTimer();
          },
          const SingleActivator(LogicalKeyboardKey.arrowDown): () {
            _controller.adjustVolume(-0.05);
            _startHideTimer();
          },
          const SingleActivator(LogicalKeyboardKey.keyM): () {
            _controller.setVolume(_controller.volume > 0 ? 0.0 : 1.0);
            _startHideTimer();
          },
          const SingleActivator(LogicalKeyboardKey.keyL): () {
            _controller.toggleControlsLock();
          },
          const SingleActivator(LogicalKeyboardKey.keyD): () {
            _showDiagnosticsModal();
          },
          const SingleActivator(LogicalKeyboardKey.keyS): () {
            _showTrackSelectionModal();
          },
          const SingleActivator(LogicalKeyboardKey.escape): () {
            context.pop();
          },
        },
        child: Focus(
          autofocus: true,
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Native Video Surface
                  _controller.engine.buildVideoSurface(context),

                  // 2. Gesture Detector Layer (Tap, Double Tap Seek, Vertical Swipes)
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _toggleControls,
                    onDoubleTapDown: (details) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final isRightSide = details.globalPosition.dx > (screenWidth / 2);
                      _controller.onDoubleTapSeek(isRightSide);
                    },
                    onVerticalDragUpdate: (details) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final isLeftSide = details.globalPosition.dx < (screenWidth / 2);
                      final delta = -details.primaryDelta! / 300.0;
                      if (isLeftSide) {
                        _controller.adjustBrightness(delta);
                      } else {
                        _controller.adjustVolume(delta);
                      }
                    },
                  ),

                  // 3. Subtitle Overlay
                  if (_controller.currentSubtitleText.isNotEmpty)
                    Positioned(
                      left: 40,
                      right: 40,
                      bottom: _controller.subtitleStyle.bottomMargin,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _controller.subtitleStyle.backgroundColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _controller.currentSubtitleText,
                            textAlign: _controller.subtitleStyle.textAlignment,
                            style: TextStyle(
                              color: _controller.subtitleStyle.textColor,
                              fontSize: _controller.subtitleStyle.fontSize,
                              fontWeight: FontWeight.bold,
                              shadows: const [
                                Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 4. Volume / Brightness HUD Indicators
                  if (_controller.showVolumeIndicator)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _controller.volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 120,
                              child: LinearProgressIndicator(
                                value: _controller.volume,
                                color: AppColors.primary,
                                backgroundColor: Colors.white24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(_controller.volume * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (_controller.showBrightnessIndicator)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.brightness_6_rounded, size: 40, color: Colors.amber),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 120,
                              child: LinearProgressIndicator(
                                value: _controller.brightness,
                                color: Colors.amber,
                                backgroundColor: Colors.white24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(_controller.brightness * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 5. Double Tap Seek Feedback Ripple
                  if (_controller.doubleTapSeekDelta != 0)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _controller.doubleTapSeekDelta > 0 ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_controller.doubleTapSeekDelta > 0 ? "+" : ""}${_controller.doubleTapSeekDelta}s',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 6. Lock Controls Overlay
                  if (_controller.isControlsLocked)
                    Positioned(
                      top: 40,
                      left: 20,
                      child: SafeArea(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black54,
                            foregroundColor: Colors.amber,
                          ),
                          icon: const Icon(Icons.lock_open_rounded),
                          label: const Text('Unlock Screen'),
                          onPressed: () => _controller.toggleControlsLock(),
                        ),
                      ),
                    ),

                  // 7. Full Controls HUD Overlay
                  if (_showControls && !_controller.isControlsLocked) ...[
                    // Vignette Gradient
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xDD000000), Colors.transparent, Color(0xEE000000)],
                          stops: [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),

                    // Top Bar
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              TvFocusWrapper(
                                onTap: () => context.pop(),
                                borderRadius: BorderRadius.circular(20),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                                  onPressed: () => context.pop(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Al Jazeera English HD', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                    Text('Newshour Live • Global News Network', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                              ),
                              // Lock Button
                              IconButton(
                                icon: const Icon(Icons.lock_outline_rounded, color: Colors.white),
                                tooltip: 'Lock Controls',
                                onPressed: () => _controller.toggleControlsLock(),
                              ),
                              // Sleep Timer
                              IconButton(
                                icon: Icon(
                                  _controller.sleepTimerRemaining != null ? Icons.alarm_on_rounded : Icons.alarm_rounded,
                                  color: _controller.sleepTimerRemaining != null ? Colors.amber : Colors.white,
                                ),
                                tooltip: 'Sleep Timer',
                                onPressed: _showSleepTimerModal,
                              ),
                              // Subtitles / Audio
                              IconButton(
                                icon: const Icon(Icons.subtitles_rounded, color: Colors.white),
                                tooltip: 'Audio & Subtitles',
                                onPressed: _showTrackSelectionModal,
                              ),
                              // Aspect Ratio
                              TextButton(
                                onPressed: () => _controller.cycleAspectRatio(),
                                style: TextButton.styleFrom(foregroundColor: Colors.white),
                                child: Text('Aspect: ${_controller.aspectRatio.name.toUpperCase()}'),
                              ),
                              // Diagnostics
                              IconButton(
                                icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
                                tooltip: 'Diagnostics (D)',
                                onPressed: _showDiagnosticsModal,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Center Rewind / Play-Pause / Forward
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TvFocusWrapper(
                            onTap: () => _controller.seekRelative(-10),
                            borderRadius: BorderRadius.circular(30),
                            child: IconButton(
                              iconSize: 44,
                              icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
                              onPressed: () => _controller.seekRelative(-10),
                            ),
                          ),
                          const SizedBox(width: 36),
                          TvFocusWrapper(
                            onTap: () => _controller.togglePlayPause(),
                            borderRadius: BorderRadius.circular(40),
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _controller.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                size: 44,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 36),
                          TvFocusWrapper(
                            onTap: () => _controller.seekRelative(10),
                            borderRadius: BorderRadius.circular(30),
                            child: IconButton(
                              iconSize: 44,
                              icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
                              onPressed: () => _controller.seekRelative(10),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Bar
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Scrubber
                              if (_controller.duration > Duration.zero)
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                    activeTrackColor: AppColors.primary,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: AppColors.primary,
                                  ),
                                  child: Slider(
                                    value: _controller.position.inSeconds.toDouble().clamp(0.0, _controller.duration.inSeconds.toDouble()),
                                    min: 0.0,
                                    max: _controller.duration.inSeconds.toDouble(),
                                    onChanged: (val) {
                                      _controller.seek(Duration(seconds: val.toInt()));
                                      _startHideTimer();
                                    },
                                  ),
                                ),
                              // Time, Speed, A-B Repeat & Quality Status
                              Row(
                                children: [
                                  Text(
                                    _controller.duration > Duration.zero
                                        ? '${_formatDuration(_controller.position)} / ${_formatDuration(_controller.duration)}'
                                        : 'LIVE • ${_formatDuration(_controller.position)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // A-B Repeat Button
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _controller.isAbRepeatEnabled ? Colors.amber : Colors.white70,
                                      side: BorderSide(color: _controller.isAbRepeatEnabled ? Colors.amber : Colors.white24),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                    onPressed: () {
                                      if (_controller.pointA == null) {
                                        _controller.setPointA();
                                      } else if (_controller.pointB == null) {
                                        _controller.setPointB();
                                      } else {
                                        _controller.clearAbRepeat();
                                      }
                                    },
                                    child: Text(
                                      _controller.pointA == null
                                          ? 'A-B Repeat'
                                          : (_controller.pointB == null
                                              ? 'Set Point B'
                                              : 'Repeat [A-B Active]'),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Speed selector
                                  PopupMenuButton<double>(
                                    initialValue: _controller.speed,
                                    onSelected: (spd) => _controller.setSpeed(spd),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Text('${_controller.speed}x', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                    itemBuilder: (ctx) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) {
                                      return PopupMenuItem(value: s, child: Text('${s}x'));
                                    }).toList(),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white38),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      _controller.diagnostics.resolution != null
                                          ? '${_controller.diagnostics.resolution!.width.toInt()}p ${_controller.diagnostics.fps?.toInt() ?? 60}'
                                          : '1080p 60',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
