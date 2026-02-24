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
    this.propertyType,
    this.propertyEra,
    this.projectStage,
    this.tenure,
  });

  final String id;
  final PaletteFamily primaryFamily;
  final PaletteFamily? secondaryFamily;
  final List<String> colourHexes;
  final PropertyType? propertyType;
  final PropertyEra? propertyEra;
  final ProjectStage? projectStage;
  final Tenure? tenure;
  final DateTime completedAt;
  final bool isComplete;
}
