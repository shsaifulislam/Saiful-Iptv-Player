import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/tv_focus_wrapper.dart';

class ChannelCategoriesPage extends StatelessWidget {
  const ChannelCategoriesPage({super.key});

  static const _categories = [
    {'name': 'News & Current Affairs', 'count': 48, 'icon': Icons.newspaper_rounded, 'color': Color(0xFFD94A3D)},
    {'name': 'Sports & Stadiums', 'count': 82, 'icon': Icons.sports_soccer_rounded, 'color': Color(0xFF287B61)},
    {'name': 'Movies & Premiere Cinema', 'count': 114, 'icon': Icons.movie_filter_rounded, 'color': Color(0xFF9E4784)},
    {'name': 'Entertainment & Drama', 'count': 96, 'icon': Icons.tv_rounded, 'color': Color(0xFFE4A43A)},
    {'name': 'Documentary & Science', 'count': 34, 'icon': Icons.public_rounded, 'color': Color(0xFF2A7B9B)},
    {'name': 'Kids & Family', 'count': 26, 'icon': Icons.child_care_rounded, 'color': Color(0xFFE06D53)},
    {'name': 'Music & Radio', 'count': 42, 'icon': Icons.music_note_rounded, 'color': Color(0xFF4A6B82)},
    {'name': 'Lifestyle & Cooking', 'count': 18, 'icon': Icons.restaurant_rounded, 'color': Color(0xFF5B8A72)},
    {'name': 'Religious & Cultural', 'count': 22, 'icon': Icons.temple_buddhist_rounded, 'color': Color(0xFFB08968)},
    {'name': 'Regional & Bengali', 'count': 58, 'icon': Icons.language_rounded, 'color': Color(0xFF2E7D32)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Channel Categories'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 1100
              ? 4
              : (constraints.maxWidth > 750 ? 3 : (constraints.maxWidth > 480 ? 2 : 1));

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1.6,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final catColor = cat['color'] as Color;

              return TvFocusWrapper(
                onTap: () => context.push(RouteNames.liveTV),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        catColor.withOpacity(0.85),
                        catColor.withOpacity(0.4),
                        const Color(0xFF141C18),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(color: Colors.white12),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            size: 32,
                            color: Colors.white,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${cat['count']} CH',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        cat['name'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
    );
  }
}

