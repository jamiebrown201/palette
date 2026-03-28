import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/analytics/analytics_service.dart';

/// Global analytics service provider.
final analyticsProvider = Provider<AnalyticsService>((_) => AnalyticsService());
