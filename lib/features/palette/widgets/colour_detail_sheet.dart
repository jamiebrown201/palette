import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/lab_colour.dart';
import 'package:palette/core/colour/palette_family.dart';
import 'package:palette/core/colour/undertone.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/data/repositories/paint_colour_repository.dart';
import 'package:palette/data/services/seed_data_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bottom sheet showing colour details, closest paint matches,
/// and a "Buy This Paint" button.
class ColourDetailSheet extends StatelessWidget {
  const ColourDetailSheet({
    required this.hex,
    required this.matches,
    required this.paintColourRepo,
    this.paletteHexes = const [],
    super.key,
  });

  final String hex;
  final List<PaintColourMatch> matches;
  final PaintColourRepository paintColourRepo;

  /// Other colours in the user's palette, for "why it works" explanations.
  final List<String> paletteHexes;

  @override
  Widget build(BuildContext context) {
    final lab = hexToLab(hex);
    final undertoneResult = classifyUndertone(lab);
    final family = classifyPaletteFamily(lab);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: PaletteColours.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Colour preview
              Center(
                child: Container(
                  width: 120,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _hexToColor(hex),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: PaletteColours.divider),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Hex value
              Center(
                child: Text(
                  hex.toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ),
              const SizedBox(height: 16),

              // Properties
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PropertyChip(
                    label: family.displayName,
                    icon: Icons.category_outlined,
                  ),
                  const SizedBox(width: 8),
                  _PropertyChip(
                    label: undertoneResult.classification.displayName,
                    icon: Icons.thermostat_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  family.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PaletteColours.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Why it works with the palette
              if (paletteHexes.length >= 2) ...[
                const SizedBox(height: 16),
                _WhyItWorksSection(hex: hex, paletteHexes: paletteHexes),
              ],
              const SizedBox(height: 16),

              // See it in a room
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/rooms');
                  },
                  icon: const Icon(Icons.meeting_room_outlined, size: 18),
                  label: const Text('See it in a room'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PaletteColours.textPrimary,
                    side: const BorderSide(color: PaletteColours.divider),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Closest paint matches
              if (matches.isNotEmpty) ...[
                Text(
                  'Closest paint matches',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                ...matches.map(
                  (m) => _PaintMatchTile(match: m),
                ),
                const SizedBox(height: 16),

                // Cross-brand matches for the closest paint
                _CrossBrandSection(
                  closestMatch: matches.first,
                  paintColourRepo: paintColourRepo,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _WhyItWorksSection extends StatelessWidget {
  const _WhyItWorksSection({
    required this.hex,
    required this.paletteHexes,
  });

  final String hex;
  final List<String> paletteHexes;

  @override
  Widget build(BuildContext context) {
    final lab = hexToLab(hex);
    final explanation = _findRelationship(lab);
    if (explanation == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PaletteColours.sageGreenLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: PaletteColours.sageGreenDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              explanation,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PaletteColours.sageGreenDark,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String? _findRelationship(LabColour thisLab) {
    for (final otherHex in paletteHexes) {
      if (otherHex == hex) continue;
      final otherLab = hexToLab(otherHex);
      final thisHue = thisLab.hueAngle;
      final otherHue = otherLab.hueAngle;
      var hueDiff = (thisHue - otherHue).abs();
      if (hueDiff > 180) hueDiff = 360 - hueDiff;

      if (hueDiff >= 165 && hueDiff <= 195) {
        return 'This colour is complementary to others in your palette, creating vibrant contrast that makes both colours feel more alive.';
      }
      if (hueDiff <= 35) {
        return 'This colour sits next to others in your palette on the colour wheel, creating a harmonious, cohesive feel.';
      }
      if (hueDiff >= 110 && hueDiff <= 130) {
        return 'This colour forms a triadic relationship with others in your palette, creating balanced vibrancy.';
      }
      if (hueDiff >= 140 && hueDiff <= 160) {
        return 'This colour is a split-complementary to others in your palette, offering softer contrast than a direct complement.';
      }
    }

    final undertone = thisLab.b > 5
        ? 'warm'
        : thisLab.b < -5
            ? 'cool'
            : 'neutral';
    return 'This $undertone-toned colour adds depth and balance to your palette.';
  }
}

class _PropertyChip extends StatelessWidget {
  const _PropertyChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: PaletteColours.warmGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: PaletteColours.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: PaletteColours.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

class _PaintMatchTile extends StatelessWidget {
  const _PaintMatchTile({required this.match});

  final PaintColourMatch match;

  @override
  Widget build(BuildContext context) {
    final colour = match.colour;
    final matchPercent = _deltaEToPercent(match.deltaE);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _hexToColor(colour.hex),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PaletteColours.divider),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      colour.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      colour.brand,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: PaletteColours.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${matchPercent.toStringAsFixed(0)}% match',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: matchPercent >= 90
                              ? PaletteColours.sageGreenDark
                              : PaletteColours.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (colour.approximatePricePerLitre != null)
                    Text(
                      '\u00A3${colour.approximatePricePerLitre!.toStringAsFixed(0)}/L',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: PaletteColours.textTertiary,
                          ),
                    ),
                ],
              ),
            ],
          ),
          if (colour.approximatePricePerLitre != null &&
              colour.priceLastChecked != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Prices approximate, last checked ${DateFormat.yMMMd().format(colour.priceLastChecked!)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: PaletteColours.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
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

/// Reusable "Buy This Paint" button that launches the retailer URL.
class BuyThisPaintButton extends StatefulWidget {
  const BuyThisPaintButton({
    required this.brand,
    required this.colourCode,
    required this.colourName,
    super.key,
  });

  final String brand;
  final String colourCode;
  final String colourName;

  @override
  State<BuyThisPaintButton> createState() => _BuyThisPaintButtonState();
}

class _BuyThisPaintButtonState extends State<BuyThisPaintButton> {
  Map<String, RetailerConfig>? _configs;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    final configs = await loadRetailerConfigs();
    if (mounted) setState(() => _configs = configs);
  }

  Future<void> _launchUrl() async {
    if (_configs == null) return;
    final config = _configs![widget.brand];
    if (config == null) return;

    final url = config.buildUrl(
      colourCode: widget.colourCode,
      colourName: widget.colourName,
    );
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _configs != null ? _launchUrl : null,
      icon: const Icon(Icons.shopping_bag_outlined, size: 16),
      label: const Text('Buy This Paint'),
      style: OutlinedButton.styleFrom(
        foregroundColor: PaletteColours.sageGreenDark,
        side: const BorderSide(color: PaletteColours.sageGreen),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        textStyle: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

class _CrossBrandSection extends StatefulWidget {
  const _CrossBrandSection({
    required this.closestMatch,
    required this.paintColourRepo,
  });

  final PaintColourMatch closestMatch;
  final PaintColourRepository paintColourRepo;

  @override
  State<_CrossBrandSection> createState() => _CrossBrandSectionState();
}

class _CrossBrandSectionState extends State<_CrossBrandSection> {
  List<CrossBrandMatch>? _crossBrandMatches;

  @override
  void initState() {
    super.initState();
    _loadCrossBrand();
  }

  Future<void> _loadCrossBrand() async {
    final matches = await widget.paintColourRepo.findCrossBrandMatches(
      widget.closestMatch.colour,
      threshold: 8.0,
    );
    if (mounted) {
      setState(() => _crossBrandMatches = matches);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_crossBrandMatches == null || _crossBrandMatches!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cross-brand equivalents',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Similar colours from other brands',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PaletteColours.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        ..._crossBrandMatches!.take(3).map((m) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _hexToColor(m.colour.hex),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: PaletteColours.divider),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.colour.name,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                          Text(
                            '${m.colour.brand} \u2022 ${m.matchPercent.toStringAsFixed(0)}% match',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: PaletteColours.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    if (m.colour.approximatePricePerLitre != null)
                      Text(
                        '\u00A3${m.colour.approximatePricePerLitre!.toStringAsFixed(0)}/L',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: PaletteColours.textTertiary,
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                BuyThisPaintButton(
                  brand: m.colour.brand,
                  colourCode: m.colour.code,
                  colourName: m.colour.name,
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        Text(
          'Paint finishes and pigments vary between brands. A close colour '
          'match is not identical. Always compare physical samples side by side.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PaletteColours.textTertiary,
                fontStyle: FontStyle.italic,
              ),
        ),
      ],
    );
  }
}

double _deltaEToPercent(double deltaE) {
  // Map delta-E to percentage: 0 -> 100%, 25+ -> 0%
  return (100 * (1 - (deltaE / 25))).clamp(0, 100);
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
