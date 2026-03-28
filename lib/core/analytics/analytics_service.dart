import 'package:flutter/foundation.dart';
import 'package:palette/core/analytics/analytics_events.dart';

/// Lightweight analytics service.
///
/// Logs events to debug console in debug mode. Designed to be swapped to
/// PostHog or Supabase logging when ready — just override [_dispatch].
class AnalyticsService {
  AnalyticsService();

  /// Track an analytics event with optional properties.
  void track(String event, [Map<String, Object?>? properties]) {
    final props = properties ?? const {};
    _dispatch(event, props);
  }

  /// Track a screen view.
  void screenView(String screenName, [Map<String, Object?>? properties]) {
    track('screen_viewed', {'screen': screenName, ...?properties});
  }

  // ── Recommendation tracking helpers ────────────────────────

  /// Track when a product recommendation card becomes visible.
  void trackRecommendationViewed({
    required String gapType,
    required String productId,
    required int position,
    required String roomId,
    required String slot,
  }) {
    track(AnalyticsEvents.productRecViewed, {
      'gap_type': gapType,
      'product_id': productId,
      'position': position,
      'room_id': roomId,
      'slot': slot,
    });
  }

  /// Track when a user taps "Buy" on a recommendation.
  void trackRecommendationBuyTapped({
    required String productId,
    required String productCategory,
    required double price,
    required String retailer,
    required String roomId,
    required String slot,
  }) {
    track(AnalyticsEvents.affiliateLinkTapped, {
      'product_id': productId,
      'product_category': productCategory,
      'price': price,
      'retailer': retailer,
      'room_id': roomId,
      'slot': slot,
    });
  }

  /// Track when a user dismisses a recommendation with a reason.
  void trackRecommendationDismissed({
    required String productId,
    required String reason,
    required String roomId,
  }) {
    track(AnalyticsEvents.productRecDismissed, {
      'product_id': productId,
      'reason': reason,
      'room_id': roomId,
    });
  }

  /// Track when a gap is identified for a room.
  void trackGapIdentified({
    required String gapType,
    required String severity,
    required String roomId,
  }) {
    track(AnalyticsEvents.gapIdentified, {
      'gap_type': gapType,
      'severity': severity,
      'room_id': roomId,
    });
  }

  /// Override point for real analytics backends.
  void _dispatch(String event, Map<String, Object?> properties) {
    if (kDebugMode) {
      debugPrint(
        '[Analytics] $event ${properties.isNotEmpty ? properties : ''}',
      );
    }
    // TODO: Forward to PostHog / Supabase when configured.
  }
}
