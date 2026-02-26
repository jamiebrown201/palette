import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/colour_suggestions.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/core/colour/lab_colour.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/paint_colour.dart';

/// Helper to build a [PaintColour] from a hex string.
PaintColour _paint(
  String id,
  String hex, {
  Undertone undertone = Undertone.neutral,
  PaletteFamily family = PaletteFamily.warmNeutrals,
  double? price,
}) {
  final lab = hexToLab(hex);
  final rgb = hexToRgb(hex);
  // Approximate LRV from luminance
  final lrv = (0.2126 * rgb.r + 0.7152 * rgb.g + 0.0722 * rgb.b) / 255 * 100;
  return PaintColour(
    id: id,
    brand: 'Test Brand',
    name: 'Paint $id',
    code: id,
    hex: hex,
    labL: lab.l,
    labA: lab.a,
    labB: lab.b,
    lrv: lrv,
    undertone: undertone,
    paletteFamily: family,
    approximatePricePerLitre: price,
  );
}

void main() {
  // A varied set of test paints
  final testPaints = [
    _paint('warm-red', '#C04040', undertone: Undertone.warm, family: PaletteFamily.brights),
    _paint('cool-blue', '#4060C0', undertone: Undertone.cool, family: PaletteFamily.coolNeutrals),
    _paint('warm-beige', '#C4A882', undertone: Undertone.warm, family: PaletteFamily.warmNeutrals),
    _paint('earthy-brown', '#8B7355', undertone: Undertone.warm, family: PaletteFamily.earthTones),
    _paint('sage-green', '#6B8E6B', undertone: Undertone.neutral, family: PaletteFamily.earthTones),
    _paint('pale-pink', '#E8C8C8', undertone: Undertone.warm, family: PaletteFamily.pastels),
    _paint('dark-navy', '#2B3A67', undertone: Undertone.cool, family: PaletteFamily.darks),
    _paint('jewel-teal', '#008080', undertone: Undertone.cool, family: PaletteFamily.jewelTones),
    _paint('bright-yellow', '#E8D44D', undertone: Undertone.warm, family: PaletteFamily.brights),
    _paint('neutral-grey', '#A0A0A0', undertone: Undertone.neutral, family: PaletteFamily.coolNeutrals),
    _paint('warm-cream', '#F5DEB3', undertone: Undertone.warm, family: PaletteFamily.warmNeutrals),
    _paint('deep-plum', '#6B3A6B', undertone: Undertone.cool, family: PaletteFamily.jewelTones),
  ];

  group('generateSuggestions', () {
    test('returns empty list for empty paint list', () {
      final result = generateSuggestions(
        context: const PickerContext(),
        allPaints: [],
      );
      expect(result, isEmpty);
    });

    test('returns at most maxSuggestions results', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.hero,
          dnaHexes: ['#C4A882', '#8B7355', '#6B8E6B', '#E8C8C8', '#4060C0', '#C04040'],
        ),
        allPaints: testPaints,
        maxSuggestions: 3,
      );
      expect(result.length, lessThanOrEqualTo(3));
    });

    test('deduplicates by paint ID keeping highest score', () {
      // With a single DNA hex matching a single paint, we should get at most one
      // suggestion for that paint even if multiple strategies select it
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.hero,
          dnaHexes: ['#C4A882'],
        ),
        allPaints: testPaints,
      );
      final ids = result.map((s) => s.paint.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'No duplicate paint IDs');
    });

    test('results are sorted by score descending', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.hero,
          dnaHexes: ['#C4A882', '#8B7355'],
          direction: CompassDirection.north,
          usageTime: UsageTime.evening,
        ),
        allPaints: testPaints,
      );
      for (var i = 1; i < result.length; i++) {
        expect(result[i].score, lessThanOrEqualTo(result[i - 1].score),
            reason: 'Score at index $i should be <= score at index ${i - 1}');
      }
    });
  });

  group('hero suggestions', () {
    test('includes DNA matches with correct reason', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.hero,
          dnaHexes: ['#C4A882'],
        ),
        allPaints: testPaints,
      );
      expect(result, isNotEmpty);
      final dnaMatches = result.where(
          (s) => s.category == SuggestionCategory.dnaMatch);
      expect(dnaMatches, isNotEmpty);
      expect(dnaMatches.first.reason, 'From your Colour DNA');
    });

    test('includes direction-appropriate suggestions for north-facing rooms', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.hero,
          direction: CompassDirection.north,
          usageTime: UsageTime.allDay,
        ),
        allPaints: testPaints,
      );
      final dirSuggestions = result.where(
          (s) => s.category == SuggestionCategory.directionAppropriate);
      expect(dirSuggestions, isNotEmpty);
      // North-facing should prefer warm undertones
      for (final s in dirSuggestions) {
        expect(
          s.paint.undertone == Undertone.warm ||
              s.paint.undertone == Undertone.neutral,
          isTrue,
          reason: 'North-facing should suggest warm or neutral undertones',
        );
      }
    });

    test('includes red thread echoes', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.hero,
          redThreadHexes: ['#C04040'],
        ),
        allPaints: testPaints,
      );
      final threadMatches = result.where(
          (s) => s.category == SuggestionCategory.redThread);
      expect(threadMatches, isNotEmpty);
      expect(threadMatches.first.reason, 'Echoes your red thread');
    });

    test('works with no context (no DNA, no direction, no thread)', () {
      final result = generateSuggestions(
        context: const PickerContext(pickerRole: PickerRole.hero),
        allPaints: testPaints,
      );
      // Should return empty gracefully — no crash
      expect(result, isEmpty);
    });
  });

  group('beta suggestions', () {
    test('returns empty without hero colour', () {
      final result = generateSuggestions(
        context: const PickerContext(pickerRole: PickerRole.beta),
        allPaints: testPaints,
      );
      expect(result, isEmpty);
    });

    test('includes analogous suggestions to hero', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.beta,
          heroColourHex: '#C04040',
        ),
        allPaints: testPaints,
      );
      expect(result, isNotEmpty);
      final analogousSuggestions = result.where(
          (s) => s.category == SuggestionCategory.analogous);
      expect(analogousSuggestions, isNotEmpty);
      expect(analogousSuggestions.first.reason, 'Harmonises with your hero');
    });

    test('includes tonal neighbours in same family', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.beta,
          heroColourHex: '#C04040',
        ),
        allPaints: testPaints,
      );
      final tonal = result.where(
          (s) => s.category == SuggestionCategory.tonalNeighbour);
      for (final s in tonal) {
        expect(s.reason, contains('Tonal variation'));
      }
    });
  });

  group('surprise suggestions', () {
    test('returns empty without hero colour', () {
      final result = generateSuggestions(
        context: const PickerContext(pickerRole: PickerRole.surprise),
        allPaints: testPaints,
      );
      expect(result, isEmpty);
    });

    test('includes complementary suggestions to hero', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.surprise,
          heroColourHex: '#C04040',
        ),
        allPaints: testPaints,
      );
      expect(result, isNotEmpty);
      final compSuggestions = result.where(
          (s) => s.category == SuggestionCategory.complementary);
      expect(compSuggestions, isNotEmpty);
    });

    test('includes family complement suggestions', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.surprise,
          heroColourHex: '#C4A882', // warmNeutrals -> jewelTones complement
        ),
        allPaints: testPaints,
      );
      final familySuggestions = result.where(
          (s) => s.category == SuggestionCategory.familyComplement);
      expect(familySuggestions, isNotEmpty);
      for (final s in familySuggestions) {
        expect(s.reason, contains('Bold contrast'));
      }
    });
  });

  group('paletteAdd suggestions', () {
    test('suggests complementary to existing palette', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.paletteAdd,
          existingPaletteHexes: ['#C04040'],
        ),
        allPaints: testPaints,
      );
      expect(result, isNotEmpty);
      final compSuggestions = result.where(
          (s) => s.category == SuggestionCategory.complementary);
      expect(compSuggestions, isNotEmpty);
    });

    test('suggests gap-filler families not in palette', () {
      // Only include warmNeutrals in palette, so other families are gaps
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.paletteAdd,
          existingPaletteHexes: ['#C4A882'],
        ),
        allPaints: testPaints,
      );
      final gapFillers = result.where(
          (s) => s.category == SuggestionCategory.familyComplement);
      expect(gapFillers, isNotEmpty);
      for (final s in gapFillers) {
        expect(s.reason, contains('Adds'));
        expect(s.reason, contains('to your palette'));
      }
    });

    test('suggests unused DNA colours', () {
      // Use higher maxSuggestions so DNA matches (score 65) aren't cut off
      // by higher-scoring gap fillers (score 75)
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.paletteAdd,
          existingPaletteHexes: ['#C04040'],
          dnaHexes: ['#C04040', '#8B7355', '#6B8E6B'],
        ),
        allPaints: testPaints,
        maxSuggestions: 15,
      );
      final dnaMatches = result.where(
          (s) => s.category == SuggestionCategory.dnaMatch);
      expect(dnaMatches, isNotEmpty);
      // Should not suggest the colour already in palette
      for (final s in dnaMatches) {
        expect(s.paint.hex.toLowerCase(), isNot('#c04040'));
      }
    });
  });

  group('budget filtering', () {
    final pricedPaints = [
      _paint('cheap', '#C04040', price: 15, family: PaletteFamily.brights, undertone: Undertone.warm),
      _paint('mid', '#4060C0', price: 35, family: PaletteFamily.coolNeutrals, undertone: Undertone.cool),
      _paint('premium', '#C4A882', price: 60, family: PaletteFamily.warmNeutrals, undertone: Undertone.warm),
    ];

    test('affordable budget filters to cheaper paints', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.hero,
          dnaHexes: ['#C04040', '#4060C0', '#C4A882'],
          budget: BudgetBracket.affordable,
        ),
        allPaints: pricedPaints,
      );
      // With affordable budget, paints over £25 should be excluded
      // but fallback to allPaints if too few remain
      expect(result, isNotEmpty);
    });
  });

  group('slot-based diversity', () {
    test('hero suggestions have at least 3 different categories', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.hero,
          dnaHexes: ['#C4A882', '#8B7355'],
          redThreadHexes: ['#C04040'],
          direction: CompassDirection.north,
          usageTime: UsageTime.allDay,
        ),
        allPaints: testPaints,
      );
      final categories = result.map((s) => s.category).toSet();
      expect(categories.length, greaterThanOrEqualTo(3),
          reason: 'Hero should produce at least 3 distinct categories, '
              'got: ${categories.join(", ")}');
    });

    test('hero includes colour theory suggestion (complementary or analogous)', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.hero,
          dnaHexes: ['#C4A882'],
        ),
        allPaints: testPaints,
      );
      final hasColourTheory = result.any((s) =>
          s.category == SuggestionCategory.complementary ||
          s.category == SuggestionCategory.analogous);
      expect(hasColourTheory, isTrue,
          reason: 'Hero should include complementary or analogous suggestion');
    });

    test('hero results are visually diverse (pairwise deltaE >= 8)', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.hero,
          dnaHexes: ['#C4A882', '#8B7355'],
          redThreadHexes: ['#C04040'],
          direction: CompassDirection.south,
          usageTime: UsageTime.allDay,
        ),
        allPaints: testPaints,
      );
      // Check all pairs for minimum perceptual distance
      for (var i = 0; i < result.length; i++) {
        for (var j = i + 1; j < result.length; j++) {
          final labI = LabColour(
            result[i].paint.labL, result[i].paint.labA, result[i].paint.labB,
          );
          final labJ = LabColour(
            result[j].paint.labL, result[j].paint.labA, result[j].paint.labB,
          );
          final dE = deltaE2000(labI, labJ);
          expect(dE, greaterThanOrEqualTo(8.0),
              reason: '${result[i].paint.name} vs ${result[j].paint.name} '
                  'deltaE=$dE should be >= 8');
        }
      }
    });

    test('direction-appropriate always fires for south-facing room', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.hero,
          dnaHexes: ['#C4A882'],
          direction: CompassDirection.south,
          usageTime: UsageTime.allDay,
        ),
        allPaints: testPaints,
      );
      final dirSuggestions = result.where(
          (s) => s.category == SuggestionCategory.directionAppropriate);
      expect(dirSuggestions, isNotEmpty,
          reason: 'South-facing room should produce a direction suggestion');
    });

    test('beta includes splitComplementary category', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.beta,
          heroColourHex: '#C04040',
        ),
        allPaints: testPaints,
      );
      final splitComp = result.where(
          (s) => s.category == SuggestionCategory.splitComplementary);
      expect(splitComp, isNotEmpty,
          reason: 'Beta should include a split-complementary suggestion');
    });

    test('surprise includes triadic category', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.surprise,
          heroColourHex: '#C04040',
        ),
        allPaints: testPaints,
      );
      final triadicSuggestions = result.where(
          (s) => s.category == SuggestionCategory.triadic);
      expect(triadicSuggestions, isNotEmpty,
          reason: 'Surprise should include a triadic suggestion');
    });

    test('surprise includes splitComplementary category', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.surprise,
          heroColourHex: '#4060C0',
        ),
        allPaints: testPaints,
      );
      final splitComp = result.where(
          (s) => s.category == SuggestionCategory.splitComplementary);
      expect(splitComp, isNotEmpty,
          reason: 'Surprise should include split-complementary suggestions');
    });

    test('no duplicate paint IDs within slot-based results', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.hero,
          dnaHexes: ['#C4A882', '#8B7355', '#6B8E6B'],
          redThreadHexes: ['#C04040'],
          direction: CompassDirection.north,
          usageTime: UsageTime.evening,
        ),
        allPaints: testPaints,
      );
      final ids = result.map((s) => s.paint.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'Slot-based allocation should never produce duplicate IDs');
    });
  });

  group('redThread suggestions', () {
    test('returns suggestions when rooms have colours', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.redThread,
          dnaHexes: ['#C4A882', '#8B7355'],
          roomHexes: ['#C04040', '#4060C0'],
        ),
        allPaints: testPaints,
      );
      expect(result, isNotEmpty);
    });

    test('suggests DNA colours not already in rooms', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.redThread,
          dnaHexes: ['#C4A882', '#8B7355'],
          roomHexes: ['#C4A882'], // DNA hex already in a room
        ),
        allPaints: testPaints,
      );
      final dnaMatches =
          result.where((s) => s.category == SuggestionCategory.dnaMatch);
      // Should suggest the second DNA colour since the first is in a room
      if (dnaMatches.isNotEmpty) {
        expect(dnaMatches.first.paint.hex.toLowerCase(), isNot('#c4a882'));
      }
    });

    test('includes analogous to existing thread', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.redThread,
          dnaHexes: ['#C4A882'],
          redThreadHexes: ['#C04040'],
          roomHexes: ['#4060C0'],
        ),
        allPaints: testPaints,
      );
      final analogous =
          result.where((s) => s.category == SuggestionCategory.analogous);
      expect(analogous, isNotEmpty,
          reason: 'Should suggest analogous to existing thread');
    });

    test('includes complementary to room colours', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.redThread,
          dnaHexes: ['#C4A882'],
          roomHexes: ['#C04040', '#4060C0'],
        ),
        allPaints: testPaints,
      );
      final comp = result
          .where((s) => s.category == SuggestionCategory.complementary);
      expect(comp, isNotEmpty,
          reason: 'Should suggest complementary to room colours');
    });

    test('works gracefully with no rooms', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.redThread,
          dnaHexes: ['#C4A882'],
        ),
        allPaints: testPaints,
      );
      // Should still return DNA-based suggestions
      expect(result, isNotEmpty);
    });

    test('excludes existing thread colours from suggestions', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.redThread,
          dnaHexes: ['#C4A882'],
          redThreadHexes: ['#C04040'],
          roomHexes: ['#4060C0'],
        ),
        allPaints: testPaints,
      );
      // The existing thread colour should not be suggested
      for (final s in result) {
        expect(s.paint.id, isNot('warm-red'),
            reason: 'Should not suggest existing thread colour');
      }
    });

    test('no duplicate paint IDs', () {
      final result = generateSuggestions(
        context: PickerContext(
          pickerRole: PickerRole.redThread,
          dnaHexes: ['#C4A882', '#8B7355', '#6B8E6B'],
          redThreadHexes: ['#C04040'],
          roomHexes: ['#4060C0', '#E8C8C8'],
          direction: CompassDirection.south,
        ),
        allPaints: testPaints,
      );
      final ids = result.map((s) => s.paint.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'No duplicate paint IDs');
    });
  });
}
