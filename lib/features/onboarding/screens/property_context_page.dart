import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/features/onboarding/providers/quiz_providers.dart';

/// Property context stage: type, era, project stage, tenure.
class PropertyContextPage extends ConsumerWidget {
  const PropertyContextPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            children: PropertyType.values.map((type) {
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
            children: PropertyEra.values.map((era) {
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
            children: ProjectStage.values.map((stage) {
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
            children: Tenure.values.map((tenure) {
              return _SelectionChip(
                label: tenure.displayName,
                isSelected: quizState.tenure == tenure,
                onTap: () => notifier.setTenure(tenure),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          FilledButton(
            onPressed: () async {
              await notifier.generateAndSaveResult();
            },
            child: const Text('See My Colour DNA'),
          ),
          const SizedBox(height: 32),
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
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
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
