import 'package:palette/core/constants/enums.dart';

/// Colour affinity data for a property era.
///
/// Used to softly bias system palette generation toward colours that
/// complement the architectural character of the user's home.
class EraAffinity {
  const EraAffinity({
    this.affinityFamilies,
    this.chromaModifier,
    this.suggestedLRange,
    required this.description,
  });

  /// Palette families that naturally complement this era.
  /// Null means no particular family preference.
  final List<PaletteFamily>? affinityFamilies;

  /// Chroma modifier: positive nudges toward higher saturation,
  /// negative toward lower. Null means no adjustment.
  final double? chromaModifier;

  /// Suggested L* range for dominant/supporting walls.
  /// Null means use the user's default range.
  final (double min, double max)? suggestedLRange;

  /// Human-readable description of the era's colour character.
  final String description;
}

/// Era affinity data for all property eras.
const Map<PropertyEra, EraAffinity> eraAffinities = {
  PropertyEra.victorian: EraAffinity(
    affinityFamilies: [PaletteFamily.jewelTones, PaletteFamily.darks],
    chromaModifier: 5.0,
    suggestedLRange: (35.0, 70.0),
    description:
        'Victorian homes suit rich, deep colours — jewel tones and '
        'dramatic darks complement high ceilings and ornate mouldings.',
  ),
  PropertyEra.edwardian: EraAffinity(
    affinityFamilies: [
      PaletteFamily.warmNeutrals,
      PaletteFamily.earthTones,
    ],
    chromaModifier: null,
    suggestedLRange: (45.0, 75.0),
    description:
        'Edwardian homes suit warm, elegant tones — soft creams, '
        'warm greys, and muted earth tones honour the period\'s '
        'lighter, more open character.',
  ),
  PropertyEra.thirtiesToFifties: EraAffinity(
    affinityFamilies: [PaletteFamily.pastels, PaletteFamily.warmNeutrals],
    chromaModifier: -3.0,
    suggestedLRange: (50.0, 80.0),
    description:
        '1930s-50s homes suit soft, understated colours — gentle '
        'pastels and warm neutrals complement the clean Art Deco '
        'and mid-century lines.',
  ),
  PropertyEra.postWar: EraAffinity(
    affinityFamilies: [
      PaletteFamily.warmNeutrals,
      PaletteFamily.coolNeutrals,
    ],
    chromaModifier: null,
    suggestedLRange: (50.0, 80.0),
    description:
        'Post-war homes benefit from both warm and cool neutrals — '
        'lighter, brighter tones help maximise light in typically '
        'compact rooms.',
  ),
  PropertyEra.modern: EraAffinity(
    affinityFamilies: null,
    chromaModifier: null,
    suggestedLRange: null,
    description:
        'Modern homes are a blank canvas — any palette family works '
        'well depending on your personal preference.',
  ),
  PropertyEra.newBuild: EraAffinity(
    affinityFamilies: null,
    chromaModifier: null,
    suggestedLRange: null,
    description:
        'New builds offer maximum flexibility — your colour DNA '
        'palette will work beautifully in these clean, contemporary spaces.',
  ),
  PropertyEra.notSure: EraAffinity(
    affinityFamilies: null,
    chromaModifier: null,
    suggestedLRange: null,
    description:
        'No worries! Your colour DNA palette works in any home — '
        'the colours are chosen for you, not the building.',
  ),
};

/// Get the era affinity for a property era, or null if not set.
EraAffinity? getEraAffinity(PropertyEra? era) {
  if (era == null) return null;
  return eraAffinities[era];
}
