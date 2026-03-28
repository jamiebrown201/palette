import 'package:drift/drift.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/sample_list_item.dart';

/// Repository for the paint sample ordering list.
class SampleListRepository {
  SampleListRepository(this._db);

  final PaletteDatabase _db;

  /// Watch all sample list items, ordered by most recent first.
  Stream<List<SampleListItem>> watchAll() =>
      (_db.select(_db.sampleListItems)
        ..orderBy([(t) => OrderingTerm.desc(t.addedAt)])).watch();

  /// Get all sample list items.
  Future<List<SampleListItem>> getAll() =>
      (_db.select(_db.sampleListItems)
        ..orderBy([(t) => OrderingTerm.desc(t.addedAt)])).get();

  /// Check if a paint colour is already in the sample list.
  Future<bool> isInList(String paintColourId) async {
    final query = _db.select(_db.sampleListItems)
      ..where((t) => t.paintColourId.equals(paintColourId));
    final results = await query.get();
    return results.isNotEmpty;
  }

  /// Add a sample to the list.
  Future<void> addSample(SampleListItemsCompanion item) =>
      _db.into(_db.sampleListItems).insert(item);

  /// Remove a sample by id.
  Future<void> removeSample(String id) =>
      (_db.delete(_db.sampleListItems)..where((t) => t.id.equals(id))).go();

  /// Mark a sample as ordered.
  Future<void> markOrdered(String id) => (_db.update(_db.sampleListItems)
    ..where(
      (t) => t.id.equals(id),
    )).write(SampleListItemsCompanion(orderedAt: Value(DateTime.now())));

  /// Mark all unordered samples as ordered.
  Future<void> markAllOrdered() => (_db.update(_db.sampleListItems)..where(
    (t) => t.orderedAt.isNull(),
  )).write(SampleListItemsCompanion(orderedAt: Value(DateTime.now())));

  /// Mark a sample as arrived.
  Future<void> markArrived(String id) => (_db.update(_db.sampleListItems)
    ..where(
      (t) => t.id.equals(id),
    )).write(SampleListItemsCompanion(arrivedAt: Value(DateTime.now())));

  /// Mark all ordered samples as arrived.
  Future<void> markAllArrived() => (_db.update(_db.sampleListItems)..where(
    (t) => t.orderedAt.isNotNull() & t.arrivedAt.isNull(),
  )).write(SampleListItemsCompanion(arrivedAt: Value(DateTime.now())));

  /// Remove all samples.
  Future<void> clearAll() => _db.delete(_db.sampleListItems).go();

  /// Count of samples.
  Future<int> itemCount() async {
    final countExp = _db.sampleListItems.id.count();
    final query = _db.selectOnly(_db.sampleListItems)..addColumns([countExp]);
    final row = await query.getSingleOrNull();
    return row?.read(countExp) ?? 0;
  }

  /// Samples that have been ordered but not yet arrived.
  Future<List<SampleListItem>> getAwaitingArrival() =>
      (_db.select(_db.sampleListItems)
            ..where((t) => t.orderedAt.isNotNull() & t.arrivedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.orderedAt)]))
          .get();
}
