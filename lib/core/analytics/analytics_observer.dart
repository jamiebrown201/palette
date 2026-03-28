import 'package:flutter/material.dart';
import 'package:palette/core/analytics/analytics_events.dart';
import 'package:palette/core/analytics/analytics_service.dart';

/// Navigator observer that fires [AnalyticsEvents.screenViewed] on push.
class AnalyticsObserver extends NavigatorObserver {
  AnalyticsObserver(this._analytics);

  final AnalyticsService _analytics;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _trackScreen(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _trackScreen(newRoute);
  }

  void _trackScreen(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      _analytics.screenView(name);
    }
  }
}
