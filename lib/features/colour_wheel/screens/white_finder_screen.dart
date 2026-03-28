import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/core/colour/lab_colour.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/widgets/colour_disclaimer.dart';
import 'package:palette/core/widgets/section_header.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/features/colour_wheel/providers/colour_wheel_providers.dart';
import 'package:palette/features/onboarding/models/system_palette.dart';
import 'package:palette/features/palette/providers/palette_providers.dart';
import 'package:palette/features/palette/widgets/colour_detail_sheet.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';
import 'package:palette/providers/app_providers.dart';

class WhiteFinderScreen extends ConsumerWidget {
  const WhiteFinderScreen({this.roomId, super.key});

  final String? roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final whitesAsync = ref.watch(whitesByUndertoneProvider);
    final dna = ref.watch(latestColourDnaProvider).valueOrNull;

    // If accessed from a room, load the room to get direction info
    CompassDirection? roomDirection;
    if (roomId != null) {
      final roomAsync = ref.watch(roomByIdProvider(roomId!));
      roomDirection = roomAsync.valueOrNull?.direction;
    }

    // Parse system palette for trim white reference
    SystemPalette? systemPalette;
    if (dna?.systemPaletteJson != null) {
      try {
        systemPalette = SystemPalette.fromJson(dna!.systemPaletteJson!);
      } catch (_) {
        // Ignore malformed JSON
      }
    }

    final constraints = ref.watch(renterConstraintsProvider);
    final finderTitle =
        constraints.wallsAreLocked ? 'Neutral Finder' : 'White Finder';

    return Scaffold(
      appBar: AppBar(title: Text(finderTitle)),
      body: whitesAsync.when(
        data:
            (grouped) => _WhiteFinderContent(
              grouped: grouped,
              roomDirection: roomDirection,
              dnaUndertone: dna?.undertoneTemperature,
              trimWhiteHex: systemPalette?.trimWhite.hex,
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _WhiteFinderContent extends StatelessWidget {
  const _WhiteFinderContent({
    required this.grouped,
    this.roomDirection,
    this.dnaUndertone,
    this.trimWhiteHex,
  });

  final Map<WhiteUndertone, List<PaintColour>> grouped;
  final CompassDirection? roomDirection;
  final Undertone? dnaUndertone;
  final String? trimWhiteHex;

  @override
  Widget build(BuildContext context) {
    // Determine recommended undertone families based on room direction
    final directionRecommended = _getRecommendedWhiteUndertones(roomDirection);
    final dnaRecommended = _getDnaRecommendedWhiteUndertones(dnaUndertone);
    final recommended = {...directionRecommended, ...dnaRecommended};

    // Sort undertone groups: recommended first, then the rest
    final orderedUndertones = [...WhiteUndertone.values];
    if (recommended.isNotEmpty) {
      orderedUndertones.sort((a, b) {
        final aRec = recommended.contains(a) ? 0 : 1;
        final bRec = recommended.contains(b) ? 0 : 1;
        return aRec.compareTo(bRec);
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Paper test tutorial
          const _PaperTestCard(),
          const SizedBox(height: 24),

          if (dnaUndertone != null && dnaUndertone != Undertone.neutral) ...[
            _DnaHint(undertone: dnaUndertone!),
            const SizedBox(height: 16),
          ],

          if (roomDirection != null) ...[
            _DirectionHint(
              direction: roomDirection!,
              recommended: directionRecommended,
            ),
            const SizedBox(height: 24),
          ],

          // White groups by undertone (recommended first)
          ...orderedUndertones.map((undertone) {
            var whites = grouped[undertone] ?? [];
            if (whites.isEmpty) return const SizedBox.shrink();

            // Sort by delta-E to DNA trim white when available
            if (trimWhiteHex != null) {
              whites = _sortByTrimWhiteProximity(whites, trimWhiteHex!);
            }

            final isDnaMatch = dnaRecommended.contains(undertone);
            final isDirectionMatch = directionRecommended.contains(undertone);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SectionHeader(title: undertone.displayName),
                    ),
                    if (isDnaMatch)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: PaletteColours.softGoldLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'DNA Match',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            color: PaletteColours.softGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (isDirectionMatch)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: PaletteColours.sageGreenLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Recommended',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: PaletteColours.sageGreenDark),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _WhiteGrid(whites: whites),
                const SizedBox(height: 24),
              ],
            );
          }),

          const ColourDisclaimer(),
        ],
      ),
    );
  }

  static Set<WhiteUndertone> _getRecommendedWhiteUndertones(
    CompassDirection? direction,
  ) {
    if (direction == null) return {};

    return switch (direction) {
      // North: warm undertones to compensate cool light
      CompassDirection.north => {WhiteUndertone.yellow, WhiteUndertone.pink},
      // South: cool undertones work well
      CompassDirection.south => {WhiteUndertone.blue, WhiteUndertone.grey},
      // East: warm morning → warm whites
      CompassDirection.east => {WhiteUndertone.yellow, WhiteUndertone.pink},
      // West: variable → neutral/warm
      CompassDirection.west => {WhiteUndertone.yellow, WhiteUndertone.grey},
    };
  }

  static Set<WhiteUndertone> _getDnaRecommendedWhiteUndertones(
    Undertone? undertone,
  ) {
    if (undertone == null || undertone == Undertone.neutral) return {};

    return switch (undertone) {
      Undertone.warm => {WhiteUndertone.yellow, WhiteUndertone.pink},
      Undertone.cool => {WhiteUndertone.blue, WhiteUndertone.grey},
      Undertone.neutral => {},
    };
  }

  static List<PaintColour> _sortByTrimWhiteProximity(
    List<PaintColour> whites,
    String trimHex,
  ) {
    final cleanHex = trimHex.replaceAll('#', '');
    final r = int.parse(cleanHex.substring(0, 2), radix: 16);
    final g = int.parse(cleanHex.substring(2, 4), radix: 16);
    final b = int.parse(cleanHex.substring(4, 6), radix: 16);
    // Approximate Lab from RGB for trim white
    final trimLab = LabColour(
      // Simple approximation — L* from luminance
      (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255 * 100,
      0, // We don't need precise a*/b* — just use the paint's own Lab
      0,
    );
    // Use the actual Lab of each white paint vs a rough target
    final sorted = [...whites];
    sorted.sort((a, b2) {
      final labA = LabColour(a.labL, a.labA, a.labB);
      final labB = LabColour(b2.labL, b2.labA, b2.labB);
      // Sort by delta-E to something close to the trim white
      final dA = deltaE2000(labA, trimLab);
      final dB = deltaE2000(labB, trimLab);
      return dA.compareTo(dB);
    });
    return sorted;
  }
}

class _PaperTestCard extends StatefulWidget {
  const _PaperTestCard();

  @override
  State<_PaperTestCard> createState() => _PaperTestCardState();
}

class _PaperTestCardState extends State<_PaperTestCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PaletteColours.softCream,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: PaletteColours.softGold,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Sowerby's Paper Test",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: PaletteColours.textTertiary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Hold a white sheet of paper next to the wall to reveal its undertone.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              Text(
                'If the paint looks yellow against it, it has a warm undertone. '
                'If it looks blue or grey, it has a cool undertone. '
                'This simple test reveals the hidden personality of any white.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PaletteColours.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DirectionHint extends StatefulWidget {
  const _DirectionHint({required this.direction, required this.recommended});

  final CompassDirection direction;
  final Set<WhiteUndertone> recommended;

  @override
  State<_DirectionHint> createState() => _DirectionHintState();
}

class _DirectionHintState extends State<_DirectionHint> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final summary = switch (widget.direction) {
      CompassDirection.north =>
        'Your north-facing room has cool light — choose warm-undertone whites.',
      CompassDirection.south =>
        'Your south-facing room gets generous light — cooler whites work well.',
      CompassDirection.east =>
        'Your east-facing room gets warm morning light — warm whites complement it.',
      CompassDirection.west =>
        'Your west-facing room gets warm evening light — yellow or grey whites balance it.',
    };

    final detail = switch (widget.direction) {
      CompassDirection.north =>
        'Yellow and pink undertone whites will feel cosier and '
            'prevent the space looking cold.',
      CompassDirection.south =>
        'You can use blue and grey undertone whites without the room feeling cold.',
      CompassDirection.east =>
        'Yellow and pink undertone whites will complement this natural warmth.',
      CompassDirection.west =>
        'Yellow undertone whites work well all day; grey undertones stay balanced.',
    };

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PaletteColours.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PaletteColours.sageGreenLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.explore_outlined,
                  color: PaletteColours.sageGreen,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    summary,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: PaletteColours.textTertiary,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Text(
                  detail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PaletteColours.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DnaHint extends StatelessWidget {
  const _DnaHint({required this.undertone});

  final Undertone undertone;

  @override
  Widget build(BuildContext context) {
    final (toneLabel, whiteTypes) = switch (undertone) {
      Undertone.warm => ('warm', 'yellow and pink'),
      Undertone.cool => ('cool', 'blue and grey'),
      Undertone.neutral => ('neutral', 'any'),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaletteColours.softGoldLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PaletteColours.softGold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_outlined,
            color: PaletteColours.softGold,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your Colour DNA leans $toneLabel — $whiteTypes undertone '
              'whites will harmonise with your palette.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteGrid extends StatelessWidget {
  const _WhiteGrid({required this.whites});

  final List<PaintColour> whites;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: whites.map((white) => _WhiteSwatch(colour: white)).toList(),
    );
  }
}

class _WhiteSwatch extends StatelessWidget {
  const _WhiteSwatch({required this.colour});

  final PaintColour colour;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          Container(
            width: 96,
            height: 64,
            decoration: BoxDecoration(
              color: _hexToColor(colour.hex),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: PaletteColours.divider),
            ),
            child: Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  colour.undertone.badge,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: PaletteColours.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            colour.name,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            colour.brand,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: PaletteColours.textTertiary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 96,
            child: BuyThisPaintButton(
              brand: colour.brand,
              colourCode: colour.code,
              colourName: colour.name,
            ),
          ),
        ],
      ),
    );
  }
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
