import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/core/theme/palette_colours.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Tools & features',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: PaletteColours.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          _ExploreCard(
            icon: Icons.color_lens_outlined,
            iconColor: PaletteColours.sageGreen,
            iconBg: PaletteColours.sageGreenLight,
            title: 'Colour Wheel',
            subtitle: 'Explore colour relationships and find harmonies',
            onTap: () => context.go('/explore/wheel'),
          ),
          const SizedBox(height: 12),
          _ExploreCard(
            icon: Icons.format_paint_outlined,
            iconColor: PaletteColours.softGoldDark,
            iconBg: PaletteColours.softGoldLight,
            title: 'White Finder',
            subtitle: 'Find the right white for your room and light',
            onTap: () => context.go('/explore/white-finder'),
          ),
          const SizedBox(height: 12),
          _ExploreCard(
            icon: Icons.library_books_outlined,
            iconColor: PaletteColours.accessibleBlueDark,
            iconBg: PaletteColours.accessibleBlueLight,
            title: 'Paint Library',
            subtitle: 'Browse colours from UK paint brands',
            onTap: () => context.go('/explore/paint-library'),
          ),
          const SizedBox(height: 12),
          _ExploreCard(
            icon: Icons.linear_scale,
            iconColor: const Color(0xFF8B3A3A),
            iconBg: const Color(0xFFF0E0E0),
            title: 'Red Thread',
            subtitle: 'Plan colour flow across your whole home',
            onTap: () => context.push('/red-thread'),
          ),
        ],
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PaletteColours.cardBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PaletteColours.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: PaletteColours.textSecondary,
                              ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: PaletteColours.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
