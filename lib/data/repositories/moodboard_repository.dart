import 'package:drift/drift.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/moodboard.dart';
import 'package:palette/data/models/moodboard_item.dart';

/// Repository for digital moodboards (Phase 1D.2).
class MoodboardRepository {
  MoodboardRepository(this._db);

  final PaletteDatabase _db;

  // ── Moodboards ────────────────────────────────────────────

  /// Watch all moodboards, ordered by most recent first.
  Stream<List<Moodboard>> watchAll() =>
      (_db.select(_db.moodboards)
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();

  /// Get all moodboards.
  Future<List<Moodboard>> getAll() =>
      (_db.select(_db.moodboards)
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();

  /// Get moodboards for a specific room.
  Stream<List<Moodboard>> watchForRoom(String roomId) =>
      (_db.select(_db.moodboards)
            ..where((t) => t.roomId.equals(roomId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  /// Get a single moodboard by ID.
  Future<Moodboard?> getById(String id) =>
      (_db.select(_db.moodboards)
        ..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Count total moodboards.
  Future<int> count() async {
    final countExp = _db.moodboards.id.count();
    final query = _db.selectOnly(_db.moodboards)..addColumns([countExp]);
    final row = await query.getSingleOrNull();
    return row?.read(countExp) ?? 0;
  }

  /// Create a moodboard.
  Future<void> create(MoodboardsCompanion moodboard) =>
      _db.into(_db.moodboards).insert(moodboard);

  /// Update a moodboard's name or room.
  Future<void> update(String id, MoodboardsCompanion companion) =>
      (_db.update(_db.moodboards)
        ..where((t) => t.id.equals(id))).write(companion);

  /// Delete a moodboard and all its items.
  Future<void> delete(String id) async {
    await (_db.delete(_db.moodboardItems)
      ..where((t) => t.moodboardId.equals(id))).go();
    await (_db.delete(_db.moodboards)..where((t) => t.id.equals(id))).go();
  }

  // ── Items ─────────────────────────────────────────────────

  /// Watch all items for a moodboard, ordered by sort order.
  Stream<List<MoodboardItem>> watchItems(String moodboardId) =>
      (_db.select(_db.moodboardItems)
            ..where((t) => t.moodboardId.equals(moodboardId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  /// Get all items for a moodboard.
  Future<List<MoodboardItem>> getItems(String moodboardId) =>
      (_db.select(_db.moodboardItems)
            ..where((t) => t.moodboardId.equals(moodboardId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  /// Add an item to a moodboard.
  Future<void> addItem(MoodboardItemsCompanion item) =>
      _db.into(_db.moodboardItems).insert(item);

  /// Remove an item by ID.
  Future<void> removeItem(String id) =>
      (_db.delete(_db.moodboardItems)..where((t) => t.id.equals(id))).go();

  /// Update item sort order.
  Future<void> updateItemOrder(String id, int newOrder) =>
      (_db.update(_db.moodboardItems)..where(
        (t) => t.id.equals(id),
      )).write(MoodboardItemsCompanion(sortOrder: Value(newOrder)));

  /// Update item label.
  Future<void> updateItemLabel(String id, String? label) =>
      (_db.update(_db.moodboardItems)..where(
        (t) => t.id.equals(id),
      )).write(MoodboardItemsCompanion(label: Value(label)));
}
