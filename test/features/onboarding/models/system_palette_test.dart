import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:palette/features/onboarding/models/system_palette.dart';

void main() {
  const trimWhite = PaintReference(
    paintId: 'tw1',
    hex: '#F5F0E8',
    name: 'White Cotton',
    brand: 'Dulux',
    role: 'trimWhite',
    roleLabel: 'Trim White',
  );

  const domWall = PaintReference(
    paintId: 'dw1',
    hex: '#C4A882',
    name: 'Camel',
    brand: 'FB',
    role: 'dominantWall',
  );

  const supWall = PaintReference(
    paintId: 'sw1',
    hex: '#D4C5A9',
    name: 'Stony Ground',
    brand: 'FB',
    role: 'supportingWall',
    roleLabel: 'Supporting Wall',
  );

  const deepAnchor = PaintReference(
    paintId: 'da1',
    hex: '#8B7355',
    name: 'Dark Buff',
    brand: 'LG',
    role: 'deepAnchor',
  );

  const accentPop = PaintReference(
    paintId: 'ap1',
    hex: '#4A6741',
    name: 'Calke Green',
    brand: 'FB',
    role: 'accentPop',
  );

  const spineColour = PaintReference(
    paintId: 'sc1',
    hex: '#DEB887',
    name: 'Burlywood',
    brand: 'Dulux',
    role: 'spineColour',
  );

  const palette = SystemPalette(
    trimWhite: trimWhite,
    dominantWalls: [domWall],
    supportingWalls: [supWall],
    deepAnchor: deepAnchor,
    accentPops: [accentPop],
    spineColour: spineColour,
  );

  group('PaintReference serialization', () {
    test('toMap includes all fields', () {
      final map = trimWhite.toMap();
      expect(map['paintId'], 'tw1');
      expect(map['hex'], '#F5F0E8');
      expect(map['name'], 'White Cotton');
      expect(map['brand'], 'Dulux');
      expect(map['role'], 'trimWhite');
      expect(map['roleLabel'], 'Trim White');
    });

    test('toMap omits null roleLabel', () {
      final map = domWall.toMap();
      expect(map.containsKey('roleLabel'), isFalse);
    });

    test('fromMap round-trips', () {
      final map = trimWhite.toMap();
      final restored = PaintReference.fromMap(map);
      expect(restored.paintId, trimWhite.paintId);
      expect(restored.hex, trimWhite.hex);
      expect(restored.name, trimWhite.name);
      expect(restored.brand, trimWhite.brand);
      expect(restored.role, trimWhite.role);
      expect(restored.roleLabel, trimWhite.roleLabel);
    });
  });

  group('SystemPalette serialization', () {
    test('toJson and fromJson round-trip', () {
      final jsonStr = palette.toJson();
      final restored = SystemPalette.fromJson(jsonStr);

      expect(restored.trimWhite.paintId, trimWhite.paintId);
      expect(restored.trimWhite.hex, trimWhite.hex);
      expect(restored.dominantWalls.length, 1);
      expect(restored.dominantWalls.first.hex, domWall.hex);
      expect(restored.supportingWalls.length, 1);
      expect(restored.supportingWalls.first.hex, supWall.hex);
      expect(restored.deepAnchor.hex, deepAnchor.hex);
      expect(restored.accentPops.length, 1);
      expect(restored.accentPops.first.hex, accentPop.hex);
      expect(restored.spineColour.hex, spineColour.hex);
    });

    test('fromMap works with decoded JSON map', () {
      final map = json.decode(palette.toJson()) as Map<String, dynamic>;
      final restored = SystemPalette.fromMap(map);
      expect(restored.trimWhite.paintId, trimWhite.paintId);
    });

    test('toColourHexes returns deduped list', () {
      final hexes = palette.toColourHexes();
      expect(hexes, isNotEmpty);
      expect(
        hexes.length,
        hexes.toSet().length,
        reason: 'No duplicate hex values',
      );
      expect(hexes.first, trimWhite.hex);
      expect(hexes, contains(domWall.hex));
      expect(hexes, contains(deepAnchor.hex));
      expect(hexes, contains(accentPop.hex));
      expect(hexes, contains(spineColour.hex));
    });

    test('toColourHexes includes all role hexes', () {
      final hexes = palette.toColourHexes();
      expect(hexes.length, greaterThanOrEqualTo(6));
    });
  });
}
