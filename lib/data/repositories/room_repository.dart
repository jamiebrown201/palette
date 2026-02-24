import 'package:drift/drift.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/locked_furniture.dart';
import 'package:palette/data/models/room.dart';

/// Repository for room profiles and their locked furniture.
class RoomRepository {
  RoomRepository(this._db);

  final PaletteDatabase _db;

  // ---- Rooms ----

  Future<List<Room>> getAllRooms() =>
      (_db.select(_db.rooms)
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Stream<List<Room>> watchAllRooms() =>
      (_db.select(_db.rooms)
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<Room?> getRoomById(String id) =>
      (_db.select(_db.rooms)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Stream<Room?> watchRoomById(String id) =>
      (_db.select(_db.rooms)..where((t) => t.id.equals(id)))
          .watchSingleOrNull();

  Future<void> insertRoom(RoomsCompanion room) =>
      _db.into(_db.rooms).insert(room);

  Future<void> updateRoom(RoomsCompanion room) =>
      (_db.update(_db.rooms)..where((t) => t.id.equals(room.id.value)))
          .write(room);

  Future<void> deleteRoom(String id) =>
      (_db.delete(_db.rooms)..where((t) => t.id.equals(id))).go();

  Future<int> roomCount() async {
    final countExp = _db.rooms.id.count();
    final query = _db.selectOnly(_db.rooms)..addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  // ---- Locked Furniture ----

  Future<List<LockedFurniture>> getFurnitureForRoom(String roomId) =>
      (_db.select(_db.lockedFurnitureItems)
            ..where((t) => t.roomId.equals(roomId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Stream<List<LockedFurniture>> watchFurnitureForRoom(String roomId) =>
      (_db.select(_db.lockedFurnitureItems)
            ..where((t) => t.roomId.equals(roomId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<void> insertFurniture(LockedFurnitureItemsCompanion furniture) =>
      _db.into(_db.lockedFurnitureItems).insert(furniture);

  Future<void> deleteFurniture(String id) =>
      (_db.delete(_db.lockedFurnitureItems)..where((t) => t.id.equals(id)))
          .go();

  Future<void> deleteAllFurnitureForRoom(String roomId) =>
      (_db.delete(_db.lockedFurnitureItems)
            ..where((t) => t.roomId.equals(roomId)))
          .go();
}
