import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/locked_furniture.dart';

void main() {
  group('LockedFurniture', () {
    test('hasEnhancedData returns false when no material fields set', () {
      const item = LockedFurniture(
        id: '1',
        roomId: 'r1',
        name: 'Sofa',
        colourHex: '#8B4513',
        role: FurnitureRole.hero,
        sortOrder: 0,
      );
      expect(item.hasEnhancedData, isFalse);
    });

    test('hasEnhancedData returns true when material is set', () {
      const item = LockedFurniture(
        id: '1',
        roomId: 'r1',
        name: 'Sofa',
        colourHex: '#8B4513',
        role: FurnitureRole.hero,
        sortOrder: 0,
        material: FurnitureMaterial.leather,
      );
      expect(item.hasEnhancedData, isTrue);
    });

    test('hasEnhancedData returns true when woodTone is set', () {
      const item = LockedFurniture(
        id: '1',
        roomId: 'r1',
        name: 'Table',
        colourHex: '#D2B48C',
        role: FurnitureRole.beta,
        sortOrder: 0,
        woodTone: WoodTone.honeyOak,
      );
      expect(item.hasEnhancedData, isTrue);
    });

    test('isKeeping returns true when status is keeping', () {
      const item = LockedFurniture(
        id: '1',
        roomId: 'r1',
        name: 'Sofa',
        colourHex: '#8B4513',
        role: FurnitureRole.hero,
        sortOrder: 0,
        status: FurnitureStatus.keeping,
      );
      expect(item.isKeeping, isTrue);
    });

    test('isKeeping returns true when status is null (default)', () {
      const item = LockedFurniture(
        id: '1',
        roomId: 'r1',
        name: 'Sofa',
        colourHex: '#8B4513',
        role: FurnitureRole.hero,
        sortOrder: 0,
      );
      expect(item.isKeeping, isTrue);
    });

    test('isKeeping returns false when status is replacing', () {
      const item = LockedFurniture(
        id: '1',
        roomId: 'r1',
        name: 'Sofa',
        colourHex: '#8B4513',
        role: FurnitureRole.hero,
        sortOrder: 0,
        status: FurnitureStatus.replacing,
      );
      expect(item.isKeeping, isFalse);
    });

    test('summaryLine shows category and material when present', () {
      const item = LockedFurniture(
        id: '1',
        roomId: 'r1',
        name: 'Oak Table',
        colourHex: '#D2B48C',
        role: FurnitureRole.beta,
        sortOrder: 0,
        category: FurnitureCategory.table,
        material: FurnitureMaterial.wood,
      );
      expect(item.summaryLine, 'Table · Wood');
    });

    test('summaryLine falls back to role when no enhanced data', () {
      const item = LockedFurniture(
        id: '1',
        roomId: 'r1',
        name: 'Sofa',
        colourHex: '#8B4513',
        role: FurnitureRole.hero,
        sortOrder: 0,
      );
      expect(item.summaryLine, 'Hero (70%)');
    });

    test('summaryLine includes status when not keeping', () {
      const item = LockedFurniture(
        id: '1',
        roomId: 'r1',
        name: 'Old Rug',
        colourHex: '#D3D3D3',
        role: FurnitureRole.beta,
        sortOrder: 0,
        category: FurnitureCategory.rug,
        status: FurnitureStatus.replacing,
      );
      expect(item.summaryLine, contains('Replacing'));
    });
  });

  group('WoodTone', () {
    test('honeyOak has warm undertone', () {
      expect(WoodTone.honeyOak.undertone, Undertone.warm);
    });

    test('ash has cool undertone', () {
      expect(WoodTone.ash.undertone, Undertone.cool);
    });
  });

  group('MetalFinish', () {
    test('antiqueBrass has warm undertone', () {
      expect(MetalFinish.antiqueBrass.undertone, Undertone.warm);
    });

    test('chrome has cool undertone', () {
      expect(MetalFinish.chrome.undertone, Undertone.cool);
    });

    test('matteBlack has neutral undertone', () {
      expect(MetalFinish.matteBlack.undertone, Undertone.neutral);
    });
  });
}
