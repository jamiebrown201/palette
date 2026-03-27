import 'package:flutter/material.dart';
import 'package:palette/core/theme/palette_colours.dart';

/// Displays the standard colour accuracy disclaimer.
///
/// Per spec: "Colours on screens are approximations. Always test
/// physical samples before committing."
class ColourDisclaimer extends StatelessWidget {
  const ColourDisclaimer({this.prefix, super.key});

  final String? prefix;

  @override
  Widget build(BuildContext context) {
    final text = prefix != null
        ? '$prefix Colours on screens are approximations. '
            'Always test physical samples before committing.'
        : 'Colours on screens are approximations. '
            'Always test physical samples before committing.';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 14,
            color: PaletteColours.textTertiary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PaletteColours.textTertiary,
                    fontSize: 11,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
