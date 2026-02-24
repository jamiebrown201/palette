import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/repositories/paint_colour_repository.dart';
import 'package:palette/data/services/seed_data_service.dart';

/// Minimal test fixture for paint colour JSON data.
const _testColoursJson = {
  'version': 1,
  'colours': [
    {
      'id': 'test-001',
      'brand': 'Test Brand A',
      'name': 'Pure White',
      'code': 'TW-001',
      'hex': '#FFFFFF',
      'lrv': 95.0,
      'collection': 'Whites',
      'approximatePricePerLitre': 25.00,
    },
    {
      'id': 'test-002',
      'brand': 'Test Brand A',
      'name': 'Warm Cream',
      'code': 'TW-002',
      'hex': '#F5E6C8',
      'lrv': 78.0,
      'collection': 'Whites',
      'approximatePricePerLitre': 25.00,
    },
    {
      'id': 'test-003',
      'brand': 'Test Brand B',
      'name': 'Hague Blue',
      'code': 'TB-001',
      'hex': '#1A3A4A',
      'lrv': 8.0,
      'collection': 'Blues',
      'approximatePricePerLitre': 50.00,
    },
    {
      'id': 'test-004',
      'brand': 'Test Brand B',
      'name': 'Bright Red',
      'code': 'TB-002',
      'hex': '#FF0000',
      'lrv': 15.0,
      'collection': 'Reds',
      'approximatePricePerLitre': 50.00,
    },
    {
      'id': 'test-005',
      'brand': 'Test Brand A',
      'name': 'Forest Green',
      'code': 'TW-003',
      'hex': '#37503E',
      'lrv': 10.0,
      'collection': 'Greens',
      'approximatePricePerLitre': 25.00,
    },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PaletteDatabase db;
  late PaintColourRepository repo;
  late SeedDataService service;

  setUp(() {
    db = PaletteDatabase(NativeDatabase.memory());
    repo = PaintColourRepository(db);
    service = SeedDataService(db, repo);

    // Mock rootBundle to return our test JSON
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      if (key == 'assets/data/paint_colours.json') {
        return ByteData.sublistView(
          utf8.encode(json.encode(_testColoursJson)),
        );
      }
      return null;
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    await db.close();
  });

  group('seedIfNeeded', () {
    test('seeds data on first launch (empty DB)', () async {
      expect(await repo.count(), 0);

      final didSeed = await service.seedIfNeeded();

      expect(didSeed, isTrue);
      expect(await repo.count(), 5);
    });

    test('does not re-seed when data already exists', () async {
      await service.seedIfNeeded();
      expect(await repo.count(), 5);

      final didSeed = await service.seedIfNeeded();
      expect(didSeed, isFalse);
      expect(await repo.count(), 5);
    });
  });

  group('computed fields', () {
    setUp(() async {
      await service.seedIfNeeded();
    });

    test('Lab values are computed from hex at load time', () async {
      final white = await repo.getById('test-001');
      expect(white, isNotNull);
      // Pure white should have L* close to 100, a* and b* close to 0
      expect(white!.labL, closeTo(100.0, 1.0));
      expect(white.labA, closeTo(0.0, 1.0));
      expect(white.labB, closeTo(0.0, 1.0));
    });

    test('undertone is classified from Lab values', () async {
      // Warm cream (#F5E6C8) should classify as warm
      final warmCream = await repo.getById('test-002');
      expect(warmCream!.undertone, Undertone.warm);

      // Hague Blue (#1A3A4A) should classify as cool
      final hagueBlue = await repo.getById('test-003');
      expect(hagueBlue!.undertone, Undertone.cool);
    });

    test('palette family is classified from Lab values', () async {
      // Hague Blue is a dark colour (L* ~25 or below)
      final hagueBlue = await repo.getById('test-003');
      expect(hagueBlue!.paletteFamily, PaletteFamily.darks);

      // Pure white is a pastel (high L*, low chroma)
      final white = await repo.getById('test-001');
      expect(white!.paletteFamily, PaletteFamily.pastels);
    });

    test('brand and collection are preserved from JSON', () async {
      final colour = await repo.getById('test-004');
      expect(colour!.brand, 'Test Brand B');
      expect(colour.collection, 'Reds');
      expect(colour.approximatePricePerLitre, 50.00);
    });
  });

  group('reseed', () {
    test('clears and reloads data', () async {
      await service.seedIfNeeded();
      expect(await repo.count(), 5);

      await service.reseed();
      expect(await repo.count(), 5);
    });
  });
}
