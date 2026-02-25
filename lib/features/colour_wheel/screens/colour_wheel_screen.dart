import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/colour_relationships.dart';
import 'package:palette/core/colour/lab_colour.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/widgets/colour_disclaimer.dart';
import 'package:palette/core/widgets/palette_bottom_sheet.dart';
import 'package:palette/core/widgets/section_header.dart';
import 'package:palette/features/colour_wheel/providers/colour_wheel_providers.dart';
import 'package:palette/features/colour_wheel/widgets/colour_wheel_painter.dart';
import 'package:palette/features/palette/widgets/colour_detail_sheet.dart';
import 'package:palette/providers/database_providers.dart';

class ColourWheelScreen extends ConsumerStatefulWidget {
  const ColourWheelScreen({super.key});

  @override
  ConsumerState<ColourWheelScreen> createState() => _ColourWheelScreenState();
}

class _ColourWheelScreenState extends ConsumerState<ColourWheelScreen> {
  double? _selectedHue;
  double _selectedRadial = 0.5;
  ColourRelationship _selectedRelationship = ColourRelationship.complementary;
  bool _showUndertones = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Colour Wheel'),
        actions: [
          IconButton(
            icon: Icon(
              _showUndertones ? Icons.thermostat : Icons.thermostat_outlined,
            ),
            tooltip: 'Toggle undertone view',
            onPressed: () => setState(() => _showUndertones = !_showUndertones),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Responsive colour wheel — fills available width
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wheelSize =
                      min(constraints.maxWidth - 16, 340.0);
                  return InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 3.0,
                    child: GestureDetector(
                      onPanDown: (details) =>
                          _handleTap(details.localPosition, wheelSize),
                      onPanUpdate: (details) =>
                          _handleTap(details.localPosition, wheelSize),
                      child: SizedBox(
                        width: wheelSize,
                        height: wheelSize,
                        child: CustomPaint(
                          painter: ColourWheelPainter(
                            selectedHue: _selectedHue,
                            selectedRadial: _selectedRadial,
                          ),
                          size: Size(wheelSize, wheelSize),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_selectedHue != null) ...[
              const SizedBox(height: 16),

              // Selected colour preview
              _SelectedColourPreview(
                hue: _selectedHue!,
                lightness: _selectedLightness,
                showUndertone: _showUndertones,
              ),
              const SizedBox(height: 24),

              // Relationship type selector
              const SectionHeader(title: 'Colour Relationships'),
              const SizedBox(height: 8),
              _RelationshipSelector(
                selected: _selectedRelationship,
                onChanged: (r) =>
                    setState(() => _selectedRelationship = r),
              ),
              const SizedBox(height: 16),

              // Relationship results
              _RelationshipResults(
                hue: _selectedHue!,
                relationship: _selectedRelationship,
                showUndertones: _showUndertones,
                onColourTap: _showColourDetail,
              ),
              const SizedBox(height: 24),

              // Paint matches
              _PaintMatchSection(
                  hue: _selectedHue!, lightness: _selectedLightness),
              const SizedBox(height: 24),
              const ColourDisclaimer(),
            ] else ...[
              const SizedBox(height: 32),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: PaletteColours.softCream,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.touch_app_outlined,
                        size: 32,
                        color: PaletteColours.sageGreen,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap the wheel to explore',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Find paint matches and colour harmonies',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: PaletteColours.textSecondary,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _handleTap(Offset localPosition, double wheelSize) {
    final halfSize = wheelSize / 2;
    final centre = Offset(halfSize, halfSize);
    final dx = localPosition.dx - centre.dx;
    final dy = localPosition.dy - centre.dy;
    final distance = sqrt(dx * dx + dy * dy);

    // Only respond to taps on the ring
    final outerRadius = halfSize;
    final innerRadius = outerRadius * 0.35;
    if (distance < innerRadius || distance > outerRadius) return;

    var angle = atan2(dy, dx) * 180 / pi + 90;
    if (angle < 0) angle += 360;

    // How far from outer to inner (0 = outer, 1 = inner)
    final radial =
        ((outerRadius - distance) / (outerRadius - innerRadius)).clamp(0.0, 1.0);

    setState(() {
      _selectedHue = angle;
      _selectedRadial = radial;
    });
  }

  /// Lightness mapped from the radial position (outer = 0.75, inner = 0.3).
  double get _selectedLightness => 0.75 - _selectedRadial * 0.45;

  Future<void> _showColourDetail(String hex) async {
    final paintRepo = ref.read(paintColourRepositoryProvider);
    final matches = await paintRepo.findClosestMatches(hex, limit: 5);
    if (!mounted) return;

    await PaletteBottomSheet.show<void>(
      context: context,
      builder: (_) => ColourDetailSheet(
        hex: hex,
        matches: matches,
        paintColourRepo: paintRepo,
      ),
    );
  }
}

class _SelectedColourPreview extends StatelessWidget {
  const _SelectedColourPreview({
    required this.hue,
    required this.lightness,
    required this.showUndertone,
  });

  final double hue;
  final double lightness;
  final bool showUndertone;

  @override
  Widget build(BuildContext context) {
    final color = HSLColor.fromAHSL(1.0, hue, 0.7, lightness).toColor();
    final hex = _colorToHex(color);
    final lab = hexToLab(hex);
    final undertone = lab.b > 5
        ? 'Warm'
        : lab.b < -5
            ? 'Cool'
            : 'Neutral';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: PaletteColours.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PaletteColours.divider),
      ),
      child: Column(
        children: [
          // Colour band across the top
          Container(height: 6, color: color),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hex.toUpperCase(),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        'Hue: ${hue.round()}\u00B0',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: PaletteColours.textSecondary,
                                ),
                      ),
                    ],
                  ),
                ),
                if (showUndertone)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: undertone == 'Warm'
                          ? PaletteColours.softGoldLight
                          : undertone == 'Cool'
                              ? PaletteColours.accessibleBlueLight
                              : PaletteColours.warmGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      undertone,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RelationshipSelector extends StatelessWidget {
  const _RelationshipSelector({
    required this.selected,
    required this.onChanged,
  });

  final ColourRelationship selected;
  final ValueChanged<ColourRelationship> onChanged;

  @override
  Widget build(BuildContext context) {
    // Horizontal scroll prevents awkward wrapping of "Split-complementary"
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ColourRelationship.values.map((r) {
          final isSelected = r == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(r.displayName),
              selected: isSelected,
              onSelected: (_) => onChanged(r),
              selectedColor: PaletteColours.sageGreenLight,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RelationshipResults extends StatelessWidget {
  const _RelationshipResults({
    required this.hue,
    required this.relationship,
    required this.showUndertones,
    this.onColourTap,
  });

  final double hue;
  final ColourRelationship relationship;
  final bool showUndertones;
  final ValueChanged<String>? onColourTap;

  @override
  Widget build(BuildContext context) {
    final baseColor = HSLColor.fromAHSL(1.0, hue, 0.7, 0.5).toColor();
    final baseHex = _colorToHex(baseColor);
    final baseLab = hexToLab(baseHex);

    final relatedColours = _getRelatedColours(baseLab, relationship);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          relationship.description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PaletteColours.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _ColourSwatchTile(
              label: 'Base',
              hex: baseHex,
              showUndertone: showUndertones,
              onTap: onColourTap != null ? () => onColourTap!(baseHex) : null,
            ),
            ...relatedColours.map(
              (entry) => _ColourSwatchTile(
                label: entry.label,
                hex: entry.hex,
                showUndertone: showUndertones,
                onTap: onColourTap != null
                    ? () => onColourTap!(entry.hex)
                    : null,
              ),
            ),
          ],
        ),
        if (onColourTap != null) ...[
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: PaletteColours.softCream,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Tap a swatch to find paint matches',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: PaletteColours.textSecondary,
                    ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<({String label, String hex})> _getRelatedColours(
    LabColour baseLab,
    ColourRelationship relationship,
  ) {
    return switch (relationship) {
      ColourRelationship.complementary => [
          (label: 'Complement', hex: labToHex(complementary(baseLab))),
        ],
      ColourRelationship.analogous => () {
          final a = analogous(baseLab);
          return [
            (label: 'Left', hex: labToHex(a.left)),
            (label: 'Right', hex: labToHex(a.right)),
          ];
        }(),
      ColourRelationship.triadic => () {
          final t = triadic(baseLab);
          return [
            (label: 'Second', hex: labToHex(t.second)),
            (label: 'Third', hex: labToHex(t.third)),
          ];
        }(),
      ColourRelationship.splitComplementary => () {
          final sc = splitComplementary(baseLab);
          return [
            (label: 'Left', hex: labToHex(sc.left)),
            (label: 'Right', hex: labToHex(sc.right)),
          ];
        }(),
    };
  }
}

class _ColourSwatchTile extends StatelessWidget {
  const _ColourSwatchTile({
    required this.label,
    required this.hex,
    required this.showUndertone,
    this.onTap,
  });

  final String label;
  final String hex;
  final bool showUndertone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(hex);
    final lab = hexToLab(hex);
    final undertone = lab.b > 5
        ? 'W'
        : lab.b < -5
            ? 'C'
            : 'N';

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PaletteColours.divider),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: showUndertone
                    ? Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            undertone,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaintMatchSection extends ConsumerWidget {
  const _PaintMatchSection({required this.hue, this.lightness = 0.5});

  final double hue;
  final double lightness;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paintColoursAsync = ref.watch(allPaintColoursProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Nearest Paint Matches'),
        const SizedBox(height: 8),
        paintColoursAsync.when(
          data: (allPaints) {
            final baseColor =
                HSLColor.fromAHSL(1.0, hue, 0.7, lightness).toColor();
            final baseHex = _colorToHex(baseColor);
            final baseLab = hexToLab(baseHex);

            final scored = allPaints.map((pc) {
              final lab = LabColour(pc.labL, pc.labA, pc.labB);
              final dE = _deltaE76(baseLab, lab);
              return (colour: pc, deltaE: dE);
            }).toList()
              ..sort((a, b) => a.deltaE.compareTo(b.deltaE));

            final top5 = scored.take(5);

            return Column(
              children: top5.map((match) {
                final percent = _deltaEToPercent(match.deltaE);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: PaletteColours.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PaletteColours.divider),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _hexToColor(match.colour.hex),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: PaletteColours.divider),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              match.colour.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${match.colour.brand}'
                              '${match.colour.approximatePricePerLitre != null ? ' \u2022 \u00A3${match.colour.approximatePricePerLitre!.toStringAsFixed(0)}/L' : ''}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: PaletteColours.textTertiary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _MatchBadge(percent: percent),
                          const SizedBox(height: 6),
                          BuyThisPaintButton(
                            brand: match.colour.brand,
                            colourCode: match.colour.code,
                            colourName: match.colour.name,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Could not load paint colours: $e'),
          ),
        ),
      ],
    );
  }

  double _deltaEToPercent(double dE) {
    if (dE <= 0) return 100;
    if (dE >= 25) return 0;
    return (1 - dE / 25) * 100;
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final colour = percent >= 70
        ? PaletteColours.sageGreen
        : percent >= 40
            ? PaletteColours.softGold
            : PaletteColours.textTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${percent.round()}%',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colour,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// CIE76 delta-E for fast UI sorting (full CIEDE2000 in the repo layer).
double _deltaE76(LabColour a, LabColour b) {
  final dl = a.l - b.l;
  final da = a.a - b.a;
  final db = a.b - b.b;
  return sqrt(dl * dl + da * da + db * db);
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}

String _colorToHex(Color color) {
  return '#${(color.r * 255).round().toRadixString(16).padLeft(2, '0')}'
      '${(color.g * 255).round().toRadixString(16).padLeft(2, '0')}'
      '${(color.b * 255).round().toRadixString(16).padLeft(2, '0')}'
      .toUpperCase();
}
