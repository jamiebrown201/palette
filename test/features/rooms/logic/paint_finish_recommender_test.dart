import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/rooms/logic/paint_finish_recommender.dart';

void main() {
  group('Paint Finish Recommender', () {
    Room makeRoom({
      String name = 'Living Room',
      CompassDirection? direction = CompassDirection.south,
      RoomSize? roomSize = RoomSize.medium,
      double? width,
      double? length,
    }) {
      return Room(
        id: 'test-room',
        name: name,
        direction: direction,
        usageTime: UsageTime.evening,
        moods: const [RoomMood.calm],
        budget: BudgetBracket.midRange,
        heroColourHex: '#C2A17C',
        betaColourHex: null,
        surpriseColourHex: null,
        isRenterMode: false,
        sortOrder: 0,
        wallColourHex: null,
        roomSize: roomSize,
        widthMetres: width,
        lengthMetres: length,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    PaintColour makePaint({double lrv = 45, double? price}) {
      return PaintColour(
        id: 'test-paint',
        brand: 'Farrow & Ball',
        name: 'Savage Ground',
        code: 'SG',
        hex: '#C2A17C',
        labL: 68,
        labA: 5,
        labB: 22,
        lrv: lrv,
        undertone: Undertone.warm,
        paletteFamily: PaletteFamily.earthTones,
        cabStar: 25,
        chromaBand: ChromaBand.mid,
        collection: null,
        approximatePricePerLitre: price,
        priceLastChecked: null,
      );
    }

    test('living room gets matt walls, eggshell woodwork, matt ceiling', () {
      final room = makeRoom(name: 'Living Room');
      final plan = generatePaintPlan(room: room);

      expect(plan.finishRecommendations, hasLength(3));

      final walls = plan.finishRecommendations.firstWhere(
        (r) => r.surface == PaintSurface.walls,
      );
      expect(walls.finish, PaintFinish.matt);

      final woodwork = plan.finishRecommendations.firstWhere(
        (r) => r.surface == PaintSurface.woodwork,
      );
      expect(woodwork.finish, PaintFinish.eggshell);

      final ceiling = plan.finishRecommendations.firstWhere(
        (r) => r.surface == PaintSurface.ceiling,
      );
      expect(ceiling.finish, PaintFinish.matt);
    });

    test('kitchen gets satin walls', () {
      final room = makeRoom(name: 'Kitchen');
      final plan = generatePaintPlan(room: room);

      final walls = plan.finishRecommendations.firstWhere(
        (r) => r.surface == PaintSurface.walls,
      );
      expect(walls.finish, PaintFinish.satin);
      expect(walls.alternativeFinish, PaintFinish.softSheen);
    });

    test('bathroom gets satin walls with moisture reasoning', () {
      final room = makeRoom(name: 'Bathroom');
      final plan = generatePaintPlan(room: room);

      final walls = plan.finishRecommendations.firstWhere(
        (r) => r.surface == PaintSurface.walls,
      );
      expect(walls.finish, PaintFinish.satin);
      expect(walls.reason, contains('moisture'));
    });

    test('hallway gets eggshell walls for durability', () {
      final room = makeRoom(name: 'Hallway');
      final plan = generatePaintPlan(room: room);

      final walls = plan.finishRecommendations.firstWhere(
        (r) => r.surface == PaintSurface.walls,
      );
      expect(walls.finish, PaintFinish.eggshell);
      expect(walls.reason, contains('scuffs'));
    });

    test('nursery gets wipeable eggshell walls', () {
      final room = makeRoom(name: 'Nursery');
      final plan = generatePaintPlan(room: room);

      final walls = plan.finishRecommendations.firstWhere(
        (r) => r.surface == PaintSurface.walls,
      );
      expect(walls.finish, PaintFinish.eggshell);
      expect(walls.reason, contains('Wipeable'));
    });

    test('home office gets matt walls for glare reduction', () {
      final room = makeRoom(name: 'Home Office');
      final plan = generatePaintPlan(room: room);

      final walls = plan.finishRecommendations.firstWhere(
        (r) => r.surface == PaintSurface.walls,
      );
      expect(walls.finish, PaintFinish.matt);
      expect(walls.reason, contains('glare'));
    });

    test('north-facing room gets light direction note', () {
      final room = makeRoom(direction: CompassDirection.north);
      final plan = generatePaintPlan(room: room);

      expect(plan.lightDirectionNote, isNotNull);
      expect(plan.lightDirectionNote, contains('northern light'));
    });

    test('south-facing room gets southern light note', () {
      final room = makeRoom(direction: CompassDirection.south);
      final plan = generatePaintPlan(room: room);

      expect(plan.lightDirectionNote, isNotNull);
      expect(plan.lightDirectionNote, contains('southern light'));
    });

    test('no direction returns null light note', () {
      final room = makeRoom(direction: null);
      final plan = generatePaintPlan(room: room);

      expect(plan.lightDirectionNote, isNull);
    });

    test('dark colour in small room triggers LRV warning', () {
      final room = makeRoom(roomSize: RoomSize.small);
      final paint = makePaint(lrv: 15);
      final plan = generatePaintPlan(room: room, heroPaint: paint);

      expect(plan.colourNote, isNotNull);
      expect(plan.colourNote, contains('feature wall'));
    });

    test('light colour triggers finish note', () {
      final room = makeRoom();
      final paint = makePaint(lrv: 85);
      final plan = generatePaintPlan(room: room, heroPaint: paint);

      expect(plan.colourNote, isNotNull);
      expect(plan.colourNote, contains('matt'));
    });

    test('mid-LRV colour in normal room has no colour note', () {
      final room = makeRoom(roomSize: RoomSize.medium);
      final paint = makePaint(lrv: 50);
      final plan = generatePaintPlan(room: room, heroPaint: paint);

      expect(plan.colourNote, isNull);
    });
  });

  group('Paint Quantity Calculator', () {
    Room makeRoom({
      double? width,
      double? length,
      RoomSize? roomSize = RoomSize.medium,
    }) {
      return Room(
        id: 'test-room',
        name: 'Living Room',
        direction: CompassDirection.south,
        usageTime: UsageTime.evening,
        moods: const [RoomMood.calm],
        budget: BudgetBracket.midRange,
        heroColourHex: '#C2A17C',
        betaColourHex: null,
        surpriseColourHex: null,
        isRenterMode: false,
        sortOrder: 0,
        wallColourHex: null,
        roomSize: roomSize,
        widthMetres: width,
        lengthMetres: length,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    test('generates quantities for all three surfaces', () {
      final room = makeRoom(width: 4, length: 5);
      final plan = generatePaintPlan(room: room);

      expect(plan.quantities, contains(PaintSurface.walls));
      expect(plan.quantities, contains(PaintSurface.woodwork));
      expect(plan.quantities, contains(PaintSurface.ceiling));
    });

    test('wall quantity increases with room size', () {
      final small = makeRoom(width: 3, length: 3);
      final large = makeRoom(width: 6, length: 6);

      final smallPlan = generatePaintPlan(room: small);
      final largePlan = generatePaintPlan(room: large);

      expect(
        largePlan.quantities[PaintSurface.walls]!.litres,
        greaterThan(smallPlan.quantities[PaintSurface.walls]!.litres),
      );
    });

    test('ceiling quantity based on floor area', () {
      final room = makeRoom(width: 4, length: 5);
      final plan = generatePaintPlan(room: room);

      // 20m² floor = 20/12 * 2 coats = ~3.3L
      final ceiling = plan.quantities[PaintSurface.ceiling]!;
      expect(ceiling.litres, closeTo(3.33, 0.1));
    });

    test('fallback dimensions used when width/length not set', () {
      final room = makeRoom(roomSize: RoomSize.medium);
      final plan = generatePaintPlan(room: room);

      expect(plan.quantities[PaintSurface.walls]!.litres, greaterThan(0));
    });

    test('estimated cost calculated when price available', () {
      final room = makeRoom(width: 4, length: 5);
      const paint = PaintColour(
        id: 'test',
        brand: 'Dulux',
        name: 'Natural White',
        code: 'NW',
        hex: '#FAEBD7',
        labL: 92,
        labA: 2,
        labB: 10,
        lrv: 80,
        undertone: Undertone.warm,
        paletteFamily: PaletteFamily.warmNeutrals,
        cabStar: 10,
        chromaBand: ChromaBand.muted,
        collection: null,
        approximatePricePerLitre: 20,
        priceLastChecked: null,
      );
      final plan = generatePaintPlan(room: room, heroPaint: paint);

      final walls = plan.quantities[PaintSurface.walls]!;
      expect(walls.estimatedCost, isNotNull);
      expect(walls.estimatedCost, greaterThan(0));
    });

    test('no estimated cost when price not available', () {
      final room = makeRoom(width: 4, length: 5);
      final plan = generatePaintPlan(room: room);

      final walls = plan.quantities[PaintSurface.walls]!;
      expect(walls.estimatedCost, isNull);
    });

    test('tins needed is at least 1', () {
      final room = makeRoom(width: 2, length: 2);
      final plan = generatePaintPlan(room: room);

      for (final entry in plan.quantities.entries) {
        expect(entry.value.tinsNeeded, greaterThanOrEqualTo(1));
      }
    });
  });

  group('formatPaintListEntry', () {
    test('produces readable output', () {
      final result = formatPaintListEntry(
        paintName: 'Savage Ground',
        finish: PaintFinish.matt,
        surface: PaintSurface.walls,
        quantity: const PaintQuantity(
          litres: 4.5,
          tinSize: 2.5,
          tinsNeeded: 2,
          estimatedCost: 100,
        ),
        roomName: 'Living Room',
      );

      expect(result, contains('Savage Ground'));
      expect(result, contains('Matt Emulsion'));
      expect(result, contains('walls'));
      expect(result, contains('2.5L'));
      expect(result, contains('£100'));
    });
  });
}
