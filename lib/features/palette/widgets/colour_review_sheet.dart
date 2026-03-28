import 'dart:math';

import 'package:flutter/material.dart';
import 'package:palette/core/colour/chroma_band.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/core/colour/lab_colour.dart';
import 'package:palette/core/colour/palette_family.dart';
import 'package:palette/core/colour/palette_feedback.dart';
import 'package:palette/core/colour/undertone.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/features/rooms/logic/colour_plan_harmony.dart';

// ---------------------------------------------------------------------------
// Structured findings
// ---------------------------------------------------------------------------

enum FindingType { strength, clash, insight }

class ColourFinding {
  const ColourFinding({
    required this.title,
    required this.description,
    required this.hexes,
    required this.type,
    this.relationship,
  });

  final String title;
  final String description;
  final List<String> hexes;
  final FindingType type;
  final ColourRelationship? relationship;
}

/// Derive structured findings with hex references from a palette.
///
/// Re-runs pairwise colour science (same logic as [analysePaletteHealth])
/// but produces [ColourFinding] objects for visual rendering.
List<ColourFinding> deriveStructuredFindings(
  List<String> hexes, {
  Map<String, String>? nameMap,
}) {
  if (hexes.length < 2) return [];

  final labs = hexes.map(hexToLab).toList();
  final findings = <ColourFinding>[];

  // ── Pairwise hue analysis ──────────────────────────────────────────────
  // Track best representative pair per relationship type to avoid
  // overwhelming the user with dozens of similar findings.
  final bestPairByRel = <ColourRelationship, (int, int, double)>{};
  final relationshipCounts = <ColourRelationship, int>{};

  for (var i = 0; i < labs.length; i++) {
    for (var j = i + 1; j < labs.length; j++) {
      final dE = deltaE2000(labs[i], labs[j]);
      final rel = classifyHuePair(labs[i], labs[j]);
      final hd = _hueDiff(labs[i], labs[j]);

      // Nearly identical clash — always show (these are important)
      if (dE < 5) {
        final nameA = _display(hexes[i], nameMap);
        final nameB = _display(hexes[j], nameMap);
        findings.add(
          ColourFinding(
            title:
                nameA == nameB ? 'Very similar colours' : '$nameA and $nameB',
            description:
                'These two are very close — swapping one '
                'could add contrast and interest',
            hexes: [hexes[i], hexes[j]],
            type: FindingType.clash,
          ),
        );
      }
      // Bold disconnected clash
      else if (dE > 50 && rel == null && hd > 120) {
        final nameA = _display(hexes[i], nameMap);
        final nameB = _display(hexes[j], nameMap);
        findings.add(
          ColourFinding(
            title: '$nameA and $nameB',
            description:
                'Bold together — a bridging tone could '
                'help connect them in a room',
            hexes: [hexes[i], hexes[j]],
            type: FindingType.clash,
          ),
        );
      }

      // Track relationship — keep the most visually distinct pair
      if (rel != null) {
        relationshipCounts[rel] = (relationshipCounts[rel] ?? 0) + 1;
        final existing = bestPairByRel[rel];
        if (existing == null || dE > existing.$3) {
          bestPairByRel[rel] = (i, j, dE);
        }
      }
    }
  }

  // Add one representative strength card per relationship type
  for (final entry in bestPairByRel.entries) {
    final rel = entry.key;
    final (i, j, _) = entry.value;
    final count = relationshipCounts[rel] ?? 1;
    final desc = switch (rel) {
      ColourRelationship.complementary =>
        'Opposite colours that bring energy and visual interest',
      ColourRelationship.analogous =>
        'Neighbouring hues that create a calm, flowing feel',
      ColourRelationship.triadic =>
        'Evenly spaced colours for balanced vibrancy',
      ColourRelationship.splitComplementary =>
        'Softer contrast than direct opposites — dynamic yet approachable',
    };
    final countNote = count > 1 ? ' ($count pairs)' : '';
    findings.add(
      ColourFinding(
        title: '${rel.displayName}$countNote',
        description: desc,
        hexes: [hexes[i], hexes[j]],
        type: FindingType.strength,
        relationship: rel,
      ),
    );
  }

  // ── Lightness spread ───────────────────────────────────────────────────
  final lightnesses = labs.map((l) => l.l).toList();
  final minL = lightnesses.reduce(min);
  final maxL = lightnesses.reduce(max);
  final lightnessRange = maxL - minL;

  final hexesByLightness = List<String>.from(hexes)
    ..sort((a, b) => hexToLab(a).l.compareTo(hexToLab(b).l));

  if (lightnessRange < 15) {
    final avgL = lightnesses.reduce((a, b) => a + b) / lightnesses.length;
    final zone =
        avgL > 65
            ? 'light tones'
            : avgL < 35
            ? 'dark tones'
            : 'mid-tones';
    findings.add(
      ColourFinding(
        title: 'Narrow tonal range',
        description:
            'Your colours cluster around $zone — a lighter or '
            'darker accent would add depth',
        hexes: hexesByLightness,
        type: FindingType.clash,
      ),
    );
  } else if (lightnessRange > 50) {
    findings.add(
      ColourFinding(
        title: 'Good tonal range',
        description:
            'Dark to light spread creates depth and '
            'visual layering in a room',
        hexes: hexesByLightness,
        type: FindingType.strength,
      ),
    );
  }

  // ── Chroma diversity ───────────────────────────────────────────────────
  final chromaBands = labs.map((l) => classifyChromaBand(l.chroma)).toList();
  final mutedCount = chromaBands.where((b) => b == ChromaBand.muted).length;
  final boldCount = chromaBands.where((b) => b == ChromaBand.bold).length;
  final allSameBand = chromaBands.toSet().length == 1;

  if (allSameBand && hexes.length >= 3) {
    if (chromaBands.first == ChromaBand.muted) {
      findings.add(
        ColourFinding(
          title: 'All muted tones',
          description:
              'A bolder colour could be a focal point '
              'and bring the palette to life',
          hexes: hexes,
          type: FindingType.clash,
        ),
      );
    } else if (chromaBands.first == ChromaBand.bold) {
      findings.add(
        ColourFinding(
          title: 'All bold tones',
          description:
              'A quieter colour would let your '
              'statement pieces breathe',
          hexes: hexes,
          type: FindingType.clash,
        ),
      );
    }
  } else if (mutedCount > 0 && boldCount > 0) {
    findings.add(
      ColourFinding(
        title: 'Muted and bold balance',
        description:
            'Rhythm between quiet and statement pieces '
            'creates visual interest',
        hexes: hexes,
        type: FindingType.strength,
      ),
    );
  }

  // ── Palette family coherence ───────────────────────────────────────────
  final families = labs.map(classifyPaletteFamily).toList();
  final familyCounts = <PaletteFamily, int>{};
  for (final f in families) {
    familyCounts[f] = (familyCounts[f] ?? 0) + 1;
  }
  final dominantEntry = familyCounts.entries.reduce(
    (a, b) => a.value >= b.value ? a : b,
  );
  final dominantFraction = dominantEntry.value / hexes.length;

  if (dominantFraction >= 0.6) {
    findings.add(
      ColourFinding(
        title: 'Rooted in ${_familyLabel(dominantEntry.key)}',
        description:
            'A cohesive family identity that makes the '
            'palette feel intentional',
        hexes: hexes,
        type: FindingType.strength,
      ),
    );
  } else if (familyCounts.length >= hexes.length && hexes.length >= 3) {
    findings.add(
      ColourFinding(
        title: 'Eclectic colour families',
        description:
            'A diverse mix — bold choices that need a '
            'unifying element to connect them',
        hexes: hexes,
        type: FindingType.insight,
      ),
    );
  }

  // ── Undertone balance ──────────────────────────────────────────────────
  final undertones = labs.map((l) => classifyUndertone(l).classification);
  final warmCount = undertones.where((u) => u == Undertone.warm).length;
  final coolCount = undertones.where((u) => u == Undertone.cool).length;
  final total = hexes.length;

  if (warmCount > 0 && coolCount > 0) {
    findings.add(
      ColourFinding(
        title: 'Warm and cool balance',
        description:
            'Temperature contrast adds dimension and prevents '
            'the palette from feeling one-note',
        hexes: hexes,
        type: FindingType.strength,
      ),
    );
  } else if (warmCount == total) {
    findings.add(
      ColourFinding(
        title: 'All warm-toned',
        description: 'Cohesive warmth — cosy and inviting',
        hexes: hexes,
        type: FindingType.insight,
      ),
    );
  } else if (coolCount == total) {
    findings.add(
      ColourFinding(
        title: 'All cool-toned',
        description: 'Serene and calming — fresh and contemporary',
        hexes: hexes,
        type: FindingType.insight,
      ),
    );
  }

  return findings;
}

double _hueDiff(LabColour a, LabColour b) {
  var diff = (a.hueAngle - b.hueAngle).abs();
  if (diff > 180) diff = 360 - diff;
  return diff;
}

String _familyLabel(PaletteFamily f) => switch (f) {
  PaletteFamily.pastels => 'pastels',
  PaletteFamily.brights => 'brights',
  PaletteFamily.jewelTones => 'jewel tones',
  PaletteFamily.earthTones => 'earth tones',
  PaletteFamily.darks => 'darks',
  PaletteFamily.warmNeutrals => 'warm neutrals',
  PaletteFamily.coolNeutrals => 'cool neutrals',
};

String _display(String hex, Map<String, String>? nameMap) {
  if (nameMap == null) return hex.toUpperCase();
  return nameMap[hex.toLowerCase()] ?? hex.toUpperCase();
}

// ---------------------------------------------------------------------------
// Colour Review Sheet
// ---------------------------------------------------------------------------

class ColourReviewSheet extends StatefulWidget {
  const ColourReviewSheet({
    required this.hexes,
    required this.nameMap,
    required this.health,
    required this.findings,
    this.onSwapColour,
    this.onAddColour,
    this.onColourTap,
    super.key,
  });

  final List<String> hexes;
  final Map<String, String> nameMap;
  final PaletteHealthSummary health;
  final List<ColourFinding> findings;
  final ValueChanged<String>? onSwapColour;
  final VoidCallback? onAddColour;
  final ValueChanged<String>? onColourTap;

  @override
  State<ColourReviewSheet> createState() => _ColourReviewSheetState();
}

class _ColourReviewSheetState extends State<ColourReviewSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _strengthsOpacity;
  late final Animation<Offset> _strengthsSlide;
  late final Animation<double> _clashesOpacity;
  late final Animation<Offset> _clashesSlide;
  late final Animation<double> _suggestionOpacity;
  late final Animation<Offset> _suggestionSlide;
  late final Animation<double> _exploreOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _headerOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _strengthsOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
    );
    _strengthsSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
      ),
    );

    _clashesOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
    );
    _clashesSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );

    _suggestionOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 0.9, curve: Curves.easeOut),
    );
    _suggestionSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.9, curve: Curves.easeOut),
      ),
    );

    _exploreOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strengths =
        widget.findings.where((f) => f.type == FindingType.strength).toList();
    final clashes =
        widget.findings.where((f) => f.type == FindingType.clash).toList();
    final insights =
        widget.findings.where((f) => f.type == FindingType.insight).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
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

              // Header
              SlideTransition(
                position: _headerSlide,
                child: FadeTransition(
                  opacity: _headerOpacity,
                  child: _buildHeader(context),
                ),
              ),

              // Strengths
              if (strengths.isNotEmpty) ...[
                const SizedBox(height: 24),
                SlideTransition(
                  position: _strengthsSlide,
                  child: FadeTransition(
                    opacity: _strengthsOpacity,
                    child: _buildStrengthsSection(context, strengths),
                  ),
                ),
              ],

              // Clashes
              if (clashes.isNotEmpty) ...[
                const SizedBox(height: 24),
                SlideTransition(
                  position: _clashesSlide,
                  child: FadeTransition(
                    opacity: _clashesOpacity,
                    child: _buildClashesSection(context, clashes),
                  ),
                ),
              ],

              // Insights
              if (insights.isNotEmpty) ...[
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _clashesOpacity,
                  child: _buildInsightsSection(context, insights),
                ),
              ],

              // Suggestion CTA
              if (widget.health.suggestion != null) ...[
                const SizedBox(height: 24),
                SlideTransition(
                  position: _suggestionSlide,
                  child: FadeTransition(
                    opacity: _suggestionOpacity,
                    child: _buildSuggestionCard(context),
                  ),
                ),
              ],

              // Explore strip
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _exploreOpacity,
                child: _buildExploreStrip(context),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final hasIssues = widget.health.hasIssues;
    final chipBg =
        hasIssues
            ? PaletteColours.softGold.withValues(alpha: 0.2)
            : PaletteColours.sageGreen.withValues(alpha: 0.2);
    final chipFg =
        hasIssues ? PaletteColours.softGoldDark : PaletteColours.sageGreenDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Palette Story',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            widget.health.verdict,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: chipFg,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.health.explanation,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: PaletteColours.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStrengthsSection(
    BuildContext context,
    List<ColourFinding> strengths,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 18,
              color: PaletteColours.sageGreen,
            ),
            const SizedBox(width: 8),
            Text(
              'What works',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final finding in strengths) ...[
          _StrengthCard(finding: finding, nameMap: widget.nameMap),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildClashesSection(
    BuildContext context,
    List<ColourFinding> clashes,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.lightbulb_outline,
              size: 18,
              color: PaletteColours.softGold,
            ),
            const SizedBox(width: 8),
            Text(
              'Worth knowing',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final finding in clashes) ...[
          _ClashCard(
            finding: finding,
            nameMap: widget.nameMap,
            onSwap:
                finding.hexes.length == 2
                    ? () {
                      Navigator.pop(context);
                      widget.onSwapColour?.call(finding.hexes.first);
                    }
                    : null,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildInsightsSection(
    BuildContext context,
    List<ColourFinding> insights,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good to know',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        for (final finding in insights) _InsightRow(finding: finding),
      ],
    );
  }

  Widget _buildSuggestionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaletteColours.sageGreenLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.auto_fix_high,
                size: 18,
                color: PaletteColours.sageGreenDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.health.suggestion!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: PaletteColours.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (widget.onAddColour != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onAddColour!();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add a colour'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExploreStrip(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore your colours',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.hexes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final hex = widget.hexes[index];
              final name = widget.nameMap[hex.toLowerCase()];
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  widget.onColourTap?.call(hex);
                },
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _hexToColor(hex),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: PaletteColours.divider),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 56,
                      child: Text(
                        name ?? '',
                        style: Theme.of(context).textTheme.labelSmall,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Visual card widgets
// ---------------------------------------------------------------------------

class _StrengthCard extends StatelessWidget {
  const _StrengthCard({required this.finding, required this.nameMap});

  final ColourFinding finding;
  final Map<String, String> nameMap;

  @override
  Widget build(BuildContext context) {
    final isPair = finding.hexes.length == 2 && finding.relationship != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaletteColours.softCream,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: PaletteColours.sageGreen, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPair)
            _PairSwatches(hexes: finding.hexes, nameMap: nameMap)
          else if (finding.hexes.length > 2)
            _PaletteStrip(hexes: finding.hexes),
          if (finding.hexes.isNotEmpty) const SizedBox(height: 12),
          if (finding.relationship != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: PaletteColours.sageGreenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                finding.title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: PaletteColours.sageGreenDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Text(finding.title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            finding.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PaletteColours.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClashCard extends StatelessWidget {
  const _ClashCard({required this.finding, required this.nameMap, this.onSwap});

  final ColourFinding finding;
  final Map<String, String> nameMap;
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    final isPair = finding.hexes.length == 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaletteColours.softGoldLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: PaletteColours.softGold, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPair)
            _LargeComparisonSwatches(hexes: finding.hexes, nameMap: nameMap)
          else if (finding.hexes.length > 2)
            _PaletteStrip(hexes: finding.hexes),
          if (finding.hexes.isNotEmpty) const SizedBox(height: 12),
          Text(
            finding.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PaletteColours.textSecondary,
            ),
          ),
          if (onSwap != null && isPair) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onSwap,
              style: OutlinedButton.styleFrom(
                foregroundColor: PaletteColours.sageGreenDark,
                side: const BorderSide(color: PaletteColours.sageGreen),
              ),
              child: const Text('Swap colour'),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Swatch components
// ---------------------------------------------------------------------------

class _PairSwatches extends StatelessWidget {
  const _PairSwatches({required this.hexes, required this.nameMap});

  final List<String> hexes;
  final Map<String, String> nameMap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < hexes.length && i < 2; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _hexToColor(hexes[i]),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: PaletteColours.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${_display(hexes[0], nameMap)}  \u2022  ${_display(hexes[1], nameMap)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _LargeComparisonSwatches extends StatelessWidget {
  const _LargeComparisonSwatches({required this.hexes, required this.nameMap});

  final List<String> hexes;
  final Map<String, String> nameMap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < hexes.length && i < 2; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: _hexToColor(hexes[i]),
                borderRadius: BorderRadius.only(
                  topLeft: i == 0 ? const Radius.circular(10) : Radius.zero,
                  bottomLeft: i == 0 ? const Radius.circular(10) : Radius.zero,
                  topRight: i == 1 ? const Radius.circular(10) : Radius.zero,
                  bottomRight: i == 1 ? const Radius.circular(10) : Radius.zero,
                ),
              ),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(6),
              child: Text(
                _display(hexes[i], nameMap),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _textColorForBackground(hexes[i]),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PaletteStrip extends StatelessWidget {
  const _PaletteStrip({required this.hexes});

  final List<String> hexes;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final hex in hexes)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _hexToColor(hex),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: PaletteColours.divider),
            ),
          ),
      ],
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.finding});

  final ColourFinding finding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: PaletteColours.textTertiary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${finding.title} — ${finding.description}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PaletteColours.textSecondary,
              ),
            ),
          ),
          ...finding.hexes
              .take(5)
              .map(
                (hex) => Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _hexToColor(hex),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Color _textColorForBackground(String hex) {
  final lab = hexToLab(hex);
  return lab.l > 55 ? PaletteColours.textPrimary : Colors.white;
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
