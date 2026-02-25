import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/features/onboarding/providers/quiz_providers.dart';
import 'package:share_plus/share_plus.dart';

/// The quiz result page showing the generated colour palette.
class QuizResultPage extends ConsumerStatefulWidget {
  const QuizResultPage({
    required this.onComplete,
    super.key,
  });

  final VoidCallback onComplete;

  @override
  ConsumerState<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends ConsumerState<QuizResultPage> {
  final _repaintKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareColourDna() async {
    setState(() => _isSharing = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'image/png', name: 'colour-dna.png')],
        text: 'I just discovered my Colour DNA! '
            'Take the quiz to find yours: https://palette.app/quiz',
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizNotifierProvider);
    final palette = quizState.generatedPalette;

    if (palette == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          RepaintBoundary(
            key: _repaintKey,
            child: Container(
              color: PaletteColours.warmWhite,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'My Colour DNA',
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your personal palette, built from your instincts',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: PaletteColours.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Primary family badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: PaletteColours.sageGreenLight,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      palette.primaryFamily.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: PaletteColours.sageGreenDark,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),

                  if (palette.secondaryFamily != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'with ${palette.secondaryFamily!.displayName} undertones',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: PaletteColours.textSecondary,
                          ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    palette.primaryFamily.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: PaletteColours.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Colour grid
                  _PaletteGrid(
                    colours: palette.colours.map((c) => c.hex).toList(),
                    surpriseIndices: [
                      for (var i = 0; i < palette.colours.length; i++)
                        if (palette.colours[i].isSurprise) i,
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Section header for colour list
          Text(
            'Your Colours',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          // Colour list with names
          ...palette.colours.map((entry) {
            final colourName = entry.paintColour?.name ?? 'Custom';
            final brand = entry.paintColour?.brand;
            return _ColourListItem(
              hex: entry.hex,
              name: colourName,
              brand: brand,
              isSurprise: entry.isSurprise,
            );
          }),

          const SizedBox(height: 32),

          // Share button
          OutlinedButton.icon(
            onPressed: _isSharing ? null : _shareColourDna,
            icon: _isSharing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined),
            label: Text(_isSharing ? 'Preparing...' : 'Share My Colour DNA'),
          ),
          const SizedBox(height: 12),

          FilledButton(
            onPressed: widget.onComplete,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Explore My Palette'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _PaletteGrid extends StatelessWidget {
  const _PaletteGrid({
    required this.colours,
    required this.surpriseIndices,
  });

  final List<String> colours;
  final List<int> surpriseIndices;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < colours.length; i++)
          Semantics(
            label:
                'Palette colour ${i + 1}${surpriseIndices.contains(i) ? ', surprise colour' : ''}',
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _hexToColor(colours[i]),
                borderRadius: BorderRadius.circular(10),
                border: surpriseIndices.contains(i)
                    ? Border.all(
                        color: PaletteColours.softGold,
                        width: 2,
                      )
                    : Border.all(
                        color: Colors.black.withValues(alpha: 0.05),
                      ),
              ),
              child: surpriseIndices.contains(i)
                  ? const Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.all(3),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: PaletteColours.softGold,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}

class _ColourListItem extends StatelessWidget {
  const _ColourListItem({
    required this.hex,
    required this.name,
    required this.isSurprise,
    this.brand,
  });

  final String hex;
  final String name;
  final String? brand;
  final bool isSurprise;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _hexToColor(hex),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: PaletteColours.divider),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (brand != null)
                  Text(
                    brand!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PaletteColours.textTertiary,
                        ),
                  ),
              ],
            ),
          ),
          if (isSurprise)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: PaletteColours.softGoldLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Surprise',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: PaletteColours.softGoldDark,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
