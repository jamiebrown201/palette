import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/features/rooms/logic/room_story.dart';

void main() {
  group('generateRoomStory', () {
    test('returns incomplete when no hero colour', () {
      final story = generateRoomStory(
        roomName: 'Living Room',
        direction: CompassDirection.south,
        usageTime: UsageTime.evening,
        moods: [RoomMood.cocooning],
        isRenterMode: false,
      );

      expect(story.isComplete, isFalse);
      expect(story.summary, isEmpty);
    });

    test('south-facing + warm hero mentions glow', () {
      // #C4A882 is a warm beige (Savage Ground-ish)
      final story = generateRoomStory(
        roomName: 'Living Room',
        direction: CompassDirection.south,
        usageTime: UsageTime.evening,
        moods: [RoomMood.cocooning],
        heroHex: '#C4A882',
        heroName: 'Savage Ground',
        isRenterMode: false,
      );

      expect(story.isComplete, isTrue);
      expect(story.summary, contains('glow'));
      expect(story.summary, contains('south'));
      expect(story.summary, contains('Savage Ground'));
    });

    test('north-facing + warm hero is aligned (warm recommended for north)', () {
      // North-facing rooms recommend warm undertones, so warm hero = aligned
      final story = generateRoomStory(
        roomName: 'Bedroom',
        direction: CompassDirection.north,
        usageTime: UsageTime.morning,
        moods: [RoomMood.calm],
        heroHex: '#C4A882',
        heroName: 'Savage Ground',
        isRenterMode: false,
      );

      expect(story.isComplete, isTrue);
      expect(story.summary, contains('glow'));
      expect(story.summary, contains('north'));
    });

    test('north-facing + cool hero mentions counterbalance', () {
      // North-facing rooms recommend warm; a cool blue hero is mismatched
      final story = generateRoomStory(
        roomName: 'Bedroom',
        direction: CompassDirection.north,
        usageTime: UsageTime.morning,
        moods: [RoomMood.calm],
        heroHex: '#4682B4', // steel blue — cool undertone
        heroName: 'Steel Blue',
        isRenterMode: false,
      );

      expect(story.isComplete, isTrue);
      expect(story.summary, contains('counterbalance'));
      expect(story.summary, contains('north'));
    });

    test('no direction skips light sentence but still returns valid story', () {
      final story = generateRoomStory(
        roomName: 'Study',
        usageTime: UsageTime.allDay,
        moods: [RoomMood.grounded],
        heroHex: '#C4A882',
        isRenterMode: false,
      );

      // No direction → not complete, but has content from mood sentence
      expect(story.isComplete, isFalse);
      expect(story.summary, isNotEmpty);
      expect(story.summary, contains('grounded'));
    });

    test('with beta and surprise includes relationship', () {
      // Complementary pair: warm beige + cool blue-green
      final story = generateRoomStory(
        roomName: 'Living Room',
        direction: CompassDirection.south,
        usageTime: UsageTime.evening,
        moods: [],
        heroHex: '#C4A882',
        betaHex: '#4A6741',
        surpriseHex: '#8B7355',
        isRenterMode: false,
      );

      expect(story.isComplete, isTrue);
      // Should have at least light sentence + relationship sentence
      expect(story.summary.split('.').length, greaterThanOrEqualTo(2));
    });

    test('renter mode mentions furniture and accessories', () {
      final story = generateRoomStory(
        roomName: 'Living Room',
        direction: CompassDirection.east,
        usageTime: UsageTime.allDay,
        moods: [RoomMood.calm],
        heroHex: '#C4A882',
        isRenterMode: true,
      );

      expect(story.summary, contains('furniture'));
      expect(story.summary, contains('renting'));
    });

    test('multiple moods joined naturally', () {
      final story = generateRoomStory(
        roomName: 'Kitchen',
        usageTime: UsageTime.morning,
        moods: [RoomMood.fresh, RoomMood.energising],
        heroHex: '#F5DEB3',
        isRenterMode: false,
      );

      expect(story.summary, contains('fresh'));
      expect(story.summary, contains('energising'));
      expect(story.summary, contains('and'));
    });

    test('single mood does not use "and"', () {
      final story = generateRoomStory(
        roomName: 'Bedroom',
        usageTime: UsageTime.evening,
        moods: [RoomMood.calm],
        heroHex: '#D4C5A9',
        isRenterMode: false,
      );

      expect(story.summary, contains('calm'));
      // Single mood should not have "and" joining
      expect(story.summary, isNot(contains(' and ')));
    });

    test('no moods and not renter skips mood sentence', () {
      final story = generateRoomStory(
        roomName: 'Bathroom',
        direction: CompassDirection.west,
        usageTime: UsageTime.morning,
        moods: [],
        heroHex: '#C4A882',
        isRenterMode: false,
      );

      expect(story.isComplete, isTrue);
      // Should only have the light sentence
      expect(story.summary, contains('west'));
      expect(story.summary, isNot(contains('vision')));
      expect(story.summary, isNot(contains('renting')));
    });

    // -----------------------------------------------------------------
    // Seed data verification tests — trace exact QA inputs
    // -----------------------------------------------------------------

    test('QA Living Room: matches expected screenshot text', () {
      // Seed: south, evening, cocooning+elegant, hero=#C4A882,
      // beta=#8B7355, surprise=#4A6741, not renter
      final story = generateRoomStory(
        roomName: 'Living Room',
        direction: CompassDirection.south,
        usageTime: UsageTime.evening,
        moods: [RoomMood.cocooning, RoomMood.elegant],
        heroHex: '#C4A882',
        betaHex: '#8B7355',
        surpriseHex: '#4A6741',
        isRenterMode: false,
        heroName: 'Savage Ground',
      );

      expect(story.isComplete, isTrue);
      // Sentence 1: south-facing + warm hero should say "glow"
      expect(story.summary, contains('south-facing living room'));
      expect(story.summary, contains('Savage Ground'));
      expect(story.summary, contains('glow'));
      // Sentence 3: mood tie-in
      expect(story.summary, contains('cocooning'));
      expect(story.summary, contains('elegant'));
    });

    test('QA Bedroom: east-facing, calm mood', () {
      // Seed: east, morning, calm, hero=#D4C5A9,
      // beta=#BC8F8F, surprise=#DEB887
      final story = generateRoomStory(
        roomName: 'Bedroom',
        direction: CompassDirection.east,
        usageTime: UsageTime.morning,
        moods: [RoomMood.calm],
        heroHex: '#D4C5A9',
        betaHex: '#BC8F8F',
        surpriseHex: '#DEB887',
        isRenterMode: false,
        heroName: 'Stony Ground',
      );

      expect(story.isComplete, isTrue);
      expect(story.summary, contains('east-facing bedroom'));
      expect(story.summary, contains('Stony Ground'));
      // East + morning recommends warm; #D4C5A9 is warm → aligned → "glow"
      expect(story.summary, contains('glow'));
      expect(story.summary, contains('calm'));
    });

    test('QA Kitchen: north-facing, fresh+energising', () {
      // Seed: north, allDay, fresh+energising, hero=#F5DEB3,
      // beta=#CD853F, surprise=#A0522D
      final story = generateRoomStory(
        roomName: 'Kitchen',
        direction: CompassDirection.north,
        usageTime: UsageTime.allDay,
        moods: [RoomMood.fresh, RoomMood.energising],
        heroHex: '#F5DEB3',
        betaHex: '#CD853F',
        surpriseHex: '#A0522D',
        isRenterMode: false,
        heroName: 'Wheat',
      );

      expect(story.isComplete, isTrue);
      expect(story.summary, contains('north-facing kitchen'));
      expect(story.summary, contains('Wheat'));
      // North recommends warm; #F5DEB3 (wheat) is warm → aligned → "glow"
      expect(story.summary, contains('glow'));
      expect(story.summary, contains('fresh'));
      expect(story.summary, contains('energising'));
    });

    test('uses generic label when heroName not provided', () {
      final story = generateRoomStory(
        roomName: 'Hall',
        direction: CompassDirection.south,
        usageTime: UsageTime.allDay,
        moods: [],
        heroHex: '#C4A882',
        isRenterMode: false,
      );

      expect(story.summary, contains('your hero colour'));
    });
  });
}
