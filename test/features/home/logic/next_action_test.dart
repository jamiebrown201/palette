import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/home/logic/next_action.dart';

Room _room({
  String id = 'r1',
  String name = 'Living Room',
  CompassDirection? direction = CompassDirection.south,
  String? heroColourHex = '#8FAE8B',
  String? betaColourHex,
  String? surpriseColourHex,
  String? wallColourHex,
}) => Room(
  id: id,
  name: name,
  direction: direction,
  usageTime: UsageTime.allDay,
  moods: const [RoomMood.cocooning],
  budget: BudgetBracket.midRange,
  heroColourHex: heroColourHex,
  betaColourHex: betaColourHex,
  surpriseColourHex: surpriseColourHex,
  wallColourHex: wallColourHex,
  isRenterMode: false,
  sortOrder: 0,
  createdAt: DateTime(2026, 3, 1),
  updatedAt: DateTime(2026, 3, 1),
);

void main() {
  group('computeNextAction', () {
    test(
      'priority 1: returns completeRoomSetup when room missing direction',
      () {
        final action = computeNextAction(
          rooms: [_room(direction: null, heroColourHex: null)],
          coherenceReport: null,
          threadColours: [],
          roomHasFurniture: {},
        );
        expect(action.type, NextActionType.completeRoomSetup);
      },
    );

    test(
      'priority 2: returns defineRedThread when 3+ rooms and no threads',
      () {
        final rooms = List.generate(
          3,
          (i) => _room(id: 'r$i', name: 'Room $i'),
        );
        final action = computeNextAction(
          rooms: rooms,
          coherenceReport: null,
          threadColours: [],
          roomHasFurniture: {'r0': true, 'r1': true, 'r2': true},
        );
        expect(action.type, NextActionType.defineRedThread);
      },
    );

    test('priority 4: returns findWhite when hero set but no wall colour', () {
      final action = computeNextAction(
        rooms: [_room(heroColourHex: '#8FAE8B', wallColourHex: null)],
        coherenceReport: null,
        threadColours: [],
        roomHasFurniture: {'r1': true},
      );
      expect(action.type, NextActionType.findWhite);
      expect(action.route, contains('white-finder'));
    });

    test('priority 4 skipped when wall colour set — falls through to '
        'completeColourPlan', () {
      final action = computeNextAction(
        rooms: [
          _room(
            heroColourHex: '#8FAE8B',
            wallColourHex: '#FFFFFF',
            betaColourHex: null,
          ),
        ],
        coherenceReport: null,
        threadColours: [],
        roomHasFurniture: {'r1': true},
      );
      expect(action.type, NextActionType.completeColourPlan);
    });

    test('priority 5: returns completeColourPlan when beta missing', () {
      final action = computeNextAction(
        rooms: [
          _room(
            heroColourHex: '#8FAE8B',
            wallColourHex: '#FFFFFF',
            betaColourHex: null,
            surpriseColourHex: '#C9A96E',
          ),
        ],
        coherenceReport: null,
        threadColours: [],
        roomHasFurniture: {'r1': true},
      );
      expect(action.type, NextActionType.completeColourPlan);
    });

    test('priority 6: returns lockFurniture when no furniture', () {
      final action = computeNextAction(
        rooms: [
          _room(
            heroColourHex: '#8FAE8B',
            wallColourHex: '#FFFFFF',
            betaColourHex: '#C9A96E',
            surpriseColourHex: '#D4B896',
          ),
        ],
        coherenceReport: null,
        threadColours: [],
        roomHasFurniture: {'r1': false},
      );
      expect(action.type, NextActionType.lockFurniture);
    });

    test('task_led variant uses imperative copy for completeRoomSetup', () {
      final action = computeNextAction(
        rooms: [_room(direction: null, heroColourHex: null)],
        coherenceReport: null,
        threadColours: [],
        roomHasFurniture: {},
        copyVariant: 'task_led',
      );
      expect(action.type, NextActionType.completeRoomSetup);
      expect(action.title, contains('Set'));
      expect(action.subtitle, contains('remaining'));
    });

    test('task_led variant uses imperative copy for defineRedThread', () {
      final rooms = List.generate(
        3,
        (i) => _room(id: 'r$i', name: 'Room $i'),
      );
      final action = computeNextAction(
        rooms: rooms,
        coherenceReport: null,
        threadColours: [],
        roomHasFurniture: {'r0': true, 'r1': true, 'r2': true},
        copyVariant: 'task_led',
      );
      expect(action.type, NextActionType.defineRedThread);
      expect(action.title, contains('Pick'));
    });

    test('returns allDone when everything is complete', () {
      final action = computeNextAction(
        rooms: [
          _room(
            heroColourHex: '#8FAE8B',
            wallColourHex: '#FFFFFF',
            betaColourHex: '#C9A96E',
            surpriseColourHex: '#D4B896',
          ),
        ],
        coherenceReport: null,
        threadColours: [],
        roomHasFurniture: {'r1': true},
      );
      expect(action.type, NextActionType.allDone);
    });
  });
}
