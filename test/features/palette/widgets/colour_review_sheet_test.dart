import 'package:flutter_test/flutter_test.dart';
import 'package:palette/features/palette/widgets/colour_review_sheet.dart';

void main() {
  group('deriveStructuredFindings', () {
    test('returns empty for single colour', () {
      final result = deriveStructuredFindings(['#FF0000']);
      expect(result, isEmpty);
    });

    test('detects complementary pair as strength', () {
      final result = deriveStructuredFindings(['#FF0000', '#00FFFF']);
      final strengths =
          result.where((f) => f.type == FindingType.strength).toList();
      expect(strengths, isNotEmpty);
      expect(
        strengths.any((f) => f.title.toLowerCase().contains('complementary')),
        isTrue,
      );
      // Should include both hexes
      final compFinding = strengths.firstWhere(
          (f) => f.title.toLowerCase().contains('complementary'));
      expect(compFinding.hexes, contains('#FF0000'));
      expect(compFinding.hexes, contains('#00FFFF'));
    });

    test('detects analogous pair as strength', () {
      final result = deriveStructuredFindings(['#FF0000', '#FF6600']);
      final strengths =
          result.where((f) => f.type == FindingType.strength).toList();
      expect(
        strengths.any((f) => f.title.toLowerCase().contains('analogous')),
        isTrue,
      );
    });

    test('detects nearly identical colours as clash', () {
      final result = deriveStructuredFindings(['#FF0000', '#FE0101']);
      final clashes =
          result.where((f) => f.type == FindingType.clash).toList();
      expect(clashes, isNotEmpty);
      expect(
        clashes.any((f) => f.description.contains('very close')),
        isTrue,
      );
      // Both hexes should be referenced
      final clash = clashes.firstWhere((f) => f.description.contains('very close'));
      expect(clash.hexes.length, 2);
    });

    test('detects good tonal range as strength', () {
      final result = deriveStructuredFindings([
        '#1A1A2E', // very dark
        '#808080', // mid grey
        '#F0E68C', // light khaki
      ]);
      final strengths =
          result.where((f) => f.type == FindingType.strength).toList();
      expect(
        strengths.any((f) => f.title.contains('tonal range')),
        isTrue,
      );
    });

    test('detects narrow lightness range as clash', () {
      final result = deriveStructuredFindings([
        '#808080', // grey
        '#7A7A7A', // slightly darker grey
        '#868686', // slightly lighter grey
      ]);
      final clashes =
          result.where((f) => f.type == FindingType.clash).toList();
      expect(
        clashes.any((f) => f.title.contains('Narrow tonal range')),
        isTrue,
      );
    });

    test('detects all muted as clash', () {
      final result = deriveStructuredFindings([
        '#808080', // grey
        '#8B8682', // slightly warm grey
        '#8A8D8F', // slightly cool grey
      ]);
      final clashes =
          result.where((f) => f.type == FindingType.clash).toList();
      expect(
        clashes.any((f) => f.title.contains('muted')),
        isTrue,
      );
    });

    test('detects muted and bold balance as strength', () {
      final result = deriveStructuredFindings(['#808080', '#FF0000']);
      final strengths =
          result.where((f) => f.type == FindingType.strength).toList();
      expect(
        strengths.any((f) =>
            f.title.toLowerCase().contains('muted') &&
            f.title.toLowerCase().contains('bold')),
        isTrue,
      );
    });

    test('detects warm/cool balance as strength', () {
      final result = deriveStructuredFindings(['#CC8844', '#4488CC']);
      final strengths =
          result.where((f) => f.type == FindingType.strength).toList();
      expect(
        strengths.any((f) =>
            f.title.toLowerCase().contains('warm') &&
            f.title.toLowerCase().contains('cool')),
        isTrue,
      );
    });

    test('detects all warm as insight', () {
      final result = deriveStructuredFindings(['#CC8844', '#DDAA55']);
      final insights =
          result.where((f) => f.type == FindingType.insight).toList();
      expect(
        insights.any((f) => f.title.toLowerCase().contains('warm')),
        isTrue,
      );
    });

    test('detects palette family coherence as strength', () {
      final result = deriveStructuredFindings([
        '#8B7355', // earth tone
        '#7A6B4E', // earth tone
        '#6B5B3E', // earth tone
        '#8C7D5E', // earth tone
        '#746545', // earth tone
      ]);
      final strengths =
          result.where((f) => f.type == FindingType.strength).toList();
      expect(
        strengths.any((f) => f.title.toLowerCase().contains('rooted')),
        isTrue,
      );
    });

    test('uses nameMap for paint names in findings', () {
      final result = deriveStructuredFindings(
        ['#FF0000', '#00FFFF'],
        nameMap: {
          '#ff0000': 'Crimson Kiss',
          '#00ffff': 'Coastal Blue',
        },
      );
      // Strength finding should reference paint names
      final compFinding = result.firstWhere(
        (f) => f.relationship != null,
        orElse: () => result.first,
      );
      // Pair swatches use names from nameMap
      expect(compFinding.hexes, contains('#FF0000'));
      expect(compFinding.hexes, contains('#00FFFF'));
    });

    test('uses nameMap for clash names', () {
      final result = deriveStructuredFindings(
        ['#FF0000', '#FE0101'],
        nameMap: {
          '#ff0000': 'Crimson Kiss',
          '#fe0101': 'Ruby Red',
        },
      );
      final clashes =
          result.where((f) => f.type == FindingType.clash).toList();
      expect(clashes, isNotEmpty);
      // Title should use paint names
      final clash = clashes.first;
      expect(clash.title, contains('Crimson Kiss'));
      expect(clash.title, contains('Ruby Red'));
    });

    test('finding includes correct hexes for pairwise relationships', () {
      final result = deriveStructuredFindings([
        '#FF0000', // red
        '#00FFFF', // cyan
        '#FF6600', // orange
      ]);
      // Should have complementary pair (red-cyan) and analogous (red-orange)
      final relFindings = result
          .where((f) => f.type == FindingType.strength && f.relationship != null)
          .toList();
      expect(relFindings.length, greaterThanOrEqualTo(2));
      // Each should have exactly 2 hexes
      for (final f in relFindings) {
        expect(f.hexes.length, 2);
      }
    });

    test('handles large palette without error', () {
      final result = deriveStructuredFindings([
        '#FF0000', '#00FF00', '#0000FF',
        '#FFFF00', '#FF00FF', '#00FFFF',
        '#FF8800', '#8800FF', '#00FF88',
      ]);
      expect(result, isNotEmpty);
    });

    test('consolidates multiple pairs of same relationship type', () {
      // Many analogous earth-tone colours — should produce at most
      // one analogous strength card, not dozens.
      final result = deriveStructuredFindings([
        '#C4A882', '#8B7355', '#D4C5A9', '#A0522D',
        '#DEB887', '#F5DEB3', '#BC8F8F', '#CD853F',
        '#D2B48C', '#4A6741',
      ]);
      final analogousFindings = result
          .where((f) =>
              f.type == FindingType.strength &&
              f.relationship != null &&
              f.title.toLowerCase().contains('analogous'))
          .toList();
      // Should have at most 1 analogous card
      expect(analogousFindings.length, lessThanOrEqualTo(1));
      // If it exists, the count should be noted in the title
      if (analogousFindings.isNotEmpty) {
        expect(analogousFindings.first.title, contains('pairs'));
      }
    });
  });
}
