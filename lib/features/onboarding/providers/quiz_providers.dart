import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/features/onboarding/logic/quiz_notifier.dart';
import 'package:palette/features/onboarding/logic/quiz_state.dart';
import 'package:palette/providers/database_providers.dart';

final quizNotifierProvider =
    StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier(
    paintColourRepo: ref.watch(paintColourRepositoryProvider),
    colourDnaRepo: ref.watch(colourDnaRepositoryProvider),
    userProfileRepo: ref.watch(userProfileRepositoryProvider),
  );
});
