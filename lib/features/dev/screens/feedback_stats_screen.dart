import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/features/rooms/logic/feedback_aggregation.dart';
import 'package:palette/features/rooms/providers/feedback_providers.dart';

/// Debug-only screen showing aggregated recommendation feedback.
///
/// Surfaces dismiss patterns and suggested weight adjustments (Phase 2C.1).
class FeedbackStatsScreen extends ConsumerWidget {
  const FeedbackStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(kDebugMode, 'FeedbackStatsScreen should only be used in debug');

    final summaryAsync = ref.watch(feedbackSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Feedback Stats')),
      body: summaryAsync.when(
        data: (summary) => _Body(summary: summary),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.summary});

  final FeedbackSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (summary.totalFeedback == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.feedback_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('No feedback yet', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Feedback is recorded when users save, buy, or dismiss '
                'product recommendations.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: PaletteColours.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overview counts
        const _SectionTitle('Overview'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _CountChip(
                  label: 'Dismissals',
                  count: summary.dismissCount,
                  colour: Colors.red.shade300,
                ),
                const SizedBox(width: 12),
                _CountChip(
                  label: 'Saves',
                  count: summary.saveCount,
                  colour: PaletteColours.sageGreen,
                ),
                const SizedBox(width: 12),
                _CountChip(
                  label: 'Buys',
                  count: summary.buyCount,
                  colour: PaletteColours.softGold,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Per-category breakdown
        if (summary.categoryStats.isNotEmpty) ...[
          const _SectionTitle('Dismiss reasons by category'),
          const SizedBox(height: 8),
          for (final stat in summary.categoryStats) _CategoryCard(stat: stat),
          const SizedBox(height: 24),
        ],

        // Suggested adjustments
        const _SectionTitle('Suggested weight adjustments'),
        const SizedBox(height: 8),
        if (summary.suggestedAdjustments.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Not enough data yet. Need at least 5 dismissals per '
                'category with a dominant reason (>40%) to suggest changes.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: PaletteColours.textTertiary,
                ),
              ),
            ),
          )
        else
          for (final adj in summary.suggestedAdjustments)
            _AdjustmentCard(adjustment: adj),

        const SizedBox(height: 24),

        // Current weights
        const _SectionTitle('Current scoring weights'),
        const SizedBox(height: 8),
        _WeightsCard(),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
  );
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.count,
    required this.colour,
  });

  final String label;
  final int count;
  final Color colour;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colour,
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colour),
          ),
        ],
      ),
    ),
  );
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.stat});

  final CategoryFeedbackStats stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(stat.category, style: theme.textTheme.titleSmall),
                const Spacer(),
                Text(
                  '${stat.totalDismissals} dismissals',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: PaletteColours.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final entry in stat.reasonBreakdown.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(entry.key, style: theme.textTheme.bodySmall),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value:
                            stat.totalDismissals > 0
                                ? entry.value / stat.totalDismissals
                                : 0,
                        backgroundColor: PaletteColours.warmGrey.withValues(
                          alpha: 0.3,
                        ),
                        color:
                            entry.key == stat.topReason
                                ? Colors.red.shade300
                                : PaletteColours.sageGreen,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${entry.value}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AdjustmentCard extends StatelessWidget {
  const _AdjustmentCard({required this.adjustment});

  final WeightAdjustment adjustment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: PaletteColours.softGold.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: PaletteColours.softGold,
                ),
                const SizedBox(width: 6),
                Text(
                  '${adjustment.category}: ${adjustment.dimension}',
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              adjustment.reason,
              style: theme.textTheme.bodySmall?.copyWith(
                color: PaletteColours.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${(adjustment.currentWeight * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, size: 12),
                const SizedBox(width: 4),
                Text(
                  '${(adjustment.suggestedWeight * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: PaletteColours.sageGreenDark,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(+${((adjustment.suggestedWeight - adjustment.currentWeight) * 100).toStringAsFixed(0)}%)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: PaletteColours.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(scoringWeightsConfigProvider);

    return configAsync.when(
      data: (config) {
        final w = config.global;
        final entries =
            w.toJson().entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Version ${config.version}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PaletteColours.textTertiary,
                  ),
                ),
                const SizedBox(height: 8),
                for (final entry in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            entry.key,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: LinearProgressIndicator(
                            value: entry.value,
                            backgroundColor: PaletteColours.warmGrey.withValues(
                              alpha: 0.3,
                            ),
                            color: PaletteColours.sageGreen,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 36,
                          child: Text(
                            '${(entry.value * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (config.categoryOverrides.isNotEmpty) ...[
                  const Divider(height: 16),
                  Text(
                    'Category overrides: '
                    '${config.categoryOverrides.keys.join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PaletteColours.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading:
          () => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      error:
          (e, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error loading weights: $e'),
            ),
          ),
    );
  }
}
