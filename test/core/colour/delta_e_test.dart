import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/core/colour/lab_colour.dart';

void main() {
  group('CIEDE2000 - Sharma 2005 reference pairs', () {
    // Reference data from Sharma, Wu, Dalal (2005) Table 1
    // Format: (Lab1, Lab2, expected deltaE)
    final referencePairs = <(LabColour, LabColour, double)>[
      (
        const LabColour(50.0000, 2.6772, -79.7751),
        const LabColour(50.0000, 0.0000, -82.7485),
        2.0425,
      ),
      (
        const LabColour(50.0000, 3.1571, -77.2803),
        const LabColour(50.0000, 0.0000, -82.7485),
        2.8615,
      ),
      (
        const LabColour(50.0000, 2.8361, -74.0200),
        const LabColour(50.0000, 0.0000, -82.7485),
        3.4412,
      ),
      (
        const LabColour(50.0000, -1.3802, -84.2814),
        const LabColour(50.0000, 0.0000, -82.7485),
        1.0000,
      ),
      (
        const LabColour(50.0000, -1.1848, -84.8006),
        const LabColour(50.0000, 0.0000, -82.7485),
        1.0000,
      ),
      (
        const LabColour(50.0000, -0.9009, -85.5211),
        const LabColour(50.0000, 0.0000, -82.7485),
        1.0000,
      ),
      (
        const LabColour(50.0000, 0.0000, 0.0000),
        const LabColour(50.0000, -1.0000, 2.0000),
        2.3669,
      ),
      (
        const LabColour(50.0000, -1.0000, 2.0000),
        const LabColour(50.0000, 0.0000, 0.0000),
        2.3669,
      ),
      (
        const LabColour(50.0000, 2.4900, -0.0010),
        const LabColour(50.0000, -2.4900, 0.0009),
        7.1792,
      ),
      (
        const LabColour(50.0000, 2.4900, -0.0010),
        const LabColour(50.0000, -2.4900, 0.0010),
        7.1792,
      ),
      (
        const LabColour(50.0000, 2.4900, -0.0010),
        const LabColour(50.0000, -2.4900, 0.0011),
        7.2195,
      ),
      (
        const LabColour(50.0000, 2.4900, -0.0010),
        const LabColour(50.0000, -2.4900, 0.0012),
        7.2195,
      ),
      (
        const LabColour(50.0000, -0.0010, 2.4900),
        const LabColour(50.0000, 0.0009, -2.4900),
        4.8045,
      ),
      (
        const LabColour(50.0000, -0.0010, 2.4900),
        const LabColour(50.0000, 0.0010, -2.4900),
        4.8045,
      ),
      (
        const LabColour(50.0000, -0.0010, 2.4900),
        const LabColour(50.0000, 0.0011, -2.4900),
        4.7461,
      ),
      (
        const LabColour(50.0000, 2.5000, 0.0000),
        const LabColour(50.0000, 0.0000, -2.5000),
        4.3065,
      ),
      (
        const LabColour(50.0000, 2.5000, 0.0000),
        const LabColour(73.0000, 25.0000, -18.0000),
        27.1492,
      ),
      (
        const LabColour(50.0000, 2.5000, 0.0000),
        const LabColour(61.0000, -5.0000, 29.0000),
        22.8977,
      ),
      (
        const LabColour(50.0000, 2.5000, 0.0000),
        const LabColour(56.0000, -27.0000, -3.0000),
        31.9030,
      ),
      (
        const LabColour(50.0000, 2.5000, 0.0000),
        const LabColour(58.0000, 24.0000, 15.0000),
        19.4535,
      ),
      (
        const LabColour(50.0000, 2.5000, 0.0000),
        const LabColour(50.0000, 3.1736, 0.5854),
        1.0000,
      ),
      (
        const LabColour(50.0000, 2.5000, 0.0000),
        const LabColour(50.0000, 3.2972, 0.0000),
        1.0000,
      ),
      (
        const LabColour(50.0000, 2.5000, 0.0000),
        const LabColour(50.0000, 1.8634, 0.5757),
        1.0000,
      ),
      (
        const LabColour(50.0000, 2.5000, 0.0000),
        const LabColour(50.0000, 3.2592, 0.3350),
        1.0000,
      ),
      (
        const LabColour(60.2574, -34.0099, 36.2677),
        const LabColour(60.4626, -34.1751, 39.4387),
        1.2644,
      ),
      (
        const LabColour(63.0109, -31.0961, -5.8663),
        const LabColour(62.8187, -29.7946, -4.0864),
        1.2630,
      ),
      (
        const LabColour(61.2901, 3.7196, -5.3901),
        const LabColour(61.4292, 2.2480, -4.9620),
        1.8731,
      ),
      (
        const LabColour(35.0831, -44.1164, 3.7933),
        const LabColour(35.0232, -40.0716, 1.5901),
        1.8645,
      ),
      (
        const LabColour(22.7233, 20.0904, -46.6940),
        const LabColour(23.0331, 14.9730, -42.5619),
        2.0373,
      ),
      (
        const LabColour(36.4612, 47.8580, 18.3852),
        const LabColour(36.2715, 50.5065, 21.2231),
        1.4146,
      ),
      (
        const LabColour(90.8027, -2.0831, 1.4410),
        const LabColour(91.1528, -1.6435, 0.0447),
        1.4441,
      ),
      (
        const LabColour(90.9257, -0.5406, -0.9208),
        const LabColour(88.6381, -0.8985, -0.7239),
        1.5381,
      ),
      (
        const LabColour(6.7747, -0.2908, -2.4247),
        const LabColour(5.8714, -0.0985, -2.2286),
        0.6377,
      ),
      (
        const LabColour(2.0776, 0.0795, -1.1350),
        const LabColour(0.9033, -0.0636, -0.5514),
        0.9082,
      ),
    ];

    for (var i = 0; i < referencePairs.length; i++) {
      final (lab1, lab2, expected) = referencePairs[i];
      test('pair ${i + 1}: expected $expected', () {
        final result = deltaE2000(lab1, lab2);
        expect(
          result,
          closeTo(expected, 0.001),
          reason: 'Pair ${i + 1}: $lab1 vs $lab2',
        );
      });
    }
  });

  group('CIEDE2000 - basic properties', () {
    test('identical colours have delta-E of 0', () {
      const lab = LabColour(50, 25, -10);
      expect(deltaE2000(lab, lab), closeTo(0, 1e-10));
    });

    test('is symmetric', () {
      const lab1 = LabColour(50, 25, -10);
      const lab2 = LabColour(60, -15, 30);
      expect(
        deltaE2000(lab1, lab2),
        closeTo(deltaE2000(lab2, lab1), 1e-10),
      );
    });

    test('is non-negative', () {
      const lab1 = LabColour(50, 25, -10);
      const lab2 = LabColour(60, -15, 30);
      expect(deltaE2000(lab1, lab2), greaterThanOrEqualTo(0));
    });
  });

  group('deltaEToMatchPercentage', () {
    test('zero delta-E gives 100%', () {
      expect(deltaEToMatchPercentage(0), 100);
    });

    test('high delta-E gives low percentage', () {
      expect(deltaEToMatchPercentage(100), 0);
    });

    test('moderate delta-E gives moderate percentage', () {
      final pct = deltaEToMatchPercentage(5);
      expect(pct, greaterThan(80));
      expect(pct, lessThan(100));
    });

    test('result is always between 0 and 100', () {
      for (var de = 0.0; de <= 200; de += 5) {
        final pct = deltaEToMatchPercentage(de);
        expect(pct, greaterThanOrEqualTo(0));
        expect(pct, lessThanOrEqualTo(100));
      }
    });
  });
}
