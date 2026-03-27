import 'package:flutter/material.dart';

/// Standard card container with consistent styling.
class PaletteCard extends StatelessWidget {
  const PaletteCard({
    required this.child,
    this.title,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final String? title;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
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
    );
  }
}
