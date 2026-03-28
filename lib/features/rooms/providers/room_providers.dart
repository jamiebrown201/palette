import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/data/models/locked_furniture.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/red_thread/providers/red_thread_providers.dart';
import 'package:palette/features/rooms/logic/room_gap_engine.dart';
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

/// Room gap analysis for a specific room.
///
/// Requires a 70/20/10 plan to be present. Returns an empty report otherwise.
final roomGapReportProvider = FutureProvider.family<RoomGapReport, String>((
  ref,
  roomId,
) async {
  final room = await ref.watch(roomByIdProvider(roomId).future);
  if (room == null) {
    return const RoomGapReport(gaps: [], dataQuality: DataQuality.none);
  }
  final furniture = await ref.watch(furnitureForRoomProvider(roomId).future);
  final threadColours = await ref.watch(threadColoursProvider.future);
  return analyseRoomGaps(
    room: room,
    furniture: furniture,
    threadColours: threadColours,
  );
});
