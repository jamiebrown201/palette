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

    final cards =
        (prompt['cards'] as List<dynamic>).cast<Map<String, dynamic>>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            prompt['prompt'] as String,
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the one that resonates most',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: PaletteColours.textTertiary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.95,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                final hex = card['hex'] as String;
                final colour = _hexToColor(hex);
                final familyWeights =
                    (card['familyWeights'] as Map<String, dynamic>)
                        .map((k, v) => MapEntry(k, (v as num).toInt()));

                return _ColourMoodCard(
                  label: card['label'] as String,
                  colour: colour,
                  delayMs: index * 80,
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

class _ColourMoodCard extends StatefulWidget {
  const _ColourMoodCard({
    required this.label,
    required this.colour,
    required this.onTap,
    this.delayMs = 0,
  });

  final String label;
  final Color colour;
  final VoidCallback onTap;
  final int delayMs;

  @override
  State<_ColourMoodCard> createState() => _ColourMoodCardState();
}

class _ColourMoodCardState extends State<_ColourMoodCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;
  bool _selected = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_selected) return;
    setState(() => _selected = true);
    Future.delayed(const Duration(milliseconds: 350), widget.onTap);
  }

  @override
  Widget build(BuildContext context) {
    final textColour =
        widget.colour.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideIn,
        child: Semantics(
          button: true,
          label: '${widget.label} colour card',
          child: GestureDetector(
            onTap: _handleTap,
            child: AnimatedScale(
              scale: _selected ? 0.95 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: widget.colour,
                  borderRadius: BorderRadius.circular(16),
                  border: _selected
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: widget.colour.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          widget.label,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: textColour,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ),
                    if (_selected)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: AnimatedOpacity(
                          opacity: _selected ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: widget.colour.computeLuminance() > 0.5
                                  ? Colors.black87
                                  : widget.colour,
                            ),
                          ),
                        ),
                      ),
                  ],
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
