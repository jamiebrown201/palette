import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/repositories/paint_colour_repository.dart';

void main() {
  late PaletteDatabase db;
  late PaintColourRepository repo;

  setUp(() {
    db = PaletteDatabase(NativeDatabase.memory());
    repo = PaintColourRepository(db);
  });

  tearDown(() => db.close());

  PaintColoursCompanion companion({
    required String id,
    required String brand,
    required String name,
    required String hex,
    required double labL,
    required double labA,
    required double labB,
    String code = 'TEST',
    double lrv = 50,
    Undertone undertone = Undertone.neutral,
    PaletteFamily paletteFamily = PaletteFamily.warmNeutrals,
  }) {
    return PaintColoursCompanion.insert(
      id: id,
      brand: brand,
      name: name,
      code: code,
      hex: hex,
      labL: labL,
      labA: labA,
      labB: labB,
      lrv: lrv,
      undertone: undertone,
      paletteFamily: paletteFamily,
    );
  }

  group('basic CRUD', () {
    test('insertAll and getAll', () async {
      await repo.insertAll([
        companion(
          id: '1',
          brand: 'Farrow & Ball',
          name: 'Hague Blue',
          hex: '#1A3A4A',
          labL: 25,
          labA: -5,
          labB: -15,
        ),
        companion(
          id: '2',
          brand: 'Farrow & Ball',
          name: "Elephant's Breath",
          hex: '#B8A99A',
          labL: 70,
          labA: 3,
          labB: 8,
        ),
      ]);

      final all = await repo.getAll();
      expect(all, hasLength(2));
    });

    test('getById returns correct colour', () async {
      await repo.insertAll([
        companion(
          id: 'test-1',
          brand: 'Dulux',
          name: 'White Cotton',
          hex: '#F5F0E8',
          labL: 95,
          labA: 0,
          labB: 4,
        ),
      ]);

      final result = await repo.getById('test-1');
      expect(result, isNotNull);
      expect(result!.name, 'White Cotton');
      expect(result.brand, 'Dulux');
    });

    test('getById returns null for missing id', () async {
      final result = await repo.getById('nonexistent');
      expect(result, isNull);
    });

    test('count returns correct number', () async {
      expect(await repo.count(), 0);

      await repo.insertAll([
        companion(
          id: '1',
          brand: 'B',
          name: 'N1',
          hex: '#000000',
          labL: 0,
          labA: 0,
          labB: 0,
        ),
        companion(
          id: '2',
          brand: 'B',
          name: 'N2',
          hex: '#FFFFFF',
          labL: 100,
          labA: 0,
          labB: 0,
        ),
      ]);

      expect(await repo.count(), 2);
    });
  });

  group('filtering', () {
    setUp(() async {
      await repo.insertAll([
        companion(
          id: '1',
          brand: 'Farrow & Ball',
          name: 'Hague Blue',
          hex: '#1A3A4A',
          labL: 25,
          labA: -5,
          labB: -15,
          undertone: Undertone.cool,
          paletteFamily: PaletteFamily.darks,
        ),
        companion(
          id: '2',
          brand: 'Dulux',
          name: 'Egyptian Cotton',
          hex: '#F0E6D6',
          labL: 92,
          labA: 2,
          labB: 8,
          undertone: Undertone.warm,
          paletteFamily: PaletteFamily.warmNeutrals,
        ),
        companion(
          id: '3',
          brand: 'Farrow & Ball',
          name: 'Wimborne White',
          hex: '#F7F2E7',
          labL: 96,
          labA: 0,
          labB: 5,
          undertone: Undertone.warm,
          paletteFamily: PaletteFamily.warmNeutrals,
        ),
      ]);
    });

    test('getByBrand filters correctly', () async {
      final fb = await repo.getByBrand('Farrow & Ball');
      expect(fb, hasLength(2));

      final dulux = await repo.getByBrand('Dulux');
      expect(dulux, hasLength(1));
      expect(dulux.first.name, 'Egyptian Cotton');
    });

    test('getByFamily filters correctly', () async {
      final darks = await repo.getByFamily(PaletteFamily.darks);
      expect(darks, hasLength(1));
      expect(darks.first.name, 'Hague Blue');

      final warmNeutrals = await repo.getByFamily(PaletteFamily.warmNeutrals);
      expect(warmNeutrals, hasLength(2));
    });

    test('getByUndertone filters correctly', () async {
      final warm = await repo.getByUndertone(Undertone.warm);
      expect(warm, hasLength(2));

      final cool = await repo.getByUndertone(Undertone.cool);
      expect(cool, hasLength(1));
    });

    test('search finds partial name matches', () async {
      final results = await repo.search('blue');
      expect(results, hasLength(1));
      expect(results.first.name, 'Hague Blue');
    });

    test('search is case-insensitive', () async {
      final results = await repo.search('EGYPTIAN');
      expect(results, hasLength(1));
    });
  });

  group('delta-E matching', () {
    setUp(() async {
      await repo.insertAll([
        companion(
          id: 'white',
          brand: 'A',
          name: 'Pure White',
          hex: '#FFFFFF',
          labL: 100,
          labA: 0,
          labB: 0,
        ),
        companion(
          id: 'offwhite',
          brand: 'A',
          name: 'Off White',
          hex: '#FAF8F5',
          labL: 97.5,
          labA: 0.3,
          labB: 1.5,
        ),
        companion(
          id: 'black',
          brand: 'B',
          name: 'Pure Black',
          hex: '#000000',
          labL: 0,
          labA: 0,
          labB: 0,
        ),
        companion(
          id: 'red',
          brand: 'B',
          name: 'Bright Red',
          hex: '#FF0000',
          labL: 53.2,
          labA: 80.1,
          labB: 67.2,
        ),
      ]);
    });

    test('findClosestMatches returns closest colours first', () async {
      final matches = await repo.findClosestMatches('#FEFEFE', limit: 4);

      expect(matches, hasLength(4));
      // Pure white should be the closest match to #FEFEFE
      expect(matches.first.colour.name, 'Pure White');
      // Off white should be second
      expect(matches[1].colour.name, 'Off White');
      // Delta-E should be sorted ascending
      expect(matches.first.deltaE, lessThan(matches[1].deltaE));
    });

    test('findClosestMatches respects limit', () async {
      final matches = await repo.findClosestMatches('#FFFFFF', limit: 2);
      expect(matches, hasLength(2));
    });

    test('findClosestMatches respects brand filter', () async {
      final matches = await repo.findClosestMatches(
        '#FFFFFF',
        limit: 10,
        brandFilter: 'B',
      );

      expect(matches.every((m) => m.colour.brand == 'B'), isTrue);
    });

    test('findCrossBrandMatches finds equivalents', () async {
      final white = await repo.getById('white');
      final matches = await repo.findCrossBrandMatches(
        white!,
        threshold: 50,
      );

      // Should only include brand B colours
      expect(matches.every((m) => m.colour.brand == 'B'), isTrue);
      expect(matches.isNotEmpty, isTrue);
    });
  });
}
