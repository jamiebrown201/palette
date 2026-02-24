import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/repositories/user_profile_repository.dart';

void main() {
  late PaletteDatabase db;
  late UserProfileRepository repo;

  setUp(() {
    db = PaletteDatabase(NativeDatabase.memory());
    repo = UserProfileRepository(db);
  });

  tearDown(() => db.close());

  group('getOrCreate', () {
    test('creates default profile on first access', () async {
      final profile = await repo.getOrCreate();
      expect(profile.id, 'default');
      expect(profile.hasCompletedOnboarding, false);
      expect(profile.subscriptionTier, SubscriptionTier.free);
      expect(profile.colourBlindMode, false);
      expect(profile.colourDnaResultId, isNull);
    });

    test('returns existing profile on subsequent access', () async {
      final first = await repo.getOrCreate();
      final second = await repo.getOrCreate();
      expect(first.id, second.id);
      expect(first.createdAt, second.createdAt);
    });
  });

  group('profile updates', () {
    test('setOnboardingComplete updates profile', () async {
      await repo.getOrCreate();
      await repo.setOnboardingComplete(colourDnaResultId: 'dna-123');

      final profile = await repo.getOrCreate();
      expect(profile.hasCompletedOnboarding, true);
      expect(profile.colourDnaResultId, 'dna-123');
    });

    test('setSubscriptionTier updates tier', () async {
      await repo.getOrCreate();
      await repo.setSubscriptionTier(SubscriptionTier.plus);

      final profile = await repo.getOrCreate();
      expect(profile.subscriptionTier, SubscriptionTier.plus);
    });

    test('setColourBlindMode toggles mode', () async {
      await repo.getOrCreate();
      await repo.setColourBlindMode(enabled: true);

      final profile = await repo.getOrCreate();
      expect(profile.colourBlindMode, true);

      await repo.setColourBlindMode(enabled: false);
      final updated = await repo.getOrCreate();
      expect(updated.colourBlindMode, false);
    });
  });
}
