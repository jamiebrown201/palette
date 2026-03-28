import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/locked_furniture.dart';
import 'package:palette/data/models/product.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/rooms/logic/lighting_planner.dart';

void main() {
  final now = DateTime.now();

  Room makeRoom({
    CompassDirection? direction = CompassDirection.south,
    UsageTime usageTime = UsageTime.evening,
    List<RoomMood> moods = const [RoomMood.cocooning],
    BudgetBracket budget = BudgetBracket.midRange,
    bool isRenterMode = false,
    RoomSize? roomSize,
  }) {
    return Room(
      id: 'room-1',
      name: 'Living Room',
      direction: direction,
      usageTime: usageTime,
      moods: moods,
      budget: budget,
      isRenterMode: isRenterMode,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
      roomSize: roomSize,
    );
  }

  Product makeProduct({
    required String id,
    required ProductCategory category,
    required String name,
    double price = 100,
    bool renterSafe = true,
  }) {
    return Product(
      id: id,
      category: category,
      name: name,
      brand: 'TestBrand',
      retailer: 'TestRetailer',
      priceGbp: price,
      affiliateUrl: 'https://example.com/$id',
      imageUrl: 'https://example.com/$id.jpg',
      primaryColourHex: '#C9A96E',
      undertone: Undertone.warm,
      materials: const [ProductMaterial.metalBrass],
      styles: const [ProductStyle.modern],
      textureFeel: TextureFeel.smooth,
      visualWeight: VisualWeight.medium,
      finishSheen: FinishSheen.lowSheen,
      renterSafe: renterSafe,
      available: true,
    );
  }

  LockedFurniture makeFurniture({
    required String name,
    FurnitureCategory category = FurnitureCategory.lighting,
    FurnitureStatus status = FurnitureStatus.keeping,
  }) {
    return LockedFurniture(
      id: 'f-$name',
      roomId: 'room-1',
      name: name,
      colourHex: '#C9A96E',
      role: FurnitureRole.beta,
      sortOrder: 0,
      category: category,
      status: status,
    );
  }

  final catalogue = [
    makeProduct(
      id: 'p1',
      category: ProductCategory.pendantLight,
      name: 'Brass Pendant',
    ),
    makeProduct(
      id: 'p2',
      category: ProductCategory.floorLamp,
      name: 'Oak Floor Lamp',
    ),
    makeProduct(
      id: 'p3',
      category: ProductCategory.tableLamp,
      name: 'Ceramic Table Lamp',
    ),
    makeProduct(
      id: 'p4',
      category: ProductCategory.plugInPendant,
      name: 'Plug-in Pendant',
    ),
    makeProduct(id: 'p5', category: ProductCategory.rug, name: 'Wool Rug'),
  ];

  group('LightingPlanner', () {
    test('generates plan with 3 layers', () {
      final plan = generateLightingPlan(
        room: makeRoom(),
        furniture: [],
        catalogue: catalogue,
      );

      expect(plan.layers.length, 3);
      expect(plan.layersTotal, 3);
    });

    test('no furniture means 0 layers covered', () {
      final plan = generateLightingPlan(
        room: makeRoom(),
        furniture: [],
        catalogue: catalogue,
      );

      expect(plan.layersCovered, 0);
      expect(plan.isComplete, false);
      expect(plan.hasGaps, true);
    });

    test('ambient layer covered by pendant furniture', () {
      final plan = generateLightingPlan(
        room: makeRoom(),
        furniture: [makeFurniture(name: 'Ceiling pendant')],
        catalogue: catalogue,
      );

      final ambient = plan.layers.firstWhere(
        (l) => l.type == LightingSubcategory.ambient,
      );
      expect(ambient.isCovered, true);
      expect(ambient.coveredBy?.name, 'Ceiling pendant');
      expect(plan.layersCovered, 1);
    });

    test('task layer covered by floor lamp furniture', () {
      final plan = generateLightingPlan(
        room: makeRoom(),
        furniture: [makeFurniture(name: 'Floor lamp')],
        catalogue: catalogue,
      );

      final task = plan.layers.firstWhere(
        (l) => l.type == LightingSubcategory.task,
      );
      expect(task.isCovered, true);
      expect(plan.layersCovered, 1);
    });

    test('accent layer covered by table lamp furniture', () {
      final plan = generateLightingPlan(
        room: makeRoom(),
        furniture: [makeFurniture(name: 'Table lamp')],
        catalogue: catalogue,
      );

      final accent = plan.layers.firstWhere(
        (l) => l.type == LightingSubcategory.accent,
      );
      expect(accent.isCovered, true);
      expect(plan.layersCovered, 1);
    });

    test('all 3 layers covered means isComplete', () {
      final plan = generateLightingPlan(
        room: makeRoom(),
        furniture: [
          makeFurniture(name: 'Ceiling pendant'),
          makeFurniture(name: 'Floor lamp'),
          makeFurniture(name: 'Table lamp'),
        ],
        catalogue: catalogue,
      );

      expect(plan.layersCovered, 3);
      expect(plan.isComplete, true);
      expect(plan.hasGaps, false);
    });

    test('uncovered layers have product recommendations', () {
      final plan = generateLightingPlan(
        room: makeRoom(),
        furniture: [],
        catalogue: catalogue,
      );

      for (final layer in plan.layers) {
        expect(layer.recommendations, isNotNull);
        expect(layer.recommendations, isNotEmpty);
      }
    });

    test('covered layers have no recommendations', () {
      final plan = generateLightingPlan(
        room: makeRoom(),
        furniture: [
          makeFurniture(name: 'Ceiling pendant'),
          makeFurniture(name: 'Floor lamp'),
          makeFurniture(name: 'Table lamp'),
        ],
        catalogue: catalogue,
      );

      for (final layer in plan.layers) {
        expect(layer.recommendations, isNull);
      }
    });

    test('renter mode adds renter note to ambient layer', () {
      final plan = generateLightingPlan(
        room: makeRoom(isRenterMode: true),
        furniture: [],
        catalogue: catalogue,
      );

      final ambient = plan.layers.firstWhere(
        (l) => l.type == LightingSubcategory.ambient,
      );
      expect(ambient.renterNote, isNotNull);
      expect(ambient.renterNote, contains('plug-in'));
    });

    test('renter mode filters to renter-safe products', () {
      final mixedCatalogue = [
        makeProduct(
          id: 'safe',
          category: ProductCategory.pendantLight,
          name: 'Plug-in Pendant',
          renterSafe: true,
        ),
        makeProduct(
          id: 'unsafe',
          category: ProductCategory.pendantLight,
          name: 'Hardwired Pendant',
          renterSafe: false,
        ),
      ];

      final plan = generateLightingPlan(
        room: makeRoom(isRenterMode: true),
        furniture: [],
        catalogue: mixedCatalogue,
      );

      final ambient = plan.layers.firstWhere(
        (l) => l.type == LightingSubcategory.ambient,
      );
      expect(ambient.recommendations?.every((p) => p.renterSafe), true);
    });

    test('north-facing evening room gets overall note', () {
      final plan = generateLightingPlan(
        room: makeRoom(
          direction: CompassDirection.north,
          usageTime: UsageTime.evening,
        ),
        furniture: [],
        catalogue: catalogue,
      );

      expect(plan.overallNote, isNotNull);
      expect(plan.overallNote, contains('North-facing'));
    });

    test('non-lighting furniture is ignored', () {
      final plan = generateLightingPlan(
        room: makeRoom(),
        furniture: [
          makeFurniture(name: 'Sofa', category: FurnitureCategory.sofa),
        ],
        catalogue: catalogue,
      );

      expect(plan.layersCovered, 0);
    });

    test('replacing furniture is not counted as covered', () {
      final plan = generateLightingPlan(
        room: makeRoom(),
        furniture: [
          makeFurniture(
            name: 'Ceiling pendant',
            status: FurnitureStatus.replacing,
          ),
        ],
        catalogue: catalogue,
      );

      final ambient = plan.layers.firstWhere(
        (l) => l.type == LightingSubcategory.ambient,
      );
      expect(ambient.isCovered, false);
    });

    test('summary changes based on coverage', () {
      final noCoverage = generateLightingPlan(
        room: makeRoom(),
        furniture: [],
        catalogue: catalogue,
      );
      expect(noCoverage.summary, contains('No lighting layers'));

      final fullCoverage = generateLightingPlan(
        room: makeRoom(),
        furniture: [
          makeFurniture(name: 'Ceiling pendant'),
          makeFurniture(name: 'Floor lamp'),
          makeFurniture(name: 'Table lamp'),
        ],
        catalogue: catalogue,
      );
      expect(fullCoverage.summary, contains('all three'));
    });

    test('ambient recommendations include pendant and plug-in pendant', () {
      final plan = generateLightingPlan(
        room: makeRoom(),
        furniture: [],
        catalogue: catalogue,
      );

      final ambient = plan.layers.firstWhere(
        (l) => l.type == LightingSubcategory.ambient,
      );
      final categories =
          ambient.recommendations?.map((p) => p.category).toSet() ?? {};
      expect(
        categories.any(
          (c) =>
              c == ProductCategory.pendantLight ||
              c == ProductCategory.plugInPendant,
        ),
        true,
      );
    });

    test('task recommendations include floor lamps', () {
      final plan = generateLightingPlan(
        room: makeRoom(),
        furniture: [],
        catalogue: catalogue,
      );

      final task = plan.layers.firstWhere(
        (l) => l.type == LightingSubcategory.task,
      );
      expect(
        task.recommendations?.any(
          (p) => p.category == ProductCategory.floorLamp,
        ),
        true,
      );
    });

    test('accent recommendations include table lamps', () {
      final plan = generateLightingPlan(
        room: makeRoom(),
        furniture: [],
        catalogue: catalogue,
      );

      final accent = plan.layers.firstWhere(
        (l) => l.type == LightingSubcategory.accent,
      );
      expect(
        accent.recommendations?.any(
          (p) => p.category == ProductCategory.tableLamp,
        ),
        true,
      );
    });

    test('each layer has whyItMatters text', () {
      final plan = generateLightingPlan(
        room: makeRoom(),
        furniture: [],
        catalogue: catalogue,
      );

      for (final layer in plan.layers) {
        expect(layer.whyItMatters, isNotEmpty);
      }
    });

    test('north-facing room ambient explanation mentions north', () {
      final plan = generateLightingPlan(
        room: makeRoom(direction: CompassDirection.north),
        furniture: [],
        catalogue: catalogue,
      );

      final ambient = plan.layers.firstWhere(
        (l) => l.type == LightingSubcategory.ambient,
      );
      expect(ambient.whyItMatters, contains('north-facing'));
    });

    test('large room gets overall note about multiple sources', () {
      final plan = generateLightingPlan(
        room: makeRoom(roomSize: RoomSize.large),
        furniture: [],
        catalogue: catalogue,
      );

      expect(plan.overallNote, isNotNull);
      expect(plan.overallNote, contains('Large rooms'));
    });
  });
}
