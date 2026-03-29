import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/locked_furniture.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/rooms/logic/renovation_sequencing.dart';

Room _makeRoom({
  String name = 'Living Room',
  bool isRenterMode = false,
  String? heroColourHex,
  String? wallColourHex,
}) {
  return Room(
    id: 'r1',
    name: name,
    usageTime: UsageTime.evening,
    moods: const [RoomMood.calm],
    budget: BudgetBracket.midRange,
    isRenterMode: isRenterMode,
    sortOrder: 0,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    direction: CompassDirection.south,
    heroColourHex: heroColourHex,
    wallColourHex: wallColourHex,
    roomSize: RoomSize.medium,
  );
}

LockedFurniture _makeFurniture({
  String name = 'Sofa',
  FurnitureCategory category = FurnitureCategory.sofa,
  FurnitureStatus? status,
}) {
  return LockedFurniture(
    id: 'f-${name.hashCode}',
    roomId: 'r1',
    name: name,
    colourHex: '#8B4513',
    role: FurnitureRole.hero,
    sortOrder: 0,
    category: category,
    status: status,
  );
}

void main() {
  group('generateRenovationGuide', () {
    test('generates steps for an owner room', () {
      final guide = generateRenovationGuide(room: _makeRoom(), furniture: []);

      expect(guide.roomName, 'Living Room');
      expect(guide.steps, isNotEmpty);
      // Owners should have structural + ceiling + walls + woodwork steps
      final titles = guide.steps.map((s) => s.title).toList();
      expect(titles, contains('Fix structural issues'));
      expect(titles, contains('Paint the ceiling'));
      expect(titles, contains('Paint the walls'));
      expect(titles, contains('Paint woodwork and trim'));
    });

    test('renter mode skips paint and structural steps', () {
      final guide = generateRenovationGuide(
        room: _makeRoom(isRenterMode: true),
        furniture: [],
      );

      final titles = guide.steps.map((s) => s.title).toList();
      expect(titles, isNot(contains('Fix structural issues')));
      expect(titles, isNot(contains('Paint the ceiling')));
      expect(titles, isNot(contains('Paint the walls')));
      expect(titles, isNot(contains('Paint woodwork and trim')));
      expect(titles, contains('Identify your wall colour'));
    });

    test('renter with identified wall colour shows done status', () {
      final guide = generateRenovationGuide(
        room: _makeRoom(isRenterMode: true, wallColourHex: '#F5F0E8'),
        furniture: [],
      );

      final wallStep = guide.steps.firstWhere(
        (s) => s.title == 'Identify your wall colour',
      );
      expect(wallStep.status, RenovationStepStatus.done);
    });

    test('locked furniture marks relevant steps as done', () {
      final guide = generateRenovationGuide(
        room: _makeRoom(),
        furniture: [
          _makeFurniture(name: 'Sofa', category: FurnitureCategory.sofa),
          _makeFurniture(
            name: 'Floor Lamp',
            category: FurnitureCategory.lighting,
          ),
          _makeFurniture(name: 'Rug', category: FurnitureCategory.rug),
        ],
      );

      final large = guide.steps.firstWhere(
        (s) => s.title == 'Place large furniture',
      );
      expect(large.status, RenovationStepStatus.done);

      final lighting = guide.steps.firstWhere(
        (s) => s.title == 'Set up lighting layers',
      );
      expect(lighting.status, RenovationStepStatus.done);

      final floor = guide.steps.firstWhere(
        (s) => s.title.contains('flooring') || s.title.contains('floor'),
      );
      expect(floor.status, RenovationStepStatus.done);
    });

    test('hero colour sets paint step to in-progress for owners', () {
      final guide = generateRenovationGuide(
        room: _makeRoom(heroColourHex: '#A67B5B'),
        furniture: [],
      );

      final paintStep = guide.steps.firstWhere(
        (s) => s.title == 'Paint the walls',
      );
      expect(paintStep.status, RenovationStepStatus.inProgress);
    });

    test('completedCount matches done steps', () {
      final guide = generateRenovationGuide(
        room: _makeRoom(),
        furniture: [
          _makeFurniture(name: 'Sofa', category: FurnitureCategory.sofa),
          _makeFurniture(name: 'Rug', category: FurnitureCategory.rug),
        ],
      );

      final doneSteps = guide.steps.where(
        (s) => s.status == RenovationStepStatus.done,
      );
      expect(guide.completedCount, doneSteps.length);
    });

    test('property note includes Victorian guidance', () {
      final guide = generateRenovationGuide(
        room: _makeRoom(),
        furniture: [],
        propertyEra: PropertyEra.victorian,
      );

      expect(guide.propertyNote, isNotNull);
      expect(guide.propertyNote, contains('Victorian'));
    });

    test('property note includes flat guidance', () {
      final guide = generateRenovationGuide(
        room: _makeRoom(),
        furniture: [],
        propertyType: PropertyType.flat,
      );

      expect(guide.propertyNote, isNotNull);
      expect(guide.propertyNote, contains('flat'));
    });

    test('renter steps include renter notes', () {
      final guide = generateRenovationGuide(
        room: _makeRoom(isRenterMode: true),
        furniture: [],
      );

      final stepsWithRenterNotes = guide.steps.where(
        (s) => s.renterNote != null,
      );
      expect(stepsWithRenterNotes, isNotEmpty);
    });

    test('all steps have sequential order numbers', () {
      final guide = generateRenovationGuide(room: _makeRoom(), furniture: []);

      for (var i = 0; i < guide.steps.length; i++) {
        expect(guide.steps[i].order, i + 1);
      }
    });

    test('renter guide has fewer steps than owner guide', () {
      final ownerGuide = generateRenovationGuide(
        room: _makeRoom(isRenterMode: false),
        furniture: [],
      );
      final renterGuide = generateRenovationGuide(
        room: _makeRoom(isRenterMode: true),
        furniture: [],
      );

      expect(renterGuide.totalCount, lessThan(ownerGuide.totalCount));
    });

    test('kitchen room gets correct paint finish tip', () {
      final guide = generateRenovationGuide(
        room: _makeRoom(name: 'Kitchen'),
        furniture: [],
      );

      final paintStep = guide.steps.firstWhere(
        (s) => s.title == 'Paint the walls',
      );
      expect(paintStep.tip, contains('satin'));
    });

    test('tenure parameter overrides room renter mode', () {
      final guide = generateRenovationGuide(
        room: _makeRoom(isRenterMode: false),
        furniture: [],
        tenure: Tenure.renter,
      );

      final titles = guide.steps.map((s) => s.title).toList();
      expect(titles, contains('Identify your wall colour'));
      expect(titles, isNot(contains('Paint the ceiling')));
    });

    test('progressPercent returns correct value', () {
      final guide = generateRenovationGuide(
        room: _makeRoom(),
        furniture: [
          _makeFurniture(name: 'Sofa', category: FurnitureCategory.sofa),
        ],
      );

      expect(guide.progressPercent, greaterThan(0));
      expect(guide.progressPercent, lessThanOrEqualTo(1.0));
      expect(
        guide.progressPercent,
        closeTo(guide.completedCount / guide.totalCount, 0.01),
      );
    });
  });
}
