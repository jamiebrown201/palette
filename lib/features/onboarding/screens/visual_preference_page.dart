import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/features/onboarding/providers/quiz_providers.dart';

/// Visual preference stage: select room images that appeal to you.
class VisualPreferencePage extends ConsumerWidget {
  const VisualPreferencePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizState = ref.watch(quizNotifierProvider);
    final notifier = ref.read(quizNotifierProvider.notifier);
    final rooms = notifier.visualPreferences;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            'Which rooms speak to you?',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Select as many as you like',
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
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                final roomId = room['id'] as String;
                final isSelected = quizState.selectedRoomIds.contains(roomId);
                final familyWeights =
                    (room['familyWeights'] as Map<String, dynamic>)
                        .map((k, v) => MapEntry(k, (v as num).toInt()));

                return _RoomCard(
                  description: room['description'] as String,
                  isSelected: isSelected,
                  onTap: () =>
                      notifier.toggleRoomSelection(roomId, familyWeights),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: notifier.advanceToPropertyContext,
            child: const Text('Continue'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$description room preference card',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? PaletteColours.sageGreen
                : PaletteColours.divider,
            width: isSelected ? 3 : 1,
          ),
          color: PaletteColours.cardBackground,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Placeholder for room image (would use actual images in production)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: PaletteColours.warmGrey,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.home_outlined,
                          size: 32,
                          color: isSelected
                              ? PaletteColours.sageGreen
                              : PaletteColours.textTertiary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PaletteColours.textPrimary,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
