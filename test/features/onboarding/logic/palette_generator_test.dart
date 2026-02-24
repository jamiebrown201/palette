import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/features/onboarding/logic/palette_generator.dart';

PaintColour _makePaintColour({
  required String id,
  required String brand,
  required String name,
  required double labL,
  required PaletteFamily family,
  String hex = '#888888',
}) {
  return PaintColour(
    id: id,
    brand: brand,
    name: name,
    code: 'TEST',
    hex: hex,
    labL: labL,
    labA: 0,
    labB: 0,
    lrv: 50,
    undertone: Undertone.neutral,
    paletteFamily: family,
  );
}

void main() {
  // Create a diverse set of test paint colours
  final testColours = [
    // Warm neutrals (various lightness)
    _makePaintColour(
      id: 'wn1', brand: 'A', name: 'Cream', labL: 90,
      family: PaletteFamily.warmNeutrals, hex: '#F5E6C8',
    ),
    _makePaintColour(
      id: 'wn2', brand: 'A', name: 'Taupe', labL: 60,
      family: PaletteFamily.warmNeutrals, hex: '#B8A99A',
    ),
    _makePaintColour(
      id: 'wn3', brand: 'A', name: 'Stone', labL: 50,
      family: PaletteFamily.warmNeutrals, hex: '#A19478',
    ),
    _makePaintColour(
      id: 'wn4', brand: 'B', name: 'Linen', labL: 85,
      family: PaletteFamily.warmNeutrals, hex: '#E8E1CD',
    ),
    _makePaintColour(
      id: 'wn5', brand: 'B', name: 'Sand', labL: 70,
      family: PaletteFamily.warmNeutrals, hex: '#C8BBA3',
    ),
    // Jewel tones
    _makePaintColour(
      id: 'jt1', brand: 'A', name: 'Emerald', labL: 35,
      family: PaletteFamily.jewelTones, hex: '#486A4E',
    ),
    _makePaintColour(
      id: 'jt2', brand: 'B', name: 'Ruby', labL: 40,
      family: PaletteFamily.jewelTones, hex: '#943732',
    ),
    _makePaintColour(
      id: 'jt3', brand: 'A', name: 'Sapphire', labL: 30,
      family: PaletteFamily.jewelTones, hex: '#3B4F66',
    ),
    // Pastels
    _makePaintColour(
      id: 'pa1', brand: 'A', name: 'Blush', labL: 80,
      family: PaletteFamily.pastels, hex: '#D5ABAB',
    ),
    _makePaintColour(
      id: 'pa2', brand: 'B', name: 'Sky', labL: 85,
      family: PaletteFamily.pastels, hex: '#8ABED6',
    ),
    _makePaintColour(
      id: 'pa3', brand: 'A', name: 'Mint', labL: 78,
      family: PaletteFamily.pastels, hex: '#97B09A',
    ),
    // Darks
    _makePaintColour(
      id: 'dk1', brand: 'A', name: 'Charcoal', labL: 20,
      family: PaletteFamily.darks, hex: '#3B3B35',
    ),
    _makePaintColour(
      id: 'dk2', brand: 'B', name: 'Navy', labL: 25,
      family: PaletteFamily.darks, hex: '#1A3A4A',
    ),
    // Earth tones
    _makePaintColour(
      id: 'et1', brand: 'A', name: 'Terracotta', labL: 55,
      family: PaletteFamily.earthTones, hex: '#C87830',
    ),
    _makePaintColour(
      id: 'et2', brand: 'B', name: 'Olive', labL: 45,
      family: PaletteFamily.earthTones, hex: '#7A8870',
    ),
    // Brights
    _makePaintColour(
      id: 'br1', brand: 'A', name: 'Sunflower', labL: 80,
      family: PaletteFamily.brights, hex: '#EDD379',
    ),
    // Cool neutrals
    _makePaintColour(
      id: 'cn1', brand: 'A', name: 'Dove', labL: 70,
      family: PaletteFamily.coolNeutrals, hex: '#B4BFC8',
    ),
    _makePaintColour(
      id: 'cn2', brand: 'B', name: 'Slate', labL: 55,
      family: PaletteFamily.coolNeutrals, hex: '#8D8D85',
    ),
  ];

  group('tallyFamilyWeights', () {
    test('aggregates weights from multiple selections', () {
      final weights = tallyFamilyWeights([
        {'warmNeutrals': 2, 'earthTones': 1},
        {'warmNeutrals': 1, 'pastels': 2},
        {'darks': 3},
      ]);

      expect(weights[PaletteFamily.warmNeutrals], 3);
      expect(weights[PaletteFamily.earthTones], 1);
      expect(weights[PaletteFamily.pastels], 2);
      expect(weights[PaletteFamily.darks], 3);
    });

    test('returns empty map for no selections', () {
      final weights = tallyFamilyWeights([]);
      expect(weights, isEmpty);
    });

    test('handles single selection', () {
      final weights = tallyFamilyWeights([
        {'jewelTones': 3, 'darks': 1},
      ]);

      expect(weights[PaletteFamily.jewelTones], 3);
      expect(weights[PaletteFamily.darks], 1);
    });
  });

  group('generatePalette', () {
    test('uses primary family from highest weight', () {
      final palette = generatePalette(
        familyWeights: {
          PaletteFamily.warmNeutrals: 10,
          PaletteFamily.jewelTones: 3,
          PaletteFamily.pastels: 1,
        },
        allPaintColours: testColours,
        random: Random(42),
      );

      expect(palette.primaryFamily, PaletteFamily.warmNeutrals);
    });

    test('sets secondary family from second highest weight', () {
      final palette = generatePalette(
        familyWeights: {
          PaletteFamily.warmNeutrals: 10,
          PaletteFamily.jewelTones: 5,
        },
        allPaintColours: testColours,
        random: Random(42),
      );

      expect(palette.secondaryFamily, PaletteFamily.jewelTones);
    });

    test('generates target number of colours', () {
      final palette = generatePalette(
        familyWeights: {PaletteFamily.warmNeutrals: 10},
        allPaintColours: testColours,
        targetSize: 8,
        random: Random(42),
      );

      expect(palette.colours.length, greaterThanOrEqualTo(1));
      expect(palette.colours.length, lessThanOrEqualTo(8));
    });

    test('includes surprise colours', () {
      final palette = generatePalette(
        familyWeights: {PaletteFamily.warmNeutrals: 10},
        allPaintColours: testColours,
        random: Random(42),
      );

      final surprises = palette.colours.where((c) => c.isSurprise).toList();
      expect(surprises, isNotEmpty);
    });

    test('fallback palette when no weights provided', () {
      final palette = generatePalette(
        familyWeights: {},
        allPaintColours: testColours,
        random: Random(42),
      );

      expect(palette.primaryFamily, PaletteFamily.warmNeutrals);
      expect(palette.colours, isNotEmpty);
    });

    test('all colours have valid hex values', () {
      final palette = generatePalette(
        familyWeights: {PaletteFamily.jewelTones: 8},
        allPaintColours: testColours,
        random: Random(42),
      );

      for (final entry in palette.colours) {
        expect(entry.hex, matches(RegExp(r'^#[0-9A-Fa-f]{6}$')));
      }
    });

    test('all colours reference a paint colour', () {
      final palette = generatePalette(
        familyWeights: {PaletteFamily.warmNeutrals: 10},
        allPaintColours: testColours,
        random: Random(42),
      );

      for (final entry in palette.colours) {
        expect(entry.paintColour, isNotNull);
      }
    });
  });

  group('countBrandsInPalette', () {
    test('counts unique brands', () {
      final entries = [
        PaletteColourEntry(
          hex: '#000000',
          isSurprise: false,
          paintColour: testColours[0], // brand A
        ),
        PaletteColourEntry(
          hex: '#111111',
          isSurprise: false,
          paintColour: testColours[3], // brand B
        ),
      ];

      expect(countBrandsInPalette(entries), 2);
    });

    test('handles entries without paint colours', () {
      final entries = [
        const PaletteColourEntry(hex: '#000000', isSurprise: false),
        PaletteColourEntry(
          hex: '#111111',
          isSurprise: false,
          paintColour: testColours[0],
        ),
      ];

      expect(countBrandsInPalette(entries), 1);
    });
  });
}
