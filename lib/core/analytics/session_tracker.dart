import 'package:flutter/widgets.dart';
import 'package:palette/core/analytics/analytics_events.dart';
import 'package:palette/core/analytics/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks session-level analytics: session_started, session_duration,
/// and days_since_last_session (spec 1E.1).
class SessionTracker with WidgetsBindingObserver {
  SessionTracker(this._analytics);

  final AnalyticsService _analytics;
  DateTime? _sessionStart;

  static const _lastSessionKey = 'analytics_last_session_ts';

  /// Call once at app startup to begin tracking.
  Future<void> start() async {
    _sessionStart = DateTime.now();
    WidgetsBinding.instance.addObserver(this);

    // Track days since last session
    final prefs = await SharedPreferences.getInstance();
    final lastTs = prefs.getInt(_lastSessionKey);
    if (lastTs != null) {
      final lastSession = DateTime.fromMillisecondsSinceEpoch(lastTs);
      final daysSince = DateTime.now().difference(lastSession).inDays;
      _analytics.track(AnalyticsEvents.daysSinceLastSession, {
        'days': daysSince,
      });
    }

    // Record this session start
    await prefs.setInt(_lastSessionKey, DateTime.now().millisecondsSinceEpoch);

    _analytics.track(AnalyticsEvents.sessionStarted);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _trackSessionDuration();
    }
    if (state == AppLifecycleState.resumed) {
      _sessionStart = DateTime.now();
    }
  }

  void _trackSessionDuration() {
    if (_sessionStart == null) return;
    final durationMs = DateTime.now().difference(_sessionStart!).inMilliseconds;
    _analytics.track(AnalyticsEvents.sessionDuration, {
      'duration_ms': durationMs,
    });
    _sessionStart = null;
  }

  /// Call to clean up the observer.
  void dispose() {
    _trackSessionDuration();
    WidgetsBinding.instance.removeObserver(this);
  }
}
