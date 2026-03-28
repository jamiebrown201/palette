import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/repositories/sample_list_repository.dart';

void main() {
  late PaletteDatabase db;
  late SampleListRepository repo;

  setUp(() {
    db = PaletteDatabase(NativeDatabase.memory());
    repo = SampleListRepository(db);
  });

  tearDown(() => db.close());

  SampleListItemsCompanion makeSample({
    required String id,
    String paintColourId = 'pc-1',
    String colourName = 'Savage Ground',
    String colourCode = 'SG-001',
    String brand = 'Farrow & Ball',
    String hex = '#C4B098',
    String? roomId,
    String? roomName,
    DateTime? addedAt,
    DateTime? orderedAt,
    DateTime? arrivedAt,
  }) {
    return SampleListItemsCompanion.insert(
      id: id,
      paintColourId: paintColourId,
      colourName: colourName,
      colourCode: colourCode,
      brand: brand,
      hex: hex,
      roomId: Value(roomId),
      roomName: Value(roomName),
      addedAt: addedAt ?? DateTime.now(),
      orderedAt: Value(orderedAt),
      arrivedAt: Value(arrivedAt),
    );
  }

  group('SampleListRepository', () {
    test('starts empty', () async {
      final items = await repo.getAll();
      expect(items, isEmpty);
    });

    test('addSample and getAll return items', () async {
      await repo.addSample(makeSample(id: 's1'));
      await repo.addSample(makeSample(id: 's2', brand: 'Dulux'));

      final items = await repo.getAll();
      expect(items, hasLength(2));
    });

    test('isInList returns true for existing paint colour', () async {
      await repo.addSample(makeSample(id: 's1', paintColourId: 'pc-99'));

      expect(await repo.isInList('pc-99'), isTrue);
      expect(await repo.isInList('pc-nonexistent'), isFalse);
    });

    test('removeSample removes the correct item', () async {
      await repo.addSample(makeSample(id: 's1'));
      await repo.addSample(makeSample(id: 's2'));
      await repo.removeSample('s1');

      final items = await repo.getAll();
      expect(items, hasLength(1));
      expect(items.first.id, 's2');
    });

    test('markOrdered sets orderedAt', () async {
      await repo.addSample(makeSample(id: 's1'));
      await repo.markOrdered('s1');

      final items = await repo.getAll();
      expect(items.first.orderedAt, isNotNull);
      expect(items.first.isOrdered, isTrue);
    });

    test('markAllOrdered marks only unordered items', () async {
      await repo.addSample(makeSample(id: 's1'));
      await repo.addSample(
        makeSample(
          id: 's2',
          orderedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );
      await repo.markAllOrdered();

      final items = await repo.getAll();
      expect(items.every((i) => i.isOrdered), isTrue);
    });

    test('markArrived sets arrivedAt', () async {
      await repo.addSample(makeSample(id: 's1'));
      await repo.markOrdered('s1');
      await repo.markArrived('s1');

      final items = await repo.getAll();
      expect(items.first.arrivedAt, isNotNull);
      expect(items.first.hasArrived, isTrue);
    });

    test('markAllArrived marks only ordered but unarrived items', () async {
      await repo.addSample(makeSample(id: 's1'));
      await repo.addSample(makeSample(id: 's2'));
      await repo.markOrdered('s1');
      // s2 not ordered, should not be marked arrived
      await repo.markAllArrived();

      final items = await repo.getAll();
      final s1 = items.firstWhere((i) => i.id == 's1');
      final s2 = items.firstWhere((i) => i.id == 's2');
      expect(s1.hasArrived, isTrue);
      expect(s2.hasArrived, isFalse);
    });

    test('clearAll removes everything', () async {
      await repo.addSample(makeSample(id: 's1'));
      await repo.addSample(makeSample(id: 's2'));
      await repo.clearAll();

      final items = await repo.getAll();
      expect(items, isEmpty);
    });

    test('itemCount returns correct count', () async {
      expect(await repo.itemCount(), 0);
      await repo.addSample(makeSample(id: 's1'));
      await repo.addSample(makeSample(id: 's2'));
      expect(await repo.itemCount(), 2);
    });

    test('getAwaitingArrival returns ordered non-arrived items', () async {
      await repo.addSample(makeSample(id: 's1'));
      await repo.addSample(makeSample(id: 's2'));
      await repo.addSample(makeSample(id: 's3'));
      await repo.markOrdered('s1');
      await repo.markOrdered('s2');
      await repo.markArrived('s2');

      final awaiting = await repo.getAwaitingArrival();
      expect(awaiting, hasLength(1));
      expect(awaiting.first.id, 's1');
    });

    test('watchAll emits updates', () async {
      final stream = repo.watchAll();

      // First emission: empty
      final first = await stream.first;
      expect(first, isEmpty);

      // Add an item and get the next emission
      await repo.addSample(makeSample(id: 's1'));
      final updated = await stream.first;
      expect(updated, hasLength(1));
    });
  });
}
