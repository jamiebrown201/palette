import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/colour_dna_result.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/assistant/logic/assistant_engine.dart';
import 'package:palette/features/red_thread/logic/coherence_checker.dart';

void main() {
  group('AssistantEngine', () {
    final baseRoom = Room(
      id: 'room-1',
      name: 'Living Room',
      direction: CompassDirection.south,
      usageTime: UsageTime.evening,
      moods: [RoomMood.cocooning],
      budget: BudgetBracket.midRange,
      heroColourHex: '#C4A882',
      isRenterMode: false,
      sortOrder: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final baseDna = ColourDnaResult(
      id: 'dna-1',
      primaryFamily: PaletteFamily.earthTones,
      colourHexes: ['#C4A882', '#8B6F47', '#D4C4A8', '#5C4033'],
      completedAt: DateTime.now(),
      isComplete: true,
      archetype: ColourArchetype.theCocooner,
      undertoneTemperature: Undertone.warm,
    );

    group('intent parsing', () {
      test('recognises room colour questions', () {
        final engine = AssistantEngine(
          AssistantContext(rooms: [baseRoom], dna: baseDna),
        );
        final response = engine.respond(
          'What colour should I paint my living room?',
        );
        expect(response.isUser, isFalse);
        expect(response.text.isNotEmpty, isTrue);
      });

      test('recognises white selection questions', () {
        final engine = AssistantEngine(AssistantContext(rooms: [baseRoom]));
        final response = engine.respond(
          'Which white works for my living room?',
        );
        expect(response.text, contains('white'));
      });

      test('recognises light direction questions', () {
        final engine = AssistantEngine(AssistantContext(rooms: [baseRoom]));
        final response = engine.respond(
          'How does light affect my living room?',
        );
        expect(response.text, contains('South'));
      });

      test('recognises red thread questions', () {
        final engine = AssistantEngine(const AssistantContext());
        final response = engine.respond('How do my rooms connect?');
        expect(response.text, contains('Red Thread'));
      });

      test('recognises material questions', () {
        final engine = AssistantEngine(AssistantContext(dna: baseDna));
        final response = engine.respond('What materials suit my style?');
        expect(response.text, contains('Cocooner'));
      });

      test('recognises greetings', () {
        final engine = AssistantEngine(const AssistantContext());
        final response = engine.respond('Hello');
        expect(response.text.toLowerCase(), contains('hello'));
      });

      test('handles unknown questions gracefully', () {
        final engine = AssistantEngine(const AssistantContext());
        final response = engine.respond('fdsjklfdsjkl');
        expect(response.text.isNotEmpty, isTrue);
        expect(response.suggestedFollowUps, isNotEmpty);
      });
    });

    group('room matching', () {
      test('matches room by name', () {
        final engine = AssistantEngine(
          AssistantContext(rooms: [baseRoom], dna: baseDna),
        );
        final response = engine.respond('What colour for my living room?');
        expect(response.roomId, equals('room-1'));
      });

      test('matches room by alias', () {
        final kitchen = baseRoom.copyWith(id: 'room-2', name: 'Kitchen');
        final engine = AssistantEngine(
          AssistantContext(rooms: [baseRoom, kitchen]),
        );
        final response = engine.respond('What colour for the kitchen?');
        expect(response.roomId, equals('room-2'));
      });

      test('falls back to first room if no match', () {
        final engine = AssistantEngine(
          AssistantContext(rooms: [baseRoom], dna: baseDna),
        );
        final response = engine.respond('What colour for my garage?');
        expect(response.roomId, equals('room-1'));
      });
    });

    group('room colour advice', () {
      test('provides paint recs when hero colour is set', () {
        final engine = AssistantEngine(
          AssistantContext(rooms: [baseRoom], dna: baseDna),
        );
        final response = engine.respond(
          'What colour should I paint my living room?',
        );
        expect(response.text, contains('hero colour'));
      });

      test('provides direction-based advice when no hero', () {
        final roomNoHero = Room(
          id: 'room-nh',
          name: 'Living Room',
          direction: CompassDirection.south,
          usageTime: UsageTime.evening,
          moods: [RoomMood.cocooning],
          budget: BudgetBracket.midRange,
          isRenterMode: false,
          sortOrder: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final engine = AssistantEngine(
          AssistantContext(rooms: [roomNoHero], dna: baseDna),
        );
        final response = engine.respond('What colour for my living room?');
        expect(response.text, contains('South'));
        expect(response.colourSwatches, isNotEmpty);
      });

      test('prompts room creation when no rooms exist', () {
        final engine = AssistantEngine(const AssistantContext());
        final response = engine.respond('What colour should I paint?');
        expect(response.text, contains('Create a room'));
      });
    });

    group('white advice', () {
      test('gives direction-specific white advice', () {
        final engine = AssistantEngine(AssistantContext(rooms: [baseRoom]));
        final response = engine.respond('Which white?');
        expect(response.text, contains('South'));
      });

      test('advises setting direction when missing', () {
        final noDir = Room(
          id: 'room-nd',
          name: 'Living Room',
          usageTime: UsageTime.evening,
          moods: [RoomMood.cocooning],
          budget: BudgetBracket.midRange,
          isRenterMode: false,
          sortOrder: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final engine = AssistantEngine(AssistantContext(rooms: [noDir]));
        final response = engine.respond('Which white?');
        expect(response.text, contains('compass direction'));
      });
    });

    group('red thread', () {
      test('explains concept when no threads defined', () {
        final engine = AssistantEngine(AssistantContext(rooms: [baseRoom]));
        final response = engine.respond('How do my rooms connect?');
        expect(response.text, contains('Red Thread'));
        expect(response.text, contains('2 to 4 colours'));
      });

      test('shows thread status when defined', () {
        final engine = AssistantEngine(
          AssistantContext(
            rooms: [baseRoom],
            threadHexes: ['#C4A882', '#8B6F47'],
            coherence: const CoherenceReport(
              results: [
                RoomCoherenceResult(
                  roomId: 'room-1',
                  roomName: 'Living Room',
                  isConnected: true,
                  matchingThreadHex: '#C4A882',
                ),
              ],
              overallCoherent: true,
            ),
          ),
        );
        final response = engine.respond('How do my rooms connect?');
        expect(response.colourSwatches, hasLength(2));
        expect(response.text, contains('connected'));
      });
    });

    group('design identity', () {
      test('shows archetype details', () {
        final engine = AssistantEngine(AssistantContext(dna: baseDna));
        final response = engine.respond('What is my design identity?');
        expect(response.text, contains('Cocooner'));
        expect(response.colourSwatches, isNotEmpty);
      });

      test('prompts quiz when no DNA', () {
        final engine = AssistantEngine(const AssistantContext());
        final response = engine.respond('What is my style?');
        expect(response.text, contains('Colour DNA quiz'));
      });
    });

    group('general design', () {
      test('explains 70/20/10 rule', () {
        final engine = AssistantEngine(const AssistantContext());
        final response = engine.respond('What is the 70/20/10 rule?');
        expect(response.text, contains('70%'));
        expect(response.text, contains('20%'));
        expect(response.text, contains('10%'));
      });

      test('explains red thread concept', () {
        final engine = AssistantEngine(const AssistantContext());
        final response = engine.respond('What is a Red Thread?');
        expect(response.text, contains('Red Thread'));
      });

      test('explains undertones', () {
        final engine = AssistantEngine(const AssistantContext());
        final response = engine.respond('What are undertones?');
        expect(response.text, contains('undertone'));
      });
    });

    group('starter suggestions', () {
      test('returns room-specific starters when rooms exist', () {
        final engine = AssistantEngine(
          AssistantContext(rooms: [baseRoom], dna: baseDna),
        );
        final starters = engine.starterSuggestions();
        expect(starters, isNotEmpty);
        expect(starters.first, contains('Living Room'));
      });

      test('returns generic starters when no rooms', () {
        final engine = AssistantEngine(const AssistantContext());
        final starters = engine.starterSuggestions();
        expect(starters, isNotEmpty);
        expect(starters.any((s) => s.contains('70/20/10')), isTrue);
      });
    });

    group('follow-ups', () {
      test('responses include follow-up suggestions', () {
        final engine = AssistantEngine(
          AssistantContext(rooms: [baseRoom], dna: baseDna),
        );
        final response = engine.respond('What colour for my living room?');
        expect(response.suggestedFollowUps, isNotEmpty);
      });
    });
  });
}
