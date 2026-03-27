import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/repositories/colour_dna_repository.dart';
import 'package:palette/data/repositories/paint_colour_repository.dart';
import 'package:palette/data/repositories/user_profile_repository.dart';
import 'package:palette/features/onboarding/data/archetype_definitions.dart';
import 'package:palette/features/onboarding/logic/palette_generator.dart';
import 'package:palette/features/onboarding/logic/quiz_state.dart';
import 'package:palette/features/onboarding/logic/quiz_weight_calculator.dart';
import 'package:palette/features/onboarding/logic/system_palette_generator.dart';
import 'package:palette/features/onboarding/logic/undertone_temperature.dart';
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

  /// Select a card in the memory prompts stage (Stage 1).
  void selectMemoryCard(
    Map<String, int> familyWeights, {
    Undertone? undertoneTemp,
    ChromaBand? chromaBand,
  }) {
    final newWeights = [...state.stage1CardWeights, familyWeights];
    final nextIndex = state.currentPromptIndex + 1;

    // Accumulate undertone and saturation tallies
    final newTally = _addUndertone(state.undertoneTally, undertoneTemp);
    final newSatTally = _addChromaBand(state.saturationTally, chromaBand);

    if (nextIndex >= (_memoryPrompts?.length ?? 4)) {
      // Move to visual preference stage
      state = state.copyWith(
        stage1CardWeights: newWeights,
        currentPromptIndex: nextIndex,
        undertoneTally: newTally,
        saturationTally: newSatTally,
        stage: QuizStage.visualPreference,
      );
    } else {
      state = state.copyWith(
        stage1CardWeights: newWeights,
        currentPromptIndex: nextIndex,
        undertoneTally: newTally,
        saturationTally: newSatTally,
      );
    }
  }

  /// Toggle a room selection in the visual preference stage (Stage 2).
  void toggleRoomSelection(
    String roomId,
    Map<String, int> familyWeights, {
    Undertone? undertoneTemp,
    ChromaBand? chromaBand,
  }) {
    final newRoomIds = Set<String>.from(state.selectedRoomIds);
    final newWeights = List<Map<String, int>>.from(state.stage2CardWeights);
    Map<Undertone, int> newTally;
    Map<ChromaBand, int> newSatTally;

    if (newRoomIds.contains(roomId)) {
      newRoomIds.remove(roomId);
      // Remove the last matching weight (best effort)
      for (var i = newWeights.length - 1; i >= 0; i--) {
        if (newWeights[i] == familyWeights) {
          newWeights.removeAt(i);
          break;
        }
      }
      // Subtract on deselect
      newTally = _subtractUndertone(state.undertoneTally, undertoneTemp);
      newSatTally = _subtractChromaBand(state.saturationTally, chromaBand);
    } else {
      newRoomIds.add(roomId);
      newWeights.add(familyWeights);
      // Add on select
      newTally = _addUndertone(state.undertoneTally, undertoneTemp);
      newSatTally = _addChromaBand(state.saturationTally, chromaBand);
    }

    state = state.copyWith(
      selectedRoomIds: newRoomIds,
      stage2CardWeights: newWeights,
      undertoneTally: newTally,
      saturationTally: newSatTally,
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

  // Renter constraint setters
  void setCanPaint(bool value) =>
      state = state.copyWith(canPaint: value);

  void setCanDrill(bool value) =>
      state = state.copyWith(canDrill: value);

  void setKeepingFlooring(bool value) =>
      state = state.copyWith(keepingFlooring: value);

  void setIsTemporaryHome(bool value) =>
      state = state.copyWith(isTemporaryHome: value);

  void setReversibleOnly(bool value) =>
      state = state.copyWith(reversibleOnly: value);

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
    // Calculate normalised weights with stage balancing and confidence
    final weightResult = calculateWeights(
      stage1CardWeights: state.stage1CardWeights,
      stage2CardWeights: state.stage2CardWeights,
      stage2CardCount: state.selectedRoomIds.length,
    );

    // Convert double weights to int for palette generation.
    // Scale by 100 before rounding to preserve relative ordering —
    // plain round() on small doubles (e.g. 1.5 vs 2.0) creates false ties.
    final familyWeights = <PaletteFamily, int>{};
    for (final entry in weightResult.finalWeights.entries) {
      final scaled = (entry.value * 100).round();
      if (scaled > 0) {
        familyWeights[entry.key] = scaled;
      }
    }

    final allPaintColours = await paintColourRepo.getAll();

    // Derive undertone temperature and saturation preference from tallies
    final undertoneTemp = deriveUndertoneTemperature(state.undertoneTally);
    final saturationPref = deriveSaturationPreference(state.saturationTally);

    final palette = generatePalette(
      familyWeights: familyWeights,
      allPaintColours: allPaintColours,
      undertoneTemperature: undertoneTemp,
      saturationPreference: saturationPref,
    );

    // Generate the role-based system palette
    final systemPalette = generateSystemPalette(
      primaryFamily: palette.primaryFamily,
      secondaryFamily: palette.secondaryFamily,
      allPaintColours: allPaintColours,
      undertoneTemperature: undertoneTemp,
      saturationPreference: saturationPref,
      propertyEra: state.propertyEra,
    );

    // Use system palette hex list if available (backward compat)
    final colourHexes = systemPalette?.toColourHexes() ??
        palette.colours.map((c) => c.hex).toList();

    // Map to archetype using family + saturation
    final archetype = mapToArchetype(
      primaryFamily: palette.primaryFamily,
      saturationPreference: saturationPref,
    );

    state = state.copyWith(
      stage: QuizStage.result,
      generatedPalette: palette,
      dnaConfidence: weightResult.confidence,
      archetype: archetype,
      systemPaletteJson: systemPalette?.toJson(),
    );

    // Persist to database
    final resultId = const Uuid().v4();
    await colourDnaRepo.insert(
      ColourDnaResultsCompanion.insert(
        id: resultId,
        primaryFamily: palette.primaryFamily,
        secondaryFamily: Value(palette.secondaryFamily),
        colourHexes: colourHexes,
        dnaConfidence: Value(weightResult.confidence),
        archetype: Value(archetype),
        propertyType: Value(state.propertyType),
        propertyEra: Value(state.propertyEra),
        projectStage: Value(state.projectStage),
        tenure: Value(state.tenure),
        undertoneTemperature: Value(undertoneTemp),
        saturationPreference: Value(saturationPref),
        systemPaletteJson: Value(systemPalette?.toJson()),
        completedAt: DateTime.now(),
        isComplete: state.stage == QuizStage.result,
      ),
    );

    // Mark onboarding complete
    await userProfileRepo.setOnboardingComplete(
      colourDnaResultId: resultId,
    );

    // Persist renter constraints (if any were answered)
    if (state.tenure == Tenure.renter) {
      await userProfileRepo.updateRenterConstraints(
        canPaint: state.canPaint,
        canDrill: state.canDrill,
        keepingFlooring: state.keepingFlooring,
        isTemporaryHome: state.isTemporaryHome,
        reversibleOnly: state.reversibleOnly,
      );
    }
  }

  /// Reset quiz state for retaking.
  void reset() {
    state = const QuizState();
  }

  /// Add an undertone vote to the tally.
  Map<Undertone, int> _addUndertone(
    Map<Undertone, int> tally,
    Undertone? undertone,
  ) {
    if (undertone == null) return tally;
    final result = Map<Undertone, int>.from(tally);
    result[undertone] = (result[undertone] ?? 0) + 1;
    return result;
  }

  /// Subtract an undertone vote from the tally (on deselect).
  Map<Undertone, int> _subtractUndertone(
    Map<Undertone, int> tally,
    Undertone? undertone,
  ) {
    if (undertone == null) return tally;
    final result = Map<Undertone, int>.from(tally);
    final current = result[undertone] ?? 0;
    if (current <= 1) {
      result.remove(undertone);
    } else {
      result[undertone] = current - 1;
    }
    return result;
  }

  /// Add a chroma band vote to the saturation tally.
  Map<ChromaBand, int> _addChromaBand(
    Map<ChromaBand, int> tally,
    ChromaBand? band,
  ) {
    if (band == null) return tally;
    final result = Map<ChromaBand, int>.from(tally);
    result[band] = (result[band] ?? 0) + 1;
    return result;
  }

  /// Subtract a chroma band vote from the saturation tally (on deselect).
  Map<ChromaBand, int> _subtractChromaBand(
    Map<ChromaBand, int> tally,
    ChromaBand? band,
  ) {
    if (band == null) return tally;
    final result = Map<ChromaBand, int>.from(tally);
    final current = result[band] ?? 0;
    if (current <= 1) {
      result.remove(band);
    } else {
      result[band] = current - 1;
    }
    return result;
  }
}
