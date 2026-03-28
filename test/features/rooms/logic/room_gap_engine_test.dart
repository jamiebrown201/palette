import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/locked_furniture.dart';
import 'package:palette/data/models/red_thread_colour.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/rooms/logic/room_gap_engine.dart';

Room _room({
  String? heroColourHex = '#C4A882',
  String? betaColourHex = '#8FAE8B',
  String? surpriseColourHex = '#C9A96E',
}) {
  return Room(
    id: 'r1',
    name: 'Living Room',
    usageTime: UsageTime.evening,
    moods: [RoomMood.cocooning],
    budget: BudgetBracket.midRange,
    isRenterMode: false,
    sortOrder: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    direction: CompassDirection.south,
    heroColourHex: heroColourHex,
    betaColourHex: betaColourHex,
    surpriseColourHex: surpriseColourHex,
  );
}

LockedFurniture _furniture({
  String id = 'f1',
  String name = 'Sofa',
  FurnitureRole role = FurnitureRole.hero,
  FurnitureCategory? category,
  FurnitureStatus? status,
  FurnitureMaterial? material,
  WoodTone? woodTone,
  MetalFinish? metalFinish,
  TextureFeel? textureFeel,
  FinishSheen? finishSheen,
}) {
  return LockedFurniture(
    id: id,
    roomId: 'r1',
    name: name,
    colourHex: '#8B7355',
    role: role,
    sortOrder: 0,
    category: category,
    status: status,
    material: material,
    woodTone: woodTone,
    metalFinish: metalFinish,
    textureFeel: textureFeel,
    finishSheen: finishSheen,
  );
}

void main() {
  group('analyseRoomGaps', () {
    test('returns empty report when no 70/20/10 plan', () {
      final room = _room(heroColourHex: '#C4A882', betaColourHex: null);
      final report = analyseRoomGaps(
        room: room,
        furniture: [],
        threadColours: [],
      );

      expect(report.hasGaps, isFalse);
    });

    test('detects rug gap when no rug locked', () {
      final report = analyseRoomGaps(
        room: _room(),
        furniture: [
          _furniture(category: FurnitureCategory.sofa),
          _furniture(
            id: 'f2',
            name: 'Table',
            category: FurnitureCategory.table,
          ),
        ],
        threadColours: [],
      );

      expect(report.gaps.any((g) => g.gapType == GapType.rug), isTrue);
    });

    test('does not detect rug gap when rug exists', () {
      final report = analyseRoomGaps(
        room: _room(),
        furniture: [_furniture(category: FurnitureCategory.rug)],
        threadColours: [],
      );

      expect(report.gaps.any((g) => g.gapType == GapType.rug), isFalse);
    });

    test('detects lighting gap when no lighting items', () {
      final report = analyseRoomGaps(
        room: _room(),
        furniture: [_furniture(category: FurnitureCategory.sofa)],
        threadColours: [],
      );

      expect(
        report.gaps.any((g) => g.gapType == GapType.ambientLighting),
        isTrue,
      );
    });

    test('detects accent colour gap when surprise tier empty', () {
      final report = analyseRoomGaps(
        room: _room(),
        furniture: [
          _furniture(role: FurnitureRole.hero),
          _furniture(id: 'f2', name: 'Rug', role: FurnitureRole.beta),
        ],
        threadColours: [],
      );

      expect(report.gaps.any((g) => g.gapType == GapType.accentColour), isTrue);
    });

    test('detects texture contrast when all smooth', () {
      final report = analyseRoomGaps(
        room: _room(),
        furniture: [
          _furniture(id: 'f1', textureFeel: TextureFeel.smooth),
          _furniture(id: 'f2', name: 'Table', textureFeel: TextureFeel.smooth),
        ],
        threadColours: [],
      );

      expect(
        report.gaps.any((g) => g.gapType == GapType.textureContrast),
        isTrue,
      );
    });

    test('detects metal clash with warm and cool metals', () {
      final report = analyseRoomGaps(
        room: _room(),
        furniture: [
          _furniture(
            id: 'f1',
            metalFinish: MetalFinish.antiqueBrass,
            material: FurnitureMaterial.metal,
          ),
          _furniture(
            id: 'f2',
            name: 'Lamp',
            metalFinish: MetalFinish.chrome,
            material: FurnitureMaterial.metal,
          ),
          _furniture(
            id: 'f3',
            name: 'Shelf',
            metalFinish: MetalFinish.copper,
            material: FurnitureMaterial.metal,
          ),
        ],
        threadColours: [],
      );

      expect(report.gaps.any((g) => g.gapType == GapType.metalClash), isTrue);
    });

    test('detects wood clash with warm and cool woods', () {
      final report = analyseRoomGaps(
        room: _room(),
        furniture: [
          _furniture(
            id: 'f1',
            woodTone: WoodTone.honeyOak,
            material: FurnitureMaterial.wood,
          ),
          _furniture(
            id: 'f2',
            name: 'Shelf',
            woodTone: WoodTone.ash,
            material: FurnitureMaterial.wood,
          ),
        ],
        threadColours: [],
      );

      expect(report.gaps.any((g) => g.gapType == GapType.woodClash), isTrue);
    });

    test('detects sheen imbalance with 3+ polished items', () {
      final report = analyseRoomGaps(
        room: _room(),
        furniture: [
          _furniture(id: 'f1', finishSheen: FinishSheen.polished),
          _furniture(
            id: 'f2',
            name: 'Mirror',
            finishSheen: FinishSheen.polished,
          ),
          _furniture(id: 'f3', name: 'Lamp', finishSheen: FinishSheen.polished),
        ],
        threadColours: [],
      );

      expect(report.gaps.any((g) => g.gapType == GapType.sheenBalance), isTrue);
    });

    test('detects red thread disconnect', () {
      final report = analyseRoomGaps(
        room: _room(),
        furniture: [],
        threadColours: [
          const RedThreadColour(id: 't1', hex: '#FF0000', sortOrder: 0),
        ],
      );

      expect(report.gaps.any((g) => g.gapType == GapType.redThread), isTrue);
    });

    test('does not flag red thread when connected', () {
      // Hero colour matches the thread colour closely
      final report = analyseRoomGaps(
        room: _room(heroColourHex: '#FF0000'),
        furniture: [],
        threadColours: [
          const RedThreadColour(id: 't1', hex: '#FF0505', sortOrder: 0),
        ],
      );

      expect(report.gaps.any((g) => g.gapType == GapType.redThread), isFalse);
    });

    test('gaps sorted by severity then confidence', () {
      final report = analyseRoomGaps(
        room: _room(),
        furniture: [],
        threadColours: [],
      );

      if (report.gaps.length >= 2) {
        for (var i = 0; i < report.gaps.length - 1; i++) {
          final current = report.gaps[i];
          final next = report.gaps[i + 1];
          expect(
            current.severity.index >= next.severity.index,
            isTrue,
            reason: '${current.gapType} should be >= ${next.gapType} severity',
          );
        }
      }
    });

    test('data quality reports correctly', () {
      // No furniture
      var report = analyseRoomGaps(
        room: _room(),
        furniture: [],
        threadColours: [],
      );
      expect(report.dataQuality, DataQuality.none);

      // Minimal — no enhanced data
      report = analyseRoomGaps(
        room: _room(),
        furniture: [_furniture()],
        threadColours: [],
      );
      expect(report.dataQuality, DataQuality.minimal);

      // Rich — all have enhanced data
      report = analyseRoomGaps(
        room: _room(),
        furniture: [
          _furniture(
            material: FurnitureMaterial.wood,
            woodTone: WoodTone.walnut,
          ),
        ],
        threadColours: [],
      );
      expect(report.dataQuality, DataQuality.rich);
    });

    test('material balance detects all warm materials', () {
      final report = analyseRoomGaps(
        room: _room(),
        furniture: [
          _furniture(id: 'f1', material: FurnitureMaterial.wood),
          _furniture(
            id: 'f2',
            name: 'Chair',
            material: FurnitureMaterial.leather,
          ),
          _furniture(
            id: 'f3',
            name: 'Basket',
            material: FurnitureMaterial.wickerRattan,
          ),
        ],
        threadColours: [],
      );

      expect(report.gaps.any((g) => g.gapType == GapType.coolMaterial), isTrue);
    });

    test('detects artwork gap when enough items but no art', () {
      final report = analyseRoomGaps(
        room: _room(),
        furniture: [
          _furniture(id: 'f1', category: FurnitureCategory.sofa),
          _furniture(
            id: 'f2',
            name: 'Table',
            category: FurnitureCategory.table,
          ),
          _furniture(id: 'f3', name: 'Rug', category: FurnitureCategory.rug),
        ],
        threadColours: [],
      );

      expect(report.gaps.any((g) => g.gapType == GapType.artwork), isTrue);
    });

    test('does not detect artwork gap when art item present', () {
      final report = analyseRoomGaps(
        room: _room(),
        furniture: [
          _furniture(id: 'f1', category: FurnitureCategory.sofa),
          _furniture(
            id: 'f2',
            name: 'Table',
            category: FurnitureCategory.table,
          ),
          _furniture(
            id: 'f3',
            name: 'Landscape Print',
            category: FurnitureCategory.other,
          ),
        ],
        threadColours: [],
      );

      expect(report.gaps.any((g) => g.gapType == GapType.artwork), isFalse);
    });

    test('detects mirror gap in north-facing room', () {
      final report = analyseRoomGaps(
        room: _room().copyWith(direction: CompassDirection.north),
        furniture: [
          _furniture(id: 'f1', category: FurnitureCategory.sofa),
          _furniture(
            id: 'f2',
            name: 'Table',
            category: FurnitureCategory.table,
          ),
          _furniture(id: 'f3', name: 'Rug', category: FurnitureCategory.rug),
        ],
        threadColours: [],
      );

      expect(report.gaps.any((g) => g.gapType == GapType.mirror), isTrue);
    });

    test('detects mirror gap in small room', () {
      final report = analyseRoomGaps(
        room: _room().copyWith(roomSize: RoomSize.small),
        furniture: [
          _furniture(id: 'f1', category: FurnitureCategory.sofa),
          _furniture(
            id: 'f2',
            name: 'Table',
            category: FurnitureCategory.table,
          ),
          _furniture(id: 'f3', name: 'Rug', category: FurnitureCategory.rug),
        ],
        threadColours: [],
      );

      expect(report.gaps.any((g) => g.gapType == GapType.mirror), isTrue);
    });

    test('does not detect mirror gap when mirror present', () {
      final report = analyseRoomGaps(
        room: _room().copyWith(direction: CompassDirection.north),
        furniture: [
          _furniture(id: 'f1', category: FurnitureCategory.sofa),
          _furniture(
            id: 'f2',
            name: 'Table',
            category: FurnitureCategory.table,
          ),
          _furniture(id: 'f3', name: 'Wall Mirror'),
        ],
        threadColours: [],
      );

      expect(report.gaps.any((g) => g.gapType == GapType.mirror), isFalse);
    });

    test('skips replacing items when checking gaps', () {
      final report = analyseRoomGaps(
        room: _room(),
        furniture: [
          _furniture(
            category: FurnitureCategory.rug,
            status: FurnitureStatus.replacing,
          ),
        ],
        threadColours: [],
      );

      // Rug is being replaced so treated as not present
      expect(report.gaps.any((g) => g.gapType == GapType.rug), isTrue);
    });
  });
}
