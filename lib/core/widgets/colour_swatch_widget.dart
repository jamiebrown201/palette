import 'package:flutter/material.dart';
import 'package:palette/core/theme/palette_colours.dart';

/// A reusable colour swatch widget that displays a colour sample
/// with its name label. Never displays colour alone (accessibility).
class ColourSwatchWidget extends StatelessWidget {
  const ColourSwatchWidget({
    required this.colour,
    required this.name,
    this.size = 48,
    this.showName = true,
    this.isSelected = false,
    this.onTap,
    this.undertoneLabel,
    super.key,
  });

  final Color colour;
  final String name;
  final double size;
  final bool showName;
  final bool isSelected;
  final VoidCallback? onTap;
  final String? undertoneLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$name colour swatch'
          '${undertoneLabel != null ? ', $undertoneLabel undertone' : ''}',
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: colour,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? PaletteColours.sageGreen
                      : PaletteColours.divider,
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: undertoneLabel != null
                  ? Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: PaletteColours.cardBackground.withValues(
                            alpha: 0.9,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          undertoneLabel!,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: PaletteColours.textPrimary,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            if (showName) ...[
              const SizedBox(height: 4),
              SizedBox(
                width: size + 8,
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.labelSmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
