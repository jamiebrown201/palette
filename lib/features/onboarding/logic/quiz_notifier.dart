import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/repositories/colour_dna_repository.dart';
import 'package:palette/data/repositories/paint_colour_repository.dart';
import 'package:palette/data/repositories/user_profile_repository.dart';
import 'package:palette/features/onboarding/logic/palette_generator.dart';
import 'package:palette/features/onboarding/logic/quiz_state.dart';
import 'package:uuid/uuid.dart';

/// Notifier managing the full Colour DNA quiz flow.
class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier({
    required this.paintColourRepo,
    required this.colourDnaRepo,
    required this.userProfileRepo,
  }) : super(const QuizState());

  final PaintColourRepository paintColourRepo;
  final ColourDnaRepository colourDnaRepo;
  final UserProfileRepository userProfileRepo;

  /// Loaded quiz content from JSON.
  List<dynamic>? _memoryPrompts;
  List<dynamic>? _visualPreferences;

  /// Number of memory prompts available.
  int get promptCount => _memoryPrompts?.length ?? 4;

  /// Load quiz content from bundled assets.
  Future<void> loadContent() async {
    final jsonString =
        await rootBundle.loadString('assets/data/quiz_content.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;
    _memoryPrompts = data['memoryPrompts'] as List<dynamic>;
    _visualPreferences = data['visualPreferences'] as List<dynamic>;
  }

  /// Get current memory prompt data.
  Map<String, dynamic>? get currentPrompt {
    if (_memoryPrompts == null) return null;
    if (state.currentPromptIndex >= _memoryPrompts!.length) return null;
    return _memoryPrompts![state.currentPromptIndex] as Map<String, dynamic>;
  }

  /// Get all visual preference cards.
  List<Map<String, dynamic>> get visualPreferences {
    if (_visualPreferences == null) return [];
    return _visualPreferences!.cast<Map<String, dynamic>>();
  }

  /// Select a card in the memory prompts stage.
  void selectMemoryCard(Map<String, int> familyWeights) {
    final newWeights = [...state.selectedCardWeights, familyWeights];
    final nextIndex = state.currentPromptIndex + 1;

    if (nextIndex >= (_memoryPrompts?.length ?? 4)) {
      // Move to visual preference stage
      state = state.copyWith(
        selectedCardWeights: newWeights,
        currentPromptIndex: nextIndex,
        stage: QuizStage.visualPreference,
      );
    } else {
      state = state.copyWith(
        selectedCardWeights: newWeights,
        currentPromptIndex: nextIndex,
      );
    }
  }

  /// Toggle a room selection in the visual preference stage.
  void toggleRoomSelection(String roomId, Map<String, int> familyWeights) {
    final newRoomIds = Set<String>.from(state.selectedRoomIds);
    final newWeights = List<Map<String, int>>.from(state.selectedCardWeights);

    if (newRoomIds.contains(roomId)) {
      newRoomIds.remove(roomId);
      // Remove the last matching weight (best effort)
      for (var i = newWeights.length - 1; i >= 0; i--) {
        if (newWeights[i] == familyWeights) {
          newWeights.removeAt(i);
          break;
        }
      }
    } else {
      newRoomIds.add(roomId);
      newWeights.add(familyWeights);
    }

    state = state.copyWith(
      selectedRoomIds: newRoomIds,
      selectedCardWeights: newWeights,
    );
  }

  /// Advance from visual preference to property context.
  void advanceToPropertyContext() {
    state = state.copyWith(stage: QuizStage.propertyContext);
  }

  /// Set property context fields.
  void setPropertyType(PropertyType type) {
    state = state.copyWith(propertyType: type);
  }

  void setPropertyEra(PropertyEra era) {
    state = state.copyWith(propertyEra: era);
  }

  void setProjectStage(ProjectStage stage) {
    state = state.copyWith(projectStage: stage);
  }

  void setTenure(Tenure tenure) {
    state = state.copyWith(tenure: tenure);
  }

  /// Navigate back to a previous stage.
  void goBackToMemoryPrompts() {
    state = state.copyWith(
      stage: QuizStage.memoryPrompts,
      currentPromptIndex: (promptCount - 1).clamp(0, 999),
    );
  }

  /// Navigate back to visual preference stage.
  void goBackToVisualPreference() {
    state = state.copyWith(stage: QuizStage.visualPreference);
  }

  /// Skip to results (can be called from any stage).
  Future<void> skipToResults() => generateAndSaveResult();

  /// Generate the palette and save the result.
  Future<void> generateAndSaveResult() async {
    final familyWeights = tallyFamilyWeights(state.selectedCardWeights);
    final allPaintColours = await paintColourRepo.getAll();

    final palette = generatePalette(
      familyWeights: familyWeights,
      allPaintColours: allPaintColours,
    );

    state = state.copyWith(
      stage: QuizStage.result,
      generatedPalette: palette,
    );

    // Persist to database
    final resultId = const Uuid().v4();
    await colourDnaRepo.insert(
      ColourDnaResultsCompanion.insert(
        id: resultId,
        primaryFamily: palette.primaryFamily,
        secondaryFamily: Value(palette.secondaryFamily),
        colourHexes: palette.colours.map((c) => c.hex).toList(),
        propertyType: Value(state.propertyType),
        propertyEra: Value(state.propertyEra),
        projectStage: Value(state.projectStage),
        tenure: Value(state.tenure),
        completedAt: DateTime.now(),
        isComplete: state.stage == QuizStage.result,
      ),
    );

    // Mark onboarding complete
    await userProfileRepo.setOnboardingComplete(
      colourDnaResultId: resultId,
    );
  }

  /// Reset quiz state for retaking.
  void reset() {
    state = const QuizState();
  }
}
