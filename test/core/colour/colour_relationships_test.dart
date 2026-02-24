import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/colour/colour_relationships.dart';
import 'package:palette/core/colour/lab_colour.dart';

void main() {
  group('labToLch and lchToLab round-trip', () {
    test('round-trip preserves values', () {
      const lab = LabColour(50, 30, 40);
      final lch = labToLch(lab);
      final roundTripped = lchToLab(lch.l, lch.c, lch.h);
      expect(roundTripped.l, closeTo(lab.l, 1e-10));
      expect(roundTripped.a, closeTo(lab.a, 1e-10));
      expect(roundTripped.b, closeTo(lab.b, 1e-10));
    });

    test('achromatic colour has zero chroma', () {
      const lab = LabColour(50, 0, 0);
      final lch = labToLch(lab);
      expect(lch.c, closeTo(0, 1e-10));
    });
  });

  group('complementary', () {
    test('rotates hue by 180 degrees', () {
      const lab = LabColour(50, 30, 40);
      final comp = complementary(lab);
      final originalLch = labToLch(lab);
      final compLch = labToLch(comp);

      var hueDiff = (compLch.h - originalLch.h).abs();
      if (hueDiff > 180) hueDiff = 360 - hueDiff;
      expect(hueDiff, closeTo(180, 0.01));
      expect(compLch.c, closeTo(originalLch.c, 1e-10));
      expect(compLch.l, closeTo(originalLch.l, 1e-10));
    });
  });

  group('analogous', () {
    test('produces +/- 30 degree rotation', () {
      const lab = LabColour(50, 30, 40);
      final result = analogous(lab);
      final originalLch = labToLch(lab);
      final leftLch = labToLch(result.left);
      final rightLch = labToLch(result.right);

      double hueDiff(double h1, double h2) {
        var d = h2 - h1;
        while (d > 180) {
          d -= 360;
        }
        while (d < -180) {
          d += 360;
        }
        return d;
      }

      expect(hueDiff(originalLch.h, leftLch.h), closeTo(-30, 0.01));
      expect(hueDiff(originalLch.h, rightLch.h), closeTo(30, 0.01));
    });
  });

  group('triadic', () {
    test('produces +/- 120 degree rotation', () {
      const lab = LabColour(50, 30, 40);
      final result = triadic(lab);
      final originalLch = labToLch(lab);
      final secondLch = labToLch(result.second);
      final thirdLch = labToLch(result.third);

      double normaliseDiff(double diff) {
        while (diff > 180) {
          diff -= 360;
        }
        while (diff < -180) {
          diff += 360;
        }
        return diff;
      }

      expect(
        normaliseDiff(secondLch.h - originalLch.h),
        closeTo(120, 0.01),
      );
      expect(
        normaliseDiff(thirdLch.h - originalLch.h),
        closeTo(-120, 0.01),
      );
    });
  });

  group('splitComplementary', () {
    test('produces +150 and +210 degree rotation', () {
      const lab = LabColour(50, 30, 40);
      final result = splitComplementary(lab);
      final originalLch = labToLch(lab);
      final leftLch = labToLch(result.left);
      final rightLch = labToLch(result.right);

      double normaliseDiff(double diff) {
        while (diff > 180) {
          diff -= 360;
        }
        while (diff < -180) {
          diff += 360;
        }
        return diff;
      }

      expect(
        normaliseDiff(leftLch.h - originalLch.h),
        closeTo(150, 0.01),
      );
      expect(
        normaliseDiff(rightLch.h - originalLch.h),
        closeTo(-150, 0.01),
      );
    });
  });

  group('hue wrapping', () {
    test('handles wrapping past 360', () {
      // A colour with hue near 350 degrees
      final lab = lchToLab(50, 30, 350);
      final result = analogous(lab);
      final rightLch = labToLch(result.right);
      // 350 + 30 = 380, should wrap to 20
      expect(rightLch.h, closeTo(20, 0.5));
    });

    test('handles wrapping past 0', () {
      final lab = lchToLab(50, 30, 10);
      final result = analogous(lab);
      final leftLch = labToLch(result.left);
      // 10 - 30 = -20, should wrap to 340
      expect(leftLch.h, closeTo(340, 0.5));
    });
  });
}
