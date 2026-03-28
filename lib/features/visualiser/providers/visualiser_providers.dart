import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/providers/app_providers.dart';

/// Credit balance for the AI Room Visualiser.
///
/// Pro: 25 credits/month, Plus: 5 credits/month, Free: 0.
/// Top-up: 10 credits for £1.99.
final visualiserCreditsProvider =
    StateNotifierProvider<VisualiserCreditsNotifier, int>((ref) {
      final tier = ref.watch(subscriptionTierProvider);
      return VisualiserCreditsNotifier(tier);
    });

class VisualiserCreditsNotifier extends StateNotifier<int> {
  VisualiserCreditsNotifier(SubscriptionTier tier)
    : super(_initialCredits(tier));

  static int _initialCredits(SubscriptionTier tier) => switch (tier) {
    SubscriptionTier.pro || SubscriptionTier.projectPass => 25,
    SubscriptionTier.plus => 5,
    SubscriptionTier.free => 0,
  };

  bool get canUseCredit => state > 0;

  /// Deduct one credit. Returns true if successful.
  bool useCredit() {
    if (state <= 0) return false;
    state = state - 1;
    return true;
  }

  /// Deduct two credits (comparison mode). Returns true if successful.
  bool useComparisonCredits() {
    if (state < 2) return false;
    state = state - 2;
    return true;
  }

  /// Add purchased credits (top-up).
  void addCredits(int count) {
    state = state + count;
  }
}

/// Tracks whether a visualisation is currently being generated.
final visualiserLoadingProvider = StateProvider<bool>((_) => false);
