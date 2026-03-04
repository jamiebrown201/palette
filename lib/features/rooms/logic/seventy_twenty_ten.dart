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
    this.warnings = const [],
  });

  /// 70% - Dominant colour (walls)
  final PaintColour heroColour;

  /// 20% - Supporting colour (large furnishings)
  final PaintColour betaColour;

  /// 10% - Accent colour (accessories, art)
  final PaintColour surpriseColour;

  /// Optional red thread dash colour
  final PaintColour? dashColour;

  /// Warnings generated during plan creation (e.g. conflicting locked furniture).
  final List<String> warnings;
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
  Undertone? dnaUndertone,
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

  final warnings = <String>[];

  // Check locked furniture for pre-filled tiers
  final lockedBeta = lockedFurniture
      ?.where((f) => f.role == FurnitureRole.beta)
      .toList();
  final lockedSurprise = lockedFurniture
      ?.where((f) => f.role == FurnitureRole.surprise)
      .toList();

  // Warn if locked items in same tier have very different colours
  if (lockedBeta != null && lockedBeta.length > 1) {
    if (_hasConflictingColours(lockedBeta.map((f) => f.colourHex))) {
      warnings.add(
        'Your locked supporting furniture items have very different colours '
        '— the suggested match is a compromise.',
      );
    }
  }
  if (lockedSurprise != null && lockedSurprise.length > 1) {
    if (_hasConflictingColours(lockedSurprise.map((f) => f.colourHex))) {
      warnings.add(
        'Your locked accent furniture items have very different colours '
        '— the suggested match is a compromise.',
      );
    }
  }

  // Determine preferred undertone: DNA preference overrides light direction
  // because DNA represents the user's aesthetic choice, while light direction
  // is environmental context.
  Undertone? preferredUndertone = dnaUndertone;
  if (preferredUndertone == null && direction != null) {
    final lightRec = getLightRecommendation(
      direction: direction,
      usageTime: usageTime,
    );
    preferredUndertone = lightRec.preferredUndertone;
  }

  // Find or use locked beta
  PaintColour betaColour;
  if (lockedBeta != null && lockedBeta.isNotEmpty) {
    // Average all locked furniture colours for this tier
    final averageHex = _averageLockedHexes(lockedBeta.map((f) => f.colourHex));
    betaColour = _findNearestPaint(
      hex: averageHex,
      allColours: candidatePaints,
      excludeIds: {heroColour.id},
    ) ?? _findNearestPaint(
      hex: averageHex,
      allColours: allPaintColours,
      excludeIds: const <String>{},
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
    final averageHex =
        _averageLockedHexes(lockedSurprise.map((f) => f.colourHex));
    surpriseColour = _findNearestPaint(
      hex: averageHex,
      allColours: candidatePaints,
      excludeIds: {heroColour.id, betaColour.id},
    ) ?? _findNearestPaint(
      hex: averageHex,
      allColours: allPaintColours,
      excludeIds: const <String>{},
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
    warnings: warnings,
  );
}

/// Find beta candidates with progressive relaxation.
///
/// Tries increasingly wider delta-E ranges and drops the undertone
/// filter if needed. Always returns at least one candidate.
List<PaintColour> _findBetaCandidates({
  required LabColour heroLab,
  required List<PaintColour> allColours,
  required String heroId,
  Undertone? preferredUndertone,
}) {
  // Progressive relaxation: strict → wide → no undertone filter → any
  final passes = [
    (minDE: 10.0, maxDE: 35.0, filterUndertone: true),
    (minDE: 5.0, maxDE: 50.0, filterUndertone: true),
    (minDE: 5.0, maxDE: 50.0, filterUndertone: false),
    (minDE: 3.0, maxDE: 70.0, filterUndertone: false),
  ];

  for (final pass in passes) {
    final candidates = <PaintColour>[];
    for (final pc in allColours) {
      if (pc.id == heroId) continue;
      final lab = LabColour(pc.labL, pc.labA, pc.labB);
      final dE = deltaE2000(heroLab, lab);
      if (dE < pass.minDE || dE > pass.maxDE) continue;
      if (pass.filterUndertone &&
          preferredUndertone != null &&
          pc.undertone != preferredUndertone &&
          pc.undertone != Undertone.neutral) {
        continue;
      }
      candidates.add(pc);
    }
    if (candidates.isNotEmpty) {
      // Sort by proximity to the dE 15–25 sweet spot
      candidates.sort((a, b) {
        final labA = LabColour(a.labL, a.labA, a.labB);
        final labB = LabColour(b.labL, b.labA, b.labB);
        final dA = (deltaE2000(heroLab, labA) - 20).abs();
        final dB = (deltaE2000(heroLab, labB) - 20).abs();
        return dA.compareTo(dB);
      });
      return candidates.take(10).toList();
    }
  }

  // Ultimate fallback: return the 5 closest paints by delta-E
  final sorted = allColours
      .where((pc) => pc.id != heroId)
      .map((pc) {
        final lab = LabColour(pc.labL, pc.labA, pc.labB);
        return (paint: pc, dE: deltaE2000(heroLab, lab));
      })
      .toList()
    ..sort((a, b) => a.dE.compareTo(b.dE));
  return sorted.take(5).map((e) => e.paint).toList();
}

/// Find surprise candidates with progressive relaxation.
///
/// Prefers a different palette family and complementary colours.
/// Falls back to wider criteria if strict search finds nothing.
List<PaintColour> _findSurpriseCandidates({
  required LabColour heroLab,
  required List<PaintColour> allColours,
  required PaletteFamily heroFamily,
  required Set<String> excludeIds,
}) {
  final complementaryFamily = _getComplementaryFamily(heroFamily);

  // Progressive relaxation: strict → relaxed → any family
  final passes = [
    (minDE: 15.0, requireDifferentFamily: true),
    (minDE: 8.0, requireDifferentFamily: true),
    (minDE: 5.0, requireDifferentFamily: false),
  ];

  for (final pass in passes) {
    final candidates = <PaintColour>[];
    for (final pc in allColours) {
      if (excludeIds.contains(pc.id)) continue;
      if (pass.requireDifferentFamily && pc.paletteFamily == heroFamily) {
        continue;
      }
      final lab = LabColour(pc.labL, pc.labA, pc.labB);
      final dE = deltaE2000(heroLab, lab);
      if (dE < pass.minDE) continue;

      final isComplementary = pc.paletteFamily == complementaryFamily;
      if (isComplementary) {
        candidates.insert(0, pc); // Prioritise complementary
      } else {
        candidates.add(pc);
      }
    }
    if (candidates.isNotEmpty) return candidates.take(8).toList();
  }

  // Ultimate fallback: closest paints excluding hero/beta
  final sorted = allColours
      .where((pc) => !excludeIds.contains(pc.id))
      .map((pc) {
        final lab = LabColour(pc.labL, pc.labA, pc.labB);
        return (paint: pc, dE: deltaE2000(heroLab, lab));
      })
      .toList()
    ..sort((a, b) => a.dE.compareTo(b.dE));
  return sorted.take(5).map((e) => e.paint).toList();
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

/// Average multiple locked furniture hex colours in Lab space.
///
/// When multiple items are locked for the same tier, this blends them
/// so the algorithm finds a paint that harmonises with all of them.
String _averageLockedHexes(Iterable<String> hexes) {
  final labs = hexes.map(hexToLab).toList();
  if (labs.length == 1) return hexes.first;

  final avgL = labs.map((l) => l.l).reduce((a, b) => a + b) / labs.length;
  final avgA = labs.map((l) => l.a).reduce((a, b) => a + b) / labs.length;
  final avgB = labs.map((l) => l.b).reduce((a, b) => a + b) / labs.length;

  return labToHex(LabColour(avgL, avgA, avgB));
}

/// Returns true if any pair of hex colours differ by more than dE 40.
bool _hasConflictingColours(Iterable<String> hexes) {
  final list = hexes.toList();
  for (var i = 0; i < list.length; i++) {
    for (var j = i + 1; j < list.length; j++) {
      final labA = hexToLab(list[i]);
      final labB = hexToLab(list[j]);
      if (deltaE2000(labA, labB) > 40) return true;
    }
  }
  return false;
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
