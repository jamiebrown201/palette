import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/data/models/red_thread_colour.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/red_thread/logic/coherence_checker.dart';
import 'package:palette/features/red_thread/logic/floor_plan_template.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';
import 'package:palette/providers/database_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'red_thread_providers.g.dart';

/// Stream of all red thread colours.
@riverpod
Stream<List<RedThreadColour>> threadColours(Ref ref) {
  return ref.watch(redThreadRepositoryProvider).watchThreadColours();
}

/// Floor plan templates loaded from asset.
@Riverpod(keepAlive: true)
Future<List<FloorPlanTemplate>> floorPlanTemplates(Ref ref) {
  return loadFloorPlanTemplates();
}

/// Coherence report for current rooms vs thread colours.
@riverpod
Future<CoherenceReport> coherenceReport(Ref ref) async {
  final rooms = await ref.watch(allRoomsProvider.future);
  final threadRepo = ref.watch(redThreadRepositoryProvider);
  final threads = await threadRepo.getThreadColours();

  return checkCoherence(
    rooms: rooms,
    threadColours: threads,
  );
}

/// Thread colour hex strings for convenience.
@riverpod
Future<List<String>> threadHexes(Ref ref) async {
  final threadRepo = ref.watch(redThreadRepositoryProvider);
  final threads = await threadRepo.getThreadColours();
  return threads.map((t) => t.hex).toList();
}

/// Room pairs that are adjacent (for side-by-side comparison).
@riverpod
Future<List<(Room, Room)>> adjacentRoomPairs(Ref ref) async {
  final rooms = await ref.watch(allRoomsProvider.future);
  final adjRepo = ref.watch(redThreadRepositoryProvider);
  final adjacencies = await adjRepo.getAdjacencies();

  final roomMap = {for (final r in rooms) r.id: r};
  final pairs = <(Room, Room)>[];

  for (final adj in adjacencies) {
    final a = roomMap[adj.roomIdA];
    final b = roomMap[adj.roomIdB];
    if (a != null && b != null) {
      pairs.add((a, b));
    }
  }

  return pairs;
}
