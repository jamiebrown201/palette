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

    test('trackRecommendationViewed does not throw', () {
      expect(
        () => service.trackRecommendationViewed(
          gapType: 'rug',
          productId: 'prod_001',
          position: 0,
          roomId: 'room_1',
          slot: 'recommended',
        ),
        returnsNormally,
      );
    });

    test('trackRecommendationBuyTapped does not throw', () {
      expect(
        () => service.trackRecommendationBuyTapped(
          productId: 'prod_001',
          productCategory: 'rug',
          price: 199.0,
          retailer: 'John Lewis',
          roomId: 'room_1',
          slot: 'bestValue',
        ),
        returnsNormally,
      );
    });

    test('trackRecommendationDismissed does not throw', () {
      expect(
        () => service.trackRecommendationDismissed(
          productId: 'prod_001',
          reason: 'price',
          roomId: 'room_1',
        ),
        returnsNormally,
      );
    });

    test('trackGapIdentified does not throw', () {
      expect(
        () => service.trackGapIdentified(
          gapType: 'rug',
          severity: 'high',
          roomId: 'room_1',
        ),
        returnsNormally,
      );
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

    test('recommendation event constants are non-empty strings', () {
      expect(AnalyticsEvents.productRecViewed, isNotEmpty);
      expect(AnalyticsEvents.productRecTapped, isNotEmpty);
      expect(AnalyticsEvents.productRecDismissed, isNotEmpty);
      expect(AnalyticsEvents.productRecSaved, isNotEmpty);
      expect(AnalyticsEvents.recommendationBought, isNotEmpty);
      expect(AnalyticsEvents.affiliateLinkTapped, isNotEmpty);
      expect(AnalyticsEvents.gapIdentified, isNotEmpty);
      expect(AnalyticsEvents.filterApplied, isNotEmpty);
      expect(AnalyticsEvents.filterCleared, isNotEmpty);
    });
  });
}
