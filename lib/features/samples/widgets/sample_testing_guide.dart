import 'package:flutter/material.dart';
import 'package:palette/core/theme/palette_colours.dart';

/// A card prompting the user to learn how to test paint samples properly.
class SampleTestingGuideCard extends StatelessWidget {
  const SampleTestingGuideCard({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PaletteColours.sageGreenLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: PaletteColours.sageGreen.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lightbulb_outline,
              size: 24,
              color: PaletteColours.sageGreenDark,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to test your samples',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: PaletteColours.sageGreenDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Follow Sowerby's moveable-card method for accurate results",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: PaletteColours.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: PaletteColours.sageGreenDark,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet with the full sample testing guide.
class SampleTestingGuideSheet extends StatelessWidget {
  const SampleTestingGuideSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: PaletteColours.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Testing Your Paint Samples',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'The moveable-card method',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: PaletteColours.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              const _GuideStep(
                number: '1',
                title: 'Paint large cards, not the wall',
                body:
                    'Paint each sample onto A4-sized pieces of thick white card '
                    'or lining paper. Apply two coats and let them dry completely. '
                    'This lets you move the sample around the room without '
                    'committing to a wall.',
              ),
              const _GuideStep(
                number: '2',
                title: 'Test against every wall',
                body:
                    'Hold or tape the card against each wall in the room. '
                    'Colours look different depending on which wall they are on '
                    'because of how light falls. The wall opposite the window '
                    'gets the most even light; the wall beside the window gets '
                    'side-lit with stronger shadows.',
              ),
              const _GuideStep(
                number: '3',
                title: 'Check at different times of day',
                body:
                    'View the sample in morning light, afternoon light, and '
                    "under your room's artificial lighting in the evening. "
                    'Colours shift dramatically. A warm beige at noon can look '
                    'pink under warm bulbs or grey on an overcast morning.',
              ),
              const _GuideStep(
                number: '4',
                title: 'Compare against your existing pieces',
                body:
                    'Hold the card next to your sofa, curtains, rug, and any '
                    'furniture you are keeping. Check that the undertones are '
                    'harmonious. Warm undertones with warm; cool with cool.',
              ),
              const _GuideStep(
                number: '5',
                title: 'Test your white separately',
                body:
                    'Your trim white matters as much as your wall colour. '
                    'Hold your white sample next to the wall colour sample. '
                    'A cool white next to a warm wall can make both look wrong.',
              ),
              const _GuideStep(
                number: '6',
                title: 'Live with it for 48 hours',
                body:
                    'Tape the card to the wall and leave it. Your first '
                    'impression may change after living with it. If you still '
                    'love it after two days in all lighting conditions, '
                    "you've found your colour.",
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PaletteColours.softCream,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: PaletteColours.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Colours on screens are approximations. Physical samples '
                        'are the only way to be certain. Invest the small cost '
                        'of samples to avoid the large cost of repainting.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: PaletteColours.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.number,
    required this.title,
    required this.body,
  });

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: PaletteColours.sageGreen,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: PaletteColours.textOnAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: PaletteColours.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
