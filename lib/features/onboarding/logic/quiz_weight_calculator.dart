import 'package:palette/core/constants/enums.dart';

/// Constants for weight calculation.
const int stage2Budget = 4;
const double stage1Weight = 0.50;
const double stage2Weight = 0.40;
const double stage3Weight = 0.10; // reserved for future use
const int consistencyBonusThreshold = 3;
const int consistencyBonusValue = 2;

/// Result of the weight calculation.
class WeightCalculationResult {
  const WeightCalculationResult({
    required this.finalWeights,
    required this.confidence,
    required this.stage1Weights,
    required this.normalisedStage2Weights,
    required this.consistencyBonusApplied,
    this.consistencyBonusFamily,
  });

  final Map<PaletteFamily, double> finalWeights;
  final DnaConfidence confidence;
  final Map<PaletteFamily, double> stage1Weights;
  final Map<PaletteFamily, double> normalisedStage2Weights;
  final bool consistencyBonusApplied;
  final PaletteFamily? consistencyBonusFamily;
}

/// Calculate final family weights with normalisation, stage weighting,
/// and consistency bonus.
///
/// [stage1CardWeights]: List of 0-4 maps (one per memory prompt answer).
/// [stage2CardWeights]: List of 0-8+ maps (one per selected room card).
/// [stage2CardCount]: Number of Stage 2 cards selected (for normalisation).
WeightCalculationResult calculateWeights({
  required List<Map<String, int>> stage1CardWeights,
  required List<Map<String, int>> stage2CardWeights,
  required int stage2CardCount,
}) {
  // Step 1: Tally Stage 1 raw weights
  final stage1Raw = _tallyWeights(stage1CardWeights);

  // Step 2: Tally Stage 2 raw weights, then normalise
  final stage2Raw = _tallyWeights(stage2CardWeights);
  final stage2Normalised = _normaliseStage2(stage2Raw, stage2CardCount);

  // Step 3: Check consistency bonus (3+ of 4 Stage 1 cards agree)
  final bonusFamily = _checkConsistencyBonus(stage1CardWeights);

  // Step 4: Apply stage weighting and combine
  final combined = <PaletteFamily, double>{};
  for (final family in PaletteFamily.values) {
    final s1 = (stage1Raw[family] ?? 0.0) * stage1Weight;
    final s2 = (stage2Normalised[family] ?? 0.0) * stage2Weight;
    combined[family] = s1 + s2;
  }

  // Step 5: Apply consistency bonus
  if (bonusFamily != null) {
    combined[bonusFamily] =
        (combined[bonusFamily] ?? 0) + consistencyBonusValue;
  }

  // Step 6: Compute confidence
  final confidence = _computeConfidence(combined);

  return WeightCalculationResult(
    finalWeights: combined,
    confidence: confidence,
    stage1Weights: stage1Raw,
    normalisedStage2Weights: stage2Normalised,
    consistencyBonusApplied: bonusFamily != null,
    consistencyBonusFamily: bonusFamily,
  );
}

/// Tally raw weights from a list of card weight maps.
Map<PaletteFamily, double> _tallyWeights(List<Map<String, int>> cardWeights) {
  final tally = <PaletteFamily, double>{};

  for (final cardMap in cardWeights) {
    for (final entry in cardMap.entries) {
      final family = PaletteFamily.values.firstWhere(
        (f) => f.name == entry.key,
        orElse: () => PaletteFamily.warmNeutrals,
      );
      tally[family] = (tally[family] ?? 0) + entry.value;
    }
  }

  return tally;
}

/// Normalise Stage 2 weights so total contribution stays constant
/// regardless of how many cards were selected.
///
/// Formula: normalisedWeight = rawWeight * (budget / numberOfCardsSelected)
/// Selecting 1 card → 4x multiplier (strong signal).
/// Selecting 8 cards → 0.5x each (diluted signal).
Map<PaletteFamily, double> _normaliseStage2(
  Map<PaletteFamily, double> raw,
  int cardCount,
) {
  if (cardCount <= 0) return {};
  final factor = stage2Budget / cardCount;
  return raw.map((family, weight) => MapEntry(family, weight * factor));
}

/// Check if 3+ of the Stage 1 cards agree on the same primary family.
/// Returns the family to bonus, or null if no bonus applies.
PaletteFamily? _checkConsistencyBonus(
  List<Map<String, int>> stage1CardWeights,
) {
  // For each card, find its primary family (highest weight key)
  final primaryFamilies = <PaletteFamily>[];

  for (final cardMap in stage1CardWeights) {
    if (cardMap.isEmpty) continue;
    String? topKey;
    int topVal = -1;
    for (final entry in cardMap.entries) {
      if (entry.value > topVal) {
        topVal = entry.value;
        topKey = entry.key;
      }
    }
    if (topKey != null) {
      primaryFamilies.add(
        PaletteFamily.values.firstWhere(
          (f) => f.name == topKey,
          orElse: () => PaletteFamily.warmNeutrals,
        ),
      );
    }
  }

  // Count occurrences
  final counts = <PaletteFamily, int>{};
  for (final f in primaryFamilies) {
    counts[f] = (counts[f] ?? 0) + 1;
  }

  // Find if any family has 3+ cards pointing to it
  for (final entry in counts.entries) {
    if (entry.value >= consistencyBonusThreshold) {
      return entry.key;
    }
  }

  return null;
}

/// Compute confidence from the final weight distribution.
///
/// - low: no clear winner (top < 25% of total)
/// - medium: top two are very close (gap < 10% of total)
/// - high: clear primary family
DnaConfidence _computeConfidence(Map<PaletteFamily, double> weights) {
  final sorted =
      weights.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

  if (sorted.isEmpty || sorted.length < 2) return DnaConfidence.low;

  final topWeight = sorted[0].value;
  final secondWeight = sorted[1].value;
  final totalWeight = sorted.fold<double>(0, (sum, e) => sum + e.value);

  if (totalWeight == 0) return DnaConfidence.low;

  if (topWeight / totalWeight <= 0.25) {
    return DnaConfidence.low;
  } else if ((topWeight - secondWeight) / totalWeight < 0.10) {
    return DnaConfidence.medium;
  } else {
    return DnaConfidence.high;
  }
}
