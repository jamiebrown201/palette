import 'package:flutter_test/flutter_test.dart';
import 'package:palette/features/rooms/data/room_colour_psychology.dart';

void main() {
  group('roomColourGuidance', () {
    test('all entries have non-empty insight and avoid', () {
      for (final entry in roomColourGuidance.entries) {
        expect(
          entry.value.insight,
          isNotEmpty,
          reason: '${entry.key} insight should not be empty',
        );
        expect(
          entry.value.avoid,
          isNotEmpty,
          reason: '${entry.key} avoid should not be empty',
        );
      }
    });

    test('covers key room types', () {
      expect(roomColourGuidance, contains('bedroom'));
      expect(roomColourGuidance, contains('kitchen'));
      expect(roomColourGuidance, contains('living'));
      expect(roomColourGuidance, contains('office'));
      expect(roomColourGuidance, contains('dining'));
      expect(roomColourGuidance, contains('bathroom'));
      expect(roomColourGuidance, contains('hallway'));
    });
  });

  group('getGuidanceForRoom', () {
    test('matches "Bedroom"', () {
      final g = getGuidanceForRoom('Bedroom');
      expect(g, isNotNull);
      expect(g!.insight, contains('sleep'));
    });

    test('matches "Master Bedroom"', () {
      expect(getGuidanceForRoom('Master Bedroom'), isNotNull);
    });

    test('matches "Living Room"', () {
      expect(getGuidanceForRoom('Living Room'), isNotNull);
    });

    test('matches "Home Office"', () {
      expect(getGuidanceForRoom('Home Office'), isNotNull);
    });

    test('matches "Kitchen"', () {
      expect(getGuidanceForRoom('Kitchen'), isNotNull);
    });

    test('matches "Dining Room"', () {
      expect(getGuidanceForRoom('Dining Room'), isNotNull);
    });

    test('matches "Bathroom"', () {
      expect(getGuidanceForRoom('Bathroom'), isNotNull);
    });

    test('matches "Hallway"', () {
      expect(getGuidanceForRoom('Hallway'), isNotNull);
    });

    test('case insensitive matching', () {
      expect(getGuidanceForRoom('KITCHEN'), isNotNull);
      expect(getGuidanceForRoom('bedroom'), isNotNull);
    });

    test('returns null for unrecognised room', () {
      expect(getGuidanceForRoom('Garage'), isNull);
      expect(getGuidanceForRoom('Loft'), isNull);
    });
  });
}
