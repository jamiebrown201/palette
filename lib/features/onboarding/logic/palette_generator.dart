import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/paint_colour.dart';

/// A generated palette from the Colour DNA quiz.
class GeneratedPalette {
  const GeneratedPalette({
    required this.primaryFamily,
    required this.colours,
    this.secondaryFamily,
  });

  final PaletteFamily primaryFamily;
  final PaletteFamily? secondaryFamily;
  final List<PaletteColourEntry> colours;
}

/// A colour entry in a generated palette.
class PaletteColourEntry {
  const PaletteColourEntry({
    required this.hex,
    required this.isSurprise,
    this.paintColour,
  });

  final String hex;
  final bool isSurprise;
  final PaintColour? paintColour;
}

/// Generates a personalised colour palette from quiz family weights.
///
/// Algorithm:
/// 1. Sort families by weight, determine primary and secondary
/// 2. Select colours from paint DB with L* spread (deterministic)
/// 3. Add 1-2 "surprise" colours from complementary families
GeneratedPalette generatePalette({
  required Map<PaletteFamily, int> familyWeights,
  required List<PaintColour> allPaintColours,
  int targetSize = 10,
  Undertone? undertoneTemperature,
  ChromaBand? saturationPreference,
}) {
  // 1. Sort families by weight, determine primary and secondary
  final sorted = familyWeights.entries.toList()
    ..sort((a, b) {
      final cmp = b.value.compareTo(a.value);
      // Deterministic tiebreaker: enum index
      return cmp != 0 ? cmp : a.key.index.compareTo(b.key.index);
    });

  if (sorted.isEmpty) {
    return _fallbackPalette(allPaintColours, targetSize);
  }

  final primaryFamily = sorted.first.key;
  final secondaryFamily =
      sorted.length > 1 && sorted[1].value > 0 ? sorted[1].key : null;

  // 2. Collect candidate colours from primary and secondary families
  //    Sort by undertone preference then saturation preference (soft sorts)
  final primaryCandidates = _sortByPreferences(
    allPaintColours
        .where((c) => c.paletteFamily == primaryFamily)
        .toList(),
    undertoneTemperature,
    saturationPreference,
  );
  final secondaryCandidates = secondaryFamily != null
      ? _sortByPreferences(
          allPaintColours
              .where((c) => c.paletteFamily == secondaryFamily)
              .toList(),
          undertoneTemperature,
          saturationPreference,
        )
      : <PaintColour>[];

  // 3. Select colours with L* spread (deterministic)
  final mainCount = targetSize - 2; // Reserve 1-2 for surprise
  final primaryCount = secondaryFamily != null
      ? (mainCount * 0.6).ceil()
      : mainCount;
  final secondaryCount = mainCount - primaryCount;

  final selectedPrimary = _selectWithLightnessSpread(
    primaryCandidates,
    primaryCount,
    saturationPreference: saturationPreference,
  );
  final selectedSecondary = _selectWithLightnessSpread(
    secondaryCandidates,
    secondaryCount,
    saturationPreference: saturationPreference,
  );

  // 4. Add surprise colours from complementary family
  final surpriseFamily = _getComplementaryFamily(primaryFamily);
  final surpriseCandidates = allPaintColours
      .where((c) => c.paletteFamily == surpriseFamily)
      .toList();
  final surprises = _selectWithLightnessSpread(
    surpriseCandidates,
    targetSize - selectedPrimary.length - selectedSecondary.length,
  );

  // 5. Build the palette entries
  final entries = <PaletteColourEntry>[
    for (final pc in selectedPrimary)
      PaletteColourEntry(hex: pc.hex, isSurprise: false, paintColour: pc),
    for (final pc in selectedSecondary)
      PaletteColourEntry(hex: pc.hex, isSurprise: false, paintColour: pc),
    for (final pc in surprises)
      PaletteColourEntry(hex: pc.hex, isSurprise: true, paintColour: pc),
  ];

  return GeneratedPalette(
    primaryFamily: primaryFamily,
    secondaryFamily: secondaryFamily,
    colours: entries,
  );
}

/// Select colours from candidates ensuring L* spread across the range.
///
/// Deterministic: sorts by L* then hex, picks from each bucket.
/// When [saturationPreference] is set, picks the best saturation match
/// from each bucket instead of the median.
List<PaintColour> _selectWithLightnessSpread(
  List<PaintColour> candidates,
  int count, {
  ChromaBand? saturationPreference,
}) {
  if (candidates.isEmpty || count <= 0) return [];

  // Sort deterministically by L* then hex
  final sorted = List.of(candidates)
    ..sort((a, b) {
      final cmp = a.labL.compareTo(b.labL);
      return cmp != 0 ? cmp : a.hex.compareTo(b.hex);
    });

  if (sorted.length <= count) return sorted;

  final selected = <PaintColour>[];
  final bucketSize = sorted.length / count;

  for (var i = 0; i < count; i++) {
    final start = (i * bucketSize).floor();
    final end = ((i + 1) * bucketSize).floor().clamp(start + 1, sorted.length);
    final bucket = sorted.sublist(start, end);

    // Pick from bucket, excluding already selected
    final available = bucket.where((c) => !selected.contains(c)).toList();
    if (available.isNotEmpty) {
      if (saturationPreference != null && available.length > 1) {
        // Pick best saturation match from bucket
        available.sort((a, b) {
          final aSat = _saturationSortKey(a.cabStar, saturationPreference);
          final bSat = _saturationSortKey(b.cabStar, saturationPreference);
          final cmp = aSat.compareTo(bSat);
          return cmp != 0 ? cmp : a.hex.compareTo(b.hex);
        });
        selected.add(available.first);
      } else {
        // Deterministic: pick the median element
        selected.add(available[available.length ~/ 2]);
      }
    }
  }

  return selected;
}

/// Sort key for saturation preference within a bucket.
/// Lower is better (ascending sort).
double _saturationSortKey(double cabStar, ChromaBand preference) {
  return switch (preference) {
    ChromaBand.muted => cabStar, // lower chroma preferred
    ChromaBand.bold => -cabStar, // higher chroma preferred
    ChromaBand.mid => (cabStar - 37.5).abs(), // closer to mid preferred
  };
}

/// Tally family weights from quiz card selections.
///
/// Kept for backward compatibility with existing tests.
Map<PaletteFamily, int> tallyFamilyWeights(
  List<Map<String, int>> selectedCardWeights,
) {
  final tally = <PaletteFamily, int>{};

  for (final cardWeights in selectedCardWeights) {
    for (final entry in cardWeights.entries) {
      final family = PaletteFamily.values.firstWhere(
        (f) => f.name == entry.key,
        orElse: () => PaletteFamily.warmNeutrals,
      );
      tally[family] = (tally[family] ?? 0) + entry.value;
    }
  }

  return tally;
}

/// Sort candidates by undertone and saturation preferences (soft sorts).
///
/// Primary key: undertone (matching → 3, neutral → 2, opposite → 1).
/// Secondary key: saturation Cab* alignment:
///   - muted → ascending Cab* (prefer lower chroma)
///   - bold → descending Cab* (prefer higher chroma)
///   - mid → distance from Cab* 37.5 ascending (prefer middle range)
/// Tertiary: L* then hex for determinism.
List<PaintColour> _sortByPreferences(
  List<PaintColour> candidates,
  Undertone? undertonePreference,
  ChromaBand? saturationPreference,
) {
  if ((undertonePreference == null || undertonePreference == Undertone.neutral) &&
      saturationPreference == null) {
    return candidates;
  }

  int undertoneScore(Undertone paintUndertone) {
    if (undertonePreference == null ||
        undertonePreference == Undertone.neutral) return 0;
    if (paintUndertone == undertonePreference) return 3;
    if (paintUndertone == Undertone.neutral) return 2;
    return 1;
  }

  double saturationSortKey(double cabStar) {
    return switch (saturationPreference) {
      ChromaBand.muted => cabStar, // ascending: lower is better
      ChromaBand.bold => -cabStar, // descending: higher is better
      ChromaBand.mid => (cabStar - 37.5).abs(), // ascending: closer to mid
      null => 0,
    };
  }

  final sorted = List.of(candidates)
    ..sort((a, b) {
      // Primary: undertone preference
      final uCmp = undertoneScore(b.undertone).compareTo(
        undertoneScore(a.undertone),
      );
      if (uCmp != 0) return uCmp;

      // Secondary: saturation preference
      if (saturationPreference != null) {
        final sCmp = saturationSortKey(a.cabStar).compareTo(
          saturationSortKey(b.cabStar),
        );
        if (sCmp != 0) return sCmp;
      }

      // Deterministic tiebreaker: L* then hex
      final lCmp = a.labL.compareTo(b.labL);
      return lCmp != 0 ? lCmp : a.hex.compareTo(b.hex);
    });

  return sorted;
}

/// Get a complementary family for "surprise" colours.
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

GeneratedPalette _fallbackPalette(
  List<PaintColour> allColours,
  int targetSize,
) {
  final warmNeutrals = allColours
      .where((c) => c.paletteFamily == PaletteFamily.warmNeutrals)
      .toList();
  final selected = _selectWithLightnessSpread(warmNeutrals, targetSize);

  return GeneratedPalette(
    primaryFamily: PaletteFamily.warmNeutrals,
    colours: [
      for (final pc in selected)
        PaletteColourEntry(hex: pc.hex, isSurprise: false, paintColour: pc),
    ],
  );
}

/// Compute how many unique paint brands are represented.
int countBrandsInPalette(List<PaletteColourEntry> entries) {
  final brands = <String>{};
  for (final e in entries) {
    if (e.paintColour != null) brands.add(e.paintColour!.brand);
  }
  return brands.length;
}
