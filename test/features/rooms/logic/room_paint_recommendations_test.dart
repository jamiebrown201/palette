import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/rooms/logic/room_paint_recommendations.dart';

void main() {
  final now = DateTime.now();

  PaintColour makePaint({
    required String name,
    required String brand,
    required String hex,
    required double labL,
    required double labA,
    required double labB,
    Undertone undertone = Undertone.warm,
    double? pricePerLitre,
  }) {
    return PaintColour(
      id: name.toLowerCase().replaceAll(' ', '-'),
      brand: brand,
      name: name,
      code: name,
      hex: hex,
      labL: labL,
      labA: labA,
      labB: labB,
      lrv: 50,
      undertone: undertone,
      paletteFamily: PaletteFamily.warmNeutrals,
      cabStar: 20,
      chromaBand: ChromaBand.mid,
      approximatePricePerLitre: pricePerLitre,
    );
  }

  Room makeRoom({
    String? heroColourHex,
    CompassDirection? direction,
    UsageTime usageTime = UsageTime.allDay,
    BudgetBracket budget = BudgetBracket.midRange,
  }) {
    return Room(
      id: 'room-1',
      name: 'Living Room',
      usageTime: usageTime,
      moods: [RoomMood.calm],
      budget: budget,
      isRenterMode: false,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
      direction: direction,
      heroColourHex: heroColourHex,
    );
  }

  group('computeRoomPaintRecommendations', () {
    test('returns empty list when room has no hero colour', () {
      final result = computeRoomPaintRecommendations(
        allPaints: [
          makePaint(
            name: 'Warm Beige',
            brand: 'TestBrand',
            hex: '#D4C4A8',
            labL: 80,
            labA: 3,
            labB: 15,
          ),
        ],
        room: makeRoom(heroColourHex: null),
      );

      expect(result, isEmpty);
    });

    test('returns matching paints sorted by score', () {
      // Hero is a warm beige — Lab(80, 3, 15)
      final paints = [
        makePaint(
          name: 'Close Match',
          brand: 'BrandA',
          hex: '#D4C4A8',
          labL: 80,
          labA: 3,
          labB: 15,
          undertone: Undertone.warm,
        ),
        makePaint(
          name: 'Distant Colour',
          brand: 'BrandB',
          hex: '#2244AA',
          labL: 30,
          labA: 10,
          labB: -50,
          undertone: Undertone.cool,
        ),
        makePaint(
          name: 'Moderate Match',
          brand: 'BrandC',
          hex: '#C8B89C',
          labL: 76,
          labA: 4,
          labB: 14,
          undertone: Undertone.warm,
        ),
      ];

      final result = computeRoomPaintRecommendations(
        allPaints: paints,
        room: makeRoom(
          heroColourHex: '#D4C4A8',
          direction: CompassDirection.north,
        ),
      );

      // Distant colour (delta-E > 30) should be filtered out
      expect(result.length, 2);
      // Close match should score highest
      expect(result.first.paint.name, 'Close Match');
    });

    test('respects budget bracket filter', () {
      final paints = [
        makePaint(
          name: 'Cheap Paint',
          brand: 'BrandA',
          hex: '#D4C4A8',
          labL: 80,
          labA: 3,
          labB: 15,
          pricePerLitre: 15,
        ),
        makePaint(
          name: 'Expensive Paint',
          brand: 'BrandB',
          hex: '#D4C4A8',
          labL: 80,
          labA: 3,
          labB: 15,
          pricePerLitre: 60,
        ),
      ];

      final result = computeRoomPaintRecommendations(
        allPaints: paints,
        room: makeRoom(
          heroColourHex: '#D4C4A8',
          budget: BudgetBracket.affordable,
        ),
      );

      // Expensive paint (£60/L) should be excluded for affordable budget (max £25/L)
      expect(result.length, 1);
      expect(result.first.paint.name, 'Cheap Paint');
    });

    test('limits results to requested count', () {
      final paints = List.generate(
        10,
        (i) => makePaint(
          name: 'Paint $i',
          brand: 'Brand$i',
          hex: '#D4C4A8',
          labL: 80 - i.toDouble(),
          labA: 3,
          labB: 15,
        ),
      );

      final result = computeRoomPaintRecommendations(
        allPaints: paints,
        room: makeRoom(heroColourHex: '#D4C4A8'),
        limit: 4,
      );

      expect(result.length, 4);
    });

    test('limits to 2 per brand for variety', () {
      final paints = List.generate(
        5,
        (i) => makePaint(
          name: 'SameBrand Paint $i',
          brand: 'SameBrand',
          hex: '#D4C4A8',
          labL: 80 - i.toDouble(),
          labA: 3,
          labB: 15,
        ),
      );

      final result = computeRoomPaintRecommendations(
        allPaints: paints,
        room: makeRoom(heroColourHex: '#D4C4A8'),
        limit: 4,
      );

      expect(result.length, 2);
    });

    test('undertone boost for direction-compatible paints', () {
      // North-facing room prefers warm undertones
      final warmPaint = makePaint(
        name: 'Warm Paint',
        brand: 'BrandA',
        hex: '#D4C4A8',
        labL: 78,
        labA: 5,
        labB: 16,
        undertone: Undertone.warm,
      );
      final coolPaint = makePaint(
        name: 'Cool Paint',
        brand: 'BrandB',
        hex: '#C4C8D4',
        labL: 78,
        labA: -2,
        labB: -8,
        undertone: Undertone.cool,
      );

      final result = computeRoomPaintRecommendations(
        allPaints: [coolPaint, warmPaint],
        room: makeRoom(
          heroColourHex: '#D4C4A8',
          direction: CompassDirection.north,
        ),
      );

      // Warm paint should score higher for north-facing room
      expect(result.isNotEmpty, true);
      expect(result.first.paint.name, 'Warm Paint');
    });

    test('reason includes direction context when available', () {
      final result = computeRoomPaintRecommendations(
        allPaints: [
          makePaint(
            name: 'Warm Beige',
            brand: 'BrandA',
            hex: '#D4C4A8',
            labL: 80,
            labA: 3,
            labB: 15,
            undertone: Undertone.warm,
          ),
        ],
        room: makeRoom(
          heroColourHex: '#D4C4A8',
          direction: CompassDirection.north,
        ),
      );

      expect(result, isNotEmpty);
      expect(result.first.reason, contains('north-facing'));
    });
  });
}
