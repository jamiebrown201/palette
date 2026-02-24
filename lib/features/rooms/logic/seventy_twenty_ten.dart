import 'dart:math';

import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/core/colour/lab_colour.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/locked_furniture.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/features/rooms/logic/light_recommendations.dart';

/// The result of a 70/20/10 colour plan generation.
class ColourPlan {
  const ColourPlan({
    required this.heroColour,
    required this.betaColour,
    required this.surpriseColour,
    this.dashColour,
  });

  /// 70% - Dominant colour (walls)
  final PaintColour heroColour;

  /// 20% - Supporting colour (large furnishings)
  final PaintColour betaColour;

  /// 10% - Accent colour (accessories, art)
  final PaintColour surpriseColour;

  /// Optional red thread dash colour
  final PaintColour? dashColour;
}

/// Generate a 70/20/10 colour plan for a room.
///
/// Algorithm:
/// 1. Start with the hero colour
/// 2. Find a beta that's analogous or complementary, filtered by light direction
/// 3. Find a surprise from a different palette family
/// 4. Optional dash colour from red thread
///
/// When [lockedFurniture] is provided, locked items pre-fill their tier and
/// the algorithm only generates colours for unfilled tiers.
///
/// When [budget] is provided, candidate paints are filtered by price bracket.
ColourPlan? generateColourPlan({
  required PaintColour heroColour,
  required List<PaintColour> allPaintColours,
  CompassDirection? direction,
  UsageTime usageTime = UsageTime.allDay,
  List<String>? redThreadHexes,
  List<LockedFurniture>? lockedFurniture,
  BudgetBracket? budget,
  Random? random,
}) {
  final rng = random ?? Random();
  final heroLab = LabColour(heroColour.labL, heroColour.labA, heroColour.labB);

  // Filter paints by budget bracket if set
  final paints = budget != null
      ? _filterByBudget(allPaintColours, budget)
      : allPaintColours;
  // Fall back to unfiltered if budget filtering leaves too few options
  final candidatePaints = paints.length >= 10 ? paints : allPaintColours;

  // Check locked furniture for pre-filled tiers
  final lockedBeta = lockedFurniture
      ?.where((f) => f.role == FurnitureRole.beta)
      .toList();
  final lockedSurprise = lockedFurniture
      ?.where((f) => f.role == FurnitureRole.surprise)
      .toList();

  // Determine preferred undertone based on light
  Undertone? preferredUndertone;
  if (direction != null) {
    final lightRec = getLightRecommendation(
      direction: direction,
      usageTime: usageTime,
    );
    preferredUndertone = lightRec.preferredUndertone;
  }

  // Find or use locked beta
  PaintColour betaColour;
  if (lockedBeta != null && lockedBeta.isNotEmpty) {
    // Find nearest paint to the locked furniture colour
    betaColour = _findNearestPaint(
      hex: lockedBeta.first.colourHex,
      allColours: candidatePaints,
      excludeIds: {heroColour.id},
    ) ?? candidatePaints.first;
  } else {
    final betaCandidates = _findBetaCandidates(
      heroLab: heroLab,
      allColours: candidatePaints,
      heroId: heroColour.id,
      preferredUndertone: preferredUndertone,
    );
    if (betaCandidates.isEmpty) return null;
    betaColour = betaCandidates[rng.nextInt(betaCandidates.length)];
  }

  // Find or use locked surprise
  PaintColour surpriseColour;
  if (lockedSurprise != null && lockedSurprise.isNotEmpty) {
    surpriseColour = _findNearestPaint(
      hex: lockedSurprise.first.colourHex,
      allColours: candidatePaints,
      excludeIds: {heroColour.id, betaColour.id},
    ) ?? candidatePaints.first;
  } else {
    final surpriseCandidates = _findSurpriseCandidates(
      heroLab: heroLab,
      allColours: candidatePaints,
      heroFamily: heroColour.paletteFamily,
      excludeIds: {heroColour.id, betaColour.id},
    );
    if (surpriseCandidates.isEmpty) return null;
    surpriseColour =
        surpriseCandidates[rng.nextInt(surpriseCandidates.length)];
  }

  // Find dash: closest red thread colour that exists as a paint colour
  PaintColour? dashColour;
  if (redThreadHexes != null && redThreadHexes.isNotEmpty) {
    dashColour = _findDashColour(
      redThreadHexes: redThreadHexes,
      allColours: candidatePaints,
      excludeIds: {heroColour.id, betaColour.id, surpriseColour.id},
    );
  }

  return ColourPlan(
    heroColour: heroColour,
    betaColour: betaColour,
    surpriseColour: surpriseColour,
    dashColour: dashColour,
  );
}

/// Find beta candidates: similar lightness direction, moderate contrast.
List<PaintColour> _findBetaCandidates({
  required LabColour heroLab,
  required List<PaintColour> allColours,
  required String heroId,
  Undertone? preferredUndertone,
}) {
  final candidates = <PaintColour>[];

  for (final pc in allColours) {
    if (pc.id == heroId) continue;

    final lab = LabColour(pc.labL, pc.labA, pc.labB);
    final dE = deltaE2000(heroLab, lab);

    // Beta should be noticeably different but not clashing
    // Delta-E between 10-35 is a good range
    if (dE < 10 || dE > 35) continue;

    // If we have a preferred undertone, filter for it
    if (preferredUndertone != null &&
        pc.undertone != preferredUndertone &&
        pc.undertone != Undertone.neutral) {
      continue;
    }

    candidates.add(pc);
  }

  // Sort by delta-E proximity to the 15-25 sweet spot
  candidates.sort((a, b) {
    final labA = LabColour(a.labL, a.labA, a.labB);
    final labB = LabColour(b.labL, b.labA, b.labB);
    final dA = (deltaE2000(heroLab, labA) - 20).abs();
    final dB = (deltaE2000(heroLab, labB) - 20).abs();
    return dA.compareTo(dB);
  });

  return candidates.take(10).toList();
}

/// Find surprise candidates: different family, complementary.
List<PaintColour> _findSurpriseCandidates({
  required LabColour heroLab,
  required List<PaintColour> allColours,
  required PaletteFamily heroFamily,
  required Set<String> excludeIds,
}) {
  final complementaryFamily = _getComplementaryFamily(heroFamily);
  final candidates = <PaintColour>[];

  for (final pc in allColours) {
    if (excludeIds.contains(pc.id)) continue;
    if (pc.paletteFamily == heroFamily) continue;

    // Prefer complementary family
    final isComplementary = pc.paletteFamily == complementaryFamily;
    final lab = LabColour(pc.labL, pc.labA, pc.labB);
    final dE = deltaE2000(heroLab, lab);

    // Surprise should be noticeable: dE > 15
    if (dE < 15) continue;

    if (isComplementary) {
      candidates.insert(0, pc); // Prioritise complementary
    } else {
      candidates.add(pc);
    }
  }

  return candidates.take(8).toList();
}

/// Find the best red thread dash colour.
PaintColour? _findDashColour({
  required List<String> redThreadHexes,
  required List<PaintColour> allColours,
  required Set<String> excludeIds,
}) {
  PaintColour? best;
  var bestDeltaE = double.infinity;

  for (final threadHex in redThreadHexes) {
    final threadLab = hexToLab(threadHex);

    for (final pc in allColours) {
      if (excludeIds.contains(pc.id)) continue;
      final lab = LabColour(pc.labL, pc.labA, pc.labB);
      final dE = deltaE2000(threadLab, lab);
      if (dE < bestDeltaE) {
        bestDeltaE = dE;
        best = pc;
      }
    }
  }

  return best;
}

/// Find the nearest paint colour to a given hex.
PaintColour? _findNearestPaint({
  required String hex,
  required List<PaintColour> allColours,
  required Set<String> excludeIds,
}) {
  final lab = hexToLab(hex);
  PaintColour? best;
  var bestDeltaE = double.infinity;

  for (final pc in allColours) {
    if (excludeIds.contains(pc.id)) continue;
    final pcLab = LabColour(pc.labL, pc.labA, pc.labB);
    final dE = deltaE2000(lab, pcLab);
    if (dE < bestDeltaE) {
      bestDeltaE = dE;
      best = pc;
    }
  }
  return best;
}

/// Filter paints by budget bracket based on price per litre.
List<PaintColour> _filterByBudget(
  List<PaintColour> paints,
  BudgetBracket budget,
) {
  return paints.where((p) {
    final price = p.approximatePricePerLitre;
    if (price == null) return true; // Include unpriced paints
    return switch (budget) {
      BudgetBracket.affordable => price <= 25,
      BudgetBracket.midRange => price > 15 && price <= 50,
      BudgetBracket.investment => price > 30,
    };
  }).toList();
}

PaletteFamily _getComplementaryFamily(PaletteFamily primary) {
  return switch (primary) {
    PaletteFamily.pastels => PaletteFamily.jewelTones,
    PaletteFamily.brights => PaletteFamily.coolNeutrals,
    PaletteFamily.jewelTones => PaletteFamily.pastels,
    PaletteFamily.earthTones => PaletteFamily.coolNeutrals,
    PaletteFamily.darks => PaletteFamily.pastels,
    PaletteFamily.warmNeutrals => PaletteFamily.jewelTones,
    PaletteFamily.coolNeutrals => PaletteFamily.earthTones,
  };
}
