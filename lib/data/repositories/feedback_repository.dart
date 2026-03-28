import 'package:drift/drift.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/recommendation_feedback.dart';

/// Repository for persisting and querying recommendation feedback.
///
/// Stores dismiss/save/buy actions so the Feedback Loop (2C.1) can
/// aggregate patterns and suggest scoring weight adjustments.
class FeedbackRepository {
  FeedbackRepository(this._db);

  final PaletteDatabase _db;

  /// Record a feedback action.
  Future<void> record(RecommendationFeedbacksCompanion entry) =>
      _db.into(_db.recommendationFeedbacks).insert(entry);

  /// All feedback entries, newest first.
  Future<List<RecommendationFeedback>> getAll() =>
      (_db.select(_db.recommendationFeedbacks)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  /// Feedback for a specific product.
  Future<List<RecommendationFeedback>> getForProduct(String productId) =>
      (_db.select(_db.recommendationFeedbacks)
        ..where((t) => t.productId.equals(productId))).get();

  /// Count of feedback entries grouped by action.
  Future<Map<String, int>> actionCounts() async {
    final all = await getAll();
    final counts = <String, int>{};
    for (final f in all) {
      counts[f.action] = (counts[f.action] ?? 0) + 1;
    }
    return counts;
  }

  /// Count of dismiss reasons across all dismissals.
  Future<Map<String, int>> dismissReasonCounts() async {
    final all = await getAll();
    final counts = <String, int>{};
    for (final f in all) {
      if (f.action == 'dismiss' && f.dismissReason != null) {
        counts[f.dismissReason!] = (counts[f.dismissReason!] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Dismiss reason counts broken down by product category.
  Future<Map<String, Map<String, int>>> dismissReasonCountsByCategory() async {
    final all = await getAll();
    final result = <String, Map<String, int>>{};
    for (final f in all) {
      if (f.action == 'dismiss' && f.dismissReason != null) {
        result.putIfAbsent(f.productCategory, () => <String, int>{});
        final cat = result[f.productCategory]!;
        cat[f.dismissReason!] = (cat[f.dismissReason!] ?? 0) + 1;
      }
    }
    return result;
  }

  /// Total count of all feedback entries.
  Future<int> totalCount() async {
    final countExp = _db.recommendationFeedbacks.id.count();
    final query = _db.selectOnly(_db.recommendationFeedbacks)
      ..addColumns([countExp]);
    final row = await query.getSingleOrNull();
    return row?.read(countExp) ?? 0;
  }

  /// Clear all feedback.
  Future<void> clearAll() => _db.delete(_db.recommendationFeedbacks).go();
}
