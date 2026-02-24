import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/repositories/room_repository.dart';

void main() {
  late PaletteDatabase db;
  late RoomRepository repo;

  setUp(() {
    db = PaletteDatabase(NativeDatabase.memory());
    repo = RoomRepository(db);
  });

  tearDown(() => db.close());

  RoomsCompanion roomCompanion({
    required String id,
    required String name,
    int sortOrder = 0,
  }) {
    return RoomsCompanion.insert(
      id: id,
      name: name,
      usageTime: UsageTime.allDay,
      moods: [RoomMood.calm],
      budget: BudgetBracket.midRange,
      isRenterMode: false,
      sortOrder: sortOrder,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  group('room CRUD', () {
    test('insertRoom and getAllRooms', () async {
      await repo.insertRoom(roomCompanion(id: '1', name: 'Living Room'));
      await repo.insertRoom(
        roomCompanion(id: '2', name: 'Bedroom', sortOrder: 1),
      );

      final rooms = await repo.getAllRooms();
      expect(rooms, hasLength(2));
      expect(rooms.first.name, 'Living Room');
      expect(rooms.last.name, 'Bedroom');
    });

    test('rooms are ordered by sortOrder', () async {
      await repo.insertRoom(
        roomCompanion(id: '1', name: 'Third', sortOrder: 2),
      );
      await repo.insertRoom(
        roomCompanion(id: '2', name: 'First', sortOrder: 0),
      );
      await repo.insertRoom(
        roomCompanion(id: '3', name: 'Second', sortOrder: 1),
      );

      final rooms = await repo.getAllRooms();
      expect(rooms[0].name, 'First');
      expect(rooms[1].name, 'Second');
      expect(rooms[2].name, 'Third');
    });

    test('getRoomById returns correct room', () async {
      await repo.insertRoom(roomCompanion(id: 'r1', name: 'Kitchen'));
      final room = await repo.getRoomById('r1');
      expect(room, isNotNull);
      expect(room!.name, 'Kitchen');
    });

    test('deleteRoom removes the room', () async {
      await repo.insertRoom(roomCompanion(id: 'r1', name: 'Kitchen'));
      expect(await repo.roomCount(), 1);

      await repo.deleteRoom('r1');
      expect(await repo.roomCount(), 0);
    });

    test('updateRoom modifies fields', () async {
      await repo.insertRoom(roomCompanion(id: 'r1', name: 'Room'));

      await repo.updateRoom(
        RoomsCompanion(
          id: const Value('r1'),
          heroColourHex: const Value('#FF0000'),
          updatedAt: Value(DateTime.now()),
        ),
      );

      final room = await repo.getRoomById('r1');
      expect(room!.heroColourHex, '#FF0000');
    });
  });

  group('room moods serialisation', () {
    test('stores and retrieves multiple moods', () async {
      await repo.insertRoom(
        RoomsCompanion.insert(
          id: 'r1',
          name: 'Lounge',
          usageTime: UsageTime.evening,
          moods: [RoomMood.cocooning, RoomMood.elegant, RoomMood.calm],
          budget: BudgetBracket.investment,
          isRenterMode: false,
          sortOrder: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final room = await repo.getRoomById('r1');
      expect(room!.moods, hasLength(3));
      expect(room.moods, contains(RoomMood.cocooning));
      expect(room.moods, contains(RoomMood.elegant));
      expect(room.moods, contains(RoomMood.calm));
    });
  });

  group('locked furniture', () {
    setUp(() async {
      await repo.insertRoom(roomCompanion(id: 'r1', name: 'Room'));
    });

    test('insertFurniture and getFurnitureForRoom', () async {
      await repo.insertFurniture(
        LockedFurnitureItemsCompanion.insert(
          id: 'f1',
          roomId: 'r1',
          name: 'Sofa',
          colourHex: '#8B4513',
          role: FurnitureRole.hero,
          sortOrder: 0,
        ),
      );

      final furniture = await repo.getFurnitureForRoom('r1');
      expect(furniture, hasLength(1));
      expect(furniture.first.name, 'Sofa');
      expect(furniture.first.role, FurnitureRole.hero);
    });

    test('deleteAllFurnitureForRoom clears room furniture', () async {
      await repo.insertFurniture(
        LockedFurnitureItemsCompanion.insert(
          id: 'f1',
          roomId: 'r1',
          name: 'Sofa',
          colourHex: '#8B4513',
          role: FurnitureRole.hero,
          sortOrder: 0,
        ),
      );
      await repo.insertFurniture(
        LockedFurnitureItemsCompanion.insert(
          id: 'f2',
          roomId: 'r1',
          name: 'Rug',
          colourHex: '#DEB887',
          role: FurnitureRole.beta,
          sortOrder: 1,
        ),
      );

      expect(await repo.getFurnitureForRoom('r1'), hasLength(2));

      await repo.deleteAllFurnitureForRoom('r1');
      expect(await repo.getFurnitureForRoom('r1'), isEmpty);
    });
  });
}
