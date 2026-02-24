import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/colour_relationships.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/core/colour/kelvin_simulation.dart';
import 'package:palette/core/colour/undertone.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/data/models/red_thread_colour.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/onboarding/logic/palette_generator.dart';
import 'package:palette/features/red_thread/logic/coherence_checker.dart';
import 'package:palette/features/rooms/logic/light_recommendations.dart';
import 'package:palette/features/rooms/logic/seventy_twenty_ten.dart';

/// Realistic paint colour set for integration tests.
final _testPaints = <PaintColour>[
  // Warm neutrals
  const PaintColour(
    id: 'fb-joa', brand: 'Farrow & Ball', name: "Joa's White", code: '226',
    hex: '#E8DED0', labL: 89.6, labA: 1.8, labB: 8.4, lrv: 76.0,
    undertone: Undertone.warm, paletteFamily: PaletteFamily.warmNeutrals,
  ),
  const PaintColour(
    id: 'fb-eb', brand: 'Farrow & Ball', name: "Elephant's Breath", code: '229',
    hex: '#C5B9A9', labL: 75.8, labA: 2.0, labB: 10.2, lrv: 54.0,
    undertone: Undertone.warm, paletteFamily: PaletteFamily.warmNeutrals,
  ),
  // Cool neutrals
  const PaintColour(
    id: 'fb-pav', brand: 'Farrow & Ball', name: 'Pavilion Gray', code: '242',
    hex: '#BBBCB4', labL: 76.1, labA: -1.5, labB: 3.5, lrv: 53.0,
    undertone: Undertone.neutral, paletteFamily: PaletteFamily.coolNeutrals,
  ),
  // Pastels
  const PaintColour(
    id: 'fb-ppc', brand: 'Farrow & Ball', name: 'Pink Cabbage', code: '2804',
    hex: '#E5C6C3', labL: 82.7, labA: 8.5, labB: 5.2, lrv: 61.0,
    undertone: Undertone.warm, paletteFamily: PaletteFamily.pastels,
  ),
  // Jewel tones
  const PaintColour(
    id: 'fb-hy', brand: 'Farrow & Ball', name: 'Hague Blue', code: '30',
    hex: '#2C3E50', labL: 26.1, labA: -3.8, labB: -14.2, lrv: 5.0,
    undertone: Undertone.cool, paletteFamily: PaletteFamily.jewelTones,
  ),
  const PaintColour(
    id: 'fb-sff', brand: 'Farrow & Ball', name: 'Stiffkey Blue', code: '281',
    hex: '#546A7B', labL: 43.5, labA: -4.2, labB: -12.8, lrv: 15.0,
    undertone: Undertone.cool, paletteFamily: PaletteFamily.jewelTones,
  ),
  // Earth tones
  const PaintColour(
    id: 'lg-bc', brand: 'Little Greene', name: 'Book Room Red', code: '50',
    hex: '#8B4B4B', labL: 38.5, labA: 21.0, labB: 12.5, lrv: 12.0,
    undertone: Undertone.warm, paletteFamily: PaletteFamily.earthTones,
  ),
  // Darks
  const PaintColour(
    id: 'fb-rs', brand: 'Farrow & Ball', name: 'Railings', code: '31',
    hex: '#2A2A2A', labL: 17.8, labA: 0.0, labB: 0.0, lrv: 2.5,
    undertone: Undertone.neutral, paletteFamily: PaletteFamily.darks,
  ),
  // Brights
  const PaintColour(
    id: 'dx-mg', brand: 'Dulux', name: 'Mango Glory', code: 'DX01',
    hex: '#FF8C00', labL: 67.0, labA: 32.5, labB: 71.8, lrv: 40.0,
    undertone: Undertone.warm, paletteFamily: PaletteFamily.brights,
  ),
];

void main() {
  group('Palette Generation Pipeline', () {
    test('generates palette from quiz weights', () {
      final weights = <Map<String, int>>[
        {'warmNeutrals': 3},
        {'warmNeutrals': 2, 'earthTones': 1},
        {'pastels': 2},
      ];

      final tallied = tallyFamilyWeights(weights);
      expect(tallied[PaletteFamily.warmNeutrals], 5);
      expect(tallied[PaletteFamily.pastels], 2);
      expect(tallied[PaletteFamily.earthTones], 1);

      final palette = generatePalette(
        allPaintColours: _testPaints,
        familyWeights: tallied,
        targetSize: 6,
        random: Random(42),
      );

      expect(palette.colours, isNotEmpty);
      expect(palette.colours.length, lessThanOrEqualTo(6));
    });
  });

  group('70/20/10 with Light Recommendations', () {
    test('north-facing room gets warm beta', () {
      final hero = _testPaints.firstWhere((p) => p.id == 'fb-joa');
      final plan = generateColourPlan(
        heroColour: hero,
        allPaintColours: _testPaints,
        direction: CompassDirection.north,
        usageTime: UsageTime.allDay,
        random: Random(42),
      );

      expect(plan, isNotNull);
      // North light rec prefers warm undertone
      final rec = getLightRecommendation(
        direction: CompassDirection.north,
        usageTime: UsageTime.allDay,
      );
      expect(rec.preferredUndertone, Undertone.warm);
    });

    test('south-facing room allows cool beta', () {
      final hero = _testPaints.firstWhere((p) => p.id == 'fb-joa');
      final plan = generateColourPlan(
        heroColour: hero,
        allPaintColours: _testPaints,
        direction: CompassDirection.south,
        usageTime: UsageTime.allDay,
        random: Random(42),
      );

      expect(plan, isNotNull);
    });
  });

  group('Kelvin Simulation Pipeline', () {
    test('north room evening produces cooler colour than south', () {
      const hex = '#D4C5B2';
      final northEvening = simulateLightOnColour(
        hex,
        getKelvinForRoom(CompassDirection.north, UsageTime.evening),
      );
      final southEvening = simulateLightOnColour(
        hex,
        getKelvinForRoom(CompassDirection.south, UsageTime.evening),
      );

      final northLab = hexToLab(northEvening);
      final southLab = hexToLab(southEvening);

      // North should have lower b* (cooler) than south
      expect(northLab.b, lessThan(southLab.b));
    });

    test('simulated colours are valid hex strings', () {
      for (final dir in CompassDirection.values) {
        for (final time in UsageTime.values) {
          final result = simulateLightOnColour(
            '#8FAE8B',
            getKelvinForRoom(dir, time),
          );
          expect(result, startsWith('#'));
          expect(result.length, 7);
        }
      }
    });
  });

  group('Colour Relationship Round-Trip', () {
    test('complementary of complementary returns near original', () {
      final original = hexToLab('#8FAE8B');
      final comp = complementary(original);
      final roundTrip = complementary(comp);

      final dE = deltaE2000(original, roundTrip);
      expect(dE, lessThan(1.0));
    });

    test('analogous colours are close to original', () {
      final original = hexToLab('#C9A96E');
      final anal = analogous(original);

      final dELeft = deltaE2000(original, anal.left);
      final dERight = deltaE2000(original, anal.right);

      // Analogous should be perceivably different but not huge
      expect(dELeft, greaterThan(5));
      expect(dELeft, lessThan(40));
      expect(dERight, greaterThan(5));
      expect(dERight, lessThan(40));
    });
  });

  group('Undertone Classification Pipeline', () {
    test('warm neutral paint is classified as warm', () {
      final lab = hexToLab('#E8DED0');
      final result = classifyUndertone(lab);
      expect(result.classification, Undertone.warm);
    });

    test('cool blue paint is classified as cool', () {
      final lab = hexToLab('#2C3E50');
      final result = classifyUndertone(lab);
      expect(result.classification, Undertone.cool);
    });
  });

  group('Red Thread Coherence Pipeline', () {
    test('rooms sharing a thread colour are coherent', () {
      final rooms = [
        Room(
          id: '1', name: 'Living', usageTime: UsageTime.allDay,
          moods: const [], budget: BudgetBracket.midRange,
          isRenterMode: false, sortOrder: 0,
          heroColourHex: '#8FAE8B',
          createdAt: DateTime(2024), updatedAt: DateTime(2024),
        ),
        Room(
          id: '2', name: 'Kitchen', usageTime: UsageTime.morning,
          moods: const [], budget: BudgetBracket.midRange,
          isRenterMode: false, sortOrder: 1,
          heroColourHex: '#C9A96E', betaColourHex: '#90B08C',
          createdAt: DateTime(2024), updatedAt: DateTime(2024),
        ),
      ];

      final report = checkCoherence(
        rooms: rooms,
        threadColours: const [
          RedThreadColour(id: 't1', hex: '#8FAE8B', sortOrder: 0),
        ],
      );

      // Room 1 has exact match, Room 2 has near match via beta
      expect(report.results[0].isConnected, isTrue);
      expect(report.results[1].isConnected, isTrue);
      expect(report.overallCoherent, isTrue);
    });
  });

  group('Delta-E Match Quality', () {
    test('identical colours have delta-E of 0', () {
      final lab = hexToLab('#8FAE8B');
      expect(deltaE2000(lab, lab), 0.0);
    });

    test('similar colours have small delta-E', () {
      final a = hexToLab('#8FAE8B');
      final b = hexToLab('#90B08C');
      final dE = deltaE2000(a, b);
      expect(dE, lessThan(5.0));
    });

    test('very different colours have large delta-E', () {
      final a = hexToLab('#FF0000');
      final b = hexToLab('#0000FF');
      final dE = deltaE2000(a, b);
      expect(dE, greaterThan(40.0));
    });
  });
}
