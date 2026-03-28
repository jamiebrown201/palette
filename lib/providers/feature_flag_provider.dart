import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/feature_flags/feature_flag_service.dart';
import 'package:palette/providers/analytics_provider.dart';

/// Global feature flag service instance.
///
/// Call `ref.read(featureFlagProvider).initialise(Experiments.all)` once at
/// app startup (e.g. in main.dart). After that, read flags anywhere via
/// `ref.read(featureFlagProvider).variant(Experiments.paywallCopy)`.
final featureFlagProvider = Provider<FeatureFlagService>((ref) {
  return FeatureFlagService(ref.read(analyticsProvider));
});
