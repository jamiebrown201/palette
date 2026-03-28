import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/features/onboarding/logic/quiz_weight_calculator.dart';

void main() {
  group('calculateWeights', () {
    // ── Fixture 1: Pure warm neutrals ───────────────────────────────────
    test('pure warm neutrals: high confidence, consistency bonus', () {
      final result = calculateWeights(
        stage1CardWeights: [
          {'warmNeutrals': 2, 'earthTones': 1, 'pastels': 1},
          {'warmNeutrals': 2, 'coolNeutrals': 1},
          {'warmNeutrals': 2, 'earthTones': 1},
          {'warmNeutrals': 3},
        ],
        stage2CardWeights: [
          {'warmNeutrals': 1, 'pastels': 1},
          {'warmNeutrals': 2, 'earthTones': 1},
        ],
        stage2CardCount: 2,
      );

      // Primary should be warmNeutrals
      final sorted =
          result.finalWeights.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      expect(sorted.first.key, PaletteFamily.warmNeutrals);

      // Confidence should be high (clear winner)
      expect(result.confidence, DnaConfidence.high);

      // Consistency bonus should be applied (all 4 Stage 1 cards point to warmNeutrals)
      expect(result.consistencyBonusApplied, isTrue);
      expect(result.consistencyBonusFamily, PaletteFamily.warmNeutrals);
    });

    // ── Fixture 2: Pure cool neutrals ───────────────────────────────────
    test('pure cool neutrals: high confidence', () {
      final result = calculateWeights(
        stage1CardWeights: [
          {'coolNeutrals': 3},
          {'coolNeutrals': 2, 'pastels': 1},
          {'coolNeutrals': 2, 'darks': 1},
          {'coolNeutrals': 3},
        ],
        stage2CardWeights: [
          {'coolNeutrals': 2},
        ],
        stage2CardCount: 1,
      );

      final sorted =
          result.finalWeights.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      expect(sorted.first.key, PaletteFamily.coolNeutrals);
      expect(result.confidence, DnaConfidence.high);
      expect(result.consistencyBonusApplied, isTrue);
    });

    // ── Fixture 3: Pure jewel tones ─────────────────────────────────────
    test('pure jewel tones: high confidence', () {
      final result = calculateWeights(
        stage1CardWeights: [
          {'jewelTones': 3, 'darks': 1},
          {'jewelTones': 2, 'earthTones': 1},
          {'jewelTones': 3},
          {'jewelTones': 2, 'pastels': 1},
        ],
        stage2CardWeights: [
          {'jewelTones': 2, 'darks': 1},
        ],
        stage2CardCount: 1,
      );

      final sorted =
          result.finalWeights.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      expect(sorted.first.key, PaletteFamily.jewelTones);
      expect(result.confidence, DnaConfidence.high);
    });

    // ── Fixture 4: Mixed warm/cool ──────────────────────────────────────
    test('mixed warm and cool: medium or low confidence', () {
      final result = calculateWeights(
        stage1CardWeights: [
          {'warmNeutrals': 3},
          {'coolNeutrals': 3},
          {'warmNeutrals': 2, 'earthTones': 1},
          {'coolNeutrals': 2, 'pastels': 1},
        ],
        stage2CardWeights: [
          {'warmNeutrals': 1},
          {'coolNeutrals': 1},
        ],
        stage2CardCount: 2,
      );

      // Confidence should not be high since warm and cool are close
      expect(result.confidence, anyOf(DnaConfidence.medium, DnaConfidence.low));

      // No consistency bonus (2 warm, 2 cool)
      expect(result.consistencyBonusApplied, isFalse);
    });

    // ── Fixture 5: Stage 2 domination (verifies normalisation) ──────────
    test('Stage 2 domination does not flip primary when Stage 1 is clear', () {
      // Stage 1: clearly warmNeutrals
      // Stage 2: 8 cards all pointing to darks
      final result = calculateWeights(
        stage1CardWeights: [
          {'warmNeutrals': 3},
          {'warmNeutrals': 3},
          {'warmNeutrals': 2, 'earthTones': 1},
          {'warmNeutrals': 3},
        ],
        stage2CardWeights: [
          {'darks': 3},
          {'darks': 3},
          {'darks': 3},
          {'darks': 3},
          {'darks': 3},
          {'darks': 3},
          {'darks': 3},
          {'darks': 3},
        ],
        stage2CardCount: 8,
      );

      final sorted =
          result.finalWeights.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      // warmNeutrals should remain primary because:
      // Stage 1 raw: warmNeutrals = 11, * 0.50 = 5.5
      // Consistency bonus: +2 = 7.5
      // Stage 2 raw: darks = 24, normalised = 24 * (4/8) = 12, * 0.40 = 4.8
      // So warmNeutrals (7.5) beats darks (4.8)
      expect(sorted.first.key, PaletteFamily.warmNeutrals);
    });

    // ── Fixture 6: Minimal Stage 2 (1 selection) ────────────────────────
    test('minimal Stage 2: single selection gets 4x multiplier', () {
      final result = calculateWeights(
        stage1CardWeights: [
          {'warmNeutrals': 2, 'earthTones': 1},
          {'warmNeutrals': 2, 'pastels': 1},
          {'warmNeutrals': 2},
          {'warmNeutrals': 3},
        ],
        stage2CardWeights: [
          {'earthTones': 2, 'warmNeutrals': 1},
        ],
        stage2CardCount: 1,
      );

      // The single Stage 2 card should get 4x: earthTones = 2*4 = 8
      // After stage weighting: earthTones = 8 * 0.40 = 3.2
      expect(result.normalisedStage2Weights[PaletteFamily.earthTones], 8.0);
    });

    // ── Fixture 7: Maximal Stage 2 (all 8 selections) ───────────────────
    test('maximal Stage 2: 8 selections each get 0.5x multiplier', () {
      final result = calculateWeights(
        stage1CardWeights: [
          {'warmNeutrals': 2},
          {'warmNeutrals': 2},
          {'warmNeutrals': 2},
          {'warmNeutrals': 2},
        ],
        stage2CardWeights: [
          {'pastels': 2},
          {'pastels': 2},
          {'pastels': 2},
          {'pastels': 2},
          {'pastels': 2},
          {'pastels': 2},
          {'pastels': 2},
          {'pastels': 2},
        ],
        stage2CardCount: 8,
      );

      // 8 cards * pastels:2 = 16 raw, normalised = 16 * (4/8) = 8.0
      expect(result.normalisedStage2Weights[PaletteFamily.pastels], 8.0);
    });

    // ── Fixture 8: Earth tones path ─────────────────────────────────────
    test('earth tones path: primary = earthTones', () {
      final result = calculateWeights(
        stage1CardWeights: [
          {'earthTones': 3},
          {'earthTones': 2, 'warmNeutrals': 1},
          {'earthTones': 3},
          {'earthTones': 2, 'darks': 1},
        ],
        stage2CardWeights: [
          {'earthTones': 2, 'warmNeutrals': 1},
        ],
        stage2CardCount: 1,
      );

      final sorted =
          result.finalWeights.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      expect(sorted.first.key, PaletteFamily.earthTones);
    });

    // ── Fixture 9: Low confidence (evenly split) ────────────────────────
    test('low confidence: Stage 1 evenly split across 4 families', () {
      final result = calculateWeights(
        stage1CardWeights: [
          {'warmNeutrals': 3},
          {'coolNeutrals': 3},
          {'pastels': 3},
          {'earthTones': 3},
        ],
        stage2CardWeights: [],
        stage2CardCount: 0,
      );

      // All four families get equal weight (3 * 0.50 = 1.5 each)
      // No consistency bonus (each family has only 1 card)
      expect(result.confidence, DnaConfidence.low);
      expect(result.consistencyBonusApplied, isFalse);
    });

    // ── Fixture 10: Consistency bonus trigger (3 of 4) ──────────────────
    test('consistency bonus: 3 of 4 Stage 1 cards agree', () {
      final result = calculateWeights(
        stage1CardWeights: [
          {'warmNeutrals': 3},
          {'warmNeutrals': 2, 'earthTones': 1},
          {'warmNeutrals': 3},
          {'darks': 3}, // 4th card is different
        ],
        stage2CardWeights: [],
        stage2CardCount: 0,
      );

      // 3 of 4 cards have warmNeutrals as top family
      expect(result.consistencyBonusApplied, isTrue);
      expect(result.consistencyBonusFamily, PaletteFamily.warmNeutrals);
    });
  });

  group('edge cases', () {
    test('zero Stage 2 selections', () {
      final result = calculateWeights(
        stage1CardWeights: [
          {'warmNeutrals': 2},
          {'warmNeutrals': 2},
          {'warmNeutrals': 2},
          {'warmNeutrals': 2},
        ],
        stage2CardWeights: [],
        stage2CardCount: 0,
      );

      // Should work fine — Stage 2 contributes nothing
      expect(result.normalisedStage2Weights, isEmpty);
      final sorted =
          result.finalWeights.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      expect(sorted.first.key, PaletteFamily.warmNeutrals);
    });

    test('empty Stage 1 (edge case)', () {
      final result = calculateWeights(
        stage1CardWeights: [],
        stage2CardWeights: [
          {'darks': 3},
        ],
        stage2CardCount: 1,
      );

      // Only Stage 2 contributes
      final sorted =
          result.finalWeights.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      expect(sorted.first.key, PaletteFamily.darks);
      expect(result.consistencyBonusApplied, isFalse);
    });

    test('cards with tied top weights', () {
      final result = calculateWeights(
        stage1CardWeights: [
          {'warmNeutrals': 2, 'earthTones': 2}, // tie
          {'warmNeutrals': 2, 'earthTones': 2}, // tie
          {'warmNeutrals': 2, 'earthTones': 2}, // tie
          {'warmNeutrals': 3},
        ],
        stage2CardWeights: [],
        stage2CardCount: 0,
      );

      // Consistency bonus check: tied cards should still be handled
      // The first key found with highest value wins per card
      expect(result.consistencyBonusApplied, isTrue);
    });
  });

  group('normalisation', () {
    test('normalisation factor is budget / cardCount', () {
      final result = calculateWeights(
        stage1CardWeights: [
          {'warmNeutrals': 1},
        ],
        stage2CardWeights: [
          {'pastels': 1},
          {'pastels': 1},
        ],
        stage2CardCount: 2,
      );

      // 2 cards * pastels:1 = 2 raw, normalised = 2 * (4/2) = 4.0
      expect(result.normalisedStage2Weights[PaletteFamily.pastels], 4.0);
    });

    test('stage weights sum to 0.90 (0.10 reserved)', () {
      // Verify the constants
      expect(stage1Weight + stage2Weight + stage3Weight, 1.0);
      expect(stage1Weight, 0.50);
      expect(stage2Weight, 0.40);
    });
  });
}
