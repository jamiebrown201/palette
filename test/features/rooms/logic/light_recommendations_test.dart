import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/features/rooms/logic/light_recommendations.dart';

void main() {
  group('getLightRecommendation', () {
    test('north-facing morning recommends warm undertone', () {
      final rec = getLightRecommendation(
        direction: CompassDirection.north,
        usageTime: UsageTime.morning,
      );

      expect(rec.direction, CompassDirection.north);
      expect(rec.usageTime, UsageTime.morning);
      expect(rec.preferredUndertone, Undertone.warm);
      expect(rec.avoidUndertone, Undertone.cool);
      expect(rec.summary, isNotEmpty);
      expect(rec.recommendation, isNotEmpty);
    });

    test('north-facing allDay recommends warm, avoid cool', () {
      final rec = getLightRecommendation(
        direction: CompassDirection.north,
        usageTime: UsageTime.allDay,
      );

      expect(rec.preferredUndertone, Undertone.warm);
      expect(rec.avoidUndertone, Undertone.cool);
    });

    test('north-facing afternoon falls through to default', () {
      final rec = getLightRecommendation(
        direction: CompassDirection.north,
        usageTime: UsageTime.afternoon,
      );

      // North wildcard match
      expect(rec.preferredUndertone, Undertone.warm);
      expect(rec.avoidUndertone, Undertone.cool);
    });

    test('south-facing morning recommends cool undertone', () {
      final rec = getLightRecommendation(
        direction: CompassDirection.south,
        usageTime: UsageTime.morning,
      );

      expect(rec.preferredUndertone, Undertone.cool);
      expect(rec.avoidUndertone, isNull);
    });

    test('south-facing allDay recommends neutral (flexible)', () {
      final rec = getLightRecommendation(
        direction: CompassDirection.south,
        usageTime: UsageTime.allDay,
      );

      expect(rec.preferredUndertone, Undertone.neutral);
      expect(rec.avoidUndertone, isNull);
    });

    test('east-facing morning recommends warm', () {
      final rec = getLightRecommendation(
        direction: CompassDirection.east,
        usageTime: UsageTime.morning,
      );

      expect(rec.preferredUndertone, Undertone.warm);
      expect(rec.avoidUndertone, isNull);
    });

    test('east-facing evening recommends warm, avoid cool', () {
      final rec = getLightRecommendation(
        direction: CompassDirection.east,
        usageTime: UsageTime.evening,
      );

      expect(rec.preferredUndertone, Undertone.warm);
      expect(rec.avoidUndertone, Undertone.cool);
    });

    test('east-facing allDay recommends warm', () {
      final rec = getLightRecommendation(
        direction: CompassDirection.east,
        usageTime: UsageTime.allDay,
      );

      expect(rec.preferredUndertone, Undertone.warm);
      expect(rec.avoidUndertone, isNull);
    });

    test('west-facing morning recommends warm, avoid cool', () {
      final rec = getLightRecommendation(
        direction: CompassDirection.west,
        usageTime: UsageTime.morning,
      );

      expect(rec.preferredUndertone, Undertone.warm);
      expect(rec.avoidUndertone, Undertone.cool);
    });

    test('west-facing evening recommends neutral', () {
      final rec = getLightRecommendation(
        direction: CompassDirection.west,
        usageTime: UsageTime.evening,
      );

      expect(rec.preferredUndertone, Undertone.neutral);
      expect(rec.avoidUndertone, isNull);
    });

    test('west-facing allDay recommends warm', () {
      final rec = getLightRecommendation(
        direction: CompassDirection.west,
        usageTime: UsageTime.allDay,
      );

      expect(rec.preferredUndertone, Undertone.warm);
      expect(rec.avoidUndertone, isNull);
    });

    test('returns recommendation for every direction+time combo', () {
      for (final dir in CompassDirection.values) {
        for (final time in UsageTime.values) {
          final rec = getLightRecommendation(
            direction: dir,
            usageTime: time,
          );
          expect(rec.summary, isNotEmpty,
              reason: '$dir/$time should have a summary');
          expect(rec.recommendation, isNotEmpty,
              reason: '$dir/$time should have a recommendation');
        }
      }
    });
  });

  group('getLightDirectionSummary', () {
    test('returns educational text for each direction', () {
      for (final dir in CompassDirection.values) {
        final summary = getLightDirectionSummary(dir);
        expect(summary, isNotEmpty);
        expect(summary.contains('-facing'), isTrue,
            reason: 'Summary for $dir should mention facing');
      }
    });

    test('north summary mentions cool light', () {
      final summary = getLightDirectionSummary(CompassDirection.north);
      expect(summary.toLowerCase(), contains('cool'));
    });

    test('south summary mentions warm light', () {
      final summary = getLightDirectionSummary(CompassDirection.south);
      expect(summary.toLowerCase(), contains('warm'));
    });
  });
}
