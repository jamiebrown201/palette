import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/locked_furniture.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/rooms/logic/room_audit.dart';

void main() {
  group('auditRoom', () {
    Room makeRoom({String? heroHex, String? betaHex, String? surpriseHex}) {
      return Room(
        id: 'r1',
        name: 'Living Room',
        direction: CompassDirection.south,
        usageTime: UsageTime.evening,
        moods: [RoomMood.cocooning],
        budget: BudgetBracket.midRange,
        heroColourHex: heroHex,
        betaColourHex: betaHex,
        surpriseColourHex: surpriseHex,
        isRenterMode: false,
        sortOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    LockedFurniture makeFurniture({
      String name = 'Item',
      FurnitureCategory? category,
      FurnitureStyle? style,
      FurnitureMaterial? material,
      WoodTone? woodTone,
      MetalFinish? metalFinish,
      TextureFeel? textureFeel,
      VisualWeight? visualWeight,
      String colourHex = '#8B7355',
    }) {
      return LockedFurniture(
        id: 'f_${name.hashCode}',
        roomId: 'r1',
        name: name,
        colourHex: colourHex,
        role: FurnitureRole.hero,
        sortOrder: 0,
        category: category,
        status: FurnitureStatus.keeping,
        material: material,
        woodTone: woodTone,
        metalFinish: metalFinish,
        style: style,
        textureFeel: textureFeel,
        visualWeight: visualWeight,
      );
    }

    test('returns unknown statuses with no furniture', () {
      final report = auditRoom(room: makeRoom(), furniture: []);

      expect(report.rules, isNotEmpty);
      // Most rules should be unknown with no data
      final unknownCount =
          report.rules.where((r) => r.status == AuditStatus.unknown).length;
      expect(unknownCount, greaterThanOrEqualTo(4));
    });

    test('colour plan scores pass with complete 70/20/10', () {
      final report = auditRoom(
        room: makeRoom(
          heroHex: '#C9A96E',
          betaHex: '#8FAE8B',
          surpriseHex: '#CC7755',
        ),
        furniture: [],
      );

      final colourRule = report.rules.firstWhere((r) => r.id == 'colour_plan');
      expect(colourRule.status, AuditStatus.pass);
    });

    test('colour plan scores partial with hero only', () {
      final report = auditRoom(
        room: makeRoom(heroHex: '#C9A96E'),
        furniture: [],
      );

      final colourRule = report.rules.firstWhere((r) => r.id == 'colour_plan');
      expect(colourRule.status, AuditStatus.partial);
    });

    test('colour plan scores needsWork with no colours', () {
      final report = auditRoom(room: makeRoom(), furniture: []);

      final colourRule = report.rules.firstWhere((r) => r.id == 'colour_plan');
      expect(colourRule.status, AuditStatus.needsWork);
    });

    test('texture layering passes with 3+ textures', () {
      final furniture = [
        makeFurniture(name: 'Sofa', textureFeel: TextureFeel.smooth),
        makeFurniture(name: 'Throw', textureFeel: TextureFeel.chunky),
        makeFurniture(name: 'Rug', textureFeel: TextureFeel.highTexture),
      ];

      final report = auditRoom(room: makeRoom(), furniture: furniture);
      final rule = report.rules.firstWhere((r) => r.id == 'texture_layering');
      expect(rule.status, AuditStatus.pass);
    });

    test('material balance passes with warm and cool', () {
      final furniture = [
        makeFurniture(name: 'Table', material: FurnitureMaterial.wood),
        makeFurniture(name: 'Lamp', material: FurnitureMaterial.metal),
      ];

      final report = auditRoom(room: makeRoom(), furniture: furniture);
      final rule = report.rules.firstWhere((r) => r.id == 'material_balance');
      expect(rule.status, AuditStatus.pass);
    });

    test('material balance partial with warm only', () {
      final furniture = [
        makeFurniture(name: 'Table', material: FurnitureMaterial.wood),
        makeFurniture(name: 'Sofa', material: FurnitureMaterial.fabric),
      ];

      final report = auditRoom(room: makeRoom(), furniture: furniture);
      final rule = report.rules.firstWhere((r) => r.id == 'material_balance');
      expect(rule.status, AuditStatus.partial);
    });

    test('metal consistency passes with 2 metals', () {
      final furniture = [
        makeFurniture(name: 'Lamp', metalFinish: MetalFinish.antiqueBrass),
        makeFurniture(name: 'Frame', metalFinish: MetalFinish.matteBlack),
      ];

      final report = auditRoom(room: makeRoom(), furniture: furniture);
      final rule = report.rules.firstWhere((r) => r.id == 'metal_consistency');
      expect(rule.status, AuditStatus.pass);
    });

    test('metal consistency fails with 3+ metals', () {
      final furniture = [
        makeFurniture(name: 'Lamp', metalFinish: MetalFinish.antiqueBrass),
        makeFurniture(name: 'Frame', metalFinish: MetalFinish.matteBlack),
        makeFurniture(name: 'Tap', metalFinish: MetalFinish.chrome),
      ];

      final report = auditRoom(room: makeRoom(), furniture: furniture);
      final rule = report.rules.firstWhere((r) => r.id == 'metal_consistency');
      expect(rule.status, AuditStatus.needsWork);
    });

    test('wood tone passes with compatible variety', () {
      final furniture = [
        makeFurniture(name: 'Table', woodTone: WoodTone.honeyOak),
        makeFurniture(name: 'Shelf', woodTone: WoodTone.walnut),
      ];

      final report = auditRoom(room: makeRoom(), furniture: furniture);
      final rule = report.rules.firstWhere((r) => r.id == 'wood_tone');
      expect(rule.status, AuditStatus.pass);
    });

    test('wood tone fails with warm/cool clash', () {
      final furniture = [
        makeFurniture(name: 'Table', woodTone: WoodTone.honeyOak),
        makeFurniture(name: 'Shelf', woodTone: WoodTone.ash),
      ];

      final report = auditRoom(room: makeRoom(), furniture: furniture);
      final rule = report.rules.firstWhere((r) => r.id == 'wood_tone');
      expect(rule.status, AuditStatus.needsWork);
    });

    test('visual weight passes with light and heavy items', () {
      final furniture = [
        makeFurniture(name: 'Bookshelf', visualWeight: VisualWeight.heavy),
        makeFurniture(name: 'Side table', visualWeight: VisualWeight.light),
      ];

      final report = auditRoom(room: makeRoom(), furniture: furniture);
      final rule = report.rules.firstWhere((r) => r.id == 'visual_weight');
      expect(rule.status, AuditStatus.pass);
    });

    test('layered lighting needs work with no lighting', () {
      final report = auditRoom(room: makeRoom(), furniture: []);
      final rule = report.rules.firstWhere((r) => r.id == 'layered_lighting');
      expect(rule.status, AuditStatus.needsWork);
    });

    test('layered lighting passes with all three layers', () {
      final furniture = [
        makeFurniture(
          name: 'Ceiling pendant',
          category: FurnitureCategory.lighting,
        ),
        makeFurniture(
          name: 'Floor reading lamp',
          category: FurnitureCategory.lighting,
        ),
        makeFurniture(
          name: 'Table lamp accent',
          category: FurnitureCategory.lighting,
        ),
      ];

      final report = auditRoom(room: makeRoom(), furniture: furniture);
      final rule = report.rules.firstWhere((r) => r.id == 'layered_lighting');
      expect(rule.status, AuditStatus.pass);
    });

    test('score is calculated correctly from rule statuses', () {
      final report = auditRoom(
        room: makeRoom(
          heroHex: '#C9A96E',
          betaHex: '#8FAE8B',
          surpriseHex: '#CC7755',
        ),
        furniture: [
          makeFurniture(
            name: 'Sofa',
            textureFeel: TextureFeel.smooth,
            material: FurnitureMaterial.fabric,
            visualWeight: VisualWeight.heavy,
            style: FurnitureStyle.modern,
          ),
          makeFurniture(
            name: 'Rug',
            textureFeel: TextureFeel.chunky,
            material: FurnitureMaterial.wood,
            visualWeight: VisualWeight.medium,
            style: FurnitureStyle.traditional,
          ),
          makeFurniture(
            name: 'Lamp',
            textureFeel: TextureFeel.highTexture,
            material: FurnitureMaterial.metal,
            visualWeight: VisualWeight.light,
            metalFinish: MetalFinish.antiqueBrass,
            category: FurnitureCategory.lighting,
          ),
        ],
      );

      // Score should be > 0 with this much data
      expect(report.score, greaterThan(0));
      expect(report.totalPossible, greaterThan(0));
      expect(report.summary, isNotEmpty);
    });

    test('old/new/black/gold detects style mix', () {
      final furniture = [
        makeFurniture(name: 'Modern sofa', style: FurnitureStyle.modern),
        makeFurniture(name: 'Vintage chair', style: FurnitureStyle.traditional),
        makeFurniture(name: 'Black frame', metalFinish: MetalFinish.matteBlack),
        makeFurniture(
          name: 'Brass lamp',
          metalFinish: MetalFinish.antiqueBrass,
        ),
      ];

      final report = auditRoom(room: makeRoom(), furniture: furniture);
      final rule = report.rules.firstWhere((r) => r.id == 'old_new_black_gold');
      expect(rule.status, AuditStatus.pass);
    });

    test('odd numbers partial with even accessories', () {
      final furniture = [
        makeFurniture(name: 'Candle 1', category: FurnitureCategory.other),
        makeFurniture(name: 'Candle 2', category: FurnitureCategory.other),
      ];

      final report = auditRoom(room: makeRoom(), furniture: furniture);
      final rule = report.rules.firstWhere((r) => r.id == 'odd_numbers');
      expect(rule.status, AuditStatus.partial);
    });

    test('odd numbers pass with odd accessories', () {
      final furniture = [
        makeFurniture(name: 'Candle 1', category: FurnitureCategory.other),
        makeFurniture(name: 'Candle 2', category: FurnitureCategory.other),
        makeFurniture(name: 'Vase', category: FurnitureCategory.other),
      ];

      final report = auditRoom(room: makeRoom(), furniture: furniture);
      final rule = report.rules.firstWhere((r) => r.id == 'odd_numbers');
      expect(rule.status, AuditStatus.pass);
    });
  });
}
