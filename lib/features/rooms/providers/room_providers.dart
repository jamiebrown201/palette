import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/data/models/locked_furniture.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/rooms/logic/room_paint_recommendations.dart';
import 'package:palette/providers/database_providers.dart';

/// Stream of all rooms, ordered by sort order.
final allRoomsProvider = StreamProvider<List<Room>>((ref) {
  return ref.watch(roomRepositoryProvider).watchAllRooms();
});

/// Stream of a single room by ID.
final roomByIdProvider = FutureProvider.family<Room?, String>((ref, roomId) {
  return ref.watch(roomRepositoryProvider).getRoomById(roomId);
});

/// Stream of furniture items for a room.
final furnitureForRoomProvider =
    FutureProvider.family<List<LockedFurniture>, String>((ref, roomId) {
      return ref.watch(roomRepositoryProvider).getFurnitureForRoom(roomId);
    });

/// Paint recommendations for a specific room, based on hero colour,
/// direction, and budget bracket.
final roomPaintRecommendationsProvider =
    FutureProvider.family<List<RoomPaintRecommendation>, Room>((
      ref,
      room,
    ) async {
      if (room.heroColourHex == null) return [];
      final paintRepo = ref.watch(paintColourRepositoryProvider);
      final allPaints = await paintRepo.getAll();
      return computeRoomPaintRecommendations(allPaints: allPaints, room: room);
    });
