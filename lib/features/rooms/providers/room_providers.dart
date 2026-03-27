import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/data/models/locked_furniture.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/providers/database_providers.dart';

/// Stream of all rooms, ordered by sort order.
final allRoomsProvider = StreamProvider<List<Room>>((ref) {
  return ref.watch(roomRepositoryProvider).watchAllRooms();
});

/// Stream of a single room by ID.
final roomByIdProvider =
    FutureProvider.family<Room?, String>((ref, roomId) {
  return ref.watch(roomRepositoryProvider).getRoomById(roomId);
});

/// Stream of furniture items for a room.
final furnitureForRoomProvider =
    FutureProvider.family<List<LockedFurniture>, String>((ref, roomId) {
  return ref.watch(roomRepositoryProvider).getFurnitureForRoom(roomId);
});
