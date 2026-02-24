import 'package:flutter/material.dart';
import 'package:palette/core/theme/palette_colours.dart';

/// A mosaic grid displaying the user's palette colours.
class PaletteGrid extends StatelessWidget {
  const PaletteGrid({
    required this.hexColours,
    this.onColourTap,
    super.key,
  });

  final List<String> hexColours;
  final void Function(String hex)? onColourTap;

  @override
  Widget build(BuildContext context) {
    if (hexColours.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < hexColours.length; i++)
          _GridTile(
            hex: hexColours[i],
            index: i,
            onTap: onColourTap != null
                ? () => onColourTap!(hexColours[i])
                : null,
          ),
      ],
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.hex,
    required this.index,
    this.onTap,
  });

  final String hex;
  final int index;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Alternate between larger and smaller tiles for visual interest
    final isLarge = index % 3 == 0;
    final size = isLarge ? 80.0 : 64.0;

    return Semantics(
      button: onTap != null,
      label: 'Palette colour ${index + 1}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _hexToColor(hex),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: PaletteColours.divider,
              width: 0.5,
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
