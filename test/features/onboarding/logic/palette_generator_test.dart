import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/colour/chroma_band.dart';
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
  double labA = 0,
  double labB = 0,
  Undertone undertone = Undertone.neutral,
}) {
  final cabStar = math.sqrt(labA * labA + labB * labB);
  return PaintColour(
    id: id,
    brand: brand,
    name: name,
    code: 'TEST',
    hex: hex,
    labL: labL,
    labA: labA,
    labB: labB,
    lrv: 50,
    undertone: undertone,
    paletteFamily: family,
    cabStar: cabStar,
    chromaBand: classifyChromaBand(cabStar),
  );
}

void main() {
  // Create a diverse set of test paint colours
  final testColours = [
    // Warm neutrals (various lightness)
    _makePaintColour(
      id: 'wn1',
      brand: 'A',
      name: 'Cream',
      labL: 90,
      family: PaletteFamily.warmNeutrals,
      hex: '#F5E6C8',
    ),
    _makePaintColour(
      id: 'wn2',
      brand: 'A',
      name: 'Taupe',
      labL: 60,
      family: PaletteFamily.warmNeutrals,
      hex: '#B8A99A',
    ),
    _makePaintColour(
      id: 'wn3',
      brand: 'A',
      name: 'Stone',
      labL: 50,
      family: PaletteFamily.warmNeutrals,
      hex: '#A19478',
    ),
    _makePaintColour(
      id: 'wn4',
      brand: 'B',
      name: 'Linen',
      labL: 85,
      family: PaletteFamily.warmNeutrals,
      hex: '#E8E1CD',
    ),
    _makePaintColour(
      id: 'wn5',
      brand: 'B',
      name: 'Sand',
      labL: 70,
      family: PaletteFamily.warmNeutrals,
      hex: '#C8BBA3',
    ),
    // Jewel tones
    _makePaintColour(
      id: 'jt1',
      brand: 'A',
      name: 'Emerald',
      labL: 35,
      family: PaletteFamily.jewelTones,
      hex: '#486A4E',
    ),
    _makePaintColour(
      id: 'jt2',
      brand: 'B',
      name: 'Ruby',
      labL: 40,
      family: PaletteFamily.jewelTones,
      hex: '#943732',
    ),
    _makePaintColour(
      id: 'jt3',
      brand: 'A',
      name: 'Sapphire',
      labL: 30,
      family: PaletteFamily.jewelTones,
      hex: '#3B4F66',
    ),
    // Pastels
    _makePaintColour(
      id: 'pa1',
      brand: 'A',
      name: 'Blush',
      labL: 80,
      family: PaletteFamily.pastels,
      hex: '#D5ABAB',
    ),
    _makePaintColour(
      id: 'pa2',
      brand: 'B',
      name: 'Sky',
      labL: 85,
      family: PaletteFamily.pastels,
      hex: '#8ABED6',
    ),
    _makePaintColour(
      id: 'pa3',
      brand: 'A',
      name: 'Mint',
      labL: 78,
      family: PaletteFamily.pastels,
      hex: '#97B09A',
    ),
    // Darks
    _makePaintColour(
      id: 'dk1',
      brand: 'A',
      name: 'Charcoal',
      labL: 20,
      family: PaletteFamily.darks,
      hex: '#3B3B35',
    ),
    _makePaintColour(
      id: 'dk2',
      brand: 'B',
      name: 'Navy',
      labL: 25,
      family: PaletteFamily.darks,
      hex: '#1A3A4A',
    ),
    // Earth tones
    _makePaintColour(
      id: 'et1',
      brand: 'A',
      name: 'Terracotta',
      labL: 55,
      family: PaletteFamily.earthTones,
      hex: '#C87830',
    ),
    _makePaintColour(
      id: 'et2',
      brand: 'B',
      name: 'Olive',
      labL: 45,
      family: PaletteFamily.earthTones,
      hex: '#7A8870',
    ),
    // Brights
    _makePaintColour(
      id: 'br1',
      brand: 'A',
      name: 'Sunflower',
      labL: 80,
      family: PaletteFamily.brights,
      hex: '#EDD379',
    ),
    // Cool neutrals
    _makePaintColour(
      id: 'cn1',
      brand: 'A',
      name: 'Dove',
      labL: 70,
      family: PaletteFamily.coolNeutrals,
      hex: '#B4BFC8',
    ),
    _makePaintColour(
      id: 'cn2',
      brand: 'B',
      name: 'Slate',
      labL: 55,
      family: PaletteFamily.coolNeutrals,
      hex: '#8D8D85',
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
      );

      expect(palette.secondaryFamily, PaletteFamily.jewelTones);
    });

    test('generates target number of colours', () {
      final palette = generatePalette(
        familyWeights: {PaletteFamily.warmNeutrals: 10},
        allPaintColours: testColours,
        targetSize: 8,
      );

      expect(palette.colours.length, greaterThanOrEqualTo(1));
      expect(palette.colours.length, lessThanOrEqualTo(8));
    });

    test('includes surprise colours', () {
      final palette = generatePalette(
        familyWeights: {PaletteFamily.warmNeutrals: 10},
        allPaintColours: testColours,
      );

      final surprises = palette.colours.where((c) => c.isSurprise).toList();
      expect(surprises, isNotEmpty);
    });

    test('fallback palette when no weights provided', () {
      final palette = generatePalette(
        familyWeights: {},
        allPaintColours: testColours,
      );

      expect(palette.primaryFamily, PaletteFamily.warmNeutrals);
      expect(palette.colours, isNotEmpty);
    });

    test('all colours have valid hex values', () {
      final palette = generatePalette(
        familyWeights: {PaletteFamily.jewelTones: 8},
        allPaintColours: testColours,
      );

      for (final entry in palette.colours) {
        expect(entry.hex, matches(RegExp(r'^#[0-9A-Fa-f]{6}$')));
      }
    });

    test('all colours reference a paint colour', () {
      final palette = generatePalette(
        familyWeights: {PaletteFamily.warmNeutrals: 10},
        allPaintColours: testColours,
      );

      for (final entry in palette.colours) {
        expect(entry.paintColour, isNotNull);
      }
    });

    test('deterministic: same inputs produce same outputs', () {
      final palette1 = generatePalette(
        familyWeights: {PaletteFamily.warmNeutrals: 10},
        allPaintColours: testColours,
      );
      final palette2 = generatePalette(
        familyWeights: {PaletteFamily.warmNeutrals: 10},
        allPaintColours: testColours,
      );

      expect(palette1.primaryFamily, palette2.primaryFamily);
      expect(palette1.secondaryFamily, palette2.secondaryFamily);
      expect(
        palette1.colours.map((c) => c.hex).toList(),
        palette2.colours.map((c) => c.hex).toList(),
      );
    });

    test('tiebreaker uses enum index for equal weights', () {
      final palette = generatePalette(
        familyWeights: {
          PaletteFamily.warmNeutrals: 5,
          PaletteFamily.coolNeutrals: 5,
        },
        allPaintColours: testColours,
      );

      // warmNeutrals has a lower enum index, so it wins the tie
      expect(palette.primaryFamily, PaletteFamily.warmNeutrals);
      expect(palette.secondaryFamily, PaletteFamily.coolNeutrals);
    });
  });

  group('generatePalette with saturationPreference', () {
    // Create colours with varying chroma to test saturation sorting
    final chromaTestColours = [
      _makePaintColour(
        id: 'low1',
        brand: 'A',
        name: 'Muted 1',
        labL: 60,
        family: PaletteFamily.warmNeutrals,
        hex: '#A09888',
        labA: 3,
        labB: 5, // Cab* ~5.8 → muted
      ),
      _makePaintColour(
        id: 'low2',
        brand: 'A',
        name: 'Muted 2',
        labL: 70,
        family: PaletteFamily.warmNeutrals,
        hex: '#B0A898',
        labA: 4,
        labB: 8, // Cab* ~8.9 → muted
      ),
      _makePaintColour(
        id: 'mid1',
        brand: 'A',
        name: 'Mid 1',
        labL: 65,
        family: PaletteFamily.warmNeutrals,
        hex: '#C0A070',
        labA: 10,
        labB: 30, // Cab* ~31.6 → mid
      ),
      _makePaintColour(
        id: 'mid2',
        brand: 'A',
        name: 'Mid 2',
        labL: 55,
        family: PaletteFamily.warmNeutrals,
        hex: '#B09060',
        labA: 15,
        labB: 35, // Cab* ~38.1 → mid
      ),
      _makePaintColour(
        id: 'high1',
        brand: 'A',
        name: 'Bold 1',
        labL: 50,
        family: PaletteFamily.warmNeutrals,
        hex: '#D08040',
        labA: 25,
        labB: 50, // Cab* ~55.9 → bold
      ),
      _makePaintColour(
        id: 'high2',
        brand: 'B',
        name: 'Bold 2',
        labL: 75,
        family: PaletteFamily.warmNeutrals,
        hex: '#E09030',
        labA: 30,
        labB: 55, // Cab* ~62.6 → bold
      ),
      // Surprise family
      _makePaintColour(
        id: 'jt1',
        brand: 'A',
        name: 'Jewel',
        labL: 35,
        family: PaletteFamily.jewelTones,
        hex: '#486A4E',
      ),
    ];

    test('muted preference produces lower average Cab* than bold', () {
      final mutedPalette = generatePalette(
        familyWeights: {PaletteFamily.warmNeutrals: 10},
        allPaintColours: chromaTestColours,
        saturationPreference: ChromaBand.muted,
        targetSize: 4,
      );
      final boldPalette = generatePalette(
        familyWeights: {PaletteFamily.warmNeutrals: 10},
        allPaintColours: chromaTestColours,
        saturationPreference: ChromaBand.bold,
        targetSize: 4,
      );

      double avgCab(GeneratedPalette p) {
        final nonSurprise =
            p.colours
                .where((c) => !c.isSurprise && c.paintColour != null)
                .toList();
        if (nonSurprise.isEmpty) return 0;
        return nonSurprise.fold<double>(
              0,
              (sum, c) => sum + c.paintColour!.cabStar,
            ) /
            nonSurprise.length;
      }

      expect(avgCab(mutedPalette), lessThan(avgCab(boldPalette)));
    });

    test('saturation preference is deterministic', () {
      final p1 = generatePalette(
        familyWeights: {PaletteFamily.warmNeutrals: 10},
        allPaintColours: chromaTestColours,
        saturationPreference: ChromaBand.muted,
      );
      final p2 = generatePalette(
        familyWeights: {PaletteFamily.warmNeutrals: 10},
        allPaintColours: chromaTestColours,
        saturationPreference: ChromaBand.muted,
      );

      expect(
        p1.colours.map((c) => c.hex).toList(),
        p2.colours.map((c) => c.hex).toList(),
      );
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
