import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/widgets/premium_gate.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/moodboard_item.dart';
import 'package:palette/features/moodboards/providers/moodboard_providers.dart';
import 'package:palette/features/moodboards/widgets/add_colour_sheet.dart'
    show AddColourSheet, AddItemResult;
import 'package:palette/features/moodboards/widgets/moodboard_item_tile.dart';
import 'package:palette/providers/app_providers.dart';
import 'package:palette/providers/database_providers.dart';
import 'package:uuid/uuid.dart';

/// Detail view for a single moodboard — grid of swatches, images, and notes.
class MoodboardDetailScreen extends ConsumerWidget {
  const MoodboardDetailScreen({required this.moodboardId, super.key});

  final String moodboardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(moodboardByIdProvider(moodboardId));
    final items = ref.watch(moodboardItemsProvider(moodboardId));
    final tier = ref.watch(subscriptionTierProvider);
    final isPremium = tier >= SubscriptionTier.plus;

    return board.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (_, __) => Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text(
                'Something went wrong. Please go back and try again.',
              ),
            ),
          ),
      data: (moodboard) {
        if (moodboard == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Moodboard not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              moodboard.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            backgroundColor: PaletteColours.warmWhite,
            surfaceTintColor: Colors.transparent,
            actions: [
              if (isPremium)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed:
                      () => _renameMoodboard(context, ref, moodboard.name),
                  tooltip: 'Rename',
                ),
            ],
          ),
          backgroundColor: PaletteColours.warmWhite,
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddSheet(context, ref),
            backgroundColor: PaletteColours.sageGreen,
            foregroundColor: PaletteColours.textOnAccent,
            tooltip: 'Add item',
            child: const Icon(Icons.add),
          ),
          body: items.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (_, __) => const Center(
                  child: Text('Something went wrong. Tap to retry.'),
                ),
            data: (itemList) {
              if (itemList.isEmpty) {
                return _EmptyMoodboard(
                  onAdd: () => _showAddSheet(context, ref),
                );
              }

              // Colour summary at top
              final colourItems =
                  itemList
                      .where((i) => i.type == 'colour' && i.colourHex != null)
                      .toList();

              return CustomScrollView(
                slivers: [
                  // Colour strip summary
                  if (colourItems.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Colour summary',
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(
                                color: PaletteColours.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                height: 32,
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
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${colourItems.length} colour${colourItems.length == 1 ? '' : 's'}'
                              ' · ${itemList.length} total item${itemList.length == 1 ? '' : 's'}',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: PaletteColours.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Premium gate for editing (free users can view only)
                  if (!isPremium && itemList.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: PremiumGate(
                          requiredTier: SubscriptionTier.plus,
                          upgradeMessage:
                              'Upgrade to edit and share moodboards',
                          child: SizedBox(height: 48),
                        ),
                      ),
                    ),

                  // Grid of items
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.0,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        childCount: itemList.length,
                        (context, index) {
                          final item = itemList[index];
                          return MoodboardItemTile(
                            item: item,
                            onDelete:
                                isPremium
                                    ? () => _deleteItem(ref, item.id)
                                    : null,
                            onLabelEdit:
                                isPremium
                                    ? () => _editLabel(context, ref, item)
                                    : null,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showAddSheet(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<AddItemResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PaletteColours.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => AddColourSheet(moodboardId: moodboardId),
    );

    if (result == null) return;

    final repo = ref.read(moodboardRepositoryProvider);
    final existingItems = await repo.getItems(moodboardId);
    final nextOrder = existingItems.isEmpty ? 0 : existingItems.length;

    await repo.addItem(
      MoodboardItemsCompanion.insert(
        id: const Uuid().v4(),
        moodboardId: moodboardId,
        type: result.type,
        colourHex: Value(result.colourHex),
        colourName: Value(result.colourName),
        imageUrl: Value(result.imageUrl),
        productId: const Value(null),
        label: Value(result.label),
        sortOrder: nextOrder,
        addedAt: DateTime.now(),
      ),
    );

    // Touch the moodboard's updatedAt
    await repo.update(
      moodboardId,
      MoodboardsCompanion(updatedAt: Value(DateTime.now())),
    );
  }

  Future<void> _deleteItem(WidgetRef ref, String id) async {
    await ref.read(moodboardRepositoryProvider).removeItem(id);
    await ref
        .read(moodboardRepositoryProvider)
        .update(
          moodboardId,
          MoodboardsCompanion(updatedAt: Value(DateTime.now())),
        );
  }

  Future<void> _editLabel(
    BuildContext context,
    WidgetRef ref,
    MoodboardItem item,
  ) async {
    final controller = TextEditingController(text: item.label);
    try {
      final newLabel = await showDialog<String>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Edit note'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Add a note...',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) => Navigator.pop(ctx, value),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, controller.text),
                  child: const Text('Save'),
                ),
              ],
            ),
      );

      if (newLabel == null) return;
      await ref
          .read(moodboardRepositoryProvider)
          .updateItemLabel(item.id, newLabel.isEmpty ? null : newLabel);
    } finally {
      controller.dispose();
    }
  }

  Future<void> _renameMoodboard(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    try {
      final newName = await showDialog<String>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Rename moodboard'),
              content: TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onSubmitted: (value) => Navigator.pop(ctx, value),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, controller.text),
                  child: const Text('Save'),
                ),
              ],
            ),
      );

      if (newName == null || newName.trim().isEmpty) return;
      await ref
          .read(moodboardRepositoryProvider)
          .update(
            moodboardId,
            MoodboardsCompanion(
              name: Value(newName.trim()),
              updatedAt: Value(DateTime.now()),
            ),
          );
    } finally {
      controller.dispose();
    }
  }

  static Color _parseHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    return PaletteColours.warmGrey;
  }
}

class _EmptyMoodboard extends StatelessWidget {
  const _EmptyMoodboard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.palette_outlined,
              size: 56,
              color: PaletteColours.sageGreen.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Start collecting',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add colour swatches and images\nto build your vision.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: PaletteColours.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add first item'),
              style: FilledButton.styleFrom(
                backgroundColor: PaletteColours.sageGreen,
                foregroundColor: PaletteColours.textOnAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
