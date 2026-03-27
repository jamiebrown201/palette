import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/undertone.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/features/rooms/logic/colour_plan_harmony.dart';
import 'package:palette/features/rooms/logic/light_recommendations.dart';

/// A contextual 2-3 sentence explanation of why a room's colour choices work.
class RoomStory {
  const RoomStory({required this.summary, required this.isComplete});

  /// Human-readable 2-3 sentence story.
  final String summary;

  /// True when enough data exists for a meaningful story (hero + direction).
  final bool isComplete;
}

/// Generate a contextual story explaining why a room's colours work together.
///
/// Builds up to 3 sentences:
/// 1. Light + undertone alignment (requires direction + heroHex)
/// 2. Colour relationship (requires heroHex + at least one of beta/surprise)
/// 3. Mood / renter tie-in (requires moods or renter mode)
///
/// Falls back gracefully when data is missing.
RoomStory generateRoomStory({
  required String roomName,
  CompassDirection? direction,
  required UsageTime usageTime,
  required List<RoomMood> moods,
  String? heroHex,
  String? betaHex,
  String? surpriseHex,
  required bool isRenterMode,
  String? heroName,
  String renterMoodTemplate = '',
}) {
  if (heroHex == null) {
    return const RoomStory(summary: '', isComplete: false);
  }

  final sentences = <String>[];

  // Sentence 1: Light + undertone alignment
  if (direction != null) {
    sentences.add(
      _lightSentence(
        roomName: roomName,
        direction: direction,
        usageTime: usageTime,
        heroHex: heroHex,
        heroName: heroName,
      ),
    );
  }

  // Sentence 2: Colour relationship
  if (betaHex != null || surpriseHex != null) {
    final relationship = _relationshipSentence(
      heroHex: heroHex,
      betaHex: betaHex,
      surpriseHex: surpriseHex,
    );
    if (relationship != null) sentences.add(relationship);
  }

  // Sentence 3: Mood / renter tie-in
  final moodSentence = _moodSentence(
    moods: moods,
    isRenterMode: isRenterMode,
    renterMoodTemplate: renterMoodTemplate,
  );
  if (moodSentence != null) sentences.add(moodSentence);

  return RoomStory(summary: sentences.join(' '), isComplete: direction != null);
}

// ---------------------------------------------------------------------------
// Sentence builders
// ---------------------------------------------------------------------------

String _lightSentence({
  required String roomName,
  required CompassDirection direction,
  required UsageTime usageTime,
  required String heroHex,
  String? heroName,
}) {
  final lab = hexToLab(heroHex);
  final undertone = classifyUndertone(lab);
  final light = getLightRecommendation(
    direction: direction,
    usageTime: usageTime,
  );

  final colourLabel = heroName ?? 'your hero colour';
  final dirLabel = direction.displayName.toLowerCase();
  final undertoneLabel = undertone.classification.displayName.toLowerCase();

  final aligned =
      undertone.classification == light.preferredUndertone ||
      light.preferredUndertone == Undertone.neutral;

  if (aligned) {
    return 'Your $dirLabel-facing ${roomName.toLowerCase()} gets '
        '${light.summary.toLowerCase()} \u2014 '
        '$colourLabel\u2019s $undertoneLabel undertone will '
        'glow beautifully in this light.';
  } else {
    return 'Your $dirLabel-facing ${roomName.toLowerCase()} gets '
        '${light.summary.toLowerCase()} \u2014 '
        '$colourLabel\u2019s $undertoneLabel undertone will '
        'counterbalance nicely, creating a cosy feel.';
  }
}

String? _relationshipSentence({
  required String heroHex,
  String? betaHex,
  String? surpriseHex,
}) {
  final harmony = analyseColourPlanHarmony(
    heroHex: heroHex,
    betaHex: betaHex,
    surpriseHex: surpriseHex,
  );

  if (harmony.relationships.isEmpty && !harmony.hasWarning) {
    return 'Your colours create a bold, eclectic combination '
        'that makes a statement.';
  }

  if (harmony.hasWarning) {
    return null; // Don't repeat warnings — they're shown elsewhere
  }

  final verdict = harmony.verdict.toLowerCase();
  return switch (harmony.relationships.first.type) {
    ColourRelationship.complementary =>
      'The complementary contrast between your colours '
          'brings energy and visual interest to the space.',
    ColourRelationship.analogous =>
      'The $verdict between your colours creates '
          'a calm, cohesive feel that flows naturally.',
    ColourRelationship.triadic =>
      'The triadic balance across your colours gives '
          'the room vibrant but controlled energy.',
    ColourRelationship.splitComplementary =>
      'The split-complementary scheme offers softer contrast '
          'than a direct complement \u2014 dynamic but approachable.',
  };
}

String? _moodSentence({
  required List<RoomMood> moods,
  required bool isRenterMode,
  String renterMoodTemplate = '',
}) {
  if (isRenterMode && renterMoodTemplate.isNotEmpty) {
    return 'These choices work \u2014 $renterMoodTemplate.';
  }
  if (isRenterMode) {
    return 'These choices focus on furniture and accessories \u2014 '
        'perfect for renting.';
  }

  if (moods.isEmpty) return null;

  final labels = moods.map((m) => m.displayName.toLowerCase()).toList();
  final joined =
      labels.length == 1
          ? labels.first
          : '${labels.sublist(0, labels.length - 1).join(', ')} '
              'and ${labels.last}';

  return 'This palette matches your $joined vision for this room.';
}
