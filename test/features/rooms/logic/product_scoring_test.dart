import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/locked_furniture.dart';
import 'package:palette/data/models/product.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/rooms/logic/product_scoring.dart';

void main() {
  group('Product Scoring Engine', () {
    late Room testRoom;
    late List<Product> candidates;

    setUp(() {
      testRoom = Room(
        id: 'room-1',
        name: 'Living Room',
        direction: CompassDirection.south,
        usageTime: UsageTime.evening,
        moods: [RoomMood.cocooning],
        budget: BudgetBracket.midRange,
        heroColourHex: '#C9B99A',
        betaColourHex: '#8B7355',
        surpriseColourHex: '#A0522D',
        isRenterMode: false,
        sortOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      candidates = [
        _product(
          id: 'p1',
          name: 'Warm Rug',
          hex: '#C9B99A',
          price: 120.0,
          undertone: Undertone.warm,
          category: ProductCategory.rug,
        ),
        _product(
          id: 'p2',
          name: 'Cool Rug',
          hex: '#4A5D4F',
          price: 100.0,
          undertone: Undertone.cool,
          category: ProductCategory.rug,
        ),
        _product(
          id: 'p3',
          name: 'Expensive Rug',
          hex: '#C9B99A',
          price: 500.0,
          undertone: Undertone.warm,
          category: ProductCategory.rug,
        ),
      ];
    });

    test('filters out products exceeding budget', () {
      final scored = scoreProducts(
        candidates: candidates,
        room: testRoom,
        lockedFurniture: [],
        archetype: ColourArchetype.theCocooner,
      );

      // Expensive rug (£500 investment tier) should be filtered out
      // since room budget is midRange
      expect(scored.every((s) => s.product.id != 'p3'), isTrue);
    });

    test('ranks warm undertone higher for south-facing room', () {
      final scored = scoreProducts(
        candidates: candidates,
        room: testRoom,
        lockedFurniture: [],
        archetype: ColourArchetype.theCocooner,
      );

      expect(scored, isNotEmpty);
      // Warm rug should score higher than cool rug in warm-toned room
      final warmScore =
          scored.firstWhere((s) => s.product.id == 'p1').totalScore;
      final coolScore =
          scored.firstWhere((s) => s.product.id == 'p2').totalScore;
      expect(warmScore, greaterThan(coolScore));
    });

    test('generates explanations for each recommendation', () {
      final scored = scoreProducts(
        candidates: candidates,
        room: testRoom,
        lockedFurniture: [],
        archetype: ColourArchetype.theCocooner,
      );

      for (final rec in scored) {
        expect(rec.primaryReason, isNotEmpty);
        expect(rec.secondaryReason, isNotEmpty);
        expect(
          rec.confidenceLabel,
          isIn(['Strong match', 'Good alternative', 'Worth considering']),
        );
      }
    });

    test('filters non-renter-safe products in renter mode', () {
      final renterRoom = Room(
        id: 'room-r',
        name: 'Renter Room',
        direction: CompassDirection.north,
        usageTime: UsageTime.allDay,
        moods: [RoomMood.calm],
        budget: BudgetBracket.midRange,
        heroColourHex: '#C9B99A',
        betaColourHex: '#8B7355',
        surpriseColourHex: '#A0522D',
        isRenterMode: true,
        sortOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final products = [
        _product(
          id: 'safe',
          name: 'Safe Lamp',
          hex: '#C9B99A',
          price: 50.0,
          undertone: Undertone.warm,
          category: ProductCategory.floorLamp,
          renterSafe: true,
        ),
        _product(
          id: 'unsafe',
          name: 'Pendant Light',
          hex: '#C9B99A',
          price: 50.0,
          undertone: Undertone.warm,
          category: ProductCategory.pendantLight,
          renterSafe: false,
        ),
      ];

      final scored = scoreProducts(
        candidates: products,
        room: renterRoom,
        lockedFurniture: [],
        archetype: null,
      );

      expect(scored.length, 1);
      expect(scored.first.product.id, 'safe');
    });

    test('rejects products introducing third metal finish', () {
      final furniture = [
        _furniture(id: 'f1', metalFinish: MetalFinish.antiqueBrass),
        _furniture(id: 'f2', metalFinish: MetalFinish.matteBlack),
      ];

      final products = [
        _product(
          id: 'chrome-lamp',
          name: 'Chrome Lamp',
          hex: '#C0C0C0',
          price: 50.0,
          undertone: Undertone.cool,
          category: ProductCategory.tableLamp,
          metalFinish: MetalFinish.chrome,
        ),
        _product(
          id: 'brass-lamp',
          name: 'Brass Lamp',
          hex: '#B8860B',
          price: 50.0,
          undertone: Undertone.warm,
          category: ProductCategory.tableLamp,
          metalFinish: MetalFinish.antiqueBrass,
        ),
      ];

      final scored = scoreProducts(
        candidates: products,
        room: testRoom,
        lockedFurniture: furniture,
        archetype: null,
      );

      // Chrome would be a 3rd metal — should be filtered out
      expect(scored.every((s) => s.product.id != 'chrome-lamp'), isTrue);
      expect(scored.any((s) => s.product.id == 'brass-lamp'), isTrue);
    });

    test('diverseRecommendations creates variety slots', () {
      final scored = scoreProducts(
        candidates: [
          ...candidates,
          _product(
            id: 'p4',
            name: 'Neutral Rug',
            hex: '#D0D0D0',
            price: 60.0,
            undertone: Undertone.neutral,
            category: ProductCategory.rug,
          ),
        ],
        room: testRoom,
        lockedFurniture: [],
        archetype: ColourArchetype.theCocooner,
      );

      final diverse = diverseRecommendations(scored: scored);
      expect(diverse, isNotEmpty);
      expect(diverse.first.$1, RecommendationSlot.recommended);
    });
  });
}

Product _product({
  required String id,
  required String name,
  required String hex,
  required double price,
  required Undertone undertone,
  required ProductCategory category,
  bool renterSafe = true,
  MetalFinish? metalFinish,
}) => Product(
  id: id,
  category: category,
  name: name,
  brand: 'Test Brand',
  retailer: 'Test Retailer',
  priceGbp: price,
  affiliateUrl: 'https://example.com',
  imageUrl: '',
  primaryColourHex: hex,
  undertone: undertone,
  materials: [ProductMaterial.fabricCotton],
  styles: [ProductStyle.modern],
  textureFeel: TextureFeel.lowTexture,
  visualWeight: VisualWeight.medium,
  finishSheen: FinishSheen.matte,
  renterSafe: renterSafe,
  available: true,
  metalFinish: metalFinish,
);

LockedFurniture _furniture({required String id, MetalFinish? metalFinish}) =>
    LockedFurniture(
      id: id,
      roomId: 'room-1',
      name: 'Test Furniture',
      colourHex: '#C9B99A',
      role: FurnitureRole.hero,
      sortOrder: 0,
      metalFinish: metalFinish,
    );
