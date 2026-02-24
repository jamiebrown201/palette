import 'package:flutter_test/flutter_test.dart';
import 'package:palette/features/red_thread/logic/floor_plan_template.dart';

void main() {
  group('FloorPlanTemplate', () {
    test('parses from JSON correctly', () {
      final json = {
        'id': 'test_house',
        'name': 'Test House',
        'propertyType': 'terraced',
        'propertyEra': 'victorian',
        'zones': [
          {
            'id': 'hallway',
            'name': 'Hallway',
            'x': 0.4,
            'y': 0.0,
            'width': 0.2,
            'height': 0.5,
          },
          {
            'id': 'kitchen',
            'name': 'Kitchen',
            'x': 0.0,
            'y': 0.5,
            'width': 0.5,
            'height': 0.5,
          },
        ],
        'adjacencies': [
          ['hallway', 'kitchen'],
        ],
      };

      final template = FloorPlanTemplate.fromJson(json);

      expect(template.id, 'test_house');
      expect(template.name, 'Test House');
      expect(template.propertyType, 'terraced');
      expect(template.propertyEra, 'victorian');
      expect(template.zones.length, 2);
      expect(template.adjacencies.length, 1);
    });

    test('zone parses position and size', () {
      final json = {
        'id': 'room',
        'name': 'Room',
        'x': 0.1,
        'y': 0.2,
        'width': 0.3,
        'height': 0.4,
      };

      final zone = FloorPlanZone.fromJson(json);

      expect(zone.id, 'room');
      expect(zone.name, 'Room');
      expect(zone.x, 0.1);
      expect(zone.y, 0.2);
      expect(zone.width, 0.3);
      expect(zone.height, 0.4);
    });

    test('adjacencies are tuples of zone IDs', () {
      final json = {
        'id': 'test',
        'name': 'Test',
        'propertyType': 'flat',
        'propertyEra': 'modern',
        'zones': <Map<String, dynamic>>[],
        'adjacencies': [
          ['a', 'b'],
          ['b', 'c'],
        ],
      };

      final template = FloorPlanTemplate.fromJson(json);

      expect(template.adjacencies.length, 2);
      expect(template.adjacencies[0].$1, 'a');
      expect(template.adjacencies[0].$2, 'b');
      expect(template.adjacencies[1].$1, 'b');
      expect(template.adjacencies[1].$2, 'c');
    });

    test('handles integer x/y/width/height values', () {
      final json = {
        'id': 'room',
        'name': 'Room',
        'x': 0,
        'y': 1,
        'width': 1,
        'height': 1,
      };

      final zone = FloorPlanZone.fromJson(json);

      expect(zone.x, 0.0);
      expect(zone.y, 1.0);
    });
  });
}
