import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/data/models/moodboard.dart';
import 'package:palette/features/moodboards/providers/moodboard_providers.dart';

/// Card displaying a moodboard with colour swatch preview strip.
class MoodboardCard extends ConsumerWidget {
  const MoodboardCard({
    required this.moodboard,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final Moodboard moodboard;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(moodboardItemsProvider(moodboard.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: PaletteColours.cardBackground,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      moodboard.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    color: PaletteColours.textTertiary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              if (moodboard.roomName != null) ...[
                const SizedBox(height: 4),
                Text(
                  moodboard.roomName!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PaletteColours.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Colour swatch preview strip
              items.when(
                loading:
                    () => const SizedBox(
                      height: 40,
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                error: (_, __) => const SizedBox(height: 40),
                data: (itemList) {
                  final colourItems =
                      itemList
                          .where(
                            (i) => i.type == 'colour' && i.colourHex != null,
                          )
                          .take(8)
                          .toList();
                  if (colourItems.isEmpty) {
                    return Container(
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: PaletteColours.softCream,
                      ),
                      child: Center(
                        child: Text(
                          '${itemList.length} item${itemList.length == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: PaletteColours.textTertiary),
                        ),
                      ),
                    );
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 40,
                      child: Row(
                        children:
                            colourItems.map((item) {
                              return Expanded(
                                child: Container(
                                  color: _parseHex(item.colourHex!),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                _formattedDate(moodboard.updatedAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PaletteColours.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _parseHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    return PaletteColours.warmGrey;
  }

  static String _formattedDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
