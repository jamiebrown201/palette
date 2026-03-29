import 'package:drift/drift.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/diary_entry.dart';

/// Repository for Design Diary CRUD operations.
class DiaryRepository {
  const DiaryRepository(this._db);

  final PaletteDatabase _db;

  /// Watch all diary entries, newest first.
  Stream<List<DiaryEntry>> watchAll() {
    final query = _db.select(_db.diaryEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch();
  }

  /// Watch diary entries for a specific room.
  Stream<List<DiaryEntry>> watchForRoom(String roomId) {
    final query =
        _db.select(_db.diaryEntries)
          ..where((t) => t.roomId.equals(roomId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return query.watch();
  }

  /// Get all entries for a room (one-shot).
  Future<List<DiaryEntry>> getForRoom(String roomId) {
    final query =
        _db.select(_db.diaryEntries)
          ..where((t) => t.roomId.equals(roomId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return query.get();
  }

  /// Get all entries (one-shot), newest first.
  Future<List<DiaryEntry>> getAll() {
    final query = _db.select(_db.diaryEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.get();
  }

  /// Insert a new diary entry.
  Future<void> insert(DiaryEntry entry) {
    return _db
        .into(_db.diaryEntries)
        .insert(
          DiaryEntriesCompanion.insert(
            id: entry.id,
            roomId: entry.roomId,
            roomName: entry.roomName,
            photoPath: entry.photoPath,
            phase: entry.phase,
            caption: Value(entry.caption),
            heroColourHex: Value(entry.heroColourHex),
            createdAt: entry.createdAt,
          ),
        );
  }

  /// Update a diary entry's caption.
  Future<void> updateCaption(String id, String? caption) {
    return (_db.update(_db.diaryEntries)..where(
      (t) => t.id.equals(id),
    )).write(DiaryEntriesCompanion(caption: Value(caption)));
  }

  /// Delete a diary entry by ID.
  Future<void> delete(String id) {
    return (_db.delete(_db.diaryEntries)..where((t) => t.id.equals(id))).go();
  }

  /// Count entries for a room.
  Future<int> countForRoom(String roomId) async {
    final entries = await getForRoom(roomId);
    return entries.length;
  }
}
