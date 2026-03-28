import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/product.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/data/models/room_adjacency.dart';
import 'package:palette/features/rooms/logic/whole_home_bundles.dart';

Room _room({
  String id = 'r1',
  String name = 'Living Room',
  String? heroColourHex = '#C9B99A',
  String? betaColourHex = '#8B7355',
  String? surpriseColourHex = '#A0522D',
  CompassDirection? direction = CompassDirection.south,
  BudgetBracket budget = BudgetBracket.midRange,
  bool isRenterMode = false,
}) {
  return Room(
    id: id,
    name: name,
    usageTime: UsageTime.evening,
    moods: [RoomMood.cocooning],
    budget: budget,
    isRenterMode: isRenterMode,
    sortOrder: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    direction: direction,
    heroColourHex: heroColourHex,
    betaColourHex: betaColourHex,
    surpriseColourHex: surpriseColourHex,
  );
}

Product _product({
  required String id,
  required String name,
  required String hex,
  double price = 120.0,
  Undertone undertone = Undertone.warm,
  ProductCategory category = ProductCategory.rug,
  bool available = true,
  bool renterSafe = true,
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
  available: available,
);

void main() {
  group('generateWholeHomeBundles', () {
    final roomA = _room(
      id: 'r1',
      name: 'Living Room',
      direction: CompassDirection.south,
    );
    final roomB = _room(
      id: 'r2',
      name: 'Hallway',
      direction: CompassDirection.north,
    );

    const adjacency = RoomAdjacency(id: 'adj1', roomIdA: 'r1', roomIdB: 'r2');

    // Thread colour close to both rooms' hero (#C9B99A)
    const threadHex = '#C4A882';

    final catalogue = [
      _product(
        id: 'p1',
        name: 'Warm Rug',
        hex: '#C4A882',
        category: ProductCategory.rug,
      ),
      _product(
        id: 'p2',
        name: 'Warm Throw',
        hex: '#C9B99A',
        category: ProductCategory.throwBlanket,
      ),
      _product(
        id: 'p3',
        name: 'Cool Lamp',
        hex: '#2E4057',
        category: ProductCategory.floorLamp,
      ),
    ];

    test('returns empty when no thread colours', () {
      final bundles = generateWholeHomeBundles(
        rooms: [roomA, roomB],
        adjacencies: [adjacency],
        threadHexes: [],
        catalogue: catalogue,
        furnitureByRoom: {},
      );
      expect(bundles, isEmpty);
    });

    test('returns empty when no adjacencies', () {
      final bundles = generateWholeHomeBundles(
        rooms: [roomA, roomB],
        adjacencies: [],
        threadHexes: [threadHex],
        catalogue: catalogue,
        furnitureByRoom: {},
      );
      expect(bundles, isEmpty);
    });

    test('returns empty with fewer than 2 rooms', () {
      final bundles = generateWholeHomeBundles(
        rooms: [roomA],
        adjacencies: [adjacency],
        threadHexes: [threadHex],
        catalogue: catalogue,
        furnitureByRoom: {},
      );
      expect(bundles, isEmpty);
    });

    test('generates bundle for adjacent rooms with shared thread', () {
      final bundles = generateWholeHomeBundles(
        rooms: [roomA, roomB],
        adjacencies: [adjacency],
        threadHexes: [threadHex],
        catalogue: catalogue,
        furnitureByRoom: {},
      );

      expect(bundles, isNotEmpty);
      final bundle = bundles.first;
      expect(bundle.roomA.id, 'r1');
      expect(bundle.roomB.id, 'r2');
      expect(bundle.headline, contains('Living Room'));
      expect(bundle.headline, contains('Hallway'));
      expect(bundle.recommendations, isNotEmpty);
    });

    test('bundle recommendations reference room names', () {
      final bundles = generateWholeHomeBundles(
        rooms: [roomA, roomB],
        adjacencies: [adjacency],
        threadHexes: [threadHex],
        catalogue: catalogue,
        furnitureByRoom: {},
      );

      expect(bundles, isNotEmpty);
      for (final rec in bundles.first.recommendations) {
        expect(rec.reason, isNotEmpty);
        expect(rec.product, isNotNull);
        expect(rec.room.id == 'r1' || rec.room.id == 'r2', isTrue);
      }
    });

    test('skips rooms without hero colours', () {
      final emptyRoom = _room(
        id: 'r3',
        name: 'Empty Room',
        heroColourHex: null,
        betaColourHex: null,
        surpriseColourHex: null,
      );

      final bundles = generateWholeHomeBundles(
        rooms: [emptyRoom, roomB],
        adjacencies: [const RoomAdjacency(id: 'adj2', roomIdA: 'r3', roomIdB: 'r2')],
        threadHexes: [threadHex],
        catalogue: catalogue,
        furnitureByRoom: {},
      );

      // May still produce a bundle if roomB has hero and catalogue matches
      // But the empty room won't contribute recommendations
      if (bundles.isNotEmpty) {
        for (final rec in bundles.first.recommendations) {
          expect(rec.room.id, 'r2');
        }
      }
    });

    test('returns empty when no catalogue products match thread', () {
      // All products are cool-coloured, far from thread
      final coolCatalogue = [
        _product(
          id: 'c1',
          name: 'Navy Cushion',
          hex: '#1A1A3E',
          undertone: Undertone.cool,
        ),
      ];

      final bundles = generateWholeHomeBundles(
        rooms: [roomA, roomB],
        adjacencies: [adjacency],
        threadHexes: [threadHex],
        catalogue: coolCatalogue,
        furnitureByRoom: {},
      );

      expect(bundles, isEmpty);
    });

    test('bundle description mentions directions when available', () {
      final bundles = generateWholeHomeBundles(
        rooms: [roomA, roomB],
        adjacencies: [adjacency],
        threadHexes: [threadHex],
        catalogue: catalogue,
        furnitureByRoom: {},
      );

      expect(bundles, isNotEmpty);
      expect(bundles.first.description, contains('facing'));
    });
  });
}
