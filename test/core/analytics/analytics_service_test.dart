import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/analytics/analytics_events.dart';
import 'package:palette/core/analytics/analytics_service.dart';

void main() {
  group('AnalyticsService', () {
    late AnalyticsService service;

    setUp(() {
      service = AnalyticsService();
    });

    test('track does not throw', () {
      expect(
        () => service.track(AnalyticsEvents.sessionStarted),
        returnsNormally,
      );
    });

    test('track with properties does not throw', () {
      expect(
        () => service.track(AnalyticsEvents.quizCompleted, {
          'archetype': 'theCocooner',
        }),
        returnsNormally,
      );
    });

    test('screenView does not throw', () {
      expect(() => service.screenView('/home'), returnsNormally);
    });
  });

  group('AnalyticsEvents', () {
    test('event constants are non-empty strings', () {
      expect(AnalyticsEvents.sessionStarted, isNotEmpty);
      expect(AnalyticsEvents.quizStarted, isNotEmpty);
      expect(AnalyticsEvents.paywallViewed, isNotEmpty);
      expect(AnalyticsEvents.roomCreated, isNotEmpty);
      expect(AnalyticsEvents.upgradeCompleted, isNotEmpty);
    });
  });
}
