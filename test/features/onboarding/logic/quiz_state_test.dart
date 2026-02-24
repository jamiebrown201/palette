import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/features/onboarding/logic/quiz_state.dart';

void main() {
  group('QuizState', () {
    test('initial state has correct defaults', () {
      const state = QuizState();

      expect(state.stage, QuizStage.memoryPrompts);
      expect(state.currentPromptIndex, 0);
      expect(state.selectedCardWeights, isEmpty);
      expect(state.selectedRoomIds, isEmpty);
      expect(state.propertyType, isNull);
      expect(state.propertyEra, isNull);
      expect(state.projectStage, isNull);
      expect(state.tenure, isNull);
      expect(state.generatedPalette, isNull);
    });

    test('hasMinimumInput is false with no selections', () {
      const state = QuizState();
      expect(state.hasMinimumInput, isFalse);
    });

    test('hasMinimumInput is true after one card selection', () {
      const state = QuizState(
        selectedCardWeights: [
          {'warmNeutrals': 2},
        ],
      );
      expect(state.hasMinimumInput, isTrue);
    });

    test('totalAnswered counts all answers', () {
      const state = QuizState(
        selectedCardWeights: [
          {'warmNeutrals': 2},
          {'pastels': 1},
        ],
        selectedRoomIds: {'room-1', 'room-3'},
      );
      expect(state.totalAnswered, 4);
    });

    test('copyWith preserves unmodified fields', () {
      const state = QuizState(
        stage: QuizStage.memoryPrompts,
        currentPromptIndex: 2,
        selectedCardWeights: [
          {'warmNeutrals': 2},
        ],
      );

      final updated = state.copyWith(stage: QuizStage.visualPreference);

      expect(updated.stage, QuizStage.visualPreference);
      expect(updated.currentPromptIndex, 2);
      expect(updated.selectedCardWeights, hasLength(1));
    });

    test('copyWith updates property context', () {
      const state = QuizState();

      final updated = state.copyWith(
        propertyType: PropertyType.terraced,
        propertyEra: PropertyEra.victorian,
        projectStage: ProjectStage.planning,
        tenure: Tenure.owner,
      );

      expect(updated.propertyType, PropertyType.terraced);
      expect(updated.propertyEra, PropertyEra.victorian);
      expect(updated.projectStage, ProjectStage.planning);
      expect(updated.tenure, Tenure.owner);
    });
  });
}
