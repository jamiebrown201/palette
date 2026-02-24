import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/paint_colour.dart';

// Test the white undertone classification logic directly.
// The actual providers are tested via integration tests since they depend on Drift.

/// Classify a white paint into its undertone family based on Lab a*/b*.
/// (Extracted from colour_wheel_providers.dart for unit testing.)
WhiteUndertone classifyWhiteUndertone(PaintColour colour) {
  final a = colour.labA;
  final b = colour.labB;

  if (b < -2) return WhiteUndertone.blue;
  if (a > 2) return WhiteUndertone.pink;
  if (b > 3) return WhiteUndertone.yellow;
  return WhiteUndertone.grey;
}

PaintColour _makeWhite({
  required String id,
  required double labA,
  required double labB,
}) {
  return PaintColour(
    id: id,
    brand: 'Test',
    name: 'Test White $id',
    code: id,
    hex: '#FFFFFF',
    labL: 95.0,
    labA: labA,
    labB: labB,
    lrv: 85.0,
    undertone: Undertone.neutral,
    paletteFamily: PaletteFamily.warmNeutrals,
  );
}

void main() {
  group('White undertone classification', () {
    test('negative b* classifies as blue undertone', () {
      final white = _makeWhite(id: 'blue', labA: 0.0, labB: -5.0);
      expect(classifyWhiteUndertone(white), WhiteUndertone.blue);
    });

    test('positive a* with neutral b classifies as pink undertone', () {
      final white = _makeWhite(id: 'pink', labA: 4.0, labB: 0.0);
      expect(classifyWhiteUndertone(white), WhiteUndertone.pink);
    });

    test('positive b* classifies as yellow undertone', () {
      final white = _makeWhite(id: 'yellow', labA: 0.0, labB: 6.0);
      expect(classifyWhiteUndertone(white), WhiteUndertone.yellow);
    });

    test('near-zero a and b classifies as grey undertone', () {
      final white = _makeWhite(id: 'grey', labA: 0.5, labB: 1.0);
      expect(classifyWhiteUndertone(white), WhiteUndertone.grey);
    });

    test('blue takes priority over pink when b is very negative', () {
      // Even with positive a*, if b* is very negative → blue
      final white = _makeWhite(id: 'blue-pink', labA: 3.0, labB: -4.0);
      expect(classifyWhiteUndertone(white), WhiteUndertone.blue);
    });

    test('borderline b at -2 stays grey (not blue)', () {
      final white = _makeWhite(id: 'borderline', labA: 0.0, labB: -2.0);
      expect(classifyWhiteUndertone(white), WhiteUndertone.grey);
    });

    test('borderline b at -2.1 classifies as blue', () {
      final white = _makeWhite(id: 'borderline-blue', labA: 0.0, labB: -2.1);
      expect(classifyWhiteUndertone(white), WhiteUndertone.blue);
    });
  });

  group('White filtering by LRV/name', () {
    test('whites are identified by high LRV or name', () {
      const colours = [
        PaintColour(
          id: '1',
          brand: 'Test',
          name: 'Brilliant White',
          code: 'BW',
          hex: '#FFFFFF',
          labL: 100.0,
          labA: 0.0,
          labB: 0.0,
          lrv: 95.0,
          undertone: Undertone.neutral,
          paletteFamily: PaletteFamily.warmNeutrals,
        ),
        PaintColour(
          id: '2',
          brand: 'Test',
          name: 'Deep Navy',
          code: 'DN',
          hex: '#1A1A3E',
          labL: 15.0,
          labA: 5.0,
          labB: -20.0,
          lrv: 3.0,
          undertone: Undertone.cool,
          paletteFamily: PaletteFamily.darks,
        ),
        PaintColour(
          id: '3',
          brand: 'Test',
          name: 'Pale Cream',
          code: 'PC',
          hex: '#F5F0E8',
          labL: 94.0,
          labA: 1.0,
          labB: 5.0,
          lrv: 82.0,
          undertone: Undertone.warm,
          paletteFamily: PaletteFamily.warmNeutrals,
        ),
      ];

      // Filter logic from provider: lrv > 70 or name contains 'white'
      final whites = colours
          .where(
              (pc) => pc.lrv > 70 || pc.name.toLowerCase().contains('white'))
          .toList();

      expect(whites.length, 2);
      expect(whites.map((w) => w.id), containsAll(['1', '3']));
    });
  });
}
