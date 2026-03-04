import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/features/onboarding/data/era_affinities.dart';

void main() {
  group('eraAffinities', () {
    test('has an entry for every PropertyEra', () {
      for (final era in PropertyEra.values) {
        expect(
          eraAffinities[era],
          isNotNull,
          reason: '${era.name} should have an era affinity',
        );
      }
    });

    test('all entries have non-empty descriptions', () {
      for (final entry in eraAffinities.entries) {
        expect(
          entry.value.description,
          isNotEmpty,
          reason: '${entry.key.name} description should not be empty',
        );
      }
    });

    test('Victorian has jewel tones and darks affinity', () {
      final victorian = eraAffinities[PropertyEra.victorian]!;
      expect(victorian.affinityFamilies, contains(PaletteFamily.jewelTones));
      expect(victorian.affinityFamilies, contains(PaletteFamily.darks));
    });

    test('Victorian has positive chroma modifier', () {
      final victorian = eraAffinities[PropertyEra.victorian]!;
      expect(victorian.chromaModifier, isNotNull);
      expect(victorian.chromaModifier, greaterThan(0));
    });

    test('modern has null affinity families', () {
      final modern = eraAffinities[PropertyEra.modern]!;
      expect(modern.affinityFamilies, isNull);
    });

    test('newBuild has null affinity families', () {
      final newBuild = eraAffinities[PropertyEra.newBuild]!;
      expect(newBuild.affinityFamilies, isNull);
    });

    test('1930s-50s has negative chroma modifier', () {
      final thirties = eraAffinities[PropertyEra.thirtiesToFifties]!;
      expect(thirties.chromaModifier, isNotNull);
      expect(thirties.chromaModifier, lessThan(0));
    });

    test('suggestedLRange has valid bounds when set', () {
      for (final entry in eraAffinities.entries) {
        final range = entry.value.suggestedLRange;
        if (range != null) {
          expect(range.$1, greaterThan(0),
              reason: '${entry.key.name} min L* should be positive');
          expect(range.$2, greaterThan(range.$1),
              reason: '${entry.key.name} max L* should be > min');
          expect(range.$2, lessThanOrEqualTo(100),
              reason: '${entry.key.name} max L* should be ≤ 100');
        }
      }
    });
  });

  group('getEraAffinity', () {
    test('returns null for null era', () {
      expect(getEraAffinity(null), isNull);
    });

    test('returns affinity for valid era', () {
      expect(getEraAffinity(PropertyEra.victorian), isNotNull);
      expect(getEraAffinity(PropertyEra.modern), isNotNull);
    });
  });
}
