import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/widgets/colour_disclaimer.dart';
import 'package:palette/core/widgets/section_header.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/features/colour_wheel/providers/colour_wheel_providers.dart';
import 'package:palette/features/palette/widgets/colour_detail_sheet.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';

class WhiteFinderScreen extends ConsumerWidget {
  const WhiteFinderScreen({this.roomId, super.key});

  final String? roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final whitesAsync = ref.watch(whitesByUndertoneProvider);

    // If accessed from a room, load the room to get direction info
    CompassDirection? roomDirection;
    if (roomId != null) {
      final roomAsync = ref.watch(roomByIdProvider(roomId!));
      roomDirection = roomAsync.valueOrNull?.direction;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('White Finder')),
      body: whitesAsync.when(
        data: (grouped) => _WhiteFinderContent(
          grouped: grouped,
          roomDirection: roomDirection,
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
  });

  final Map<WhiteUndertone, List<PaintColour>> grouped;
  final CompassDirection? roomDirection;

  @override
  Widget build(BuildContext context) {
    // Determine recommended undertone families based on room direction
    final recommended = _getRecommendedWhiteUndertones(roomDirection);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Paper test tutorial
          const _PaperTestCard(),
          const SizedBox(height: 24),

          if (roomDirection != null) ...[
            _DirectionHint(
              direction: roomDirection!,
              recommended: recommended,
            ),
            const SizedBox(height: 24),
          ],

          // White groups by undertone
          ...WhiteUndertone.values.map((undertone) {
            final whites = grouped[undertone] ?? [];
            if (whites.isEmpty) return const SizedBox.shrink();

            final isRecommended = recommended.contains(undertone);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SectionHeader(title: undertone.displayName),
                    ),
                    if (isRecommended)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: PaletteColours.sageGreenLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Recommended',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: PaletteColours.sageGreenDark,
                                  ),
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

  Set<WhiteUndertone> _getRecommendedWhiteUndertones(
      CompassDirection? direction) {
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
                const Icon(Icons.lightbulb_outline,
                    color: PaletteColours.softGold),
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
  const _DirectionHint({
    required this.direction,
    required this.recommended,
  });

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
                const Icon(Icons.explore_outlined,
                    color: PaletteColours.sageGreen),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
