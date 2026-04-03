import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:palette/core/analytics/analytics_service.dart';
import 'package:palette/core/feature_flags/experiment.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local feature flag service backed by SharedPreferences.
///
/// On first launch, each registered experiment is assigned a random variant
/// (uniform distribution). The assignment is persisted so it stays stable
/// across sessions. Designed to be swapped to PostHog feature flags when
/// the backend is ready — replace [_assignVariant] with a remote lookup.
class FeatureFlagService {
  FeatureFlagService(this._analytics);

  final AnalyticsService _analytics;

  /// In-memory cache of experiment → variant. Populated by [initialise].
  final Map<String, String> _assignments = {};

  static const _prefix = 'ab_experiment_';
  static const _cohortIdKey = 'ab_cohort_id';

  /// The stable cohort identifier for this device.
  String? _cohortId;

  /// Read-only access to the cohort ID (available after [initialise]).
  String? get cohortId => _cohortId;

  /// Read-only snapshot of all current assignments.
  Map<String, String> get assignments => Map.unmodifiable(_assignments);

  /// Must be called once at app startup before reading any flags.
  Future<void> initialise(List<Experiment> experiments) async {
    final prefs = await SharedPreferences.getInstance();

    // Ensure a stable cohort ID exists for this installation.
    _cohortId = prefs.getString(_cohortIdKey);
    if (_cohortId == null) {
      _cohortId = _generateCohortId();
      await prefs.setString(_cohortIdKey, _cohortId!);
    }

    for (final experiment in experiments) {
      final key = '$_prefix${experiment.id}';
      var variant = prefs.getString(key);

      if (variant == null || !experiment.variants.contains(variant)) {
        // First time seeing this experiment (or variant list changed).
        variant = _assignVariant(experiment);
        await prefs.setString(key, variant);

        _analytics.track('experiment_assigned', {
          'experiment_id': experiment.id,
          'variant': variant,
          'cohort_id': _cohortId,
        });
      }

      _assignments[experiment.id] = variant;
    }

    if (kDebugMode) {
      debugPrint('[FeatureFlags] Cohort: $_cohortId');
      debugPrint('[FeatureFlags] Assignments: $_assignments');
    }
  }

  /// Returns the assigned variant for [experiment], or [experiment.control]
  /// if the experiment hasn't been initialised.
  String variant(Experiment experiment) {
    return _assignments[experiment.id] ?? experiment.control;
  }

  /// Convenience: returns `true` when the assigned variant matches [name].
  bool isVariant(Experiment experiment, String name) {
    return variant(experiment) == name;
  }

  /// Override a variant for testing / QA mode. Only available in debug builds.
  /// Not persisted across restarts unless [persist] is true.
  Future<void> overrideVariant(
    Experiment experiment,
    String variantName, {
    bool persist = false,
  }) async {
    if (!kDebugMode) return;
    _assignments[experiment.id] = variantName;
    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefix${experiment.id}', variantName);
    }
    _analytics.track('experiment_overridden', {
      'experiment_id': experiment.id,
      'variant': variantName,
      'cohort_id': _cohortId,
    });
  }

  /// Resets all assignments. Only available in debug builds.
  Future<void> resetAll() async {
    if (!kDebugMode) return;
    final prefs = await SharedPreferences.getInstance();
    for (final key in _assignments.keys) {
      await prefs.remove('$_prefix$key');
    }
    _assignments.clear();
  }

  /// Record an exposure event — call this when the variant is actually
  /// rendered on screen so analytics can measure intent-to-treat properly.
  void trackExposure(Experiment experiment) {
    _analytics.track('experiment_exposure', {
      'experiment_id': experiment.id,
      'variant': variant(experiment),
      'cohort_id': _cohortId,
    });
  }

  // ── Private helpers ──────────────────────────────────────────

  /// Uniform random assignment across variants.
  String _assignVariant(Experiment experiment) {
    final random = Random();
    return experiment.variants[random.nextInt(experiment.variants.length)];
  }

  /// Generates a compact unique cohort ID.
  String _generateCohortId() {
    final random = Random.secure();
    final bytes = List.generate(8, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
