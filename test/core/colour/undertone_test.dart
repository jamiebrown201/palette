import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/colour/lab_colour.dart';
import 'package:palette/core/colour/undertone.dart';
import 'package:palette/core/constants/enums.dart';

void main() {
  group('classifyUndertone', () {
    test('positive b* classifies as warm', () {
      // Strong yellow undertone
      const lab = LabColour(70, 5, 30);
      final result = classifyUndertone(lab);
      expect(result.classification, Undertone.warm);
      expect(result.confidence, greaterThan(0.5));
    });

    test('negative b* classifies as cool', () {
      // Strong blue undertone
      const lab = LabColour(50, -10, -25);
      final result = classifyUndertone(lab);
      expect(result.classification, Undertone.cool);
      expect(result.confidence, greaterThan(0.5));
    });

    test('near-zero b* and a* classifies as neutral', () {
      // Pure grey
      const lab = LabColour(50, 0, 0);
      final result = classifyUndertone(lab);
      expect(result.classification, Undertone.neutral);
    });

    test('boundary values classify as neutral with lower confidence', () {
      // Just at the boundary
      const lab = LabColour(50, 0, 4);
      final result = classifyUndertone(lab);
      expect(result.classification, Undertone.neutral);
      expect(result.confidence, lessThan(1.0));
    });

    test('strong warm colour has high confidence', () {
      const lab = LabColour(60, 20, 40);
      final result = classifyUndertone(lab);
      expect(result.classification, Undertone.warm);
      expect(result.confidence, greaterThan(0.7));
    });

    test('Hague Blue (deep blue-green) is cool', () {
      // Approximate Lab values for Farrow & Ball Hague Blue (#3C5064)
      const lab = LabColour(33.5, -4.5, -14.5);
      final result = classifyUndertone(lab);
      expect(result.classification, Undertone.cool);
    });

    test('warm gold is warm', () {
      // Approximate Lab values for a warm gold colour
      const lab = LabColour(70, 10, 50);
      final result = classifyUndertone(lab);
      expect(result.classification, Undertone.warm);
    });
  });
}
