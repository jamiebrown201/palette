import 'package:flutter/foundation.dart';

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
