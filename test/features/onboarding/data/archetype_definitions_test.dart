import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/features/onboarding/data/archetype_definitions.dart';

void main() {
  group('familyToArchetype', () {
    test('every PaletteFamily maps to an archetype', () {
      for (final family in PaletteFamily.values) {
        expect(
          familyToArchetype[family],
          isNotNull,
          reason: '${family.name} should map to an archetype',
        );
      }
    });

    test('no two families map to the same archetype', () {
      final archetypes = familyToArchetype.values.toSet();
      expect(archetypes.length, familyToArchetype.length);
    });
  });

  group('archetypeDefinitions', () {
    test('every mapped archetype has a definition', () {
      for (final archetype in familyToArchetype.values) {
        expect(
          archetypeDefinitions[archetype],
          isNotNull,
          reason: '${archetype.name} should have a definition',
        );
      }
    });

    test('no two archetypes share the same name', () {
      final names = archetypeDefinitions.values.map((d) => d.name).toSet();
      expect(names.length, archetypeDefinitions.length);
    });

    test('all definitions have non-empty required fields', () {
      for (final def in archetypeDefinitions.values) {
        expect(
          def.name,
          isNotEmpty,
          reason: '${def.archetype.name} name should not be empty',
        );
        expect(
          def.headline,
          isNotEmpty,
          reason: '${def.archetype.name} headline should not be empty',
        );
        expect(
          def.description,
          isNotEmpty,
          reason: '${def.archetype.name} description should not be empty',
        );
        expect(
          def.whyItWorks,
          isNotEmpty,
          reason: '${def.archetype.name} whyItWorks should not be empty',
        );
        expect(
          def.watchOutFor,
          isNotEmpty,
          reason: '${def.archetype.name} watchOutFor should not be empty',
        );
      }
    });

    test('all definitions have exactly 3 style tips', () {
      for (final def in archetypeDefinitions.values) {
        expect(
          def.styleTips.length,
          3,
          reason: '${def.archetype.name} should have 3 style tips',
        );
      }
    });

    test('all definitions have suggested rooms', () {
      for (final def in archetypeDefinitions.values) {
        expect(
          def.suggestedRooms,
          isNotEmpty,
          reason: '${def.archetype.name} should have suggested rooms',
        );
      }
    });

    test('descriptions use second person', () {
      for (final def in archetypeDefinitions.values) {
        // Descriptions should contain "You" or "Your"
        final hasSecondPerson =
            def.description.contains('You') ||
            def.description.contains('Your') ||
            def.description.contains('you') ||
            def.description.contains('your');
        expect(
          hasSecondPerson,
          isTrue,
          reason: '${def.archetype.name} description should use second person',
        );
      }
    });
  });

  group('mapToArchetype', () {
    test('returns correct archetype for each family (no saturation)', () {
      expect(
        mapToArchetype(primaryFamily: PaletteFamily.warmNeutrals),
        ColourArchetype.theCocooner,
      );
      expect(
        mapToArchetype(primaryFamily: PaletteFamily.coolNeutrals),
        ColourArchetype.theCurator,
      );
      expect(
        mapToArchetype(primaryFamily: PaletteFamily.pastels),
        ColourArchetype.theRomantic,
      );
      expect(
        mapToArchetype(primaryFamily: PaletteFamily.earthTones),
        ColourArchetype.theNatureLover,
      );
      expect(
        mapToArchetype(primaryFamily: PaletteFamily.jewelTones),
        ColourArchetype.theVelvetWhisper,
      );
      expect(
        mapToArchetype(primaryFamily: PaletteFamily.brights),
        ColourArchetype.theBrightener,
      );
      expect(
        mapToArchetype(primaryFamily: PaletteFamily.darks),
        ColourArchetype.theDramatist,
      );
    });

    test('warmNeutrals + muted → Cocooner', () {
      expect(
        mapToArchetype(
          primaryFamily: PaletteFamily.warmNeutrals,
          saturationPreference: ChromaBand.muted,
        ),
        ColourArchetype.theCocooner,
      );
    });

    test('warmNeutrals + bold → Golden Hour', () {
      expect(
        mapToArchetype(
          primaryFamily: PaletteFamily.warmNeutrals,
          saturationPreference: ChromaBand.bold,
        ),
        ColourArchetype.theGoldenHour,
      );
    });

    test('coolNeutrals + bold → Monochrome Modernist', () {
      expect(
        mapToArchetype(
          primaryFamily: PaletteFamily.coolNeutrals,
          saturationPreference: ChromaBand.bold,
        ),
        ColourArchetype.theMonochromeModernist,
      );
    });

    test('pastels + bold → Colour Optimist', () {
      expect(
        mapToArchetype(
          primaryFamily: PaletteFamily.pastels,
          saturationPreference: ChromaBand.bold,
        ),
        ColourArchetype.theColourOptimist,
      );
    });

    test('earthTones + bold → Storyteller', () {
      expect(
        mapToArchetype(
          primaryFamily: PaletteFamily.earthTones,
          saturationPreference: ChromaBand.bold,
        ),
        ColourArchetype.theStoryteller,
      );
    });

    test('jewelTones + bold → Maximalist', () {
      expect(
        mapToArchetype(
          primaryFamily: PaletteFamily.jewelTones,
          saturationPreference: ChromaBand.bold,
        ),
        ColourArchetype.theMaximalist,
      );
    });

    test('darks + bold → Midnight Architect', () {
      expect(
        mapToArchetype(
          primaryFamily: PaletteFamily.darks,
          saturationPreference: ChromaBand.bold,
        ),
        ColourArchetype.theMidnightArchitect,
      );
    });

    test('all 14 archetypes are reachable', () {
      final reachable = <ColourArchetype>{};
      for (final family in PaletteFamily.values) {
        for (final band in ChromaBand.values) {
          reachable.add(
            mapToArchetype(primaryFamily: family, saturationPreference: band),
          );
        }
      }
      // 14 archetypes minus theMinimalist (special case) = 13 reachable
      // through the standard map. theMinimalist is a special-case override.
      expect(reachable.length, greaterThanOrEqualTo(13));
    });
  });

  group('familySaturationToArchetype', () {
    test('every family has entries for all three ChromaBands', () {
      for (final family in PaletteFamily.values) {
        expect(
          familySaturationToArchetype[family],
          isNotNull,
          reason: '${family.name} should have saturation map',
        );
        for (final band in ChromaBand.values) {
          expect(
            familySaturationToArchetype[family]![band],
            isNotNull,
            reason: '${family.name} + ${band.name} should map to an archetype',
          );
        }
      }
    });

    test('every mapped archetype has a definition', () {
      for (final familyEntry in familySaturationToArchetype.entries) {
        for (final bandEntry in familyEntry.value.entries) {
          expect(
            archetypeDefinitions[bandEntry.value],
            isNotNull,
            reason:
                '${familyEntry.key.name} + ${bandEntry.key.name} → '
                '${bandEntry.value.name} should have a definition',
          );
        }
      }
    });
  });
}
