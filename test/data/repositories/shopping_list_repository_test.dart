import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/repositories/shopping_list_repository.dart';

void main() {
  late PaletteDatabase db;
  late ShoppingListRepository repo;

  setUp(() {
    db = PaletteDatabase(NativeDatabase.memory());
    repo = ShoppingListRepository(db);
  });

  tearDown(() => db.close());

  ShoppingListItemsCompanion makeItem({
    required String id,
    String productId = 'prod-1',
    String roomId = 'room-1',
    String roomName = 'Living Room',
    String productName = 'Chunky Jute Rug',
    String brand = 'John Lewis',
    String retailer = 'John Lewis',
    double priceGbp = 199.0,
    String affiliateUrl = 'https://example.com/buy',
    String primaryColourHex = '#C9A96E',
    String categoryName = 'Rug',
    DateTime? addedAt,
  }) {
    return ShoppingListItemsCompanion.insert(
      id: id,
      productId: productId,
      roomId: roomId,
      roomName: roomName,
      productName: productName,
      brand: brand,
      retailer: retailer,
      priceGbp: priceGbp,
      affiliateUrl: affiliateUrl,
      primaryColourHex: primaryColourHex,
      categoryName: categoryName,
      addedAt: addedAt ?? DateTime.now(),
    );
  }

  group('ShoppingListRepository', () {
    test('starts empty', () async {
      final items = await repo.getAll();
      expect(items, isEmpty);
    });

    test('addItem and getAll returns items', () async {
      await repo.addItem(makeItem(id: 'item-1'));
      await repo.addItem(makeItem(id: 'item-2', productId: 'prod-2'));

      final items = await repo.getAll();
      expect(items, hasLength(2));
    });

    test('items are ordered by addedAt descending', () async {
      final earlier = DateTime(2026, 1, 1);
      final later = DateTime(2026, 6, 1);

      await repo.addItem(
        makeItem(id: 'old', productName: 'Old Item', addedAt: earlier),
      );
      await repo.addItem(
        makeItem(
          id: 'new',
          productId: 'prod-2',
          productName: 'New Item',
          addedAt: later,
        ),
      );

      final items = await repo.getAll();
      expect(items.first.productName, 'New Item');
      expect(items.last.productName, 'Old Item');
    });

    test('getForRoom filters by roomId', () async {
      await repo.addItem(makeItem(id: 'a', roomId: 'room-1'));
      await repo.addItem(
        makeItem(id: 'b', productId: 'prod-2', roomId: 'room-2'),
      );

      final room1Items = await repo.getForRoom('room-1');
      expect(room1Items, hasLength(1));
      expect(room1Items.first.roomId, 'room-1');

      final room2Items = await repo.getForRoom('room-2');
      expect(room2Items, hasLength(1));
      expect(room2Items.first.roomId, 'room-2');
    });

    test('isInList returns true only when product+room combo exists', () async {
      await repo.addItem(
        makeItem(id: 'x', productId: 'prod-1', roomId: 'room-1'),
      );

      expect(await repo.isInList('prod-1', 'room-1'), isTrue);
      expect(await repo.isInList('prod-1', 'room-2'), isFalse);
      expect(await repo.isInList('prod-2', 'room-1'), isFalse);
    });

    test('removeItem removes by id', () async {
      await repo.addItem(makeItem(id: 'to-remove'));
      await repo.addItem(makeItem(id: 'to-keep', productId: 'prod-2'));

      await repo.removeItem('to-remove');

      final items = await repo.getAll();
      expect(items, hasLength(1));
      expect(items.first.id, 'to-keep');
    });

    test('removeAllForRoom clears only that room', () async {
      await repo.addItem(makeItem(id: 'a', roomId: 'room-1'));
      await repo.addItem(
        makeItem(id: 'b', productId: 'prod-2', roomId: 'room-1'),
      );
      await repo.addItem(
        makeItem(id: 'c', productId: 'prod-3', roomId: 'room-2'),
      );

      await repo.removeAllForRoom('room-1');

      final items = await repo.getAll();
      expect(items, hasLength(1));
      expect(items.first.roomId, 'room-2');
    });

    test('clearAll empties the list', () async {
      await repo.addItem(makeItem(id: 'a'));
      await repo.addItem(makeItem(id: 'b', productId: 'prod-2'));

      await repo.clearAll();

      final items = await repo.getAll();
      expect(items, isEmpty);
    });

    test('totalCost sums all item prices', () async {
      await repo.addItem(makeItem(id: 'a', priceGbp: 100.0));
      await repo.addItem(
        makeItem(id: 'b', productId: 'prod-2', priceGbp: 250.0),
      );

      final total = await repo.totalCost();
      expect(total, 350.0);
    });

    test('itemCount returns correct count', () async {
      expect(await repo.itemCount(), 0);

      await repo.addItem(makeItem(id: 'a'));
      expect(await repo.itemCount(), 1);

      await repo.addItem(makeItem(id: 'b', productId: 'prod-2'));
      expect(await repo.itemCount(), 2);
    });

    test('watchAll emits updates', () async {
      final stream = repo.watchAll();

      // First emission: empty
      expect(await stream.first, isEmpty);

      // Add an item
      await repo.addItem(makeItem(id: 'w'));

      // Second emission should include the item
      final items = await stream.first;
      expect(items, hasLength(1));
      expect(items.first.id, 'w');
    });
  });
}
