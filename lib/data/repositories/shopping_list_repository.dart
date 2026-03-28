import 'package:drift/drift.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/shopping_list_item.dart';

/// Repository for the cross-room shopping list.
class ShoppingListRepository {
  ShoppingListRepository(this._db);

  final PaletteDatabase _db;

  /// Watch all shopping list items, ordered by most recent first.
  Stream<List<ShoppingListItem>> watchAll() =>
      (_db.select(_db.shoppingListItems)
        ..orderBy([(t) => OrderingTerm.desc(t.addedAt)])).watch();

  /// Get all shopping list items.
  Future<List<ShoppingListItem>> getAll() =>
      (_db.select(_db.shoppingListItems)
        ..orderBy([(t) => OrderingTerm.desc(t.addedAt)])).get();

  /// Items for a specific room.
  Future<List<ShoppingListItem>> getForRoom(String roomId) =>
      (_db.select(_db.shoppingListItems)
            ..where((t) => t.roomId.equals(roomId))
            ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]))
          .get();

  /// Check if a product is already in the shopping list for a room.
  Future<bool> isInList(String productId, String roomId) async {
    final query = _db.select(_db.shoppingListItems)
      ..where((t) => t.productId.equals(productId) & t.roomId.equals(roomId));
    final results = await query.get();
    return results.isNotEmpty;
  }

  /// Add an item to the shopping list.
  Future<void> addItem(ShoppingListItemsCompanion item) =>
      _db.into(_db.shoppingListItems).insert(item);

  /// Remove an item by id.
  Future<void> removeItem(String id) =>
      (_db.delete(_db.shoppingListItems)..where((t) => t.id.equals(id))).go();

  /// Remove all items for a specific room.
  Future<void> removeAllForRoom(String roomId) =>
      (_db.delete(_db.shoppingListItems)
        ..where((t) => t.roomId.equals(roomId))).go();

  /// Remove all items.
  Future<void> clearAll() => _db.delete(_db.shoppingListItems).go();

  /// Total estimated cost across all items.
  Future<double> totalCost() async {
    final items = await getAll();
    return items.fold<double>(0, (sum, item) => sum + item.priceGbp);
  }

  /// Count of items.
  Future<int> itemCount() async {
    final countExp = _db.shoppingListItems.id.count();
    final query = _db.selectOnly(_db.shoppingListItems)..addColumns([countExp]);
    final row = await query.getSingleOrNull();
    return row?.read(countExp) ?? 0;
  }
}
