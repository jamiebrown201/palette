import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/features/rooms/logic/feedback_aggregation.dart';
import 'package:palette/features/rooms/logic/product_scoring.dart';
import 'package:palette/providers/database_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feedback_providers.g.dart';

/// Versioned scoring weights loaded from the bundled JSON asset.
@Riverpod(keepAlive: true)
Future<ScoringWeightsConfig> scoringWeightsConfig(Ref ref) =>
    ScoringWeightsConfig.load();

/// The feedback aggregation service.
@Riverpod(keepAlive: true)
FeedbackAggregationService feedbackAggregationService(Ref ref) =>
    FeedbackAggregationService(ref.watch(feedbackRepositoryProvider));

/// Computed feedback summary with suggested weight adjustments.
@riverpod
Future<FeedbackSummary> feedbackSummary(Ref ref) async {
  final service = ref.watch(feedbackAggregationServiceProvider);
  final config = await ref.watch(scoringWeightsConfigProvider.future);
  return service.analyse(weights: config.global);
}
