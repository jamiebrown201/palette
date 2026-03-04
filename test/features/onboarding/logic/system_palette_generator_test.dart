import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/colour/chroma_band.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/features/onboarding/logic/system_palette_generator.dart';

int _hexCounter = 0;

PaintColour _make({
  required String id,
  required double labL,
  double labA = 0,
  double labB = 0,
  Undertone undertone = Undertone.warm,
  PaletteFamily family = PaletteFamily.warmNeutrals,
}) {
  _hexCounter++;
  final hex = '#${_hexCounter.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  final cabStar = math.sqrt(labA * labA + labB * labB);
  return PaintColour(
    id: id,
    brand: 'Test',
    name: 'Test $id',
    code: id,
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
  // Build a diverse test palette covering the roles we need
  final testPaints = <PaintColour>[
    // Whites (trim candidates)
    _make(id: 'w1', labL: 95, labA: 0.5, labB: 2, family: PaletteFamily.warmNeutrals),
    _make(id: 'w2', labL: 93, labA: -0.5, labB: -1, family: PaletteFamily.coolNeutrals, undertone: Undertone.cool),
    // Warm neutrals (dominant/supporting candidates)
    _make(id: 'wn1', labL: 70, labA: 3, labB: 15, family: PaletteFamily.warmNeutrals),
    _make(id: 'wn2', labL: 60, labA: 4, labB: 18, family: PaletteFamily.warmNeutrals),
    _make(id: 'wn3', labL: 50, labA: 5, labB: 20, family: PaletteFamily.warmNeutrals),
    _make(id: 'wn4', labL: 75, labA: 2, labB: 10, family: PaletteFamily.warmNeutrals),
    // Earth tones (secondary family candidates)
    _make(id: 'et1', labL: 55, labA: 10, labB: 25, family: PaletteFamily.earthTones),
    _make(id: 'et2', labL: 45, labA: 8, labB: 20, family: PaletteFamily.earthTones),
    _make(id: 'et3', labL: 65, labA: 6, labB: 15, family: PaletteFamily.earthTones),
    // Deep darks (anchor candidates)
    _make(id: 'd1', labL: 30, labA: 5, labB: 10, family: PaletteFamily.warmNeutrals),
    _make(id: 'd2', labL: 25, labA: -3, labB: -20, family: PaletteFamily.darks, undertone: Undertone.cool),
    // Jewel tones (accent candidates, high chroma)
    _make(id: 'jt1', labL: 35, labA: -10, labB: -35, family: PaletteFamily.jewelTones, undertone: Undertone.cool),
    _make(id: 'jt2', labL: 40, labA: 30, labB: -25, family: PaletteFamily.jewelTones, undertone: Undertone.cool),
    // Brights (accent candidates, high chroma)
    _make(id: 'br1', labL: 70, labA: 25, labB: 40, family: PaletteFamily.brights),
    // Spine candidates (muted mid-tones)
    _make(id: 'sp1', labL: 68, labA: 2, labB: 8, family: PaletteFamily.warmNeutrals),
    _make(id: 'sp2', labL: 72, labA: 1, labB: 5, family: PaletteFamily.coolNeutrals, undertone: Undertone.neutral),
  ];

  group('generateSystemPalette', () {
    test('generates a complete palette for warm neutrals', () {
      final palette = generateSystemPalette(
        primaryFamily: PaletteFamily.warmNeutrals,
        secondaryFamily: PaletteFamily.earthTones,
        allPaintColours: testPaints,
        undertoneTemperature: Undertone.warm,
      );

      expect(palette, isNotNull);
      expect(palette!.trimWhite.role, 'trimWhite');
      expect(palette.dominantWalls, isNotEmpty);
      expect(palette.deepAnchor.role, 'deepAnchor');
      expect(palette.spineColour.role, 'spineColour');
    });

    test('trim white has high lightness', () {
      final palette = generateSystemPalette(
        primaryFamily: PaletteFamily.warmNeutrals,
        allPaintColours: testPaints,
      );

      expect(palette, isNotNull);
      // Trim white should come from whites we defined at L* 93-95
      final trimPaint = testPaints.firstWhere(
        (p) => p.id == palette!.trimWhite.paintId,
      );
      expect(trimPaint.labL, greaterThan(80));
    });

    test('dominant walls are in mid lightness range', () {
      final palette = generateSystemPalette(
        primaryFamily: PaletteFamily.warmNeutrals,
        allPaintColours: testPaints,
      );

      expect(palette, isNotNull);
      for (final wall in palette!.dominantWalls) {
        final paint = testPaints.firstWhere((p) => p.id == wall.paintId);
        expect(paint.labL, greaterThanOrEqualTo(35));
        expect(paint.labL, lessThanOrEqualTo(90));
      }
    });

    test('deep anchor has low lightness', () {
      final palette = generateSystemPalette(
        primaryFamily: PaletteFamily.warmNeutrals,
        secondaryFamily: PaletteFamily.earthTones,
        allPaintColours: testPaints,
      );

      expect(palette, isNotNull);
      final anchorPaint = testPaints.firstWhere(
        (p) => p.id == palette!.deepAnchor.paintId,
      );
      expect(anchorPaint.labL, lessThan(65));
    });

    test('accent pop has high chroma when available', () {
      final palette = generateSystemPalette(
        primaryFamily: PaletteFamily.warmNeutrals,
        allPaintColours: testPaints,
      );

      expect(palette, isNotNull);
      if (palette!.accentPops.isNotEmpty) {
        final accentPaint = testPaints.firstWhere(
          (p) => p.id == palette.accentPops.first.paintId,
        );
        expect(accentPaint.cabStar, greaterThan(10));
      }
    });

    test('toColourHexes produces correct number of entries', () {
      final palette = generateSystemPalette(
        primaryFamily: PaletteFamily.warmNeutrals,
        secondaryFamily: PaletteFamily.earthTones,
        allPaintColours: testPaints,
      );

      expect(palette, isNotNull);
      final hexes = palette!.toColourHexes();
      // At minimum: trim + 1 dominant + deep anchor + spine = 4
      expect(hexes.length, greaterThanOrEqualTo(4));
      // At maximum: trim + 2 dominant + 3 supporting + anchor + 1 accent + spine = 9
      expect(hexes.length, lessThanOrEqualTo(9));
    });

    test('muted saturation preference produces 0 accent pops', () {
      final palette = generateSystemPalette(
        primaryFamily: PaletteFamily.warmNeutrals,
        secondaryFamily: PaletteFamily.earthTones,
        allPaintColours: testPaints,
        undertoneTemperature: Undertone.warm,
        saturationPreference: ChromaBand.muted,
      );

      expect(palette, isNotNull);
      expect(palette!.accentPops, isEmpty);
    });

    test('bold saturation preference allows accent pops', () {
      final palette = generateSystemPalette(
        primaryFamily: PaletteFamily.warmNeutrals,
        secondaryFamily: PaletteFamily.earthTones,
        allPaintColours: testPaints,
        undertoneTemperature: Undertone.warm,
        saturationPreference: ChromaBand.bold,
      );

      expect(palette, isNotNull);
      // Bold users should get accent pops if high-chroma candidates exist
      // (our test data has jewel tones and brights with decent Cab*)
      expect(palette!.accentPops, isNotEmpty);
    });

    test('mid saturation preference allows accent pops', () {
      final palette = generateSystemPalette(
        primaryFamily: PaletteFamily.warmNeutrals,
        allPaintColours: testPaints,
        saturationPreference: ChromaBand.mid,
      );

      expect(palette, isNotNull);
      // Mid users should still get accent pops (not gated)
      if (palette!.accentPops.isNotEmpty) {
        final accentPaint = testPaints.firstWhere(
          (p) => p.id == palette.accentPops.first.paintId,
        );
        expect(accentPaint.cabStar, greaterThan(10));
      }
    });

    test('returns null for empty paint list', () {
      final palette = generateSystemPalette(
        primaryFamily: PaletteFamily.warmNeutrals,
        allPaintColours: [],
      );

      expect(palette, isNull);
    });

    test('deterministic: same inputs produce same outputs', () {
      final p1 = generateSystemPalette(
        primaryFamily: PaletteFamily.warmNeutrals,
        secondaryFamily: PaletteFamily.earthTones,
        allPaintColours: testPaints,
        undertoneTemperature: Undertone.warm,
      );
      final p2 = generateSystemPalette(
        primaryFamily: PaletteFamily.warmNeutrals,
        secondaryFamily: PaletteFamily.earthTones,
        allPaintColours: testPaints,
        undertoneTemperature: Undertone.warm,
      );

      expect(p1, isNotNull);
      expect(p2, isNotNull);
      expect(p1!.trimWhite.paintId, p2!.trimWhite.paintId);
      expect(p1.deepAnchor.paintId, p2.deepAnchor.paintId);
      expect(p1.spineColour.paintId, p2.spineColour.paintId);
    });

    test('works with cool neutrals as primary', () {
      final palette = generateSystemPalette(
        primaryFamily: PaletteFamily.coolNeutrals,
        allPaintColours: testPaints,
        undertoneTemperature: Undertone.cool,
      );

      // May return null if not enough cool neutral paints, but should not throw
      if (palette != null) {
        expect(palette.trimWhite.role, 'trimWhite');
      }
    });

    test('works with jewel tones as primary', () {
      final palette = generateSystemPalette(
        primaryFamily: PaletteFamily.jewelTones,
        allPaintColours: testPaints,
      );

      // May use progressive relaxation
      if (palette != null) {
        expect(palette.dominantWalls, isNotEmpty);
      }
    });
  });
}
