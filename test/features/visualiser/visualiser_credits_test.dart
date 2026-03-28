import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/features/visualiser/providers/visualiser_providers.dart';

void main() {
  group('VisualiserCreditsNotifier', () {
    test('pro tier starts with 25 credits', () {
      final notifier = VisualiserCreditsNotifier(SubscriptionTier.pro);
      expect(notifier.debugState, 25);
    });

    test('plus tier starts with 5 credits', () {
      final notifier = VisualiserCreditsNotifier(SubscriptionTier.plus);
      expect(notifier.debugState, 5);
    });

    test('free tier starts with 0 credits', () {
      final notifier = VisualiserCreditsNotifier(SubscriptionTier.free);
      expect(notifier.debugState, 0);
    });

    test('project pass starts with 25 credits', () {
      final notifier = VisualiserCreditsNotifier(SubscriptionTier.projectPass);
      expect(notifier.debugState, 25);
    });

    test('useCredit deducts one credit', () {
      final notifier = VisualiserCreditsNotifier(SubscriptionTier.pro);
      expect(notifier.useCredit(), isTrue);
      expect(notifier.debugState, 24);
    });

    test('useCredit fails when no credits remain', () {
      final notifier = VisualiserCreditsNotifier(SubscriptionTier.free);
      expect(notifier.useCredit(), isFalse);
      expect(notifier.debugState, 0);
    });

    test('useComparisonCredits deducts two credits', () {
      final notifier = VisualiserCreditsNotifier(SubscriptionTier.plus);
      expect(notifier.useComparisonCredits(), isTrue);
      expect(notifier.debugState, 3);
    });

    test('useComparisonCredits fails when fewer than 2 credits', () {
      final notifier = VisualiserCreditsNotifier(SubscriptionTier.plus);
      // Use 4 credits, leaving 1
      for (var i = 0; i < 4; i++) {
        notifier.useCredit();
      }
      expect(notifier.debugState, 1);
      expect(notifier.useComparisonCredits(), isFalse);
      expect(notifier.debugState, 1);
    });

    test('addCredits increases balance', () {
      final notifier = VisualiserCreditsNotifier(SubscriptionTier.free);
      notifier.addCredits(10);
      expect(notifier.debugState, 10);
    });

    test('addCredits stacks with existing balance', () {
      final notifier = VisualiserCreditsNotifier(SubscriptionTier.pro);
      notifier.addCredits(10);
      expect(notifier.debugState, 35);
    });

    test('canUseCredit reflects balance', () {
      final notifier = VisualiserCreditsNotifier(SubscriptionTier.free);
      expect(notifier.canUseCredit, isFalse);
      notifier.addCredits(1);
      expect(notifier.canUseCredit, isTrue);
      notifier.useCredit();
      expect(notifier.canUseCredit, isFalse);
    });
  });
}
