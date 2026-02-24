import 'package:drift/drift.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/red_thread_colour.dart';
import 'package:palette/data/models/room_adjacency.dart';

/// Repository for Red Thread whole-house colour coherence.
class RedThreadRepository {
  RedThreadRepository(this._db);

  final PaletteDatabase _db;

  // ---- Thread Colours ----

  Future<List<RedThreadColour>> getThreadColours() =>
      (_db.select(_db.redThreadColours)
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Stream<List<RedThreadColour>> watchThreadColours() =>
      (_db.select(_db.redThreadColours)
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<void> insertThreadColour(RedThreadColoursCompanion colour) =>
      _db.into(_db.redThreadColours).insert(colour);

  Future<void> deleteThreadColour(String id) =>
      (_db.delete(_db.redThreadColours)..where((t) => t.id.equals(id))).go();

  Future<void> clearThreadColours() => _db.delete(_db.redThreadColours).go();

  // ---- Room Adjacencies ----

  Future<List<RoomAdjacency>> getAdjacencies() =>
      _db.select(_db.roomAdjacencies).get();

  Future<void> insertAdjacency(RoomAdjacenciesCompanion adjacency) =>
      _db.into(_db.roomAdjacencies).insert(adjacency);

  Future<void> deleteAdjacency(String id) =>
      (_db.delete(_db.roomAdjacencies)..where((t) => t.id.equals(id))).go();

  Future<void> clearAdjacencies() =>
      _db.delete(_db.roomAdjacencies).go();

  /// Check coherence: does every room share at least one thread colour?
  ///
  /// Returns a list of room IDs that are "disconnected" (don't contain
  /// any of the thread colours within delta-E < 15).
  Future<List<String>> findDisconnectedRooms() async {
    final threadColours = await getThreadColours();
    if (threadColours.isEmpty) return [];

    final rooms = await (_db.select(_db.rooms)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();

    final disconnected = <String>[];

    for (final room in rooms) {
      final roomHexes = [
        if (room.heroColourHex != null) room.heroColourHex!,
        if (room.betaColourHex != null) room.betaColourHex!,
        if (room.surpriseColourHex != null) room.surpriseColourHex!,
      ];

      if (roomHexes.isEmpty) {
        disconnected.add(room.id);
        continue;
      }

      final hasThread = _roomSharesThreadColour(roomHexes, threadColours);
      if (!hasThread) {
        disconnected.add(room.id);
      }
    }

    return disconnected;
  }

  bool _roomSharesThreadColour(
    List<String> roomHexes,
    List<RedThreadColour> threadColours,
  ) {
    const coherenceThreshold = 15.0;

    for (final threadColour in threadColours) {
      final threadLab = hexToLab(threadColour.hex);
      for (final roomHex in roomHexes) {
        final roomLab = hexToLab(roomHex);
        if (deltaE2000(threadLab, roomLab) < coherenceThreshold) {
          return true;
        }
      }
    }
    return false;
  }
}
