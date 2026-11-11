import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/tv_focus_wrapper.dart';
import '../../../playback/audio/audio_queue_manager.dart';
import '../../../playback/player_adapter_factory.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  late final AudioQueueManager _queueManager;

  final List<AudioTrackItem> _tracks = const [
    AudioTrackItem(
      id: 'audio-1',
      title: 'Chillout Ambient Lo-Fi Radio',
      artist: 'Online Stream Studio',
      album: 'Chill Streams 24/7',
      uri: 'https://stream.iptvprovider.com/audio/chillout.mp3',
      format: 'MP3 (320 kbps)',
      duration: Duration(hours: 1, minutes: 20),
    ),
    AudioTrackItem(
      id: 'audio-2',
      title: 'Classical Symphony in D Minor',
      artist: 'Vienna Philharmonic Orchestra',
      album: 'European Masterworks',
      uri: 'https://stream.iptvprovider.com/audio/symphony.flac',
      format: 'FLAC (Lossless 24-bit 96kHz)',
      duration: Duration(minutes: 45, seconds: 12),
    ),
    AudioTrackItem(
      id: 'audio-3',
      title: 'Bengali Classical & Baul Harmonies',
      artist: 'Baul Shadhok & Ensemble',
      album: 'Folk Heritage',
      uri: 'https://stream.iptvprovider.com/audio/baul_folk.aac',
      format: 'AAC-LC (256 kbps)',
      duration: Duration(minutes: 32, seconds: 40),
    ),
    AudioTrackItem(
      id: 'audio-4',
      title: 'Retro Synthwave Highway',
      artist: 'Neon Cyberwave',
      album: 'Midnight Cruising',
      uri: 'https://stream.iptvprovider.com/audio/synthwave.ogg',
      format: 'OGG Vorbis (Quality 8)',
      duration: Duration(minutes: 28, seconds: 15),
    ),
    AudioTrackItem(
      id: 'audio-5',
      title: 'Acoustic Morning Coffee',
      artist: 'Studio Session Live',
      album: 'Peaceful Moments',
      uri: 'https://stream.iptvprovider.com/audio/acoustic.wav',
      format: 'WAV (PCM Uncompressed)',
      duration: Duration(minutes: 18, seconds: 50),
    ),
  ];

  @override
  void initState() {
    super.initState();
    final engine = PlayerAdapterFactory.create();
    _queueManager = AudioQueueManager(engine: engine);
    _queueManager.setQueue(_tracks, startIndex: 0, autoPlay: false);
  }

  @override
  void dispose() {
    _queueManager.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music & Audio Player'),
        actions: [
          IconButton(
            icon: const Icon(Icons.speed_rounded),
            tooltip: 'Playback Speed',
            onPressed: () {
              final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
              final nextIndex = (speeds.indexOf(_queueManager.playbackSpeed) + 1) % speeds.length;
              _queueManager.setSpeed(speeds[nextIndex]);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: _queueManager,
        builder: (context, _) {
          final current = _queueManager.currentTrack;

          return Column(
            children: [
              // Format Compatibility Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: isDark ? const Color(0xFF141923) : const Color(0xFFE9ECF2),
                child: const Row(
                  children: [
                    Icon(Icons.audiotrack_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Universal Audio Engine: MP3 • AAC • FLAC • WAV • OGG with Background Playback Support',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              // Track List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: _queueManager.queue.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final track = _queueManager.queue[index];
                    final isCurrent = index == _queueManager.currentIndex;

                    return TvFocusWrapper(
                      onTap: () => _queueManager.playTrackAtIndex(index),
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      child: Card(
                        color: isCurrent ? AppColors.primary.withValues(alpha: 0.12) : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                          side: BorderSide(
                            color: isCurrent ? AppColors.primary : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCurrent
                                ? AppColors.primary
                                : (isDark ? const Color(0xFF23322B) : const Color(0xFFE2EBE5)),
                            child: Icon(
                              isCurrent
                                  ? (_queueManager.isPlaying ? Icons.graphic_eq_rounded : Icons.pause_rounded)
                                  : Icons.music_note_rounded,
                              color: isCurrent ? Colors.white : AppColors.secondary,
                            ),
                          ),
                          title: Text(
                            track.title,
                            style: TextStyle(
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${track.artist} • ${track.album ?? "Single"}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isCurrent ? AppColors.primary : Colors.white10,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              track.format.split(' ').first,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Playback Dock
              if (current != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141923) : const Color(0xFFE4EDE7),
                    border: const Border(top: BorderSide(color: Colors.white12)),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Scrubber
                        if (_queueManager.duration > Duration.zero)
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: AppColors.primary,
                            ),
                            child: Slider(
                              value: _queueManager.position.inSeconds.toDouble().clamp(0.0, _queueManager.duration.inSeconds.toDouble()),
                              min: 0.0,
                              max: _queueManager.duration.inSeconds.toDouble(),
                              onChanged: (val) {
                                _queueManager.seek(Duration(seconds: val.toInt()));
                              },
                            ),
                          ),
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.music_note_rounded, color: Colors.white),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    current.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    '${current.artist} • ${_formatDuration(_queueManager.position)} / ${_formatDuration(_queueManager.duration)}',
                                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                            // Shuffle
                            IconButton(
                              icon: Icon(
                                Icons.shuffle_rounded,
                                color: _queueManager.isShuffled ? AppColors.primary : Colors.white60,
                                size: 22,
                              ),
                              tooltip: 'Shuffle',
                              onPressed: () => _queueManager.toggleShuffle(),
                            ),
                            // Previous
                            IconButton(
                              icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 26),
                              onPressed: () => _queueManager.previous(),
                            ),
                            // Play / Pause
                            IconButton(
                              icon: Icon(
                                _queueManager.isPlaying
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_fill_rounded,
                                size: 40,
                                color: AppColors.primary,
                              ),
                              onPressed: () => _queueManager.togglePlayPause(),
                            ),
                            // Next
                            IconButton(
                              icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 26),
                              onPressed: () => _queueManager.next(),
                            ),
                            // Repeat
                            IconButton(
                              icon: Icon(
                                _queueManager.repeatMode == AudioRepeatMode.one
                                    ? Icons.repeat_one_rounded
                                    : Icons.repeat_rounded,
                                color: _queueManager.repeatMode != AudioRepeatMode.off
                                    ? AppColors.primary
                                    : Colors.white60,
                                size: 22,
                              ),
                              tooltip: 'Repeat Mode',
                              onPressed: () => _queueManager.cycleRepeatMode(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
