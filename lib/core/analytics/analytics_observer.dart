import 'package:flutter/material.dart';
import 'package:palette/core/analytics/analytics_events.dart';
import 'package:palette/core/analytics/analytics_service.dart';

/// Screens that should have time-on-screen tracking (spec 1E.1).
const _trackedScreens = {'/home', '/explore', '/rooms/'};

bool _isTrackedScreen(String? name) {
  if (name == null) return false;
  return _trackedScreens.any((s) => name.startsWith(s));
}

/// Navigator observer that fires [AnalyticsEvents.screenViewed] on push
/// and [AnalyticsEvents.timeOnScreen] on pop for key screens.
class AnalyticsObserver extends NavigatorObserver {
  AnalyticsObserver(this._analytics);

  final AnalyticsService _analytics;
  final Map<String, DateTime> _screenEntryTimes = {};

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _trackScreen(route);
    _recordEntry(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _trackTimeOnScreen(oldRoute);
    if (newRoute != null) {
      _trackScreen(newRoute);
      _recordEntry(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _trackTimeOnScreen(route);
    // Re-entering previous route
    if (previousRoute != null) _recordEntry(previousRoute);
  }

  void _trackScreen(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      _analytics.screenView(name);
    }
  }

  void _recordEntry(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && _isTrackedScreen(name)) {
      _screenEntryTimes[name] = DateTime.now();
    }
  }

  void _trackTimeOnScreen(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null) return;
    final entry = _screenEntryTimes.remove(name);
    if (entry != null && _isTrackedScreen(name)) {
      final durationMs = DateTime.now().difference(entry).inMilliseconds;
      _analytics.track(AnalyticsEvents.timeOnScreen, {
        'screen': name,
        'duration_ms': durationMs,
      });
    }
  }
}
