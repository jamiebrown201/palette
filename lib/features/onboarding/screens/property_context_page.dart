import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/constants/branded_terms.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/features/onboarding/logic/quiz_notifier.dart';
import 'package:palette/features/onboarding/logic/quiz_state.dart';
import 'package:palette/features/onboarding/providers/quiz_providers.dart';

/// Property context stage: type, era, project stage, tenure.
class PropertyContextPage extends ConsumerStatefulWidget {
  const PropertyContextPage({super.key});

  @override
  ConsumerState<PropertyContextPage> createState() =>
      _PropertyContextPageState();
}

class _PropertyContextPageState extends ConsumerState<PropertyContextPage> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizNotifierProvider);
    final notifier = ref.read(quizNotifierProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            'Tell us about your home',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us tailor recommendations to your space',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: PaletteColours.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Property Type
          const _SectionLabel(label: 'Property type'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                PropertyType.values.map((type) {
                  return _SelectionChip(
                    label: type.displayName,
                    isSelected: quizState.propertyType == type,
                    onTap: () => notifier.setPropertyType(type),
                  );
                }).toList(),
          ),
          const SizedBox(height: 24),

          // Property Era
          const _SectionLabel(label: 'Property era'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                PropertyEra.values.map((era) {
                  return _SelectionChip(
                    label: era.displayName,
                    isSelected: quizState.propertyEra == era,
                    onTap: () => notifier.setPropertyEra(era),
                  );
                }).toList(),
          ),
          const SizedBox(height: 24),

          // Project Stage
          const _SectionLabel(label: 'Where are you in your project?'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                ProjectStage.values.map((stage) {
                  return _SelectionChip(
                    label: stage.displayName,
                    isSelected: quizState.projectStage == stage,
                    onTap: () => notifier.setProjectStage(stage),
                  );
                }).toList(),
          ),
          const SizedBox(height: 24),

          // Tenure
          const _SectionLabel(label: 'Do you own or rent?'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                Tenure.values.map((tenure) {
                  return _SelectionChip(
                    label: tenure.displayName,
                    isSelected: quizState.tenure == tenure,
                    onTap: () => notifier.setTenure(tenure),
                  );
                }).toList(),
          ),

          // Renter constraint questions — revealed when tenure == renter
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child:
                quizState.tenure == Tenure.renter
                    ? _RenterConstraintSection(
                      quizState: quizState,
                      notifier: notifier,
                    )
                    : const SizedBox.shrink(),
          ),
          const SizedBox(height: 32),

          FilledButton(
            onPressed:
                _isGenerating
                    ? null
                    : () async {
                      setState(() => _isGenerating = true);
                      try {
                        await notifier.generateAndSaveResult();
                      } catch (_) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Something went wrong. Please try again.',
                              ),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isGenerating = false);
                      }
                    },
            child:
                _isGenerating
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('See My ${BrandedTerms.colourDna}'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed:
                _isGenerating
                    ? null
                    : () async {
                      setState(() => _isGenerating = true);
                      try {
                        await notifier.generateAndSaveResult();
                      } finally {
                        if (mounted) setState(() => _isGenerating = false);
                      }
                    },
            style: TextButton.styleFrom(
              foregroundColor: PaletteColours.textTertiary,
            ),
            child: const Text('Skip this step'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _RenterConstraintSection extends StatelessWidget {
  const _RenterConstraintSection({
    required this.quizState,
    required this.notifier,
  });

  final QuizState quizState;
  final QuizNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const _SectionLabel(label: 'Help us tailor your experience'),
        const SizedBox(height: 4),
        Text(
          "We'll help you create a home you love, deposit intact.",
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: PaletteColours.textTertiary),
        ),
        const SizedBox(height: 16),
        _YesNoRow(
          label: 'Can you paint the walls?',
          value: quizState.canPaint,
          onChanged: notifier.setCanPaint,
        ),
        _YesNoRow(
          label: 'Can you drill or mount things?',
          value: quizState.canDrill,
          onChanged: notifier.setCanDrill,
        ),
        _YesNoRow(
          label: 'Keeping the existing flooring?',
          value: quizState.keepingFlooring,
          onChanged: notifier.setKeepingFlooring,
        ),
        _YesNoRow(
          label: 'Is this a temporary home?',
          value: quizState.isTemporaryHome,
          onChanged: notifier.setIsTemporaryHome,
        ),
        _YesNoRow(
          label: 'Reversible changes only?',
          value: quizState.reversibleOnly,
          onChanged: notifier.setReversibleOnly,
        ),
      ],
    );
  }
}

class _YesNoRow extends StatelessWidget {
  const _YesNoRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool? value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 12),
          _SelectionChip(
            label: 'Yes',
            isSelected: value == true,
            onTap: () => onChanged(true),
          ),
          const SizedBox(width: 8),
          _SelectionChip(
            label: 'No',
            isSelected: value == false,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _SelectionChip extends StatelessWidget {
  const _SelectionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: PaletteColours.sageGreenLight,
        checkmarkColor: PaletteColours.sageGreenDark,
      ),
    );
  }
}
