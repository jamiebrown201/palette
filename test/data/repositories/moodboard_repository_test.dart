import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/repositories/moodboard_repository.dart';

void main() {
  late PaletteDatabase db;
  late MoodboardRepository repo;

  setUp(() {
    db = PaletteDatabase(NativeDatabase.memory());
    repo = MoodboardRepository(db);
  });

  tearDown(() => db.close());

  MoodboardsCompanion makeBoard({
    required String id,
    String name = 'Test Board',
    String? roomId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return MoodboardsCompanion.insert(
      id: id,
      name: name,
      roomId: Value(roomId),
      roomName: const Value(null),
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  MoodboardItemsCompanion makeItem({
    required String id,
    required String moodboardId,
    String type = 'colour',
    String? colourHex,
    int sortOrder = 0,
    DateTime? addedAt,
  }) {
    return MoodboardItemsCompanion.insert(
      id: id,
      moodboardId: moodboardId,
      type: type,
      colourHex: Value(colourHex),
      colourName: const Value(null),
      imageUrl: const Value(null),
      productId: const Value(null),
      label: const Value(null),
      sortOrder: sortOrder,
      addedAt: addedAt ?? DateTime.now(),
    );
  }

  group('MoodboardRepository — moodboards', () {
    test('starts empty', () async {
      final boards = await repo.getAll();
      expect(boards, isEmpty);
    });

    test('create and getAll', () async {
      await repo.create(makeBoard(id: 'b1'));
      await repo.create(makeBoard(id: 'b2', name: 'Second Board'));

      final boards = await repo.getAll();
      expect(boards, hasLength(2));
    });

    test('getById returns correct board', () async {
      await repo.create(makeBoard(id: 'b1', name: 'My Board'));
      final board = await repo.getById('b1');
      expect(board, isNotNull);
      expect(board!.name, 'My Board');
    });

    test('getById returns null for missing id', () async {
      final board = await repo.getById('nonexistent');
      expect(board, isNull);
    });

    test('count returns correct total', () async {
      expect(await repo.count(), 0);
      await repo.create(makeBoard(id: 'b1'));
      expect(await repo.count(), 1);
      await repo.create(makeBoard(id: 'b2'));
      expect(await repo.count(), 2);
    });

    test('update changes name', () async {
      await repo.create(makeBoard(id: 'b1', name: 'Old Name'));
      await repo.update(
        'b1',
        const MoodboardsCompanion(name: Value('New Name')),
      );

      final board = await repo.getById('b1');
      expect(board!.name, 'New Name');
    });

    test('delete removes board and its items', () async {
      await repo.create(makeBoard(id: 'b1'));
      await repo.addItem(makeItem(id: 'i1', moodboardId: 'b1'));
      await repo.addItem(makeItem(id: 'i2', moodboardId: 'b1'));

      await repo.delete('b1');

      expect(await repo.getById('b1'), isNull);
      final items = await repo.getItems('b1');
      expect(items, isEmpty);
    });

    test('boards ordered by updatedAt descending', () async {
      final earlier = DateTime(2026, 1, 1);
      final later = DateTime(2026, 6, 1);

      await repo.create(makeBoard(id: 'old', name: 'Old', updatedAt: earlier));
      await repo.create(makeBoard(id: 'new', name: 'New', updatedAt: later));

      final boards = await repo.getAll();
      expect(boards.first.name, 'New');
      expect(boards.last.name, 'Old');
    });

    test('watchAll emits updates', () async {
      final stream = repo.watchAll();
      expect(await stream.first, isEmpty);

      await repo.create(makeBoard(id: 'b1'));
      final boards = await stream.first;
      expect(boards, hasLength(1));
    });
  });

  group('MoodboardRepository — items', () {
    setUp(() async {
      await repo.create(makeBoard(id: 'board-1'));
    });

    test('addItem and getItems', () async {
      await repo.addItem(
        makeItem(id: 'i1', moodboardId: 'board-1', colourHex: 'FF0000'),
      );
      await repo.addItem(
        makeItem(
          id: 'i2',
          moodboardId: 'board-1',
          colourHex: '00FF00',
          sortOrder: 1,
        ),
      );

      final items = await repo.getItems('board-1');
      expect(items, hasLength(2));
      expect(items.first.colourHex, 'FF0000');
    });

    test('items ordered by sortOrder ascending', () async {
      await repo.addItem(
        makeItem(id: 'i2', moodboardId: 'board-1', sortOrder: 2),
      );
      await repo.addItem(
        makeItem(id: 'i1', moodboardId: 'board-1', sortOrder: 1),
      );

      final items = await repo.getItems('board-1');
      expect(items.first.id, 'i1');
      expect(items.last.id, 'i2');
    });

    test('removeItem removes by id', () async {
      await repo.addItem(makeItem(id: 'i1', moodboardId: 'board-1'));
      await repo.addItem(
        makeItem(id: 'i2', moodboardId: 'board-1', sortOrder: 1),
      );

      await repo.removeItem('i1');
      final items = await repo.getItems('board-1');
      expect(items, hasLength(1));
      expect(items.first.id, 'i2');
    });

    test('updateItemLabel changes label', () async {
      await repo.addItem(makeItem(id: 'i1', moodboardId: 'board-1'));

      await repo.updateItemLabel('i1', 'My note');
      final items = await repo.getItems('board-1');
      expect(items.first.label, 'My note');
    });

    test('updateItemOrder changes sort order', () async {
      await repo.addItem(
        makeItem(id: 'i1', moodboardId: 'board-1', sortOrder: 0),
      );

      await repo.updateItemOrder('i1', 5);
      final items = await repo.getItems('board-1');
      expect(items.first.sortOrder, 5);
    });

    test('watchItems emits updates', () async {
      final stream = repo.watchItems('board-1');
      expect(await stream.first, isEmpty);

      await repo.addItem(
        makeItem(id: 'i1', moodboardId: 'board-1', colourHex: 'AABBCC'),
      );
      final items = await stream.first;
      expect(items, hasLength(1));
      expect(items.first.colourHex, 'AABBCC');
    });
  });

  group('MoodboardRepository — room filtering', () {
    test('watchForRoom only returns boards for that room', () async {
      await repo.create(makeBoard(id: 'b1', roomId: 'room-1'));
      await repo.create(makeBoard(id: 'b2', roomId: 'room-2'));
      await repo.create(makeBoard(id: 'b3', roomId: 'room-1'));

      final stream = repo.watchForRoom('room-1');
      final boards = await stream.first;
      expect(boards, hasLength(2));
      expect(boards.every((b) => b.roomId == 'room-1'), isTrue);
    });
  });
}
