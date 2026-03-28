import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/analytics/analytics_events.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/widgets/section_header.dart';
import 'package:palette/data/models/sample_list_item.dart';
import 'package:palette/data/services/seed_data_service.dart';
import 'package:palette/features/samples/providers/sample_list_providers.dart';
import 'package:palette/features/samples/widgets/sample_testing_guide.dart';
import 'package:palette/providers/analytics_provider.dart';
import 'package:palette/providers/database_providers.dart';
import 'package:url_launcher/url_launcher.dart';

/// The Sample List screen (Phase 1D.3).
///
/// Shows paint samples the user wants to order, grouped by brand,
/// with links to each brand's sample ordering page.
class SampleListScreen extends ConsumerStatefulWidget {
  const SampleListScreen({super.key});

  @override
  ConsumerState<SampleListScreen> createState() => _SampleListScreenState();
}

class _SampleListScreenState extends ConsumerState<SampleListScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).track(AnalyticsEvents.sampleListViewed);
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(sampleListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample List'),
        actions: [
          itemsAsync.whenOrNull(
                data:
                    (items) =>
                        items.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Clear all',
                              onPressed: () => _confirmClearAll(context),
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
        error: (_, __) => const Center(child: Text('Could not load samples')),
        data: (items) {
          if (items.isEmpty) return const _EmptyState();
          return _SampleListBody(items: items);
        },
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Clear sample list?'),
            content: const Text('This will remove all samples from your list.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  ref.read(sampleListRepositoryProvider).clearAll();
                  Navigator.pop(ctx);
                },
                child: const Text(
                  'Clear all',
                  style: TextStyle(color: PaletteColours.destructive),
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
              Icons.color_lens_outlined,
              size: 64,
              color: PaletteColours.warmGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'No samples yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Order Sample" on any paint colour '
              'to add it to your list.',
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

class _SampleListBody extends ConsumerWidget {
  const _SampleListBody({required this.items});

  final List<SampleListItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Group by brand
    final byBrand = <String, List<SampleListItem>>{};
    for (final item in items) {
      byBrand.putIfAbsent(item.brand, () => []).add(item);
    }
    final brands = byBrand.keys.toList()..sort();

    // Separate by status
    final hasOrdered = items.any((i) => i.isOrdered);
    final hasArrived = items.any((i) => i.hasArrived);

    // Only show arrival prompt after 3+ days since earliest order (spec 1D.3)
    final orderedItems = items.where((i) => i.isOrdered && !i.hasArrived);
    final earliestOrderedAt =
        orderedItems.isEmpty
            ? null
            : orderedItems
                .map((i) => i.orderedAt!)
                .reduce((a, b) => a.isBefore(b) ? a : b);
    final showArrivalPrompt =
        hasOrdered &&
        !hasArrived &&
        earliestOrderedAt != null &&
        DateTime.now().difference(earliestOrderedAt) >= const Duration(days: 3);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          _SummaryCard(
            itemCount: items.length,
            brandCount: brands.length,
            hasOrdered: hasOrdered,
          ),
          const SizedBox(height: 16),

          // Mark all as ordered button
          if (items.any((i) => !i.isOrdered))
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(sampleListRepositoryProvider).markAllOrdered();
                    ref.read(analyticsProvider).track(
                      AnalyticsEvents.sampleMarkedOrdered,
                      {'scope': 'all'},
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All samples marked as ordered'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text("I've ordered all samples"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PaletteColours.sageGreenDark,
                    side: const BorderSide(color: PaletteColours.sageGreen),
                  ),
                ),
              ),
            ),

          // Samples arrived prompt (3-5 day follow-up per spec 1D.3)
          if (showArrivalPrompt)
            _ArrivedPromptCard(
              onConfirm: () {
                ref.read(sampleListRepositoryProvider).markAllArrived();
                ref.read(analyticsProvider).track(
                  AnalyticsEvents.sampleMarkedArrived,
                  {'scope': 'all'},
                );
              },
            ),

          // Testing guide (shown when samples have arrived)
          if (hasArrived)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SampleTestingGuideCard(
                onTap: () {
                  ref
                      .read(analyticsProvider)
                      .track(AnalyticsEvents.sampleTestingGuideOpened);
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    builder: (_) => const SampleTestingGuideSheet(),
                  );
                },
              ),
            ),

          // Grouped by brand
          for (final brand in brands) ...[
            SectionHeader(
              title: brand,
              actionLabel: 'Order samples',
              onAction: () => _openBrandSamplePage(context, ref, brand),
            ),
            ...byBrand[brand]!.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SampleItemCard(item: item),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Tip
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Always test physical samples in your room before '
              'committing to a colour. Colours on screens are approximations.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: PaletteColours.textTertiary,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openBrandSamplePage(
    BuildContext context,
    WidgetRef ref,
    String brand,
  ) async {
    final configs = await loadRetailerConfigs();
    final config = configs[brand];
    if (config == null) return;
    final uri = Uri.tryParse(config.homepageUrl);
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.itemCount,
    required this.brandCount,
    required this.hasOrdered,
  });

  final int itemCount;
  final int brandCount;
  final bool hasOrdered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaletteColours.softCream,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 1),
            blurRadius: 4,
            color: Color(0x0A2C2C2C),
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
                  '$itemCount ${itemCount == 1 ? 'sample' : 'samples'}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'from $brandCount ${brandCount == 1 ? 'brand' : 'brands'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: PaletteColours.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (hasOrdered)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: PaletteColours.sageGreenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check,
                    size: 14,
                    color: PaletteColours.sageGreenDark,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ordered',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: PaletteColours.sageGreenDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ArrivedPromptCard extends StatelessWidget {
  const _ArrivedPromptCard({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaletteColours.softGoldLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PaletteColours.softGold.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                size: 20,
                color: PaletteColours.softGoldDark,
              ),
              const SizedBox(width: 8),
              Text(
                'Have your samples arrived?',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Once they arrive, we'll show you how to test them "
            'properly in your rooms.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: PaletteColours.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: PaletteColours.softGold,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes, they arrived'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SampleItemCard extends ConsumerWidget {
  const _SampleItemCard({required this.item});

  final SampleListItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colour = hexToColor(item.hex);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: PaletteColours.destructiveLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: PaletteColours.destructive,
        ),
      ),
      onDismissed: (_) {
        ref.read(sampleListRepositoryProvider).removeSample(item.id);
        ref.read(analyticsProvider).track(AnalyticsEvents.sampleRemoved, {
          'brand': item.brand,
          'colour': item.colourName,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.colourName} removed'),
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
              color: Color(0x0A2C2C2C),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Colour swatch
              Container(
                width: 44,
                height: 44,
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
              // Colour info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.colourName,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.brand} · ${item.colourCode}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: PaletteColours.textSecondary,
                      ),
                    ),
                    if (item.roomName != null) ...[
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
                            item.roomName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: PaletteColours.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Status indicators
              _StatusBadge(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.item});

  final SampleListItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (item.hasArrived) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: PaletteColours.sageGreenLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Arrived',
          style: theme.textTheme.labelSmall?.copyWith(
            color: PaletteColours.sageGreenDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    if (item.isOrdered) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: PaletteColours.softGoldLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Ordered',
          style: theme.textTheme.labelSmall?.copyWith(
            color: PaletteColours.softGoldDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
