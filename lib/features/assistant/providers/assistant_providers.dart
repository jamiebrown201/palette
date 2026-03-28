import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/features/assistant/logic/assistant_engine.dart';
import 'package:palette/features/palette/providers/palette_providers.dart';
import 'package:palette/features/red_thread/providers/red_thread_providers.dart';
import 'package:palette/features/rooms/logic/room_gap_engine.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';
import 'package:palette/providers/database_providers.dart';

/// Builds the [AssistantContext] from all relevant user data.
final assistantContextProvider = FutureProvider<AssistantContext>((ref) async {
  final dna = await ref.watch(latestColourDnaProvider.future);
  final rooms = await ref.watch(allRoomsProvider.future);
  final paintRepo = ref.watch(paintColourRepositoryProvider);
  final allPaints = await paintRepo.getAll();

  // Thread colours
  final threadRepo = ref.watch(redThreadRepositoryProvider);
  final threads = await threadRepo.getThreadColours();
  final threadHexes = threads.map((t) => t.hex).toList();

  // Coherence report
  final coherence =
      threads.isNotEmpty
          ? await ref.watch(coherenceReportProvider.future)
          : null;

  // Build furniture map
  final roomRepo = ref.watch(roomRepositoryProvider);
  final furnitureByRoom = <String, List<dynamic>>{};
  for (final room in rooms) {
    furnitureByRoom[room.id] = await roomRepo.getFurnitureForRoom(room.id);
  }

  // Build gap reports
  final gapsByRoom = <String, RoomGapReport>{};
  for (final room in rooms) {
    if (room.heroColourHex != null) {
      final furniture = await roomRepo.getFurnitureForRoom(room.id);
      gapsByRoom[room.id] = analyseRoomGaps(
        room: room,
        furniture: furniture,
        threadColours: threads,
      );
    }
  }

  return AssistantContext(
    dna: dna,
    rooms: rooms,
    threadHexes: threadHexes,
    furnitureByRoom: {
      for (final e in furnitureByRoom.entries) e.key: e.value.cast(),
    },
    allPaints: allPaints,
    coherence: coherence,
    gapsByRoom: gapsByRoom,
  );
});

/// The conversation message history.
final assistantMessagesProvider =
    StateNotifierProvider<AssistantMessagesNotifier, List<AssistantMessage>>(
      (ref) => AssistantMessagesNotifier(),
    );

class AssistantMessagesNotifier extends StateNotifier<List<AssistantMessage>> {
  AssistantMessagesNotifier() : super(const []);

  void addMessage(AssistantMessage message) {
    state = [...state, message];
  }

  void clear() {
    state = const [];
  }
}
