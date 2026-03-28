import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/colour_dna_result.dart';
import 'package:palette/data/models/locked_furniture.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/red_thread/logic/coherence_checker.dart';
import 'package:palette/features/rooms/logic/light_recommendations.dart';
import 'package:palette/features/rooms/logic/room_gap_engine.dart';
import 'package:palette/features/rooms/logic/room_paint_recommendations.dart';

/// A message in the assistant conversation.
class AssistantMessage {
  const AssistantMessage({
    required this.text,
    required this.isUser,
    this.roomId,
    this.colourSwatches = const [],
    this.suggestedFollowUps = const [],
  });

  final String text;
  final bool isUser;
  final String? roomId;

  /// Hex colours to display as swatches alongside the message.
  final List<String> colourSwatches;

  /// Suggested follow-up prompts the user can tap.
  final List<String> suggestedFollowUps;
}

/// Context data the engine uses to generate responses.
class AssistantContext {
  const AssistantContext({
    this.dna,
    this.rooms = const [],
    this.threadHexes = const [],
    this.furnitureByRoom = const {},
    this.allPaints = const [],
    this.coherence,
    this.gapsByRoom = const {},
  });

  final ColourDnaResult? dna;
  final List<Room> rooms;
  final List<String> threadHexes;
  final Map<String, List<LockedFurniture>> furnitureByRoom;
  final List<PaintColour> allPaints;
  final CoherenceReport? coherence;
  final Map<String, RoomGapReport> gapsByRoom;
}

/// The intent parsed from the user's question.
enum AssistantIntent {
  roomColour,
  roomWhite,
  lightDirection,
  redThread,
  roomGap,
  material,
  designIdentity,
  generalDesign,
  greeting,
  unknown,
}

/// Rule-based engine that generates design advice from user data.
///
/// Parses user questions into intents, then builds personalised responses
/// using Colour DNA, room profiles, Red Thread, and the Design Rules Engine.
class AssistantEngine {
  const AssistantEngine(this.context);

  final AssistantContext context;

  /// Generate a response to a user's question.
  AssistantMessage respond(String question) {
    final lower = question.toLowerCase().trim();
    final intent = _parseIntent(lower);
    final room = _matchRoom(lower);

    return switch (intent) {
      AssistantIntent.roomColour => _respondRoomColour(room),
      AssistantIntent.roomWhite => _respondWhiteAdvice(room),
      AssistantIntent.lightDirection => _respondLightDirection(room),
      AssistantIntent.redThread => _respondRedThread(),
      AssistantIntent.roomGap => _respondRoomGap(room),
      AssistantIntent.material => _respondMaterial(),
      AssistantIntent.designIdentity => _respondDesignIdentity(),
      AssistantIntent.generalDesign => _respondGeneralDesign(lower),
      AssistantIntent.greeting => _respondGreeting(),
      AssistantIntent.unknown => _respondUnknown(),
    };
  }

  /// Generate contextual starter suggestions based on user's data.
  List<String> starterSuggestions() {
    final suggestions = <String>[];

    if (context.rooms.isNotEmpty) {
      final first = context.rooms.first;
      suggestions.add('What colour should I paint my ${first.name}?');
    }

    if (context.rooms.any((r) => r.direction != null)) {
      final directed = context.rooms.firstWhere((r) => r.direction != null);
      suggestions.add('How does light affect my ${directed.name}?');
    }

    if (context.rooms.length >= 2) {
      suggestions.add('How do my rooms connect?');
    }

    if (context.dna?.archetype != null) {
      suggestions.add('What materials suit my style?');
    }

    if (suggestions.isEmpty) {
      suggestions.addAll([
        'What is the 70/20/10 rule?',
        'How do I choose the right white?',
        'What is a Red Thread?',
      ]);
    }

    return suggestions.take(3).toList();
  }

  // ── Intent parsing ─────────────────────────────────────────

  AssistantIntent _parseIntent(String q) {
    if (_isGreeting(q)) return AssistantIntent.greeting;

    if (_matches(q, [
      'what colour',
      'which colour',
      'paint my',
      'color for',
      'colour for',
      'what should i paint',
      'suggest a colour',
      'best colour',
      'recommend a colour',
    ])) {
      return AssistantIntent.roomColour;
    }

    if (_matches(q, ['white', 'which white', 'trim', 'ceiling colour'])) {
      return AssistantIntent.roomWhite;
    }

    if (_matches(q, [
      'light',
      'sunlight',
      'north-facing',
      'south-facing',
      'east-facing',
      'west-facing',
      'direction',
      'morning light',
      'evening light',
      'natural light',
    ])) {
      return AssistantIntent.lightDirection;
    }

    if (_matches(q, [
      'red thread',
      'connect',
      'whole home',
      'flow',
      'coherence',
      'rooms together',
      'cohesive',
    ])) {
      return AssistantIntent.redThread;
    }

    if (_matches(q, [
      'need',
      'missing',
      'gap',
      'what does my room need',
      'what else',
      'complete',
      'finish',
    ])) {
      return AssistantIntent.roomGap;
    }

    if (_matches(q, [
      'material',
      'wood',
      'metal',
      'fabric',
      'texture',
      'rug',
      'cushion',
      'throw',
      'lamp',
      'furniture',
      'curtain',
    ])) {
      return AssistantIntent.material;
    }

    if (_matches(q, [
      'my style',
      'my identity',
      'design identity',
      'archetype',
      'dna',
      'personality',
      'suit me',
      'suits me',
      'identity',
    ])) {
      return AssistantIntent.designIdentity;
    }

    if (_matches(q, [
      '70/20/10',
      '70 20 10',
      'rule',
      'undertone',
      'how do i',
      'what is',
      'explain',
      'help',
    ])) {
      return AssistantIntent.generalDesign;
    }

    return AssistantIntent.unknown;
  }

  bool _isGreeting(String q) {
    final greetings = [
      'hi',
      'hello',
      'hey',
      'good morning',
      'good afternoon',
      'good evening',
      'howdy',
    ];
    return greetings.any((g) => q == g || q.startsWith('$g '));
  }

  bool _matches(String q, List<String> keywords) {
    return keywords.any((k) => q.contains(k));
  }

  // ── Room matching ──────────────────────────────────────────

  Room? _matchRoom(String q) {
    for (final room in context.rooms) {
      if (q.contains(room.name.toLowerCase())) return room;
    }
    // Common room name aliases
    final aliases = <String, List<String>>{
      'living': ['living', 'lounge', 'sitting'],
      'bedroom': ['bedroom', 'master'],
      'kitchen': ['kitchen'],
      'bathroom': ['bathroom', 'loo', 'toilet', 'ensuite', 'en-suite'],
      'hallway': ['hallway', 'hall', 'entrance', 'corridor'],
      'dining': ['dining'],
      'office': ['office', 'study'],
      'nursery': ['nursery', 'kids', 'children'],
    };

    for (final room in context.rooms) {
      final roomLower = room.name.toLowerCase();
      for (final entry in aliases.entries) {
        if (roomLower.contains(entry.key)) {
          if (entry.value.any((alias) => q.contains(alias))) return room;
        }
      }
    }
    return context.rooms.isNotEmpty ? context.rooms.first : null;
  }

  // ── Response generators ────────────────────────────────────

  AssistantMessage _respondRoomColour(Room? room) {
    if (room == null) {
      return const AssistantMessage(
        text:
            'Create a room first so I can give you personalised '
            'colour advice based on your light direction and mood.',
        isUser: false,
        suggestedFollowUps: ['What is the 70/20/10 rule?'],
      );
    }

    final buf = StringBuffer();
    final swatches = <String>[];
    final followUps = <String>[];

    // Hero colour advice
    if (room.heroColourHex != null) {
      final paints = computeRoomPaintRecommendations(
        allPaints: context.allPaints,
        room: room,
        limit: 3,
      );

      buf.writeln(
        'Your ${room.name} already has a hero colour set. '
        'Here are my top paint matches:',
      );
      buf.writeln();

      for (final rec in paints) {
        buf.writeln(
          '${rec.paint.brand} ${rec.paint.name} \u2014 '
          '${rec.reason}',
        );
        swatches.add(rec.paint.hex);
      }

      if (paints.isEmpty) {
        buf.writeln(
          'I couldn\'t find close paint matches in your budget '
          'bracket. Try adjusting the budget for more options.',
        );
      }

      followUps.add('Which white works for my ${room.name}?');
      followUps.add('What does my ${room.name} still need?');
    } else {
      // Suggest colours based on direction + mood + archetype
      buf.write('For your ${room.name}');
      if (room.direction != null) {
        buf.write(' (${room.direction!.displayName}-facing');
        buf.write(', ${room.usageTime.displayName.toLowerCase()} use)');
      }
      buf.writeln(':');
      buf.writeln();

      if (room.direction != null) {
        final lightRec = getLightRecommendation(
          direction: room.direction!,
          usageTime: room.usageTime,
        );
        buf.writeln(lightRec.recommendation);
        buf.writeln();

        if (lightRec.preferredUndertone == Undertone.warm) {
          buf.writeln(
            'I\'d recommend warm undertones here \u2014 think '
            'earthy creams, soft golds, or muted terracotta.',
          );
        } else if (lightRec.preferredUndertone == Undertone.cool) {
          buf.writeln(
            'Cool undertones will sing in this light \u2014 '
            'sage greens, soft blues, or cool greys.',
          );
        }
      }

      // Archetype-driven suggestion
      if (context.dna?.archetype != null) {
        buf.writeln();
        buf.writeln(
          'As ${context.dna!.archetype!.displayName}, '
          'your palette leans towards '
          '${context.dna!.primaryFamily.description.toLowerCase()}. '
          'Trust that instinct here.',
        );

        // Show palette colours as swatches
        swatches.addAll(context.dna!.colourHexes.take(4));
      }

      if (room.moods.isNotEmpty) {
        final moodNames = room.moods
            .map((m) => m.displayName.toLowerCase())
            .join(' and ');
        buf.writeln();
        buf.writeln(
          'You\'ve set a $moodNames mood for this room. '
          '${_moodGuidance(room.moods.first)}',
        );
      }

      followUps.add('How does light affect my ${room.name}?');
      followUps.add('What materials suit my style?');
    }

    return AssistantMessage(
      text: buf.toString().trimRight(),
      isUser: false,
      roomId: room.id,
      colourSwatches: swatches,
      suggestedFollowUps: followUps,
    );
  }

  AssistantMessage _respondWhiteAdvice(Room? room) {
    final buf = StringBuffer();
    final followUps = <String>[];

    if (room == null) {
      return const AssistantMessage(
        text:
            'Every white has an undertone \u2014 blue, pink, yellow, or grey '
            '\u2014 and the wrong white can undermine your entire colour scheme. '
            'Create a room so I can recommend the right white for your light.',
        isUser: false,
        suggestedFollowUps: ['What is the 70/20/10 rule?'],
      );
    }

    buf.writeln('Choosing the right white for your ${room.name}:');
    buf.writeln();

    if (room.direction != null) {
      final dir = room.direction!;
      switch (dir) {
        case CompassDirection.north:
          buf.writeln(
            'North-facing rooms get cool, bluish light. '
            'Avoid cool whites (blue or grey undertone) \u2014 they\'ll '
            'make the room feel cold. Choose warm whites with a yellow '
            'or pink undertone.',
          );
          buf.writeln();
          buf.writeln(
            'Try: Farrow & Ball Pointing, Dulux Jasmine White, '
            'or Little Greene Slaked Lime.',
          );
        case CompassDirection.south:
          buf.writeln(
            'South-facing rooms are flooded with warm light. '
            'You can use almost any white here. Cool whites (grey or blue '
            'undertone) will feel clean and crisp. Warm whites will feel '
            'extra cosy.',
          );
          buf.writeln();
          buf.writeln(
            'Try: Farrow & Ball Strong White, Dulux White Mist, '
            'or Little Greene Loft White.',
          );
        case CompassDirection.east:
          buf.writeln(
            'East-facing rooms get strong morning light that fades '
            'by afternoon. A warm white balances the cooler afternoon light '
            'while still looking fresh in the morning.',
          );
          buf.writeln();
          buf.writeln(
            'Try: Farrow & Ball White Tie, Dulux Natural Calico, '
            'or Little Greene Flint.',
          );
        case CompassDirection.west:
          buf.writeln(
            'West-facing rooms are darker in the morning but glow '
            'golden in the evening. A neutral white works beautifully, '
            'avoiding anything too yellow which would look orange at sunset.',
          );
          buf.writeln();
          buf.writeln(
            'Try: Farrow & Ball Wimborne White, Dulux Timeless, '
            'or Little Greene Shirting.',
          );
      }
    } else {
      buf.writeln(
        'Set your room\'s compass direction so I can recommend '
        'the right white. The direction your window faces changes how '
        'every white looks throughout the day.',
      );
    }

    buf.writeln();
    buf.writeln(
      'Pro tip: Use Sowerby\'s Paper Test \u2014 hold a sheet of '
      'plain printer paper against your wall sample. The contrast reveals '
      'the undertone instantly.',
    );

    followUps.add('What colour should I paint my ${room.name}?');
    followUps.add('How does light affect my ${room.name}?');

    return AssistantMessage(
      text: buf.toString().trimRight(),
      isUser: false,
      roomId: room.id,
      suggestedFollowUps: followUps,
    );
  }

  AssistantMessage _respondLightDirection(Room? room) {
    if (room == null || room.direction == null) {
      return AssistantMessage(
        text:
            'Light direction is one of the most important factors in '
            'choosing colours. The same green that looks warm and inviting '
            'in a south-facing room can look cold and dingy facing north.\n\n'
            '${room != null ? 'Set your ${room.name}\'s compass direction '
                    'and I\'ll give you specific advice.' : 'Create a room to '
                    'get personalised light advice.'}',
        isUser: false,
        suggestedFollowUps: const ['What is the 70/20/10 rule?'],
      );
    }

    final lightRec = getLightRecommendation(
      direction: room.direction!,
      usageTime: room.usageTime,
    );

    final buf = StringBuffer();
    buf.writeln(
      'Light in your ${room.name} '
      '(${room.direction!.displayName}-facing, '
      '${room.usageTime.displayName.toLowerCase()} use):',
    );
    buf.writeln();
    buf.writeln(lightRec.recommendation);
    buf.writeln();

    // Time-of-day specifics
    switch (room.direction!) {
      case CompassDirection.north:
        buf.writeln(
          'Morning: soft, cool light. Afternoon: indirect and '
          'consistent. Evening: warm artificial light dominates.',
        );
        buf.writeln();
        buf.writeln(
          'Warm undertones compensate for the cool natural light. '
          'Consider a soft sheen on one wall to bounce what light '
          'there is around the room.',
        );
      case CompassDirection.south:
        buf.writeln(
          'Morning: gentle brightness. Afternoon: flooding sunlight. '
          'Evening: golden glow as the light fades.',
        );
        buf.writeln();
        buf.writeln(
          'You\'ve got the most forgiving light direction. '
          'Matt finishes work beautifully because you don\'t need '
          'the paint to reflect light for you.',
        );
      case CompassDirection.east:
        buf.writeln(
          'Morning: bright, warm light. Afternoon: fades to neutral. '
          'Evening: relies on artificial light.',
        );
        buf.writeln();
        buf.writeln(
          'If you use this room mainly in the morning, you can '
          'be bolder with colour. If it\'s an evening room too, '
          'choose colours that also look good under warm lamps.',
        );
      case CompassDirection.west:
        buf.writeln(
          'Morning: subdued, cool light. Afternoon: warming up. '
          'Evening: spectacular golden-hour glow.',
        );
        buf.writeln();
        buf.writeln(
          'West-facing rooms come alive in the evening. Colours '
          'with warm undertones will glow magnificently at sunset, '
          'but check them in morning light too \u2014 they can look '
          'flat without direct sun.',
        );
    }

    return AssistantMessage(
      text: buf.toString().trimRight(),
      isUser: false,
      roomId: room.id,
      suggestedFollowUps: [
        'What colour should I paint my ${room.name}?',
        'Which white works for my ${room.name}?',
      ],
    );
  }

  AssistantMessage _respondRedThread() {
    final buf = StringBuffer();
    final swatches = <String>[];

    if (context.threadHexes.isEmpty) {
      buf.writeln(
        'The Red Thread is your whole-home colour story \u2014 '
        '2 to 4 colours that appear in some form in every room, '
        'creating subconscious harmony as you move through your home.',
      );
      buf.writeln();
      buf.writeln(
        'Without it, each room can feel like a separate '
        'decorating decision. With it, your home feels intentional.',
      );
      buf.writeln();

      if (context.rooms.length >= 2) {
        buf.writeln(
          'You have ${context.rooms.length} rooms. '
          'Head to the Red Thread screen to define your connecting colours.',
        );
      } else {
        buf.writeln(
          'Create at least 2 rooms to start planning '
          'your Red Thread.',
        );
      }
    } else {
      buf.writeln(
        'Your Red Thread has '
        '${context.threadHexes.length} connecting colour'
        '${context.threadHexes.length == 1 ? '' : 's'}.',
      );
      swatches.addAll(context.threadHexes);

      if (context.coherence != null) {
        buf.writeln();
        final report = context.coherence!;
        if (report.overallCoherent) {
          buf.writeln(
            'All ${report.connectedCount} rooms are connected '
            '\u2014 your colour story flows beautifully throughout '
            'your home.',
          );
        } else {
          buf.writeln(
            '${report.connectedCount} of '
            '${report.results.length} rooms are connected.',
          );

          final disconnected =
              report.results.where((r) => !r.isConnected).toList();
          if (disconnected.isNotEmpty) {
            buf.writeln();
            buf.writeln('Rooms that need attention:');
            for (final r in disconnected) {
              buf.writeln(
                '\u2022 ${r.roomName} \u2014 no thread colour '
                'present. Add a cushion, throw, or accent in one of '
                'your thread colours.',
              );
            }
          }
        }
      }
    }

    return AssistantMessage(
      text: buf.toString().trimRight(),
      isUser: false,
      colourSwatches: swatches,
      suggestedFollowUps:
          context.rooms.isNotEmpty
              ? ['What does my ${context.rooms.first.name} still need?']
              : const ['What is the 70/20/10 rule?'],
    );
  }

  AssistantMessage _respondRoomGap(Room? room) {
    if (room == null) {
      return const AssistantMessage(
        text:
            'Create a room with a colour plan so I can tell you '
            'what it still needs.',
        isUser: false,
        suggestedFollowUps: ['What is the 70/20/10 rule?'],
      );
    }

    final report = context.gapsByRoom[room.id];
    if (report == null || !report.hasGaps) {
      if (room.heroColourHex == null) {
        return AssistantMessage(
          text:
              'Your ${room.name} needs a hero colour first. '
              'Once you\'ve set your 70/20/10 plan, I can diagnose '
              'what the room still needs.',
          isUser: false,
          roomId: room.id,
          suggestedFollowUps: ['What colour should I paint my ${room.name}?'],
        );
      }

      return AssistantMessage(
        text:
            'Your ${room.name} is looking well-planned! '
            'No major design gaps detected. Keep layering with '
            'personal touches \u2014 artwork, books, plants \u2014 '
            'to make it truly yours.',
        isUser: false,
        roomId: room.id,
        suggestedFollowUps: [
          'How do my rooms connect?',
          'What materials suit my style?',
        ],
      );
    }

    final buf = StringBuffer();
    buf.writeln('Here\'s what your ${room.name} still needs:');
    buf.writeln();

    final gaps = report.gaps.take(3);
    for (final gap in gaps) {
      final confidence = switch (gap.confidence) {
        GapConfidence.high => 'Strong suggestion',
        GapConfidence.medium => 'Worth considering',
        GapConfidence.low => 'Nice to have',
      };
      buf.writeln('\u2022 ${gap.title}');
      buf.writeln('  ${gap.whyItMatters} ($confidence)');
      buf.writeln();
    }

    if (report.dataQuality == DataQuality.minimal) {
      buf.writeln(
        'Add your existing furniture for better recommendations '
        '\u2014 the more I know about what\'s in the room, the better '
        'my advice gets.',
      );
    }

    return AssistantMessage(
      text: buf.toString().trimRight(),
      isUser: false,
      roomId: room.id,
      suggestedFollowUps: [
        'What colour should I paint my ${room.name}?',
        'What materials suit my style?',
      ],
    );
  }

  AssistantMessage _respondMaterial() {
    final buf = StringBuffer();
    final archetype = context.dna?.archetype;

    if (archetype == null) {
      buf.writeln(
        'Complete the Colour DNA quiz to get personalised '
        'material and texture recommendations tailored to your '
        'design identity.',
      );
      return AssistantMessage(
        text: buf.toString().trimRight(),
        isUser: false,
        suggestedFollowUps: const ['What is the 70/20/10 rule?'],
      );
    }

    buf.writeln('As ${archetype.displayName}, here\'s your material palette:');
    buf.writeln();

    // Archetype family guidance
    final (metals, woods, fabrics, avoid) = _archetypeMaterials(archetype);

    buf.writeln('Best metals: $metals');
    buf.writeln('Best wood tones: $woods');
    buf.writeln('Best fabrics: $fabrics');
    buf.writeln('Avoid: $avoid');
    buf.writeln();

    buf.writeln('Key rules:');
    buf.writeln(
      '\u2022 Stick to one dominant metal + one accent metal '
      'per room. Mixing three metals creates visual noise.',
    );
    buf.writeln(
      '\u2022 Wood tones don\'t need to match exactly, but their '
      'undertones should agree (warm with warm, cool with cool).',
    );
    buf.writeln(
      '\u2022 Layer at least 3 textures per room. If everything '
      'is smooth, add a chunky knit or woven basket.',
    );

    // Room-specific texture advice
    if (context.rooms.isNotEmpty) {
      for (final room in context.rooms.take(2)) {
        final furniture = context.furnitureByRoom[room.id] ?? [];
        if (furniture.isNotEmpty) {
          final allSmooth = furniture.every(
            (f) =>
                f.textureFeel == TextureFeel.smooth ||
                f.textureFeel == TextureFeel.lowTexture,
          );
          if (allSmooth) {
            buf.writeln();
            buf.writeln(
              'In your ${room.name}, all surfaces are smooth '
              '\u2014 add something with texture like a chunky throw '
              'or woven rug to balance it out.',
            );
          }
        }
      }
    }

    return AssistantMessage(
      text: buf.toString().trimRight(),
      isUser: false,
      suggestedFollowUps:
          context.rooms.isNotEmpty
              ? [
                'What does my ${context.rooms.first.name} still need?',
                'How do my rooms connect?',
              ]
              : const ['What is the 70/20/10 rule?'],
    );
  }

  AssistantMessage _respondDesignIdentity() {
    final dna = context.dna;
    if (dna == null) {
      return const AssistantMessage(
        text:
            'Complete the Colour DNA quiz to discover your design '
            'identity. It takes under 3 minutes and I\'ll be able to give '
            'you much more personalised advice.',
        isUser: false,
        suggestedFollowUps: ['What is the 70/20/10 rule?'],
      );
    }

    final buf = StringBuffer();
    final swatches = <String>[];

    buf.writeln('You are ${dna.archetype?.displayName ?? 'unique'}.');
    buf.writeln();
    buf.writeln('Your palette family: ${dna.primaryFamily.displayName}');
    if (dna.secondaryFamily != null) {
      buf.writeln('Secondary lean: ${dna.secondaryFamily!.displayName}');
    }
    if (dna.undertoneTemperature != null) {
      buf.writeln('Undertone: ${dna.undertoneTemperature!.displayName}');
    }
    buf.writeln();
    buf.writeln(
      '${dna.primaryFamily.description}. '
      'This means you\'re naturally drawn to these kinds of spaces, '
      'and your rooms will feel most "you" when they honour this instinct.',
    );

    swatches.addAll(dna.colourHexes.take(6));

    if (dna.archetype != null) {
      final (metals, woods, fabrics, avoid) = _archetypeMaterials(
        dna.archetype!,
      );
      buf.writeln();
      buf.writeln('Your best materials: $fabrics, $woods');
      buf.writeln('Your best metals: $metals');
      buf.writeln('Avoid: $avoid');
    }

    return AssistantMessage(
      text: buf.toString().trimRight(),
      isUser: false,
      colourSwatches: swatches,
      suggestedFollowUps: const [
        'What materials suit my style?',
        'How do my rooms connect?',
      ],
    );
  }

  AssistantMessage _respondGeneralDesign(String q) {
    if (q.contains('70/20/10') || q.contains('70 20 10')) {
      return const AssistantMessage(
        text:
            'The 70/20/10 rule divides a room\'s colour into three tiers:\n\n'
            '\u2022 70% Hero \u2014 your walls, ceiling, and largest furniture. '
            'This is the colour that sets the overall mood.\n'
            '\u2022 20% Beta \u2014 one large piece plus smaller touches. '
            'This adds depth and interest without competing.\n'
            '\u2022 10% Surprise \u2014 your accent colour in cushions, art, '
            'and accessories. This is what makes the room pop.\n\n'
            'The magic is in the proportions. Too much accent feels chaotic. '
            'Too little feels safe and boring. The 70/20/10 balance gives '
            'every colour a clear job.',
        isUser: false,
        suggestedFollowUps: [
          'What is a Red Thread?',
          'How do I choose the right white?',
        ],
      );
    }

    if (q.contains('undertone')) {
      return const AssistantMessage(
        text:
            'Every colour has an undertone \u2014 a subtle lean towards warm '
            '(yellow, red) or cool (blue, grey). Even whites have undertones.\n\n'
            'Why it matters: colours with clashing undertones in the same room '
            'create visual tension. A warm cream wall with cool grey flooring '
            'feels "off" even if you can\'t explain why.\n\n'
            'The rule: keep undertones consistent within a room. Warm with '
            'warm, cool with cool. The only exception is deliberate contrast '
            'in accent pieces.',
        isUser: false,
        suggestedFollowUps: [
          'How do I choose the right white?',
          'What is the 70/20/10 rule?',
        ],
      );
    }

    if (q.contains('white') || q.contains('choose')) {
      return const AssistantMessage(
        text:
            'There\'s no such thing as "just white." Every white has an '
            'undertone \u2014 blue, pink, yellow, or grey \u2014 and the '
            'wrong one can make your room feel clinical or dingy.\n\n'
            'The key is matching your white\'s undertone to your room\'s '
            'light direction:\n'
            '\u2022 North-facing: warm whites (yellow/pink undertone)\n'
            '\u2022 South-facing: any white works; cool whites feel crisp\n'
            '\u2022 East-facing: warm whites for afternoon balance\n'
            '\u2022 West-facing: neutral whites to avoid orange evenings\n\n'
            'Try the Paper Test: hold a sheet of printer paper next to your '
            'paint sample. The contrast reveals the undertone instantly.',
        isUser: false,
        suggestedFollowUps: [
          'What is the 70/20/10 rule?',
          'What is a Red Thread?',
        ],
      );
    }

    if (q.contains('red thread') || q.contains('connect')) {
      return const AssistantMessage(
        text:
            'The Red Thread is the idea that 2\u20134 colours should appear '
            'in some form in every room of your home, creating subconscious '
            'harmony as you move from space to space.\n\n'
            'Without it, each room feels like a separate decorating decision. '
            'With it, your home tells a coherent colour story.\n\n'
            'It doesn\'t mean every room looks the same \u2014 it means '
            'there\'s a connecting thread. Your hallway cream becomes your '
            'living room cushion, your bedroom throw picks up your '
            'kitchen accent.',
        isUser: false,
        suggestedFollowUps: [
          'How do my rooms connect?',
          'What is the 70/20/10 rule?',
        ],
      );
    }

    // General help
    return const AssistantMessage(
      text:
          'I can help you with:\n\n'
          '\u2022 Colour advice for any room\n'
          '\u2022 White selection based on your light\n'
          '\u2022 How light direction affects colour\n'
          '\u2022 What your rooms still need\n'
          '\u2022 Materials and textures for your style\n'
          '\u2022 How to connect your rooms with a Red Thread\n\n'
          'Ask me anything about your home \u2014 I know your rooms, your '
          'palette, and your style.',
      isUser: false,
      suggestedFollowUps: [
        'What is the 70/20/10 rule?',
        'What is a Red Thread?',
        'How do I choose the right white?',
      ],
    );
  }

  AssistantMessage _respondGreeting() {
    final name = context.dna?.archetype?.displayName;
    final greeting =
        name != null
            ? 'Hello! As $name, you\'ve got great instincts. '
                'What can I help you with today?'
            : 'Hello! I\'m your pocket interior designer. '
                'Ask me anything about your home \u2014 colours, materials, '
                'light, or what to buy next.';

    return AssistantMessage(
      text: greeting,
      isUser: false,
      suggestedFollowUps: starterSuggestions(),
    );
  }

  AssistantMessage _respondUnknown() {
    return AssistantMessage(
      text:
          'I\'m best at helping with room colours, materials, '
          'light direction, and your whole-home colour story. '
          'Try asking me about one of your rooms.',
      isUser: false,
      suggestedFollowUps: starterSuggestions(),
    );
  }

  // ── Helpers ────────────────────────────────────────────────

  String _moodGuidance(RoomMood mood) => switch (mood) {
    RoomMood.calm =>
      'For calm, lean towards muted tones with low '
          'saturation. Soft blues, gentle greens, and warm neutrals.',
    RoomMood.energising =>
      'For energy, consider warmer, slightly '
          'more saturated tones. Terracotta, warm yellow, or a confident green.',
    RoomMood.cocooning =>
      'For cocooning, wrap the room in deep, warm '
          'colours. Rich earth tones, dark greens, or warm greys.',
    RoomMood.elegant =>
      'For elegance, pair refined neutrals with one '
          'confident colour. Think charcoal with brass, or deep navy with cream.',
    RoomMood.fresh =>
      'For freshness, choose clean colours with a hint of '
          'brightness. Soft sage, gentle aqua, or crisp warm white.',
    RoomMood.grounded =>
      'For a grounded feel, earth tones anchor the space. '
          'Clay, olive, warm stone, or deep moss.',
    RoomMood.dramatic =>
      'For drama, don\'t be afraid of dark colours. '
          'A deep wall colour with metallic accents creates impact.',
    RoomMood.playful =>
      'For playfulness, mix complementary colours and '
          'patterns. This is where your 10% accent does the heavy lifting.',
  };

  (String metals, String woods, String fabrics, String avoid)
  _archetypeMaterials(ColourArchetype archetype) {
    return switch (archetype) {
      ColourArchetype.theCocooner ||
      ColourArchetype.theGoldenHour ||
      ColourArchetype.theVelvetWhisper => (
        'Antique brass, brushed gold, matte black',
        'Honey oak, walnut, weathered pine',
        'Linen, boucle, chunky knit, velvet',
        'Chrome, high-gloss, acrylic',
      ),
      ColourArchetype.theMonochromeModernist ||
      ColourArchetype.theMinimalist ||
      ColourArchetype.theMidnightArchitect => (
        'Brushed nickel, polished chrome, matte black',
        'White oak, ash, light birch',
        'Cotton, smooth linen, light wool',
        'Brass, copper, dark stained wood',
      ),
      ColourArchetype.theCurator ||
      ColourArchetype.theStoryteller ||
      ColourArchetype.theDramatist => (
        'Aged brass, dark bronze, matte black',
        'Dark walnut, mahogany, ebony stain',
        'Velvet, heavy linen, tapestry, leather',
        'Chrome, plastic, light pine',
      ),
      ColourArchetype.theNatureLover || ColourArchetype.theRomantic => (
        'Matte black, copper, aged brass',
        'Reclaimed wood, teak, bamboo',
        'Jute, rattan, raw linen, cotton',
        'Chrome, high-gloss, synthetic',
      ),
      ColourArchetype.theBrightener ||
      ColourArchetype.theColourOptimist ||
      ColourArchetype.theMaximalist => (
        'Polished brass, chrome, copper',
        'Any wood with strong grain contrast',
        'Velvet, silk, bold-pattern cotton',
        'Muted finishes, weathered looks',
      ),
    };
  }
}
