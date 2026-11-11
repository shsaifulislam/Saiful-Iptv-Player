import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../widgets/tv_focus_wrapper.dart';

class ChannelCard extends StatelessWidget {
  const ChannelCard({
    required this.channelName,
    required this.onTap,
    super.key,
    this.channelNumber,
    this.logoUrl,
    this.groupTitle,
    this.currentProgram,
    this.isLive = true,
    this.programProgress,
    this.width = 240,
    this.height = 135,
  });

  final String channelName;
  final VoidCallback onTap;
  final int? channelNumber;
  final String? logoUrl;
  final String? groupTitle;
  final String? currentProgram;
  final bool isLive;
  final double? programProgress;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TvFocusWrapper(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF19221F),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: Colors.white12, width: 0.8),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Dark pattern background
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                Icons.tv_rounded,
                size: 90,
                color: Colors.white.withOpacity(0.04),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Logo / Number / Live Pill
                  Row(
                    children: [
                      // Logo or fallback icon
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF283630),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: logoUrl != null && logoUrl!.startsWith('http')
                            ? Image.network(
                                logoUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => _buildFallbackLogo(),
                              )
                            : _buildFallbackLogo(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (channelNumber != null)
                              Text(
                                'CH $channelNumber',
                                style: const TextStyle(
                                  color: AppColors.secondaryLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            Text(
                              groupTitle ?? 'General',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isLive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 3,
                                backgroundColor: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),

                  // Channel Name
                  Text(
                    channelName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Current Program
                  if (currentProgram != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      currentProgram!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // EPG Progress Bar
            if (programProgress != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  value: programProgress!.clamp(0.0, 1.0),
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.secondary),
                  minHeight: 3,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackLogo() {
    return Center(
      child: Text(
        channelName.isNotEmpty ? channelName[0].toUpperCase() : 'TV',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

