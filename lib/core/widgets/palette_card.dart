import 'package:flutter/material.dart';
import 'package:palette/core/theme/palette_colours.dart';

/// Card depth levels for visual hierarchy.
/// Level 0: flush (backgrounds), Level 1: subtle (content cards),
/// Level 2: elevated (interactive cards, CTAs, Next Action).
enum CardDepth { flush, subtle, elevated }

/// Standard card container with consistent styling and depth hierarchy.
class PaletteCard extends StatelessWidget {
  const PaletteCard({
    required this.child,
    this.title,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.depth = CardDepth.subtle,
    super.key,
  });

  final Widget child;
  final String? title;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final CardDepth depth;

  List<BoxShadow> get _shadows => switch (depth) {
    CardDepth.flush => const [],
    CardDepth.subtle => const [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
    CardDepth.elevated => const [
      BoxShadow(
        color: Color(0x1F000000),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PaletteColours.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PaletteColours.divider),
        boxShadow: _shadows,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
