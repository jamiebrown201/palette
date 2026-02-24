import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/data/models/red_thread_colour.dart';
import 'package:palette/data/models/room.dart';

/// Result of a coherence check for a single room.
class RoomCoherenceResult {
  const RoomCoherenceResult({
    required this.roomId,
    required this.roomName,
    required this.isConnected,
    required this.matchingThreadHex,
  });

  final String roomId;
  final String roomName;
  final bool isConnected;

  /// The thread colour hex that connects this room (null if disconnected).
  final String? matchingThreadHex;
}

/// Result of a full coherence check across all rooms.
class CoherenceReport {
  const CoherenceReport({
    required this.results,
    required this.overallCoherent,
  });

  final List<RoomCoherenceResult> results;
  final bool overallCoherent;

  int get connectedCount => results.where((r) => r.isConnected).length;
  int get disconnectedCount => results.where((r) => !r.isConnected).length;
}

/// Check colour coherence across all rooms against thread colours.
///
/// A room is "connected" if at least one of its 70/20/10 colours
/// matches a thread colour within delta-E < [threshold].
CoherenceReport checkCoherence({
  required List<Room> rooms,
  required List<RedThreadColour> threadColours,
  double threshold = 15.0,
}) {
  if (threadColours.isEmpty || rooms.isEmpty) {
    return const CoherenceReport(results: [], overallCoherent: true);
  }

  final results = <RoomCoherenceResult>[];

  for (final room in rooms) {
    final roomHexes = [
      if (room.heroColourHex != null) room.heroColourHex!,
      if (room.betaColourHex != null) room.betaColourHex!,
      if (room.surpriseColourHex != null) room.surpriseColourHex!,
    ];

    if (roomHexes.isEmpty) {
      results.add(RoomCoherenceResult(
        roomId: room.id,
        roomName: room.name,
        isConnected: false,
        matchingThreadHex: null,
      ));
      continue;
    }

    String? matchHex;
    for (final thread in threadColours) {
      final threadLab = hexToLab(thread.hex);
      for (final roomHex in roomHexes) {
        final roomLab = hexToLab(roomHex);
        if (deltaE2000(threadLab, roomLab) < threshold) {
          matchHex = thread.hex;
          break;
        }
      }
      if (matchHex != null) break;
    }

    results.add(RoomCoherenceResult(
      roomId: room.id,
      roomName: room.name,
      isConnected: matchHex != null,
      matchingThreadHex: matchHex,
    ));
  }

  return CoherenceReport(
    results: results,
    overallCoherent: results.every((r) => r.isConnected),
  );
}
