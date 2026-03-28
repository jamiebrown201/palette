import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/colour/colour_conversions.dart';

void main() {
  group('colorToHex', () {
    test('converts white', () {
      expect(colorToHex(const Color(0xFFFFFFFF)), '#FFFFFF');
    });

    test('converts black', () {
      expect(colorToHex(const Color(0xFF000000)), '#000000');
    });

    test('converts red', () {
      expect(colorToHex(const Color(0xFFFF0000)), '#FF0000');
    });

    test('converts sage green', () {
      expect(colorToHex(const Color(0xFF8FAE8B)), '#8FAE8B');
    });

    test('round-trips with hexToColor', () {
      const original = '#A37B2C';
      final colour = hexToColor(original);
      expect(colorToHex(colour), original);
    });
  });
}
