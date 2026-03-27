import 'package:palette/core/constants/enums.dart';
import 'package:palette/features/onboarding/logic/palette_generator.dart';

/// The stage of the Colour DNA quiz.
enum QuizStage { memoryPrompts, visualPreference, propertyContext, result }

/// Complete quiz state managed by the notifier.
class QuizState {
  const QuizState({
    this.stage = QuizStage.memoryPrompts,
    this.currentPromptIndex = 0,
    this.stage1CardWeights = const [],
    this.stage2CardWeights = const [],
    this.selectedRoomIds = const {},
    this.propertyType,
    this.propertyEra,
    this.projectStage,
    this.tenure,
    this.canPaint,
    this.canDrill,
    this.keepingFlooring,
    this.isTemporaryHome,
    this.reversibleOnly,
    this.generatedPalette,
    this.dnaConfidence,
    this.archetype,
    this.systemPaletteJson,
    this.undertoneTally = const {},
    this.saturationTally = const {},
  });

  final QuizStage stage;

  // Memory Prompts stage (Stage 1)
  final int currentPromptIndex;
  final List<Map<String, int>> stage1CardWeights;

  // Visual Preference stage (Stage 2)
  final List<Map<String, int>> stage2CardWeights;
  final Set<String> selectedRoomIds;

  // Undertone temperature tally (accumulated across stages)
  final Map<Undertone, int> undertoneTally;

  // Saturation/chroma preference tally (accumulated across stages)
  final Map<ChromaBand, int> saturationTally;

  // Property Context stage
  final PropertyType? propertyType;
  final PropertyEra? propertyEra;
  final ProjectStage? projectStage;
  final Tenure? tenure;

  // Renter constraints (shown when tenure == renter)
  final bool? canPaint;
  final bool? canDrill;
  final bool? keepingFlooring;
  final bool? isTemporaryHome;
  final bool? reversibleOnly;

  // Result
  final GeneratedPalette? generatedPalette;
  final DnaConfidence? dnaConfidence;
  final ColourArchetype? archetype;
  final String? systemPaletteJson;

  /// Total prompts answered across all stages.
  int get totalAnswered => stage1CardWeights.length + selectedRoomIds.length;

  /// Whether the user has answered at least one question
  /// (minimum for generating a result).
  bool get hasMinimumInput => stage1CardWeights.isNotEmpty;

  QuizState copyWith({
    QuizStage? stage,
    int? currentPromptIndex,
    List<Map<String, int>>? stage1CardWeights,
    List<Map<String, int>>? stage2CardWeights,
    Set<String>? selectedRoomIds,
    Map<Undertone, int>? undertoneTally,
    Map<ChromaBand, int>? saturationTally,
    PropertyType? propertyType,
    PropertyEra? propertyEra,
    ProjectStage? projectStage,
    Tenure? tenure,
    bool? canPaint,
    bool? canDrill,
    bool? keepingFlooring,
    bool? isTemporaryHome,
    bool? reversibleOnly,
    GeneratedPalette? generatedPalette,
    DnaConfidence? dnaConfidence,
    ColourArchetype? archetype,
    String? systemPaletteJson,
  }) {
    return QuizState(
      stage: stage ?? this.stage,
      currentPromptIndex: currentPromptIndex ?? this.currentPromptIndex,
      stage1CardWeights: stage1CardWeights ?? this.stage1CardWeights,
      stage2CardWeights: stage2CardWeights ?? this.stage2CardWeights,
      selectedRoomIds: selectedRoomIds ?? this.selectedRoomIds,
      undertoneTally: undertoneTally ?? this.undertoneTally,
      saturationTally: saturationTally ?? this.saturationTally,
      propertyType: propertyType ?? this.propertyType,
      propertyEra: propertyEra ?? this.propertyEra,
      projectStage: projectStage ?? this.projectStage,
      tenure: tenure ?? this.tenure,
      canPaint: canPaint ?? this.canPaint,
      canDrill: canDrill ?? this.canDrill,
      keepingFlooring: keepingFlooring ?? this.keepingFlooring,
      isTemporaryHome: isTemporaryHome ?? this.isTemporaryHome,
      reversibleOnly: reversibleOnly ?? this.reversibleOnly,
      generatedPalette: generatedPalette ?? this.generatedPalette,
      dnaConfidence: dnaConfidence ?? this.dnaConfidence,
      archetype: archetype ?? this.archetype,
      systemPaletteJson: systemPaletteJson ?? this.systemPaletteJson,
    );
  }
}
