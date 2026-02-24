import 'package:drift/drift.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/user_profile.dart';

/// Repository for the local user profile (single-row table).
class UserProfileRepository {
  UserProfileRepository(this._db);

  final PaletteDatabase _db;

  static const _defaultId = 'default';

  /// Get the user profile, creating a default one if it doesn't exist.
  Future<UserProfile> getOrCreate() async {
    final existing = await (_db.select(_db.userProfiles)
          ..where((t) => t.id.equals(_defaultId)))
        .getSingleOrNull();

    if (existing != null) return existing;

    final now = DateTime.now();
    await _db.into(_db.userProfiles).insert(
          UserProfilesCompanion.insert(
            id: _defaultId,
            hasCompletedOnboarding: false,
            subscriptionTier: SubscriptionTier.free,
            colourBlindMode: false,
            createdAt: now,
            updatedAt: now,
          ),
        );

    return (_db.select(_db.userProfiles)
          ..where((t) => t.id.equals(_defaultId)))
        .getSingle();
  }

  Stream<UserProfile> watchProfile() =>
      (_db.select(_db.userProfiles)..where((t) => t.id.equals(_defaultId)))
          .watchSingle();

  Future<void> setOnboardingComplete({
    required String colourDnaResultId,
  }) async {
    final stmt = _db.update(_db.userProfiles)
      ..where((t) => t.id.equals(_defaultId));
    await stmt.write(
      UserProfilesCompanion(
        hasCompletedOnboarding: const Value(true),
        colourDnaResultId: Value(colourDnaResultId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setSubscriptionTier(SubscriptionTier tier) async {
    final stmt = _db.update(_db.userProfiles)
      ..where((t) => t.id.equals(_defaultId));
    await stmt.write(
      UserProfilesCompanion(
        subscriptionTier: Value(tier),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setColourBlindMode({required bool enabled}) async {
    final stmt = _db.update(_db.userProfiles)
      ..where((t) => t.id.equals(_defaultId));
    await stmt.write(
      UserProfilesCompanion(
        colourBlindMode: Value(enabled),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
