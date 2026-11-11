import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../widgets/tv_focus_wrapper.dart';

class HeroBanner extends StatelessWidget {
  const HeroBanner({
    required this.title,
    required this.synopsis,
    required this.onPlayTap,
    super.key,
    this.badgeText = 'FEATURED',
    this.genres = const [],
    this.backdropUrl,
    this.onInfoTap,
    this.onFavoriteTap,
    this.isFavorite = false,
  });

  final String title;
  final String synopsis;
  final VoidCallback onPlayTap;
  final String badgeText;
  final List<String> genres;
  final String? backdropUrl;
  final VoidCallback? onInfoTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF141C19),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Backdrop
          if (backdropUrl != null && backdropUrl!.startsWith('http'))
            Image.network(
              backdropUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallbackBackdrop(),
            )
          else
            _buildFallbackBackdrop(),

          // Cinematic Dark Vignette & Gradient Overlays
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Colors.transparent,
                  Color(0x88111815),
                  Color(0xF50E1512),
                  Color(0xFF0B100E),
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Colors.transparent,
                  Color(0xDD0B100E),
                  Color(0xFF0B100E),
                ],
                stops: [0.0, 0.4, 0.85, 1.0],
              ),
            ),
          ),

          // Content Layer
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Top Badge
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    if (genres.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Text(
                        genres.join(' â€¢ '),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Hero Title
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),

                // Synopsis
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Text(
                    synopsis,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    TvFocusWrapper(
                      onTap: onPlayTap,
                      child: FilledButton.icon(
                        onPressed: onPlayTap,
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: const Text(
                          'Watch Now',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    if (onInfoTap != null) ...[
                      const SizedBox(width: 12),
                      TvFocusWrapper(
                        onTap: onInfoTap!,
                        child: OutlinedButton.icon(
                          onPressed: onInfoTap,
                          icon: const Icon(Icons.info_outline_rounded, size: 18),
                          label: const Text('Details'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (onFavoriteTap != null) ...[
                      const SizedBox(width: 12),
                      TvFocusWrapper(
                        onTap: onFavoriteTap!,
                        child: IconButton.outlined(
                          onPressed: onFavoriteTap,
                          icon: Icon(
                            isFavorite
                                ? Icons.bookmark_added_rounded
                                : Icons.bookmark_add_outlined,
                            color: isFavorite
                                ? AppColors.tertiary
                                : Colors.white,
                          ),
                          style: IconButton.styleFrom(
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackBackdrop() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E2B25),
            Color(0xFF141F1A),
            Color(0xFF0F1714),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.live_tv_rounded,
          size: 110,
          color: Colors.white.withOpacity(0.06),
        ),
      ),
    );
  }
}

