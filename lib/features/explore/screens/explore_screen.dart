import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/core/analytics/analytics_events.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/constants/branded_terms.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/widgets/section_header.dart';
import 'package:palette/features/explore/data/learn_content.dart';
import 'package:palette/features/onboarding/data/archetype_definitions.dart';
import 'package:palette/features/palette/providers/palette_providers.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';
import 'package:palette/providers/analytics_provider.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dnaAsync = ref.watch(latestColourDnaProvider);
    final roomsAsync = ref.watch(allRoomsProvider);
    final rooms = roomsAsync.valueOrNull ?? [];

    // Build personalised subtitles when room context exists
    final contextRoom = rooms.isNotEmpty ? rooms.first : null;
    final roomNote =
        contextRoom != null && contextRoom.direction != null
            ? '${contextRoom.direction!.displayName.toLowerCase()}-facing ${contextRoom.name}'
            : null;

    final wheelSubtitle =
        roomNote != null
            ? 'Explore harmonies for your $roomNote'
            : 'See where your palette sits';
    final whiteSubtitle =
        roomNote != null
            ? 'Find whites for your $roomNote'
            : 'Find the right white for your rooms and light';
    final librarySubtitle =
        roomNote != null
            ? 'Recommended paints for your $roomNote'
            : 'Browse colours from UK paint brands';

    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Tools section ──
          const SectionHeader(title: 'Tools'),
          _ExploreCard(
            icon: Icons.color_lens_outlined,
            iconColor: PaletteColours.sageGreen,
            iconBg: PaletteColours.sageGreenLight,
            title: 'Colour Wheel',
            subtitle: wheelSubtitle,
            onTap: () {
              ref.read(analyticsProvider).track(
                AnalyticsEvents.colourWheelOpened,
                {'context': 'explore'},
              );
              context.go('/explore/wheel');
            },
          ),
          const SizedBox(height: 12),
          _ExploreCard(
            icon: Icons.format_paint_outlined,
            iconColor: PaletteColours.softGoldDark,
            iconBg: PaletteColours.softGoldLight,
            title: 'White Finder',
            subtitle: whiteSubtitle,
            onTap: () {
              ref.read(analyticsProvider).track(
                AnalyticsEvents.whiteFinderOpened,
                {'context': 'explore'},
              );
              context.go('/explore/white-finder');
            },
          ),
          const SizedBox(height: 12),
          _ExploreCard(
            icon: Icons.library_books_outlined,
            iconColor: PaletteColours.accessibleBlueDark,
            iconBg: PaletteColours.accessibleBlueLight,
            title: 'Paint Library',
            subtitle: librarySubtitle,
            onTap: () => context.go('/explore/paint-library'),
          ),

          const SizedBox(height: 24),

          // ── Learn section ──
          const SectionHeader(title: 'Learn'),
          for (int i = 0; i < learnArticles.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _LearnCard(article: learnArticles[i]),
          ],

          const SizedBox(height: 24),

          // ── Your Palette section ──
          const SectionHeader(title: 'Your Palette'),
          _ExploreCard(
            icon: Icons.linear_scale,
            iconColor: PaletteColours.redThread,
            iconBg: PaletteColours.redThreadLight,
            title: BrandedTerms.redThread,
            subtitle: BrandedTerms.redThreadSubtitle,
            onTap: () => context.push('/red-thread'),
          ),
          const SizedBox(height: 12),
          dnaAsync.when(
            data: (dna) {
              if (dna == null) {
                return _ExploreCard(
                  icon: Icons.auto_awesome,
                  iconColor: PaletteColours.softGoldDark,
                  iconBg: PaletteColours.softGoldLight,
                  title: BrandedTerms.colourDna,
                  subtitle: '${BrandedTerms.colourDnaSubtitle} — take the quiz',
                  onTap: () => context.push('/onboarding'),
                );
              }
              final archetypeName =
                  dna.archetype != null
                      ? archetypeDefinitions[dna.archetype]?.name
                      : null;
              return _DnaMiniCard(
                label: archetypeName ?? dna.primaryFamily.displayName,
                hexes: dna.colourHexes.take(4).toList(),
                onTap: () => context.push('/palette'),
              );
            },
            loading: () => const SizedBox(height: 64),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tool / navigation card (reused from previous version)
// ─────────────────────────────────────────────────────────────────────────────

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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

// ─────────────────────────────────────────────────────────────────────────────
// Expandable learn card
// ─────────────────────────────────────────────────────────────────────────────

class _LearnCard extends StatefulWidget {
  const _LearnCard({required this.article});

  final LearnArticle article;

  @override
  State<_LearnCard> createState() => _LearnCardState();
}

class _LearnCardState extends State<_LearnCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.article;
    return Material(
      color: PaletteColours.cardBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: PaletteColours.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: a.iconBg.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(a.icon, color: a.iconColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            a.subtitle,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: PaletteColours.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.25 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(
                        Icons.chevron_right,
                        color: PaletteColours.textTertiary,
                      ),
                    ),
                  ],
                ),
                // Expanded body
                if (_isExpanded) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: PaletteColours.divider),
                  const SizedBox(height: 14),
                  Text(
                    a.body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: PaletteColours.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact DNA summary card
// ─────────────────────────────────────────────────────────────────────────────

class _DnaMiniCard extends StatelessWidget {
  const _DnaMiniCard({
    required this.label,
    required this.hexes,
    required this.onTap,
  });

  final String label;
  final List<String> hexes;
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
              // Palette swatches
              for (final hex in hexes) ...[
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: hexToColor(hex),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: PaletteColours.divider,
                      width: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${BrandedTerms.colourDna} \u2022 ${BrandedTerms.colourDnaSubtitle}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PaletteColours.textSecondary,
                      ),
                    ),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
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
