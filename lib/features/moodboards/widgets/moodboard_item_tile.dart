import 'package:flutter/material.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/data/models/moodboard_item.dart';

/// A single tile in the moodboard grid.
///
/// Renders differently based on item type: colour swatch, image, or product.
class MoodboardItemTile extends StatelessWidget {
  const MoodboardItemTile({
    required this.item,
    this.onDelete,
    this.onLabelEdit,
    super.key,
  });

  final MoodboardItem item;
  final VoidCallback? onDelete;
  final VoidCallback? onLabelEdit;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLabelEdit,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildContent(context),
            if (item.label != null && item.label!.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        PaletteColours.textOnAccent.withValues(alpha: 0),
                        PaletteColours.textPrimary.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  child: Text(
                    item.label!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PaletteColours.textOnAccent,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            if (onDelete != null)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDelete,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: PaletteColours.textPrimary.withValues(
                            alpha: 0.4,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: PaletteColours.textOnAccent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (item.type) {
      case 'colour':
        return _buildColour(context);
      case 'image':
        return _buildImage();
      default:
        return const ColoredBox(
          color: PaletteColours.softCream,
          child: Center(child: Icon(Icons.help_outline)),
        );
    }
  }

  Widget _buildColour(BuildContext context) {
    final hex = item.colourHex ?? 'E8E4DE';
    final cleaned = hex.replaceFirst('#', '');
    final colour =
        cleaned.length == 6
            ? Color(int.parse('FF$cleaned', radix: 16))
            : PaletteColours.warmGrey;

    return ColoredBox(
      color: colour,
      child:
          item.colourName != null && item.label == null
              ? Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        PaletteColours.textOnAccent.withValues(alpha: 0),
                        PaletteColours.textPrimary.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.colourName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PaletteColours.textOnAccent,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '#$cleaned'.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PaletteColours.textOnAccent.withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : null,
    );
  }

  Widget _buildImage() {
    if (item.imageUrl == null || item.imageUrl!.isEmpty) {
      return const ColoredBox(
        color: PaletteColours.softCream,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: PaletteColours.textTertiary,
          ),
        ),
      );
    }
    return Image.network(
      item.imageUrl!,
      fit: BoxFit.cover,
      errorBuilder:
          (_, __, ___) => const ColoredBox(
            color: PaletteColours.softCream,
            child: Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: PaletteColours.textTertiary,
              ),
            ),
          ),
    );
  }
}
