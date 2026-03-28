import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/colour/lab_colour.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/features/rooms/logic/colour_plan_harmony.dart';

void main() {
  group('analyseColourPlanHarmony', () {
    test('detects complementary relationship', () {
      // Red hero + cyan beta ≈ opposite on colour wheel (hue diff ~167°)
      final result = analyseColourPlanHarmony(
        heroHex: '#C04040',
        betaHex: '#40C0C0',
      );
      expect(result.verdict, contains('Complementary'));
      expect(result.relationships, isNotEmpty);
      expect(result.relationships.first.type, ColourRelationship.complementary);
      expect(result.explanation, contains('opposite'));
    });

    test('detects analogous relationship', () {
      // Warm beige + earthy brown ≈ close hues
      final result = analyseColourPlanHarmony(
        heroHex: '#C4A882',
        betaHex: '#B89060',
      );
      expect(result.verdict, contains('Analogous'));
      expect(result.relationships, isNotEmpty);
      expect(result.relationships.first.type, ColourRelationship.analogous);
      expect(result.explanation, contains('next to each other'));
    });

    test('warns about near-duplicate colours', () {
      // Two very similar beige colours
      final result = analyseColourPlanHarmony(
        heroHex: '#C4A882',
        betaHex: '#C5A983',
      );
      expect(result.warning, isNotNull);
      expect(result.warning, contains('similar'));
    });

    test('warns about bold unrecognised combinations', () {
      // Very different colours with no standard relationship
      final result = analyseColourPlanHarmony(
        heroHex: '#F5DEB3', // pale wheat
        betaHex: '#2B3A67', // dark navy
      );
      // Should either find a relationship or produce a bold warning
      expect(
        result.relationships.isNotEmpty || result.warning != null,
        isTrue,
        reason: 'Should detect a relationship or warn about bold combination',
      );
    });

    test('works with only hero and beta (no surprise)', () {
      final result = analyseColourPlanHarmony(
        heroHex: '#C04040',
        betaHex: '#4080A0',
      );
      expect(result.verdict, isNotEmpty);
      expect(result.explanation, isNotEmpty);
    });

    test('works with only hero and surprise (no beta)', () {
      final result = analyseColourPlanHarmony(
        heroHex: '#C04040',
        surpriseHex: '#40C040',
      );
      expect(result.verdict, isNotEmpty);
      expect(result.explanation, isNotEmpty);
    });

    test('returns getting started when neither beta nor surprise set', () {
      final result = analyseColourPlanHarmony(heroHex: '#C04040');
      expect(result.verdict, 'Getting started');
    });

    test('analyses all three colours together', () {
      final result = analyseColourPlanHarmony(
        heroHex: '#C04040',
        betaHex: '#4080A0',
        surpriseHex: '#40C040',
      );
      expect(result.verdict, isNotEmpty);
      // With 3 colours there should be 3 pairwise comparisons possible
      // (hero-beta, hero-surprise, beta-surprise)
      expect(result.explanation, isNotEmpty);
    });
  });

  group('classifyHuePair', () {
    test('detects complementary (hue diff ~180)', () {
      // Manually construct labs with known hue angles
      // Red (a=50,b=0) → hue ~0°, Cyan (a=-50,b=0) → hue ~180°
      final result = classifyHuePair(
        const LabColour(50, 50, 0), // hue ≈ 0°
        const LabColour(50, -50, 0), // hue ≈ 180°
      );
      expect(result, ColourRelationship.complementary);
    });

    test('detects analogous (hue diff < 35)', () {
      // Two warm colours with similar hue
      final result = classifyHuePair(
        const LabColour(60, 20, 30), // warm
        const LabColour(55, 15, 35), // similar warm
      );
      expect(result, ColourRelationship.analogous);
    });
  });
}
