import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/features/rooms/logic/seventy_twenty_ten.dart';

/// Create a test paint colour with known Lab values.
PaintColour _makePaint({
  required String id,
  required String hex,
  required double labL,
  required double labA,
  required double labB,
  Undertone undertone = Undertone.warm,
  PaletteFamily family = PaletteFamily.warmNeutrals,
}) {
  return PaintColour(
    id: id,
    brand: 'Test',
    name: 'Test $id',
    code: id,
    hex: hex,
    labL: labL,
    labA: labA,
    labB: labB,
    lrv: 50.0,
    undertone: undertone,
    paletteFamily: family,
  );
}

void main() {
  // A set of paint colours with diverse Lab values and families
  final testColours = <PaintColour>[
    // Warm neutrals (hero candidates)
    _makePaint(
      id: 'wn1',
      hex: '#D4C5B2',
      labL: 80.0,
      labA: 2.0,
      labB: 12.0,
      undertone: Undertone.warm,
      family: PaletteFamily.warmNeutrals,
    ),
    // Beta candidate: moderate delta-E from wn1
    _makePaint(
      id: 'wn2',
      hex: '#B8A78E',
      labL: 70.0,
      labA: 4.0,
      labB: 18.0,
      undertone: Undertone.warm,
      family: PaletteFamily.warmNeutrals,
    ),
    // Another warm neutral, close to hero
    _makePaint(
      id: 'wn3',
      hex: '#CFC0AD',
      labL: 78.0,
      labA: 3.0,
      labB: 14.0,
      undertone: Undertone.warm,
      family: PaletteFamily.warmNeutrals,
    ),
    // Jewel tone (complementary family for warm neutrals)
    _makePaint(
      id: 'jt1',
      hex: '#1A5276',
      labL: 35.0,
      labA: -5.0,
      labB: -30.0,
      undertone: Undertone.cool,
      family: PaletteFamily.jewelTones,
    ),
    // Another jewel tone
    _makePaint(
      id: 'jt2',
      hex: '#4A235A',
      labL: 25.0,
      labA: 20.0,
      labB: -25.0,
      undertone: Undertone.cool,
      family: PaletteFamily.jewelTones,
    ),
    // Earth tone (different family)
    _makePaint(
      id: 'et1',
      hex: '#7B5E3F',
      labL: 45.0,
      labA: 10.0,
      labB: 25.0,
      undertone: Undertone.warm,
      family: PaletteFamily.earthTones,
    ),
    // Pastel (different family)
    _makePaint(
      id: 'ps1',
      hex: '#E8D5E3',
      labL: 88.0,
      labA: 8.0,
      labB: -5.0,
      undertone: Undertone.neutral,
      family: PaletteFamily.pastels,
    ),
    // Cool neutral
    _makePaint(
      id: 'cn1',
      hex: '#B0B5B8',
      labL: 73.0,
      labA: -1.0,
      labB: -3.0,
      undertone: Undertone.cool,
      family: PaletteFamily.coolNeutrals,
    ),
  ];

  group('generateColourPlan', () {
    test('generates a plan with hero, beta, and surprise', () {
      final plan = generateColourPlan(
        heroColour: testColours[0], // wn1
        allPaintColours: testColours,
        random: Random(42),
      );

      expect(plan, isNotNull);
      expect(plan!.heroColour.id, 'wn1');
      expect(plan.betaColour.id, isNot('wn1'));
      expect(plan.surpriseColour.id, isNot('wn1'));
      expect(plan.surpriseColour.id, isNot(plan.betaColour.id));
    });

    test('surprise colour is from a different family than hero', () {
      final plan = generateColourPlan(
        heroColour: testColours[0], // warmNeutrals
        allPaintColours: testColours,
        random: Random(42),
      );

      expect(plan, isNotNull);
      expect(plan!.surpriseColour.paletteFamily,
          isNot(PaletteFamily.warmNeutrals));
    });

    test('dash colour is present when red thread hexes provided', () {
      final plan = generateColourPlan(
        heroColour: testColours[0],
        allPaintColours: testColours,
        redThreadHexes: ['#4A235A'], // Close to jt2
        random: Random(42),
      );

      expect(plan, isNotNull);
      expect(plan!.dashColour, isNotNull);
    });

    test('dash colour is null when no red thread hexes', () {
      final plan = generateColourPlan(
        heroColour: testColours[0],
        allPaintColours: testColours,
        random: Random(42),
      );

      expect(plan, isNotNull);
      expect(plan!.dashColour, isNull);
    });

    test('respects light direction for beta undertone filtering', () {
      // North-facing should prefer warm undertones for beta
      final plan = generateColourPlan(
        heroColour: testColours[0],
        allPaintColours: testColours,
        direction: CompassDirection.north,
        usageTime: UsageTime.allDay,
        random: Random(42),
      );

      expect(plan, isNotNull);
      // Beta should be warm or neutral (not cool, since north prefers warm)
      expect(plan!.betaColour.undertone, isNot(Undertone.cool));
    });

    test('returns null when no beta candidates available', () {
      // Only the hero colour exists
      final plan = generateColourPlan(
        heroColour: testColours[0],
        allPaintColours: [testColours[0]],
        random: Random(42),
      );

      expect(plan, isNull);
    });

    test('returns null when no surprise candidates available', () {
      // Only warm neutrals — no other family for surprise
      final sameFamily = [
        testColours[0], // wn1
        testColours[1], // wn2
        testColours[2], // wn3
      ];

      final plan = generateColourPlan(
        heroColour: sameFamily[0],
        allPaintColours: sameFamily,
        random: Random(42),
      );

      expect(plan, isNull);
    });

    test('all plan colours are distinct', () {
      final plan = generateColourPlan(
        heroColour: testColours[0],
        allPaintColours: testColours,
        redThreadHexes: ['#4A235A'],
        random: Random(42),
      );

      expect(plan, isNotNull);
      final ids = {
        plan!.heroColour.id,
        plan.betaColour.id,
        plan.surpriseColour.id,
      };
      expect(ids.length, 3, reason: 'Hero, beta, surprise should be distinct');

      if (plan.dashColour != null) {
        ids.add(plan.dashColour!.id);
        expect(ids.length, 4,
            reason: 'Dash should be distinct from other tiers');
      }
    });

    test('deterministic with fixed seed', () {
      final plan1 = generateColourPlan(
        heroColour: testColours[0],
        allPaintColours: testColours,
        random: Random(99),
      );
      final plan2 = generateColourPlan(
        heroColour: testColours[0],
        allPaintColours: testColours,
        random: Random(99),
      );

      expect(plan1, isNotNull);
      expect(plan2, isNotNull);
      expect(plan1!.betaColour.id, plan2!.betaColour.id);
      expect(plan1.surpriseColour.id, plan2.surpriseColour.id);
    });
  });
}
