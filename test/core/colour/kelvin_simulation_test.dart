import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/colour/kelvin_simulation.dart';
import 'package:palette/core/constants/enums.dart';

void main() {
  group('kelvinToRgb', () {
    test('produces valid RGB values for daylight (6500K)', () {
      final rgb = kelvinToRgb(6500);
      expect(rgb.r, inInclusiveRange(0, 255));
      expect(rgb.g, inInclusiveRange(0, 255));
      expect(rgb.b, inInclusiveRange(0, 255));
      // Daylight should be near-white
      expect(rgb.r, greaterThan(240));
      expect(rgb.g, greaterThan(240));
      expect(rgb.b, greaterThan(240));
    });

    test('warm light (3000K) has orange tint', () {
      final rgb = kelvinToRgb(3000);
      expect(rgb.r, greaterThan(rgb.b));
      expect(rgb.r, 255); // Red maxes out at warm temperatures
    });

    test('cool light (10000K) has blue tint', () {
      final rgb = kelvinToRgb(10000);
      expect(rgb.b, 255); // Blue maxes out at cool temperatures
    });

    test('all values in range for various temperatures', () {
      for (final k in [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 10000, 15000, 20000]) {
        final rgb = kelvinToRgb(k);
        expect(rgb.r, inInclusiveRange(0, 255), reason: '${k}K red');
        expect(rgb.g, inInclusiveRange(0, 255), reason: '${k}K green');
        expect(rgb.b, inInclusiveRange(0, 255), reason: '${k}K blue');
      }
    });
  });

  group('simulateLightOnColour', () {
    test('does not produce invalid hex values', () {
      final result = simulateLightOnColour('#FF0000', 3000);
      expect(result, startsWith('#'));
      expect(result.length, 7);
      // Verify it parses as valid hex
      final value = int.parse(result.substring(1), radix: 16);
      expect(value, inInclusiveRange(0, 0xFFFFFF));
    });

    test('zero opacity returns original colour', () {
      final result = simulateLightOnColour('#FF0000', 3000, opacity: 0);
      expect(result, '#FF0000');
    });

    test('warm light shifts colour warmer', () {
      // A neutral grey under warm light should have more red
      final warmResult = simulateLightOnColour('#808080', 3000);
      final coolResult = simulateLightOnColour('#808080', 10000);
      // Parse and compare red channels
      final warmR = int.parse(warmResult.substring(1, 3), radix: 16);
      final coolR = int.parse(coolResult.substring(1, 3), radix: 16);
      expect(warmR, greaterThanOrEqualTo(coolR));
    });
  });

  group('getKelvinForRoom', () {
    test('north-facing rooms have cool temperatures', () {
      final k = getKelvinForRoom(CompassDirection.north, UsageTime.morning);
      expect(k, greaterThan(7000));
    });

    test('south-facing rooms have warm temperatures', () {
      final k = getKelvinForRoom(CompassDirection.south, UsageTime.afternoon);
      expect(k, lessThan(6000));
    });

    test('east-facing morning is warm', () {
      final k = getKelvinForRoom(CompassDirection.east, UsageTime.morning);
      expect(k, lessThan(4000));
    });

    test('west-facing evening is warm', () {
      final k = getKelvinForRoom(CompassDirection.west, UsageTime.evening);
      expect(k, lessThan(4000));
    });

    test('allDay returns midday value', () {
      final allDay =
          getKelvinForRoom(CompassDirection.south, UsageTime.allDay);
      final midday =
          getKelvinForRoom(CompassDirection.south, UsageTime.afternoon);
      expect(allDay, midday);
    });
  });
}
