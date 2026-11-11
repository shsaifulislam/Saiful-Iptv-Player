import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../widgets/tv_focus_wrapper.dart';

class PosterCard extends StatelessWidget {
  const PosterCard({
    required this.title,
    required this.onTap,
    super.key,
    this.posterUrl,
    this.badgeText,
    this.subtitle,
    this.rating,
    this.progressPercentage,
    this.width = 150,
    this.height = 225,
  });

  final String title;
  final VoidCallback onTap;
  final String? posterUrl;
  final String? badgeText;
  final String? subtitle;
  final double? rating;
  final double? progressPercentage;
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
          color: const Color(0xFF1B2320),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Poster placeholder or image
            if (posterUrl != null && posterUrl!.startsWith('http'))
              Image.network(
                posterUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackBackground(),
              )
            else
              _buildFallbackBackground(),

            // Cinematic Gradient Overlay (Netflix style)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x22000000),
                    Color(0xCC0B100E),
                    Color(0xF5080C0A),
                  ],
                  stops: [0.0, 0.45, 0.8, 1.0],
                ),
              ),
            ),

            // Top Badges
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        badgeText!.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  if (rating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.white24, width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 12, color: AppColors.tertiary),
                          const SizedBox(width: 3),
                          Text(
                            rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Content
            Positioned(
              left: 10,
              right: 10,
              bottom: progressPercentage != null ? 12 : 10,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
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

            // Progress Bar (Continue Watching)
            if (progressPercentage != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  value: progressPercentage!.clamp(0.0, 1.0),
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 3.5,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackBackground() {
    return Container(
      color: const Color(0xFF222B27),
      child: Center(
        child: Icon(
          Icons.movie_creation_outlined,
          size: 40,
          color: Colors.white.withOpacity(0.18),
        ),
      ),
    );
  }
}

