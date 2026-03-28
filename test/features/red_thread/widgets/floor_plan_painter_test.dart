import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palette/features/red_thread/logic/floor_plan_template.dart';
import 'package:palette/features/red_thread/widgets/floor_plan_painter.dart';

void main() {
  const template = FloorPlanTemplate(
    id: 'test',
    name: 'Test',
    propertyType: 'flat',
    propertyEra: 'modern',
    zones: [
      FloorPlanZone(
        id: 'living',
        name: 'Living Room',
        x: 0.0,
        y: 0.0,
        width: 0.5,
        height: 0.5,
      ),
      FloorPlanZone(
        id: 'kitchen',
        name: 'Kitchen',
        x: 0.5,
        y: 0.0,
        width: 0.5,
        height: 0.5,
      ),
      FloorPlanZone(
        id: 'bedroom',
        name: 'Bedroom',
        x: 0.0,
        y: 0.5,
        width: 1.0,
        height: 0.5,
      ),
    ],
    adjacencies: [('living', 'kitchen'), ('living', 'bedroom')],
  );

  group('FloorPlanPainter', () {
    test('shouldRepaint returns true when disconnectedZoneIds change', () {
      const painter1 = FloorPlanPainter(
        template: template,
        roomColours: {},
        threadHexes: [],
        disconnectedZoneIds: {},
      );

      const painter2 = FloorPlanPainter(
        template: template,
        roomColours: {},
        threadHexes: [],
        disconnectedZoneIds: {'bedroom'},
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns false when all fields are same', () {
      const painter1 = FloorPlanPainter(
        template: template,
        roomColours: {'living': '#C8B48C'},
        threadHexes: ['#C8B48C'],
        disconnectedZoneIds: {'bedroom'},
      );

      const painter2 = FloorPlanPainter(
        template: template,
        roomColours: {'living': '#C8B48C'},
        threadHexes: ['#C8B48C'],
        disconnectedZoneIds: {'bedroom'},
      );

      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('shouldRepaint returns true when roomColours change', () {
      const painter1 = FloorPlanPainter(
        template: template,
        roomColours: {'living': '#C8B48C'},
        threadHexes: [],
        disconnectedZoneIds: {},
      );

      const painter2 = FloorPlanPainter(
        template: template,
        roomColours: {'living': '#FF0000'},
        threadHexes: [],
        disconnectedZoneIds: {},
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    testWidgets('paints without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: CustomPaint(
                painter: FloorPlanPainter(
                  template: template,
                  roomColours: {'living': '#C8B48C', 'kitchen': '#8FAE8B'},
                  threadHexes: ['#C8B48C'],
                  disconnectedZoneIds: {'bedroom'},
                ),
              ),
            ),
          ),
        ),
      );

      // Verify it renders without errors
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('paints with empty data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: CustomPaint(
                painter: FloorPlanPainter(
                  template: template,
                  roomColours: {},
                  threadHexes: [],
                  disconnectedZoneIds: {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
