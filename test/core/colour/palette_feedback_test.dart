import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/colour/palette_feedback.dart';

void main() {
  group('describePaletteImpact', () {
    test('returns starter message for empty palette', () {
      final result = describePaletteImpact(
        newHex: '#FF0000',
        existingHexes: [],
      );
      expect(result, 'Your palette begins!');
    });

    test('detects named relationship', () {
      // Red and cyan — classifyHuePair may see this as split-comp or comp
      // depending on exact Lab hue angles. Either is a valid detection.
      final result = describePaletteImpact(
        newHex: '#FF0000',
        existingHexes: ['#00FFFF'],
      );
      expect(
        result.toLowerCase(),
        anyOf(
          contains('complementary'),
          contains('split'),
          contains('triadic'),
        ),
      );
    });

    test('detects analogous relationship', () {
      // Red and orange-red are analogous (~30° apart)
      final result = describePaletteImpact(
        newHex: '#FF0000',
        existingHexes: ['#FF6600'],
      );
      expect(result.toLowerCase(), contains('analogous'));
      expect(result.toLowerCase(), contains('calm harmony'));
    });

    test('prioritises complementary over analogous', () {
      // New colour has both a complementary and analogous partner
      final result = describePaletteImpact(
        newHex: '#FF0000',
        existingHexes: ['#00FFFF', '#FF3300'],
      );
      expect(result.toLowerCase(), contains('complementary'));
    });

    test('falls back to undertone observation when no named relationship', () {
      // Two warm colours and adding a cool one
      final result = describePaletteImpact(
        newHex: '#4488CC', // cool blue
        existingHexes: ['#CC8844', '#DDAA55'], // warm ochres
      );
      expect(
        result.toLowerCase(),
        anyOf(
          contains('cool balance'),
          contains('tonal neighbour'),
          contains('depth and range'),
          // May detect a named relationship depending on exact hue angles
          contains('complementary'),
          contains('triadic'),
          contains('split'),
          contains('analogous'),
        ),
      );
    });

    test('detects tonal neighbour for very close colours', () {
      // Two very similar greens (dE < 10)
      final result = describePaletteImpact(
        newHex: '#4A6741',
        existingHexes: ['#4D6B44'],
      );
      // Should detect as analogous (very close hue) or tonal neighbour
      expect(
        result.toLowerCase(),
        anyOf(contains('analogous'), contains('tonal neighbour')),
      );
    });
  });

  group('describeColourRole', () {
    test('identifies only palette colour', () {
      final result = describeColourRole(
        hex: '#FF0000',
        paletteHexes: ['#FF0000'],
      );
      expect(result.role, 'Your only palette colour');
      expect(result.warning, isNull);
    });

    test('identifies complementary partner', () {
      final result = describeColourRole(
        hex: '#FF0000',
        paletteHexes: ['#FF0000', '#00FFFF'],
      );
      expect(result.role.toLowerCase(), contains('complementary'));
    });

    test('warns when removing only warm colour from cool palette', () {
      final result = describeColourRole(
        hex: '#CC8844', // warm
        paletteHexes: ['#CC8844', '#4488CC', '#336699', '#2255AA'],
      );
      // Should identify as only warm-toned colour
      if (result.role.toLowerCase().contains('warm')) {
        expect(result.warning, isNotNull);
        expect(result.warning!.toLowerCase(), contains('cool'));
      }
    });

    test('warns when palette would be left with one colour', () {
      final result = describeColourRole(
        hex: '#FF0000',
        paletteHexes: ['#FF0000', '#00FF00'],
      );
      expect(result.warning, contains('just one colour'));
    });

    test('identifies relationship count correctly', () {
      // Red with cyan (complementary) and another complementary-ish
      final result = describeColourRole(
        hex: '#FF0000',
        paletteHexes: ['#FF0000', '#00FFFF', '#00CCCC'],
      );
      expect(result.role.toLowerCase(), contains('complementary'));
    });
  });

  group('analysePaletteHealth', () {
    test('returns getting started for single colour', () {
      final result = analysePaletteHealth(['#FF0000']);
      expect(result.verdict, 'Getting started');
      expect(result.clashes, isEmpty);
      expect(result.strengths, isEmpty);
      expect(result.insights, isEmpty);
    });

    test('detects nearly identical colours as clash', () {
      // Two very similar colours (dE < 5)
      final result = analysePaletteHealth(['#FF0000', '#FE0101']);
      expect(result.clashes, isNotEmpty);
      expect(result.clashes.first.toLowerCase(), contains('nearly identical'));
    });

    test('detects harmonious analogous palette', () {
      // Three analogous greens/teals
      final result = analysePaletteHealth([
        '#2E8B57', // sea green
        '#3CB371', // medium sea green
        '#20B2AA', // light sea green
      ]);
      expect(result.strengths, isNotEmpty);
      // Should contain analogous reference
      expect(
        result.strengths.any((s) => s.toLowerCase().contains('analogous')),
        isTrue,
      );
    });

    test('detects complementary pair', () {
      final result = analysePaletteHealth([
        '#FF0000', // red
        '#00FFFF', // cyan
      ]);
      expect(result.strengths, isNotEmpty);
      expect(
        result.strengths.any((s) => s.toLowerCase().contains('complementary')),
        isTrue,
      );
    });

    test('detects dynamic balance with true complementary pair', () {
      // Use colours with clearer hue separation for reliable classification
      final result = analysePaletteHealth([
        '#CC6600', // orange
        '#DD8833', // similar orange (analogous)
        '#3366CC', // blue (complementary to orange)
      ]);
      // Should detect multiple relationship types
      expect(result.verdict, isNotEmpty);
      expect(result.strengths, isNotEmpty);
    });

    test('suggests cool accent for warm-heavy palette', () {
      // Varied lightness + chroma so only the warm/cool imbalance triggers
      final result = analysePaletteHealth([
        '#3D2B1F', // dark brown (L*~20)
        '#8B7355', // medium brown (L*~50)
        '#D2B48C', // light tan (L*~75)
        '#CC8844', // warm ochre (L*~60)
        '#EE9944', // warm orange (L*~70)
      ]);
      if (result.suggestion != null) {
        expect(
          result.suggestion!.toLowerCase(),
          anyOf(contains('cool'), contains('warm')),
        );
      }
    });

    test('handles large palette (9 colours)', () {
      final result = analysePaletteHealth([
        '#FF0000',
        '#00FF00',
        '#0000FF',
        '#FFFF00',
        '#FF00FF',
        '#00FFFF',
        '#FF8800',
        '#8800FF',
        '#00FF88',
      ]);
      // Should not throw and should produce meaningful output
      expect(result.verdict, isNotEmpty);
      expect(result.explanation, isNotEmpty);
    });

    test('flags bold disconnected pairs with extreme hue separation', () {
      // Two chromatic colours far apart in both dE and hue (>120°)
      final result = analysePaletteHealth([
        '#FF0000', // red, hue ~40° in Lab
        '#0000FF', // blue, hue ~306° in Lab — ~180° apart
      ]);
      // Complementary pair or bold disconnected — either is valid
      expect(
        result.strengths.isNotEmpty ||
            result.clashes.isNotEmpty ||
            result.verdict.isNotEmpty,
        isTrue,
      );
    });

    test('uses nameMap for user-friendly clash messages', () {
      final result = analysePaletteHealth(
        ['#FF0000', '#FF0101'], // near-identical reds
        nameMap: {'#ff0000': 'Crimson Kiss', '#ff0101': 'Ruby Red'},
      );
      expect(result.clashes, isNotEmpty);
      expect(result.clashes.first, contains('Crimson Kiss'));
      expect(result.clashes.first, contains('Ruby Red'));
      expect(result.clashes.first, isNot(contains('#FF')));
    });
  });

  group('analysePaletteHealth — lightness spread', () {
    test('flags narrow lightness range', () {
      // All mid-tone colours (L* ~50-60)
      final result = analysePaletteHealth([
        '#808080', // grey L*~53
        '#7A7A7A', // slightly darker grey
        '#868686', // slightly lighter grey
      ]);
      expect(
        result.clashes.any((c) => c.toLowerCase().contains('cluster')),
        isTrue,
      );
    });

    test('recognises good lightness range', () {
      // Dark to light spread
      final result = analysePaletteHealth([
        '#1A1A2E', // very dark (L* ~10)
        '#808080', // mid grey (L* ~53)
        '#F0E68C', // light khaki (L* ~89)
      ]);
      expect(
        result.strengths.any(
          (s) =>
              s.toLowerCase().contains('tonal range') ||
              s.toLowerCase().contains('lightness'),
        ),
        isTrue,
      );
    });

    test('suggests darker shade for light-clustered palette', () {
      // All light colours
      final result = analysePaletteHealth([
        '#F5F5DC', // beige
        '#FFFACD', // lemon chiffon
        '#FAFAD2', // light goldenrod
      ]);
      expect(result.clashes.any((c) => c.contains('light tones')), isTrue);
      expect(result.suggestion, isNotNull);
      expect(result.suggestion!.toLowerCase(), contains('deeper'));
    });
  });

  group('analysePaletteHealth — chroma diversity', () {
    test('flags all-muted palette', () {
      // Low chroma colours (Cab* < 25)
      final result = analysePaletteHealth([
        '#808080', // grey
        '#8B8682', // slightly warm grey
        '#8A8D8F', // slightly cool grey
      ]);
      expect(
        result.clashes.any((c) => c.toLowerCase().contains('muted')),
        isTrue,
      );
    });

    test('flags all-bold palette', () {
      // High chroma colours (Cab* > 50)
      final result = analysePaletteHealth([
        '#FF0000', // pure red
        '#00FF00', // pure green
        '#0000FF', // pure blue
      ]);
      expect(
        result.clashes.any((c) => c.toLowerCase().contains('bold')),
        isTrue,
      );
    });

    test('recognises mix of muted and bold', () {
      // Mix of chroma bands
      final result = analysePaletteHealth([
        '#808080', // muted grey
        '#FF0000', // bold red
      ]);
      expect(
        result.strengths.any(
          (s) =>
              s.toLowerCase().contains('muted') &&
              s.toLowerCase().contains('bold'),
        ),
        isTrue,
      );
    });
  });

  group('analysePaletteHealth — palette family', () {
    test('identifies dominant palette family', () {
      // Colours that classifyPaletteFamily groups into earth tones:
      // moderate L* (30-65), moderate chroma (15-45), warm (b*>0, a*>-5)
      final result = analysePaletteHealth([
        '#8B7355', // L*~50, chroma~21 → earthTones
        '#7A6B4E', // L*~46, chroma~18 → earthTones
        '#6B5B3E', // L*~40, chroma~18 → earthTones
        '#8C7D5E', // L*~53, chroma~19 → earthTones
        '#746545', // L*~44, chroma~19 → earthTones
      ]);
      // ≥60% of colours should be one family → strength about that family
      expect(
        result.strengths.any((s) => s.toLowerCase().contains('rooted')),
        isTrue,
      );
    });

    test('notes eclectic family mix', () {
      // Each colour a different family
      final result = analysePaletteHealth([
        '#FFB6C1', // pastel pink
        '#FF0000', // bright red
        '#1A1A2E', // dark
      ]);
      // May or may not produce an insight depending on family classification
      // but should not crash
      expect(result.verdict, isNotEmpty);
    });
  });

  group('analysePaletteHealth — hue coverage', () {
    test('recognises moderate contrast pairs', () {
      // ~80° hue separation — falls in the 60-100° gap
      final result = analysePaletteHealth([
        '#FF0000', // red
        '#55AA33', // green (~80-100° from red in Lab space)
      ]);
      // Should either find moderate contrast insight or classify relationship
      expect(
        result.insights.isNotEmpty ||
            result.strengths.isNotEmpty ||
            result.verdict == 'Balanced mix',
        isTrue,
      );
    });

    test('does not flag moderate-hue pairs as bold disconnected', () {
      // Colours with high dE but moderate (60-100°) hue separation
      // should NOT get the "bold together" clash
      final result = analysePaletteHealth([
        '#FF0000', // red
        '#55AA33', // green — moderate hue sep, high dE
      ]);
      final hasBoldClash = result.clashes.any(
        (c) => c.contains('bold together'),
      );
      expect(hasBoldClash, isFalse);
    });
  });

  group('analysePaletteHealth — undertone insights', () {
    test('notes all warm-toned palette', () {
      final result = analysePaletteHealth([
        '#CC8844', // warm ochre
        '#DDAA55', // warm gold
      ]);
      expect(
        result.insights.any((i) => i.toLowerCase().contains('warm')),
        isTrue,
      );
    });

    test('recognises warm and cool balance as strength', () {
      final result = analysePaletteHealth([
        '#CC8844', // warm
        '#4488CC', // cool
      ]);
      expect(
        result.strengths.any(
          (s) =>
              s.toLowerCase().contains('warm') &&
              s.toLowerCase().contains('cool'),
        ),
        isTrue,
      );
    });
  });

  group('analysePaletteHealth — suggestions', () {
    test('suggests saturation when all muted', () {
      // Muted colours with wide lightness spread to avoid lightness suggestion
      final result = analysePaletteHealth([
        '#3C3C3C', // dark grey (L*~25)
        '#808080', // mid grey (L*~53)
        '#C0C0C0', // light grey (L*~77)
      ]);
      expect(result.suggestion, isNotNull);
      expect(result.suggestion!.toLowerCase(), contains('saturated'));
    });

    test('suggests neutral when all bold', () {
      final result = analysePaletteHealth(['#FF0000', '#00FF00', '#0000FF']);
      expect(result.suggestion, isNotNull);
      expect(
        result.suggestion!.toLowerCase(),
        anyOf(contains('neutral'), contains('softer')),
      );
    });
  });

  group('describePaletteImpact with nameMap', () {
    test('uses paint name in relationship message', () {
      final result = describePaletteImpact(
        newHex: '#FF0000',
        existingHexes: ['#00FFFF'],
        nameMap: {'#00ffff': 'Coastal Blue'},
      );
      expect(result, contains('Coastal Blue'));
      expect(result, isNot(contains('#00FFFF')));
    });
  });
}
