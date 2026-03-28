import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/widgets/section_header.dart';
import 'package:palette/data/models/shopping_list_item.dart';
import 'package:palette/features/shopping_list/providers/shopping_list_providers.dart';
import 'package:palette/providers/analytics_provider.dart';
import 'package:palette/providers/database_providers.dart';
import 'package:url_launcher/url_launcher.dart';

/// The aggregated Shopping List screen (Phase 2B.2).
///
/// Shows all saved product recommendations grouped by retailer,
/// with total estimated cost and direct buy links.
class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(shoppingListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          itemsAsync.whenOrNull(
                data:
                    (items) =>
                        items.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Clear all',
                              onPressed: () => _confirmClearAll(context, ref),
                            )
                            : null,
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: itemsAsync.when(
        loading:
            () => const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        error: (_, __) => const Center(child: Text('Could not load list')),
        data: (items) {
          if (items.isEmpty) return const _EmptyState();
          return _ShoppingListBody(items: items);
        },
      ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Clear shopping list?'),
            content: const Text(
              'This will remove all items from your shopping list.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  ref.read(shoppingListRepositoryProvider).clearAll();
                  Navigator.pop(ctx);
                },
                child: Text(
                  'Clear all',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ],
          ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: PaletteColours.warmGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'Your shopping list is empty',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Save product recommendations from your rooms '
              'to build your shopping list.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PaletteColours.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShoppingListBody extends ConsumerWidget {
  const _ShoppingListBody({required this.items});

  final List<ShoppingListItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Group by retailer
    final byRetailer = <String, List<ShoppingListItem>>{};
    for (final item in items) {
      byRetailer.putIfAbsent(item.retailer, () => []).add(item);
    }
    final retailers = byRetailer.keys.toList()..sort();

    // Total cost
    final total = items.fold<double>(0, (sum, i) => sum + i.priceGbp);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PaletteColours.softCream,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  offset: Offset(0, 1),
                  blurRadius: 4,
                  color: Color(0x0A000000),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'across ${retailers.length} ${retailers.length == 1 ? 'retailer' : 'retailers'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: PaletteColours.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Estimated total',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: PaletteColours.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '£${total.toStringAsFixed(0)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: PaletteColours.sageGreenDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Grouped by retailer
          for (final retailer in retailers) ...[
            SectionHeader(title: retailer),
            ...byRetailer[retailer]!.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ShoppingListItemCard(item: item),
              ),
            ),
            // Retailer subtotal
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Subtotal: £${byRetailer[retailer]!.fold<double>(0, (s, i) => s + i.priceGbp).toStringAsFixed(0)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: PaletteColours.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Commission disclosure
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'We may earn a commission if you buy through these links. '
              'This never affects which products we recommend.',
              style: theme.textTheme.bodySmall?.copyWith(
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

class _ShoppingListItemCard extends ConsumerWidget {
  const _ShoppingListItemCard({required this.item});

  final ShoppingListItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colour = hexToColor(item.primaryColourHex);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: Colors.red.shade700),
      ),
      onDismissed: (_) {
        ref.read(shoppingListRepositoryProvider).removeItem(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.productName} removed'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PaletteColours.warmGrey),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 1),
              blurRadius: 4,
              color: Color(0x0A000000),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Colour swatch
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colour,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: PaletteColours.warmGrey,
                    width: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.brand} · ${item.categoryName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: PaletteColours.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.meeting_room_outlined,
                          size: 12,
                          color: PaletteColours.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.roomName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: PaletteColours.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Price + buy
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '£${item.priceGbp.toStringAsFixed(0)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 28,
                    child: FilledButton.icon(
                      onPressed: () => _openLink(context, ref),
                      icon: const Icon(Icons.open_in_new, size: 12),
                      label: const Text('Buy'),
                      style: FilledButton.styleFrom(
                        backgroundColor: PaletteColours.sageGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        textStyle: const TextStyle(fontSize: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openLink(BuildContext context, WidgetRef ref) async {
    ref.read(analyticsProvider).track('affiliate_link_tapped', {
      'product_id': item.productId,
      'product_category': item.categoryName,
      'price': item.priceGbp,
      'retailer': item.retailer,
      'source': 'shopping_list',
    });

    final uri = Uri.tryParse(item.affiliateUrl);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    }
  }
}
