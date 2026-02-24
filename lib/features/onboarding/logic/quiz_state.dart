import 'package:palette/core/constants/enums.dart';
import 'package:palette/features/onboarding/logic/palette_generator.dart';

/// The stage of the Colour DNA quiz.
enum QuizStage { memoryPrompts, visualPreference, propertyContext, result }

/// Complete quiz state managed by the notifier.
class QuizState {
  const QuizState({
    this.stage = QuizStage.memoryPrompts,
    this.currentPromptIndex = 0,
    this.selectedCardWeights = const [],
    this.selectedRoomIds = const {},
    this.propertyType,
    this.propertyEra,
    this.projectStage,
    this.tenure,
    this.generatedPalette,
  });

  final QuizStage stage;

  // Memory Prompts stage
  final int currentPromptIndex;
  final List<Map<String, int>> selectedCardWeights;

  // Visual Preference stage
  final Set<String> selectedRoomIds;

  // Property Context stage
  final PropertyType? propertyType;
  final PropertyEra? propertyEra;
  final ProjectStage? projectStage;
  final Tenure? tenure;

  // Result
  final GeneratedPalette? generatedPalette;

  /// Total prompts answered across all stages.
  int get totalAnswered =>
      selectedCardWeights.length + selectedRoomIds.length;

  /// Whether the user has answered at least one question
  /// (minimum for generating a result).
  bool get hasMinimumInput => selectedCardWeights.isNotEmpty;

  QuizState copyWith({
    QuizStage? stage,
    int? currentPromptIndex,
    List<Map<String, int>>? selectedCardWeights,
    Set<String>? selectedRoomIds,
    PropertyType? propertyType,
    PropertyEra? propertyEra,
    ProjectStage? projectStage,
    Tenure? tenure,
    GeneratedPalette? generatedPalette,
  }) {
    return QuizState(
      stage: stage ?? this.stage,
      currentPromptIndex: currentPromptIndex ?? this.currentPromptIndex,
      selectedCardWeights: selectedCardWeights ?? this.selectedCardWeights,
      selectedRoomIds: selectedRoomIds ?? this.selectedRoomIds,
      propertyType: propertyType ?? this.propertyType,
      propertyEra: propertyEra ?? this.propertyEra,
      projectStage: projectStage ?? this.projectStage,
      tenure: tenure ?? this.tenure,
      generatedPalette: generatedPalette ?? this.generatedPalette,
    );
  }
}
