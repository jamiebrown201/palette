/// A persisted record of user feedback on a product recommendation.
///
/// Used by the Recommendation Feedback Loop (2C.1) to aggregate dismiss
/// patterns, saves, and buys for scoring weight recalibration.
class RecommendationFeedback {
  const RecommendationFeedback({
    required this.id,
    required this.productId,
    required this.roomId,
    required this.productCategory,
    required this.action,
    required this.createdAt,
    this.dismissReason,
  });

  final String id;
  final String productId;
  final String roomId;
  final String productCategory;

  /// 'dismiss', 'save', or 'buy'.
  final String action;

  /// Only set when [action] is 'dismiss'. Values: 'style', 'price',
  /// 'colour', 'scale', 'material', 'other'.
  final String? dismissReason;

  final DateTime createdAt;
}
