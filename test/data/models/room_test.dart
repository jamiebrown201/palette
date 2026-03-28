import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/room.dart';

void main() {
  group('Room.areaMetres', () {
    Room makeRoom({
      RoomSize? roomSize,
      double? widthMetres,
      double? lengthMetres,
    }) => Room(
      id: 'test',
      name: 'Test Room',
      usageTime: UsageTime.allDay,
      moods: [RoomMood.calm],
      budget: BudgetBracket.midRange,
      isRenterMode: false,
      sortOrder: 0,
      roomSize: roomSize,
      widthMetres: widthMetres,
      lengthMetres: lengthMetres,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('returns null when no size or dimensions set', () {
      expect(makeRoom().areaMetres, isNull);
    });

    test('returns default area for small size bracket', () {
      expect(makeRoom(roomSize: RoomSize.small).areaMetres, 8.0);
    });

    test('returns default area for medium size bracket', () {
      expect(makeRoom(roomSize: RoomSize.medium).areaMetres, 15.0);
    });

    test('returns default area for large size bracket', () {
      expect(makeRoom(roomSize: RoomSize.large).areaMetres, 25.0);
    });

    test('manual dimensions override size bracket default', () {
      final room = makeRoom(
        roomSize: RoomSize.small,
        widthMetres: 5.0,
        lengthMetres: 4.0,
      );
      expect(room.areaMetres, 20.0);
    });

    test('partial manual dimensions fall back to size bracket', () {
      final room = makeRoom(roomSize: RoomSize.medium, widthMetres: 5.0);
      // Only width set, no length — falls back to bracket default
      expect(room.areaMetres, 15.0);
    });
  });

  group('RoomSize.recommendedRugSizes', () {
    test('small room recommends small rug', () {
      expect(RoomSize.small.recommendedRugSizes, [RugSize.small120x170]);
    });

    test('medium room recommends medium and large rugs', () {
      expect(RoomSize.medium.recommendedRugSizes, [
        RugSize.medium160x230,
        RugSize.large200x290,
      ]);
    });

    test('large room recommends large and extra large rugs', () {
      expect(RoomSize.large.recommendedRugSizes, [
        RugSize.large200x290,
        RugSize.extraLarge240x340,
      ]);
    });
  });
}
