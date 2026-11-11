import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/tv_focus_wrapper.dart';
import '../../iptv/models/epg_program.dart';
import '../../iptv/models/iptv_channel.dart';
import '../../iptv/services/playlist_manager.dart';

class EpgGuidePage extends StatefulWidget {
  const EpgGuidePage({super.key});

  @override
  State<EpgGuidePage> createState() => _EpgGuidePageState();
}

class _EpgGuidePageState extends State<EpgGuidePage> {
  final PlaylistManager _manager = PlaylistManager.instance;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _manager.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _manager.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Today, ${d.day}/${d.month}/${d.year}';
    }
    return '${d.day}/${d.month}/${d.year}';
  }

  void _showProgramDetails(IptvChannel channel, EpgProgram program) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141923),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final startStr = '${program.startTime.toLocal().hour.toString().padLeft(2, '0')}:${program.startTime.toLocal().minute.toString().padLeft(2, '0')}';
        final endStr = '${program.endTime.toLocal().hour.toString().padLeft(2, '0')}:${program.endTime.toLocal().minute.toString().padLeft(2, '0')}';

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      channel.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white60),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                program.title,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                '$startStr - $endStr (${program.durationMinutes} min) • ${program.category ?? "General"}',
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Text(
                program.description ?? 'No detailed synopsis provided for this broadcast.',
                style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _manager.setActiveChannel(channel);
                    context.push(RouteNames.player);
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Tune In Live'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final channels = _manager.allChannels;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EPG Program Guide'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded),
            tooltip: 'Jump to Now',
            onPressed: () {
              setState(() => _selectedDate = DateTime.now());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Date Navigator Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            color: const Color(0xFF141923),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                  tooltip: 'Previous Day',
                  onPressed: () {
                    setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
                  },
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _formatDate(_selectedDate),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                  tooltip: 'Next Day',
                  onPressed: () {
                    setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
                  },
                ),
              ],
            ),
          ),

          // Timeline Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            color: isDark ? const Color(0xFF192420) : const Color(0xFFE2EBE5),
            child: const Row(
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    'CHANNELS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('CURRENT AIRING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('UPCOMING SCHEDULE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // EPG Channel Rows
          Expanded(
            child: channels.isEmpty
                ? const Center(
                    child: Text('No channels available. Add a playlist to see EPG guide.', style: TextStyle(color: Colors.white54)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: channels.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
                    itemBuilder: (context, index) {
                      final channel = channels[index];
                      final currentProg = _manager.getCurrentProgram(channel.tvgId);
                      final nextProg = _manager.getNextProgram(channel.tvgId);

                      return Container(
                        height: 76,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                        child: Row(
                          children: [
                            // Channel Label
                            SizedBox(
                              width: 140,
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.tv_rounded, size: 20, color: AppColors.secondary),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          channel.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          channel.groupTitle,
                                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Program Block: Current Program
                            Expanded(
                              flex: 1,
                              child: TvFocusWrapper(
                                onTap: () {
                                  if (currentProg != null) {
                                    _showProgramDetails(channel, currentProg);
                                  } else {
                                    _manager.setActiveChannel(channel);
                                    context.push(RouteNames.player);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E2838),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        currentProg?.title ?? 'Live Feed',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        currentProg != null
                                            ? '${currentProg.durationMinutes} min • Airing Now'
                                            : 'Continuous Live Stream',
                                        style: const TextStyle(fontSize: 10, color: Colors.greenAccent),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Program Block: Next Program
                            Expanded(
                              flex: 1,
                              child: TvFocusWrapper(
                                onTap: () {
                                  if (nextProg != null) {
                                    _showProgramDetails(channel, nextProg);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141923),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        nextProg?.title ?? 'Upcoming Program',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        nextProg != null
                                            ? '${nextProg.durationMinutes} min • Up Next'
                                            : 'Schedule Pending',
                                        style: const TextStyle(fontSize: 10, color: Colors.white38),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
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
