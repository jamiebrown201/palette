import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/colour_dna_result.dart';
import 'package:palette/data/models/colour_interaction.dart';
import 'package:palette/features/onboarding/logic/dna_drift.dart';

/// Helper to build a minimal DNA result for testing.
ColourDnaResult _makeDna({
  PaletteFamily primary = PaletteFamily.warmNeutrals,
  PaletteFamily? secondary,
  Undertone? undertone = Undertone.warm,
  ChromaBand? saturation = ChromaBand.muted,
  List<String> hexes = const ['#B8A99A', '#8B7C64', '#DDA92A'],
}) =>
    ColourDnaResult(
      id: 'test-dna',
      primaryFamily: primary,
      secondaryFamily: secondary,
      colourHexes: hexes,
      completedAt: DateTime(2025, 1, 1),
      isComplete: true,
      undertoneTemperature: undertone,
      saturationPreference: saturation,
    );

/// Helper to build a colour interaction.
ColourInteraction _makeInteraction({
  required String hex,
  String type = 'heroSelected',
  String screen = 'planner',
}) =>
    ColourInteraction(
      id: 'int-${hex.hashCode}',
      interactionType: type,
      hex: hex,
      contextScreen: screen,
      createdAt: DateTime(2025, 6, 1),
    );

void main() {
  group('computeDrift', () {
    test('empty interactions → drift 0', () {
      final dna = _makeDna();
      final drift = computeDrift(dna, []);

      expect(drift.familyDrift, 0);
      expect(drift.chromaDrift, 0);
      expect(drift.undertoneDrift, 0);
      expect(drift.overallDrift, 0);
      expect(drift.suggestedFamily, isNull);
      expect(drift.suggestedSaturation, isNull);
      expect(drift.suggestedUndertone, isNull);
    });

    test('all interactions match DNA → drift near 0', () {
      // Use earthTones DNA + earthTone-classified colours to ensure family match.
      // Many warm muted colours classify as earthTones due to moderate chroma.
      final dna = _makeDna(
        primary: PaletteFamily.earthTones,
        secondary: PaletteFamily.warmNeutrals,
        undertone: Undertone.warm,
        saturation: ChromaBand.muted,
      );
      // Warm earthy muted colours (L 30-65, chroma 15-45, b>0, a>-5)
      final interactions = [
        _makeInteraction(hex: '#8B7C64'), // earth tone
        _makeInteraction(hex: '#917B5C'), // earth tone
        _makeInteraction(hex: '#7A6B52'), // earth tone
        _makeInteraction(hex: '#6E5F48'), // earth tone
      ];

      final drift = computeDrift(dna, interactions);
      expect(drift.familyDrift, lessThan(0.5));
      expect(drift.overallDrift, lessThan(0.3));
    });

    test('all interactions differ from DNA → high drift', () {
      // DNA is warm neutrals + muted + warm
      final dna = _makeDna(
        primary: PaletteFamily.warmNeutrals,
        undertone: Undertone.warm,
        saturation: ChromaBand.muted,
      );
      // Interactions are all cool, bold, bright colours
      final interactions = [
        _makeInteraction(hex: '#0055FF'), // cool, bright, bold
        _makeInteraction(hex: '#2200CC'), // cool, jewel/dark, bold
        _makeInteraction(hex: '#0088FF'), // cool, bright, bold
        _makeInteraction(hex: '#3300EE'), // cool, bright, bold
        _makeInteraction(hex: '#0066DD'), // cool, bright, bold
      ];

      final drift = computeDrift(dna, interactions);
      expect(drift.familyDrift, greaterThan(0.6));
      expect(drift.overallDrift, greaterThan(0.4));
    });

    test('mixed interactions → moderate drift', () {
      final dna = _makeDna(
        primary: PaletteFamily.warmNeutrals,
        secondary: PaletteFamily.earthTones,
        undertone: Undertone.warm,
        saturation: ChromaBand.muted,
      );
      // Mix of matching and non-matching
      final interactions = [
        _makeInteraction(hex: '#B8A99A'), // warm neutral (match)
        _makeInteraction(hex: '#8B7C64'), // earth tone (match)
        _makeInteraction(hex: '#0055FF'), // cool bright (no match)
        _makeInteraction(hex: '#C8BBA3'), // warm neutral (match)
        _makeInteraction(hex: '#1A3A4A'), // dark cool (no match)
      ];

      final drift = computeDrift(dna, interactions);
      expect(drift.familyDrift, greaterThan(0.1));
      expect(drift.familyDrift, lessThanOrEqualTo(0.8));
      expect(drift.overallDrift, greaterThan(0.1));
      expect(drift.overallDrift, lessThan(0.7));
    });

    test('colourRemoved interactions are excluded', () {
      final dna = _makeDna();
      // Only removal interactions — should be treated like empty
      final interactions = [
        _makeInteraction(hex: '#0055FF', type: 'colourRemoved'),
        _makeInteraction(hex: '#FF0000', type: 'colourRemoved'),
      ];

      final drift = computeDrift(dna, interactions);
      expect(drift.overallDrift, 0);
    });

    test('undertone drift: warm DNA + cool selections → high undertone drift', () {
      final dna = _makeDna(
        primary: PaletteFamily.coolNeutrals,
        undertone: Undertone.warm,
        saturation: ChromaBand.muted,
      );
      // All cool undertone selections
      final interactions = [
        _makeInteraction(hex: '#5B758A'), // cool
        _makeInteraction(hex: '#8ABED6'), // cool
        _makeInteraction(hex: '#B4BFC8'), // cool
        _makeInteraction(hex: '#1A3A4A'), // cool
      ];

      final drift = computeDrift(dna, interactions);
      expect(drift.undertoneDrift, greaterThanOrEqualTo(0.5));
    });

    test('chroma drift: muted DNA + bold selections → high chroma drift', () {
      final dna = _makeDna(
        primary: PaletteFamily.brights,
        undertone: Undertone.warm,
        saturation: ChromaBand.muted,
      );
      // All bold/high-chroma selections
      final interactions = [
        _makeInteraction(hex: '#E64D42'), // bold red
        _makeInteraction(hex: '#FF4400'), // bold orange
        _makeInteraction(hex: '#00CC44'), // bold green
        _makeInteraction(hex: '#0055FF'), // bold blue
      ];

      final drift = computeDrift(dna, interactions);
      expect(drift.chromaDrift, greaterThan(0.4));
    });

    test('suggested fields populate when drift is significant', () {
      final dna = _makeDna(
        primary: PaletteFamily.warmNeutrals,
        undertone: Undertone.warm,
        saturation: ChromaBand.muted,
      );
      // Consistently cool, bold colours
      final interactions = List.generate(
        10,
        (_) => _makeInteraction(hex: '#0055FF'),
      );

      final drift = computeDrift(dna, interactions);
      // At least one suggestion should be populated
      expect(
        drift.suggestedFamily != null ||
            drift.suggestedSaturation != null ||
            drift.suggestedUndertone != null,
        isTrue,
        reason: 'Expected at least one suggestion for significant drift',
      );
    });

    test('no saturation preference in DNA → chroma drift is 0', () {
      final dna = _makeDna(saturation: null);
      final interactions = [
        _makeInteraction(hex: '#FF0000'),
        _makeInteraction(hex: '#00FF00'),
      ];

      final drift = computeDrift(dna, interactions);
      expect(drift.chromaDrift, 0);
    });

    test('no undertone preference in DNA → undertone drift is 0', () {
      final dna = _makeDna(undertone: null);
      final interactions = [
        _makeInteraction(hex: '#0055FF'),
        _makeInteraction(hex: '#0088FF'),
      ];

      final drift = computeDrift(dna, interactions);
      expect(drift.undertoneDrift, 0);
    });
  });
}
