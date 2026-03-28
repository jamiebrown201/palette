import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/analytics/analytics_service.dart';
import 'package:palette/core/feature_flags/experiment.dart';
import 'package:palette/core/feature_flags/feature_flag_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FeatureFlagService service;
  late AnalyticsService analytics;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    analytics = AnalyticsService();
    service = FeatureFlagService(analytics);
  });

  group('FeatureFlagService', () {
    test('assigns cohort ID on first initialisation', () async {
      await service.initialise(Experiments.all);
      expect(service.cohortId, isNotNull);
      expect(service.cohortId!.length, 16); // 8 bytes = 16 hex chars
    });

    test('assigns a variant for every experiment', () async {
      await service.initialise(Experiments.all);
      for (final exp in Experiments.all) {
        final v = service.variant(exp);
        expect(
          exp.variants.contains(v),
          isTrue,
          reason: '${exp.id} should have a valid variant',
        );
      }
    });

    test('variant is stable across initialisations', () async {
      await service.initialise(Experiments.all);
      final firstAssignment = Map<String, String>.from(service.assignments);

      // Re-initialise with a fresh instance but same SharedPrefs state.
      final service2 = FeatureFlagService(analytics);
      await service2.initialise(Experiments.all);

      for (final exp in Experiments.all) {
        expect(
          service2.variant(exp),
          firstAssignment[exp.id],
          reason: '${exp.id} variant should persist',
        );
      }
    });

    test('cohort ID is stable across initialisations', () async {
      await service.initialise(Experiments.all);
      final firstCohortId = service.cohortId;

      final service2 = FeatureFlagService(analytics);
      await service2.initialise(Experiments.all);
      expect(service2.cohortId, firstCohortId);
    });

    test('overrideVariant changes the current assignment', () async {
      await service.initialise(Experiments.all);
      const target = Experiments.paywallCopy;

      await service.overrideVariant(target, 'social_proof');
      expect(service.variant(target), 'social_proof');
    });

    test('overrideVariant with persist saves to SharedPreferences', () async {
      await service.initialise(Experiments.all);
      const target = Experiments.trialLength;

      await service.overrideVariant(target, '7_day', persist: true);

      // Re-initialise to check persistence.
      final service2 = FeatureFlagService(analytics);
      await service2.initialise(Experiments.all);
      expect(service2.variant(target), '7_day');
    });

    test('resetAll clears all assignments', () async {
      await service.initialise(Experiments.all);
      expect(service.assignments, isNotEmpty);

      await service.resetAll();
      expect(service.assignments, isEmpty);
    });

    test('returns control variant when experiment not initialised', () {
      const exp = Experiments.blurIntensity;
      expect(service.variant(exp), exp.control);
    });

    test('isVariant returns correct boolean', () async {
      await service.initialise(Experiments.all);
      const exp = Experiments.paywallCopy;
      final v = service.variant(exp);
      expect(service.isVariant(exp, v), isTrue);
      expect(service.isVariant(exp, 'nonexistent_variant'), isFalse);
    });
  });

  group('Experiments', () {
    test('all experiments have at least 2 variants', () {
      for (final exp in Experiments.all) {
        expect(
          exp.variants.length,
          greaterThanOrEqualTo(2),
          reason: '${exp.id} needs at least control + one variant',
        );
      }
    });

    test('all experiment IDs are unique', () {
      final ids = Experiments.all.map((e) => e.id).toSet();
      expect(ids.length, Experiments.all.length);
    });

    test('control is always the first variant', () {
      for (final exp in Experiments.all) {
        expect(
          exp.control,
          exp.variants.first,
          reason: '${exp.id} control should be first variant',
        );
      }
    });
  });
}
