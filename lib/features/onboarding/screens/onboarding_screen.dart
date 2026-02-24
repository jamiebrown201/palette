import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/core/widgets/progress_bar.dart';
import 'package:palette/features/onboarding/logic/quiz_state.dart';
import 'package:palette/features/onboarding/providers/quiz_providers.dart';
import 'package:palette/features/onboarding/screens/memory_prompt_page.dart';
import 'package:palette/features/onboarding/screens/property_context_page.dart';
import 'package:palette/features/onboarding/screens/quiz_result_page.dart';
import 'package:palette/features/onboarding/screens/visual_preference_page.dart';
import 'package:palette/providers/app_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _contentLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    await ref.read(quizNotifierProvider.notifier).loadContent();
    if (mounted) setState(() => _contentLoaded = true);
  }

  void _skipQuiz() {
    ref.read(hasCompletedOnboardingProvider.notifier).state = true;
    context.go('/home');
  }

  void _onQuizComplete() {
    ref.read(hasCompletedOnboardingProvider.notifier).state = true;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizNotifierProvider);

    if (!_contentLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress and skip
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (quizState.stage != QuizStage.result &&
                          quizState.stage != QuizStage.memoryPrompts)
                        IconButton(
                          onPressed: _goBack,
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        )
                      else
                        const SizedBox(width: 48),
                      if (quizState.stage != QuizStage.result)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (quizState.hasMinimumInput)
                              TextButton(
                                onPressed: () async {
                                  await ref
                                      .read(quizNotifierProvider.notifier)
                                      .skipToResults();
                                },
                                child: const Text('See results'),
                              ),
                            TextButton(
                              onPressed: _skipQuiz,
                              child: const Text('Skip'),
                            ),
                          ],
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                  if (quizState.stage != QuizStage.result)
                    SteppedProgressBar(
                      totalSteps: 3,
                      currentStep: quizState.stage.index,
                    ),
                ],
              ),
            ),

            // Quiz content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStage(quizState),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStage(QuizState state) {
    return switch (state.stage) {
      QuizStage.memoryPrompts => MemoryPromptPage(
          key: ValueKey('prompt-${state.currentPromptIndex}'),
        ),
      QuizStage.visualPreference => const VisualPreferencePage(
          key: ValueKey('visual'),
        ),
      QuizStage.propertyContext => const PropertyContextPage(
          key: ValueKey('property'),
        ),
      QuizStage.result => QuizResultPage(
          key: const ValueKey('result'),
          onComplete: _onQuizComplete,
        ),
    };
  }

  void _goBack() {
    final notifier = ref.read(quizNotifierProvider.notifier);
    final current = ref.read(quizNotifierProvider);
    switch (current.stage) {
      case QuizStage.visualPreference:
        notifier.goBackToMemoryPrompts();
      case QuizStage.propertyContext:
        notifier.goBackToVisualPreference();
      case _:
        break;
    }
  }
}
