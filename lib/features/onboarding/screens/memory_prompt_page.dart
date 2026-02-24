import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/features/onboarding/providers/quiz_providers.dart';

/// A single memory prompt step showing colour-mood cards.
class MemoryPromptPage extends ConsumerWidget {
  const MemoryPromptPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(quizNotifierProvider.notifier);
    final prompt = notifier.currentPrompt;

    if (prompt == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final cards = (prompt['cards'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            prompt['prompt'] as String,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the one that resonates most',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: PaletteColours.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                final hex = card['hex'] as String;
                final colour = _hexToColor(hex);
                final familyWeights = (card['familyWeights']
                        as Map<String, dynamic>)
                    .map((k, v) => MapEntry(k, (v as num).toInt()));

                return _ColourMoodCard(
                  label: card['label'] as String,
                  colour: colour,
                  onTap: () => notifier.selectMemoryCard(familyWeights),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ColourMoodCard extends StatelessWidget {
  const _ColourMoodCard({
    required this.label,
    required this.colour,
    required this.onTap,
  });

  final String label;
  final Color colour;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Determine text colour based on luminance
    final textColour =
        colour.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    return Semantics(
      button: true,
      label: '$label colour card',
      child: Material(
        color: colour,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: textColour,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
