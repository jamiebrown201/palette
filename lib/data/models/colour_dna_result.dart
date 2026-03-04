import 'package:palette/core/constants/enums.dart';

/// The result of the Colour DNA onboarding quiz.
class ColourDnaResult {
  const ColourDnaResult({
    required this.id,
    required this.primaryFamily,
    required this.colourHexes,
    required this.completedAt,
    required this.isComplete,
    this.secondaryFamily,
    this.dnaConfidence,
    this.archetype,
    this.propertyType,
    this.propertyEra,
    this.projectStage,
    this.tenure,
    this.undertoneTemperature,
    this.saturationPreference,
    this.systemPaletteJson,
  });

  final String id;
  final PaletteFamily primaryFamily;
  final PaletteFamily? secondaryFamily;
  final List<String> colourHexes;
  final DnaConfidence? dnaConfidence;
  final ColourArchetype? archetype;
  final PropertyType? propertyType;
  final PropertyEra? propertyEra;
  final ProjectStage? projectStage;
  final Tenure? tenure;
  final Undertone? undertoneTemperature;
  final ChromaBand? saturationPreference;
  final String? systemPaletteJson;
  final DateTime completedAt;
  final bool isComplete;
}
