import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/core/colour/lab_colour.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/features/onboarding/data/era_affinities.dart';
import 'package:palette/features/onboarding/models/system_palette.dart';

/// Generate a role-based system palette from quiz results.
///
/// Roles: trim white, dominant walls (1-2), supporting walls (2-3),
/// deep anchor, accent pops (0-1), spine colour.
///
/// Each step uses progressive relaxation — strict filters first,
/// then widening if too few candidates.
SystemPalette? generateSystemPalette({
  required PaletteFamily primaryFamily,
  PaletteFamily? secondaryFamily,
  required List<PaintColour> allPaintColours,
  Undertone? undertoneTemperature,
  ChromaBand? saturationPreference,
  PropertyEra? propertyEra,
}) {
  if (allPaintColours.isEmpty) return null;

  final primaryPaints =
      allPaintColours.where((c) => c.paletteFamily == primaryFamily).toList();
  final secondaryPaints =
      secondaryFamily != null
          ? allPaintColours
              .where((c) => c.paletteFamily == secondaryFamily)
              .toList()
          : <PaintColour>[];
  final combinedPaints = [...primaryPaints, ...secondaryPaints];

  // Step 1: Trim White
  final trimWhite = _selectTrimWhite(
    allPaintColours,
    primaryPaints,
    undertoneTemperature,
  );
  if (trimWhite == null) return null;

  // Step 2: Dominant Walls (1-2)
  final eraAffinity = getEraAffinity(propertyEra);
  final dominantWalls = _selectDominantWalls(
    primaryPaints,
    undertoneTemperature,
    eraLRange: eraAffinity?.suggestedLRange,
  );
  if (dominantWalls.isEmpty) return null;

  // Step 3: Supporting Walls (2-3)
  final supportingWalls = _selectSupportingWalls(
    combinedPaints,
    dominantWalls,
    undertoneTemperature,
  );

  // Step 4: Deep Anchor (1)
  final deepAnchor = _selectDeepAnchor(
    combinedPaints,
    dominantWalls,
    allPaintColours,
  );
  if (deepAnchor == null) return null;

  // Step 5: Accent Pops (0-1)
  // Spec D5: muted users get 0 accent pops
  final accentPops =
      saturationPreference == ChromaBand.muted
          ? <PaintColour>[]
          : _selectAccentPops(
            allPaintColours,
            primaryFamily,
            dominantWalls,
            undertoneTemperature,
          );

  // Step 6: Spine Colour (1)
  final spineColour = _selectSpineColour(
    allPaintColours,
    dominantWalls,
    supportingWalls,
  );
  if (spineColour == null) return null;

  return SystemPalette(
    trimWhite: _toRef(trimWhite, 'trimWhite', 'Trim & Ceiling'),
    dominantWalls:
        dominantWalls
            .map((p) => _toRef(p, 'dominantWall', 'Main Wall Colour'))
            .toList(),
    supportingWalls:
        supportingWalls
            .map((p) => _toRef(p, 'supportingWall', 'Supporting Wall'))
            .toList(),
    deepAnchor: _toRef(deepAnchor, 'deepAnchor', 'Deep Anchor'),
    accentPops:
        accentPops.map((p) => _toRef(p, 'accentPop', 'Accent Pop')).toList(),
    spineColour: _toRef(spineColour, 'spineColour', 'Spine Colour'),
  );
}

PaintReference _toRef(PaintColour paint, String role, String roleLabel) {
  return PaintReference(
    paintId: paint.id,
    hex: paint.hex,
    name: paint.name,
    brand: paint.brand,
    role: role,
    roleLabel: roleLabel,
  );
}

LabColour _labOf(PaintColour p) => LabColour(p.labL, p.labA, p.labB);

double _dE(PaintColour a, PaintColour b) => deltaE2000(_labOf(a), _labOf(b));

bool _matchesUndertone(PaintColour p, Undertone? pref) {
  if (pref == null || pref == Undertone.neutral) return true;
  return p.undertone == pref || p.undertone == Undertone.neutral;
}

// ---------------------------------------------------------------------------
// Step 1: Trim White
// ---------------------------------------------------------------------------

PaintColour? _selectTrimWhite(
  List<PaintColour> all,
  List<PaintColour> primaryPaints,
  Undertone? undertone,
) {
  // Compute average a*/b* of primary family
  double avgA = 0, avgB = 0;
  if (primaryPaints.isNotEmpty) {
    for (final p in primaryPaints) {
      avgA += p.labA;
      avgB += p.labB;
    }
    avgA /= primaryPaints.length;
    avgB /= primaryPaints.length;
  }
  final targetLab = LabColour(95, avgA, avgB);

  // Progressive relaxation: L* > 90 → > 85 → > 80
  for (final minL in [90.0, 85.0, 80.0]) {
    var candidates = all.where((c) => c.labL > minL).toList();
    if (candidates.isEmpty) continue;

    // Prefer matching undertone
    if (undertone != null && undertone != Undertone.neutral) {
      final matched =
          candidates.where((c) => _matchesUndertone(c, undertone)).toList();
      if (matched.isNotEmpty) candidates = matched;
    }

    // Sort by delta-E to target
    candidates.sort((a, b) {
      final dA = deltaE2000(_labOf(a), targetLab);
      final dB = deltaE2000(_labOf(b), targetLab);
      final cmp = dA.compareTo(dB);
      return cmp != 0 ? cmp : a.hex.compareTo(b.hex);
    });

    return candidates.first;
  }

  return null;
}

// ---------------------------------------------------------------------------
// Step 2: Dominant Walls (1-2 from primary family, L* 55-80)
// ---------------------------------------------------------------------------

List<PaintColour> _selectDominantWalls(
  List<PaintColour> primaryPaints,
  Undertone? undertone, {
  (double, double)? eraLRange,
}) {
  for (final baseRange in [(55.0, 80.0), (45.0, 85.0), (35.0, 90.0)]) {
    // Soft blend with era's suggested L* range (80% user, 20% era)
    final range = _blendLRange(baseRange, eraLRange);
    var candidates =
        primaryPaints
            .where((c) => c.labL >= range.$1 && c.labL <= range.$2)
            .toList();
    if (candidates.isEmpty) continue;

    // Prefer matching undertone
    if (undertone != null && undertone != Undertone.neutral) {
      final matched =
          candidates.where((c) => _matchesUndertone(c, undertone)).toList();
      if (matched.length >= 2) candidates = matched;
    }

    // Sort by L* for spread
    candidates.sort((a, b) {
      final cmp = a.labL.compareTo(b.labL);
      return cmp != 0 ? cmp : a.hex.compareTo(b.hex);
    });

    if (candidates.length == 1) return [candidates.first];

    // Pick two with maximum L* spread
    return [candidates.first, candidates.last];
  }

  // Fallback: just use the first primary paint
  if (primaryPaints.isNotEmpty) return [primaryPaints.first];
  return [];
}

// ---------------------------------------------------------------------------
// Step 3: Supporting Walls (2-3 from primary+secondary, min dE 10 from dominant)
// ---------------------------------------------------------------------------

List<PaintColour> _selectSupportingWalls(
  List<PaintColour> combined,
  List<PaintColour> dominantWalls,
  Undertone? undertone,
) {
  final usedIds = dominantWalls.map((p) => p.id).toSet();

  for (final range in [
    (45.0, 75.0, 10.0),
    (35.0, 85.0, 7.0),
    (25.0, 90.0, 5.0),
  ]) {
    var candidates =
        combined
            .where(
              (c) =>
                  !usedIds.contains(c.id) &&
                  c.labL >= range.$1 &&
                  c.labL <= range.$2,
            )
            .toList();

    // Filter by min delta-E from each dominant wall
    candidates =
        candidates.where((c) {
          return dominantWalls.every((d) => _dE(c, d) >= range.$3);
        }).toList();

    if (candidates.isEmpty) continue;

    // Prefer matching undertone
    if (undertone != null && undertone != Undertone.neutral) {
      final matched =
          candidates.where((c) => _matchesUndertone(c, undertone)).toList();
      if (matched.length >= 2) candidates = matched;
    }

    // Sort by L* for spread, pick up to 3
    candidates.sort((a, b) {
      final cmp = a.labL.compareTo(b.labL);
      return cmp != 0 ? cmp : a.hex.compareTo(b.hex);
    });

    final count = candidates.length.clamp(0, 3);
    if (count <= 3) return candidates.take(count).toList();

    // Pick with spread: first, middle, last
    return [
      candidates.first,
      candidates[candidates.length ~/ 2],
      candidates.last,
    ];
  }

  return [];
}

// ---------------------------------------------------------------------------
// Step 4: Deep Anchor (1, L* < 45, lowest dE to dominant wall)
// ---------------------------------------------------------------------------

PaintColour? _selectDeepAnchor(
  List<PaintColour> combined,
  List<PaintColour> dominantWalls,
  List<PaintColour> all,
) {
  if (dominantWalls.isEmpty) return null;
  final dominantLab = _labOf(dominantWalls.first);

  for (final maxL in [45.0, 55.0, 65.0]) {
    var candidates = combined.where((c) => c.labL < maxL).toList();

    // Fallback to all paints if no combined candidates
    if (candidates.isEmpty) {
      candidates = all.where((c) => c.labL < maxL).toList();
    }

    if (candidates.isEmpty) continue;

    // Sort by delta-E to dominant wall (closest harmonically)
    candidates.sort((a, b) {
      final dA = deltaE2000(_labOf(a), dominantLab);
      final dB = deltaE2000(_labOf(b), dominantLab);
      final cmp = dA.compareTo(dB);
      return cmp != 0 ? cmp : a.hex.compareTo(b.hex);
    });

    return candidates.first;
  }

  return null;
}

// ---------------------------------------------------------------------------
// Step 5: Accent Pops (0-1, complementary/analogous, Cab* > 30)
// ---------------------------------------------------------------------------

List<PaintColour> _selectAccentPops(
  List<PaintColour> all,
  PaletteFamily primaryFamily,
  List<PaintColour> dominantWalls,
  Undertone? undertone,
) {
  final compFamilies = _getAccentFamilies(primaryFamily);

  for (final minCab in [30.0, 20.0, 10.0]) {
    var candidates =
        all
            .where(
              (c) =>
                  compFamilies.contains(c.paletteFamily) && c.cabStar > minCab,
            )
            .toList();

    if (candidates.isEmpty) continue;

    // Prefer matching undertone
    if (undertone != null && undertone != Undertone.neutral) {
      final matched =
          candidates.where((c) => _matchesUndertone(c, undertone)).toList();
      if (matched.isNotEmpty) candidates = matched;
    }

    // Sort by max hue contrast to dominant wall
    if (dominantWalls.isNotEmpty) {
      final domLab = _labOf(dominantWalls.first);
      candidates.sort((a, b) {
        final dA = deltaE2000(_labOf(a), domLab);
        final dB = deltaE2000(_labOf(b), domLab);
        final cmp = dB.compareTo(dA); // Higher delta-E = more contrast
        return cmp != 0 ? cmp : a.hex.compareTo(b.hex);
      });
    }

    return [candidates.first];
  }

  return [];
}

Set<PaletteFamily> _getAccentFamilies(PaletteFamily primary) {
  return switch (primary) {
    PaletteFamily.warmNeutrals => {
      PaletteFamily.jewelTones,
      PaletteFamily.brights,
    },
    PaletteFamily.coolNeutrals => {
      PaletteFamily.earthTones,
      PaletteFamily.brights,
    },
    PaletteFamily.earthTones => {
      PaletteFamily.coolNeutrals,
      PaletteFamily.jewelTones,
    },
    PaletteFamily.pastels => {PaletteFamily.jewelTones, PaletteFamily.darks},
    PaletteFamily.jewelTones => {
      PaletteFamily.pastels,
      PaletteFamily.warmNeutrals,
    },
    PaletteFamily.darks => {PaletteFamily.pastels, PaletteFamily.brights},
    PaletteFamily.brights => {PaletteFamily.coolNeutrals, PaletteFamily.darks},
  };
}

// ---------------------------------------------------------------------------
// Step 6: Spine Colour (1 neutral/muted mid-tone, L* 60-80, Cab* < 30)
// ---------------------------------------------------------------------------

PaintColour? _selectSpineColour(
  List<PaintColour> all,
  List<PaintColour> dominantWalls,
  List<PaintColour> supportingWalls,
) {
  final referenceColours = [...dominantWalls, ...supportingWalls];

  for (final params in [
    (60.0, 80.0, 30.0),
    (50.0, 85.0, 40.0),
    (40.0, 90.0, 50.0),
  ]) {
    var candidates =
        all
            .where(
              (c) =>
                  c.labL >= params.$1 &&
                  c.labL <= params.$2 &&
                  c.cabStar < params.$3,
            )
            .toList();

    if (candidates.isEmpty) continue;

    // Sort by minimum summed delta-E to all dominant + supporting walls
    // (the spine should be close to all of them)
    if (referenceColours.isNotEmpty) {
      candidates.sort((a, b) {
        final sumA = referenceColours.fold<double>(
          0,
          (sum, ref) => sum + deltaE2000(_labOf(a), _labOf(ref)),
        );
        final sumB = referenceColours.fold<double>(
          0,
          (sum, ref) => sum + deltaE2000(_labOf(b), _labOf(ref)),
        );
        final cmp = sumA.compareTo(sumB);
        return cmp != 0 ? cmp : a.hex.compareTo(b.hex);
      });
    }

    return candidates.first;
  }

  return null;
}

/// Blend a base L* range with an era-suggested range (80% base, 20% era).
/// Returns the base range if era range is null.
(double, double) _blendLRange((double, double) base, (double, double)? era) {
  if (era == null) return base;
  final minL = base.$1 * 0.8 + era.$1 * 0.2;
  final maxL = base.$2 * 0.8 + era.$2 * 0.2;
  return (minL, maxL);
}
