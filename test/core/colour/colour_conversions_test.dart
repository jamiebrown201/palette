import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/lab_colour.dart';

void main() {
  group('hexToRgb', () {
    test('parses hex with # prefix', () {
      final rgb = hexToRgb('#FF0000');
      expect(rgb.r, 255);
      expect(rgb.g, 0);
      expect(rgb.b, 0);
    });

    test('parses hex without # prefix', () {
      final rgb = hexToRgb('00FF00');
      expect(rgb.r, 0);
      expect(rgb.g, 255);
      expect(rgb.b, 0);
    });

    test('parses lowercase hex', () {
      final rgb = hexToRgb('#ff00ff');
      expect(rgb.r, 255);
      expect(rgb.g, 0);
      expect(rgb.b, 255);
    });

    test('parses white', () {
      final rgb = hexToRgb('#FFFFFF');
      expect(rgb.r, 255);
      expect(rgb.g, 255);
      expect(rgb.b, 255);
    });

    test('parses black', () {
      final rgb = hexToRgb('#000000');
      expect(rgb.r, 0);
      expect(rgb.g, 0);
      expect(rgb.b, 0);
    });
  });

  group('rgbToHex', () {
    test('converts to uppercase hex with # prefix', () {
      expect(rgbToHex(255, 0, 0), '#FF0000');
      expect(rgbToHex(0, 255, 0), '#00FF00');
      expect(rgbToHex(0, 0, 255), '#0000FF');
    });

    test('pads single-digit values', () {
      expect(rgbToHex(0, 0, 0), '#000000');
      expect(rgbToHex(1, 2, 3), '#010203');
    });
  });

  group('RGB to Lab conversion', () {
    test('pure white converts correctly', () {
      final lab = rgbToLab(255, 255, 255);
      expect(lab.l, closeTo(100.0, 0.5));
      expect(lab.a, closeTo(0.0, 0.5));
      expect(lab.b, closeTo(0.0, 0.5));
    });

    test('pure black converts correctly', () {
      final lab = rgbToLab(0, 0, 0);
      expect(lab.l, closeTo(0.0, 0.5));
      expect(lab.a, closeTo(0.0, 0.5));
      expect(lab.b, closeTo(0.0, 0.5));
    });

    test('pure red converts correctly', () {
      final lab = rgbToLab(255, 0, 0);
      expect(lab.l, closeTo(53.23, 1.0));
      expect(lab.a, closeTo(80.11, 1.0));
      expect(lab.b, closeTo(67.22, 1.0));
    });

    test('pure green converts correctly', () {
      final lab = rgbToLab(0, 128, 0);
      expect(lab.l, closeTo(46.23, 1.0));
      expect(lab.a, closeTo(-51.7, 1.0));
      expect(lab.b, closeTo(49.9, 1.5));
    });

    test('mid grey converts correctly', () {
      final lab = rgbToLab(128, 128, 128);
      expect(lab.l, closeTo(53.59, 1.0));
      expect(lab.a, closeTo(0.0, 0.5));
      expect(lab.b, closeTo(0.0, 0.5));
    });
  });

  group('Lab to RGB conversion', () {
    test('white Lab converts to white RGB', () {
      final rgb = labToRgb(const LabColour(100, 0, 0));
      expect(rgb.r, closeTo(255, 1));
      expect(rgb.g, closeTo(255, 1));
      expect(rgb.b, closeTo(255, 1));
    });

    test('black Lab converts to black RGB', () {
      final rgb = labToRgb(const LabColour(0, 0, 0));
      expect(rgb.r, 0);
      expect(rgb.g, 0);
      expect(rgb.b, 0);
    });
  });

  group('round-trip conversions', () {
    test('hex -> Lab -> hex round-trip is stable', () {
      const testColours = [
        '#FF0000',
        '#00FF00',
        '#0000FF',
        '#FFFFFF',
        '#000000',
        '#808080',
        '#C9A96E',
        '#8FAE8B',
        '#3C5064',
      ];

      for (final hex in testColours) {
        final lab = hexToLab(hex);
        final roundTripped = labToHex(lab);
        final original = hexToRgb(hex);
        final result = hexToRgb(roundTripped);

        // Allow 1 unit per channel difference due to floating point
        expect(
          (original.r - result.r).abs(),
          lessThanOrEqualTo(1),
          reason: 'Red channel mismatch for $hex',
        );
        expect(
          (original.g - result.g).abs(),
          lessThanOrEqualTo(1),
          reason: 'Green channel mismatch for $hex',
        );
        expect(
          (original.b - result.b).abs(),
          lessThanOrEqualTo(1),
          reason: 'Blue channel mismatch for $hex',
        );
      }
    });
  });
}
