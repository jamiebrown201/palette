import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('can be created with supabaseUserId', () {
      final now = DateTime.now();
      final profile = UserProfile(
        id: 'default',
        supabaseUserId: 'abc-123-def',
        hasCompletedOnboarding: true,
        subscriptionTier: SubscriptionTier.free,
        colourBlindMode: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(profile.supabaseUserId, 'abc-123-def');
    });

    test('supabaseUserId defaults to null', () {
      final now = DateTime.now();
      final profile = UserProfile(
        id: 'default',
        hasCompletedOnboarding: false,
        subscriptionTier: SubscriptionTier.free,
        colourBlindMode: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(profile.supabaseUserId, isNull);
    });
  });
}
