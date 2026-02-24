import 'dart:math';

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
/// 1. Tally family weights from all quiz selections
/// 2. Determine primary (and optional secondary) family
/// 3. Select 8-12 colours from paint DB with L* spread
/// 4. Add 1-2 "surprise" colours from complementary families
GeneratedPalette generatePalette({
  required Map<PaletteFamily, int> familyWeights,
  required List<PaintColour> allPaintColours,
  int targetSize = 10,
  Random? random,
}) {
  final rng = random ?? Random();

  // 1. Sort families by weight, determine primary and secondary
  final sorted = familyWeights.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  if (sorted.isEmpty) {
    // Fallback: warm neutrals as primary
    return _fallbackPalette(allPaintColours, rng, targetSize);
  }

  final primaryFamily = sorted.first.key;
  final secondaryFamily =
      sorted.length > 1 && sorted[1].value > 0 ? sorted[1].key : null;

  // 2. Collect candidate colours from primary and secondary families
  final primaryCandidates = allPaintColours
      .where((c) => c.paletteFamily == primaryFamily)
      .toList();
  final secondaryCandidates = secondaryFamily != null
      ? allPaintColours
          .where((c) => c.paletteFamily == secondaryFamily)
          .toList()
      : <PaintColour>[];

  // 3. Select colours with L* spread
  final mainCount = targetSize - 2; // Reserve 1-2 for surprise
  final primaryCount = secondaryFamily != null
      ? (mainCount * 0.6).ceil()
      : mainCount;
  final secondaryCount = mainCount - primaryCount;

  final selectedPrimary = _selectWithLightnessSpread(
    primaryCandidates,
    primaryCount,
    rng,
  );
  final selectedSecondary = _selectWithLightnessSpread(
    secondaryCandidates,
    secondaryCount,
    rng,
  );

  // 4. Add surprise colours from complementary family
  final surpriseFamily = _getComplementaryFamily(primaryFamily);
  final surpriseCandidates = allPaintColours
      .where((c) => c.paletteFamily == surpriseFamily)
      .toList();
  final surprises = _selectWithLightnessSpread(
    surpriseCandidates,
    targetSize - selectedPrimary.length - selectedSecondary.length,
    rng,
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
/// Divides the L* range into buckets and picks from each.
List<PaintColour> _selectWithLightnessSpread(
  List<PaintColour> candidates,
  int count,
  Random rng,
) {
  if (candidates.isEmpty || count <= 0) return [];
  if (candidates.length <= count) return List.of(candidates)..shuffle(rng);

  // Sort by lightness
  final sorted = List.of(candidates)
    ..sort((a, b) => a.labL.compareTo(b.labL));

  final selected = <PaintColour>[];
  final bucketSize = sorted.length / count;

  for (var i = 0; i < count; i++) {
    final start = (i * bucketSize).floor();
    final end = ((i + 1) * bucketSize).floor().clamp(start + 1, sorted.length);
    final bucket = sorted.sublist(start, end);

    // Pick randomly within bucket, ensuring we don't duplicate
    final available = bucket.where((c) => !selected.contains(c)).toList();
    if (available.isNotEmpty) {
      selected.add(available[rng.nextInt(available.length)]);
    }
  }

  return selected;
}

/// Tally family weights from quiz card selections.
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
  Random rng,
  int targetSize,
) {
  final warmNeutrals = allColours
      .where((c) => c.paletteFamily == PaletteFamily.warmNeutrals)
      .toList();
  final selected = _selectWithLightnessSpread(warmNeutrals, targetSize, rng);

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
