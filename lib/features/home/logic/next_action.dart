import 'package:palette/core/constants/branded_terms.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/red_thread_colour.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/red_thread/logic/coherence_checker.dart';

// ---------------------------------------------------------------------------
// Next Recommended Action
// ---------------------------------------------------------------------------

enum NextActionType {
  completeRoomSetup,
  defineRedThread,
  resolveCoherence,
  findWhite,
  completeColourPlan,
  lockFurniture,
  allDone,
}

class NextAction {
  const NextAction({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final NextActionType type;
  final String title;
  final String subtitle;
  final String route;
}

/// Compute the single most impactful next action for the user.
///
/// Priority hierarchy:
/// 1. Complete room setup (missing direction, moods, or hero colour)
/// 2. Define Red Thread (3+ rooms, no thread colours)
/// 3. Resolve coherence (rooms not connected to thread)
/// 4. Find the right white (rooms with hero but no white selected)
/// 5. Complete 70/20/10 plan (hero set but beta/surprise missing)
/// 6. Lock furniture (rooms with no locked items)
/// 7. All done
///
/// The [copyVariant] parameter supports the next-action copy A/B test
/// (spec 1E.2). Pass 'task_led' for direct imperative copy, or 'outcome_led'
/// (default/control) for user-outcome-focused language.
NextAction computeNextAction({
  required List<Room> rooms,
  required CoherenceReport? coherenceReport,
  required List<RedThreadColour> threadColours,
  required Map<String, bool> roomHasFurniture,
  String copyVariant = 'outcome_led',
}) {
  final taskLed = copyVariant == 'task_led';
  // Priority 1: rooms missing core setup
  for (final room in rooms) {
    if (room.direction == null ||
        room.moods.isEmpty ||
        room.heroColourHex == null) {
      final missing = <String>[];
      if (room.direction == null) missing.add('direction');
      if (room.moods.isEmpty) missing.add('mood');
      if (room.heroColourHex == null) missing.add('hero colour');
      return NextAction(
        type: NextActionType.completeRoomSetup,
        title:
            taskLed
                ? 'Set ${missing.join(', ')} for ${room.name}'
                : 'Finish setting up ${room.name}',
        subtitle:
            taskLed
                ? '${missing.length} step${missing.length == 1 ? '' : 's'} remaining'
                : 'Missing: ${missing.join(', ')}',
        route: '/rooms/${room.id}',
      );
    }
  }

  // Priority 2: define Red Thread
  if (rooms.length >= 3 && threadColours.isEmpty) {
    return NextAction(
      type: NextActionType.defineRedThread,
      title:
          taskLed
              ? 'Pick 2-4 unifying colours'
              : 'Connect your ${rooms.length} rooms so the house feels cohesive',
      subtitle:
          taskLed
              ? 'Define your ${BrandedTerms.redThread}'
              : BrandedTerms.redThreadSubtitle,
      route: '/red-thread',
    );
  }

  // Priority 3: resolve coherence
  if (coherenceReport != null &&
      threadColours.isNotEmpty &&
      coherenceReport.disconnectedCount > 0) {
    final disconnected = coherenceReport.results.firstWhere(
      (r) => !r.isConnected,
    );
    final count = coherenceReport.disconnectedCount;
    return NextAction(
      type: NextActionType.resolveCoherence,
      title: 'Connect ${disconnected.roomName} to the thread',
      subtitle: '$count room${count == 1 ? '' : 's'} not yet connected',
      route: '/rooms/${disconnected.roomId}',
    );
  }

  // Priority 4: find the right white
  for (final room in rooms) {
    if (room.heroColourHex != null && room.wallColourHex == null) {
      return NextAction(
        type: NextActionType.findWhite,
        title: 'Find the right white for ${room.name}',
        subtitle: 'The right white ties your palette together',
        route: '/explore/white-finder?roomId=${room.id}',
      );
    }
  }

  // Priority 5: complete 70/20/10 plan
  for (final room in rooms) {
    if (room.heroColourHex != null &&
        (room.betaColourHex == null || room.surpriseColourHex == null)) {
      return NextAction(
        type: NextActionType.completeColourPlan,
        title: 'Complete the colour plan for ${room.name}',
        subtitle: 'Add supporting and accent colours',
        route: '/rooms/${room.id}',
      );
    }
  }

  // Priority 6: lock furniture
  for (final room in rooms) {
    if (!(roomHasFurniture[room.id] ?? false)) {
      return NextAction(
        type: NextActionType.lockFurniture,
        title: 'Lock furniture for ${room.name}',
        subtitle: 'Record existing pieces to plan around them',
        route: '/rooms/${room.id}',
      );
    }
  }

  // All done
  return const NextAction(
    type: NextActionType.allDone,
    title: 'Your design plan is complete!',
    subtitle: 'All rooms are set up and connected',
    route: '',
  );
}

// ---------------------------------------------------------------------------
// Room Progress
// ---------------------------------------------------------------------------

class RoomProgress {
  const RoomProgress({
    required this.completed,
    required this.total,
    required this.summary,
  });

  final int completed;
  final int total; // always 7
  final String summary;
}

/// Compute room progress matching the 7-item checklist on room detail.
///
/// "White considered" is always false (informational), so max reachable is 6/7.
RoomProgress computeRoomProgress({
  required Room room,
  required bool hasFurniture,
  required bool isRedThreadConnected,
}) {
  var completed = 0;
  const total = 7;

  if (room.direction != null) completed++;
  if (room.moods.isNotEmpty) completed++;
  if (room.heroColourHex != null) completed++;
  if (room.betaColourHex != null && room.surpriseColourHex != null) {
    completed++;
  }
  // "White considered" is always false (informational)
  if (hasFurniture) completed++;
  if (isRedThreadConnected) completed++;

  final parts = <String>[];
  if (room.direction != null) {
    parts.add('${room.direction!.displayName}-facing');
  }
  parts.add(room.usageTime.displayName);
  if (room.moods.isNotEmpty) parts.add(room.moods.first.displayName);

  return RoomProgress(
    completed: completed,
    total: total,
    summary: parts.join(', '),
  );
}
