import 'package:palette/data/repositories/feedback_repository.dart';
import 'package:palette/features/rooms/logic/product_scoring.dart';

/// Aggregated feedback statistics for one product category.
class CategoryFeedbackStats {
  const CategoryFeedbackStats({
    required this.category,
    required this.totalDismissals,
    required this.reasonBreakdown,
    required this.topReason,
  });

  final String category;
  final int totalDismissals;

  /// reason -> count
  final Map<String, int> reasonBreakdown;
  final String? topReason;
}

/// A suggested weight adjustment based on aggregate feedback patterns.
class WeightAdjustment {
  const WeightAdjustment({
    required this.category,
    required this.dimension,
    required this.currentWeight,
    required this.suggestedWeight,
    required this.reason,
  });

  final String category;
  final String dimension;
  final double currentWeight;
  final double suggestedWeight;
  final String reason;
}

/// Overall feedback summary including action counts and suggested adjustments.
class FeedbackSummary {
  const FeedbackSummary({
    required this.totalFeedback,
    required this.dismissCount,
    required this.saveCount,
    required this.buyCount,
    required this.categoryStats,
    required this.suggestedAdjustments,
  });

  final int totalFeedback;
  final int dismissCount;
  final int saveCount;
  final int buyCount;
  final List<CategoryFeedbackStats> categoryStats;
  final List<WeightAdjustment> suggestedAdjustments;
}

/// Analyses persisted recommendation feedback to surface patterns
/// and suggest scoring weight recalibrations.
///
/// Spec 2C.1: "Aggregate user feedback (save, dismiss with reason, buy)
/// to refine scoring weights. This does not require ML; adjust weights
/// based on aggregate engagement patterns."
class FeedbackAggregationService {
  FeedbackAggregationService(this._repo);

  final FeedbackRepository _repo;

  /// Minimum dismissals in a category before suggesting weight changes.
  static const int _minDismissals = 5;

  /// Threshold: if a reason accounts for > 40% of dismissals, suggest
  /// increasing the corresponding weight.
  static const double _dominantReasonThreshold = 0.40;

  /// Generate a complete feedback summary with suggested adjustments.
  Future<FeedbackSummary> analyse({
    ScoringWeights weights = kDefaultWeights,
  }) async {
    final actionCounts = await _repo.actionCounts();
    final dismissCount = actionCounts['dismiss'] ?? 0;
    final saveCount = actionCounts['save'] ?? 0;
    final buyCount = actionCounts['buy'] ?? 0;
    final total = dismissCount + saveCount + buyCount;

    final byCategory = await _repo.dismissReasonCountsByCategory();

    final categoryStats = <CategoryFeedbackStats>[];
    for (final entry in byCategory.entries) {
      final totalCat = entry.value.values.fold<int>(0, (s, v) => s + v);
      String? topReason;
      var topCount = 0;
      for (final reason in entry.value.entries) {
        if (reason.value > topCount) {
          topCount = reason.value;
          topReason = reason.key;
        }
      }
      categoryStats.add(
        CategoryFeedbackStats(
          category: entry.key,
          totalDismissals: totalCat,
          reasonBreakdown: entry.value,
          topReason: topReason,
        ),
      );
    }

    // Sort by most dismissed category first.
    categoryStats.sort(
      (a, b) => b.totalDismissals.compareTo(a.totalDismissals),
    );

    final adjustments = _suggestAdjustments(
      categoryStats: categoryStats,
      weights: weights,
    );

    return FeedbackSummary(
      totalFeedback: total,
      dismissCount: dismissCount,
      saveCount: saveCount,
      buyCount: buyCount,
      categoryStats: categoryStats,
      suggestedAdjustments: adjustments,
    );
  }

  /// Map dismiss reasons to scoring dimensions and suggest weight bumps.
  List<WeightAdjustment> _suggestAdjustments({
    required List<CategoryFeedbackStats> categoryStats,
    required ScoringWeights weights,
  }) {
    final adjustments = <WeightAdjustment>[];

    for (final stat in categoryStats) {
      if (stat.totalDismissals < _minDismissals) continue;

      for (final entry in stat.reasonBreakdown.entries) {
        final ratio = entry.value / stat.totalDismissals;
        if (ratio < _dominantReasonThreshold) continue;

        final mapping = _reasonToDimension(entry.key, weights);
        if (mapping == null) continue;

        // Suggest a 20% weight increase for the dominant reason.
        final bumped = (mapping.currentWeight * 1.20).clamp(0.0, 0.30);

        adjustments.add(
          WeightAdjustment(
            category: stat.category,
            dimension: mapping.dimension,
            currentWeight: mapping.currentWeight,
            suggestedWeight: bumped,
            reason:
                '"${entry.key}" accounts for '
                '${(ratio * 100).toStringAsFixed(0)}% '
                'of ${stat.category} dismissals.',
          ),
        );
      }
    }

    return adjustments;
  }

  /// Map a dismiss reason string to the scoring dimension it corresponds to.
  ({String dimension, double currentWeight})? _reasonToDimension(
    String reason,
    ScoringWeights weights,
  ) => switch (reason) {
    'price' => (dimension: 'budgetFit', currentWeight: weights.budgetFit),
    'colour' => (
      dimension: 'colourCompatibility',
      currentWeight: weights.colourCompatibility,
    ),
    'style' => (dimension: 'styleFit', currentWeight: weights.styleFit),
    'scale' => (dimension: 'scaleFit', currentWeight: weights.scaleFit),
    'material' => (
      dimension: 'finishMaterialHarmony',
      currentWeight: weights.finishMaterialHarmony,
    ),
    _ => null,
  };
}
