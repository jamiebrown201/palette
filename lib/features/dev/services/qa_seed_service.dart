import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/features/palette/providers/palette_providers.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';
import 'package:palette/providers/app_providers.dart';
import 'package:palette/providers/database_providers.dart';

/// Debug-only service for seeding/clearing demo data during QA.
class QaSeedService {
  /// Seed a complete demo dataset for QA screenshots.
  ///
  /// Inserts a ColourDnaResult, 3 rooms with colours, sets onboarding
  /// complete and subscription to Plus.
  static Future<void> seedDemoData(WidgetRef ref) async {
    final colourDnaRepo = ref.read(colourDnaRepositoryProvider);
    final roomRepo = ref.read(roomRepositoryProvider);

    final now = DateTime.now();

    // 1. Insert a ColourDnaResult
    await colourDnaRepo.insert(ColourDnaResultsCompanion.insert(
      id: 'qa-demo-dna-001',
      primaryFamily: PaletteFamily.warmNeutrals,
      secondaryFamily: const Value(PaletteFamily.earthTones),
      colourHexes: [
        '#C4A882',
        '#8B7355',
        '#D4C5A9',
        '#A0522D',
        '#DEB887',
        '#F5DEB3',
        '#BC8F8F',
        '#CD853F',
        '#D2B48C',
        '#4A6741',
      ],
      propertyType: const Value(PropertyType.terraced),
      propertyEra: const Value(PropertyEra.victorian),
      projectStage: const Value(ProjectStage.planning),
      tenure: const Value(Tenure.owner),
      completedAt: now,
      isComplete: true,
    ));

    // 2. Insert 3 rooms
    await roomRepo.insertRoom(RoomsCompanion.insert(
      id: 'qa-room-living',
      name: 'Living Room',
      direction: const Value(CompassDirection.south),
      usageTime: UsageTime.evening,
      moods: [RoomMood.cocooning, RoomMood.elegant],
      budget: BudgetBracket.midRange,
      heroColourHex: const Value('#C4A882'),
      betaColourHex: const Value('#8B7355'),
      surpriseColourHex: const Value('#4A6741'),
      isRenterMode: false,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    ));

    await roomRepo.insertRoom(RoomsCompanion.insert(
      id: 'qa-room-bedroom',
      name: 'Bedroom',
      direction: const Value(CompassDirection.east),
      usageTime: UsageTime.morning,
      moods: [RoomMood.calm],
      budget: BudgetBracket.affordable,
      heroColourHex: const Value('#D4C5A9'),
      betaColourHex: const Value('#BC8F8F'),
      surpriseColourHex: const Value('#DEB887'),
      isRenterMode: false,
      sortOrder: 1,
      createdAt: now,
      updatedAt: now,
    ));

    await roomRepo.insertRoom(RoomsCompanion.insert(
      id: 'qa-room-kitchen',
      name: 'Kitchen',
      direction: const Value(CompassDirection.north),
      usageTime: UsageTime.allDay,
      moods: [RoomMood.fresh, RoomMood.energising],
      budget: BudgetBracket.investment,
      heroColourHex: const Value('#F5DEB3'),
      betaColourHex: const Value('#CD853F'),
      surpriseColourHex: const Value('#A0522D'),
      isRenterMode: false,
      sortOrder: 2,
      createdAt: now,
      updatedAt: now,
    ));

    // 3. Update app state (in-memory + database for persistence)
    ref.read(hasCompletedOnboardingProvider.notifier).state = true;
    ref.read(subscriptionTierProvider.notifier).state = SubscriptionTier.plus;

    final profileRepo = ref.read(userProfileRepositoryProvider);
    await profileRepo.setOnboardingComplete(
        colourDnaResultId: 'qa-demo-dna-001');
    await profileRepo.setSubscriptionTier(SubscriptionTier.plus);

    // 4. Invalidate providers so UI refreshes
    ref
      ..invalidate(allRoomsProvider)
      ..invalidate(latestColourDnaProvider);
  }

  /// Clear all user-generated data and reset to fresh-install state.
  static Future<void> clearAllData(WidgetRef ref) async {
    final db = ref.read(paletteDatabaseProvider);

    // Delete in dependency order (children first)
    await db.delete(db.lockedFurnitureItems).go();
    await db.delete(db.roomAdjacencies).go();
    await db.delete(db.redThreadColours).go();
    await db.delete(db.rooms).go();
    await db.delete(db.paletteColours).go();
    await db.delete(db.colourDnaResults).go();

    // Reset state (in-memory + database for persistence)
    ref.read(hasCompletedOnboardingProvider.notifier).state = false;
    ref.read(subscriptionTierProvider.notifier).state = SubscriptionTier.free;
    ref.read(colourBlindModeProvider.notifier).state = false;

    final profileRepo = ref.read(userProfileRepositoryProvider);
    await profileRepo.setSubscriptionTier(SubscriptionTier.free);
    await profileRepo.setColourBlindMode(enabled: false);
    // Reset onboarding by updating the profile directly
    await (db.update(db.userProfiles)
          ..where((t) => t.id.equals('default')))
        .write(UserProfilesCompanion(
      hasCompletedOnboarding: const Value(false),
      colourDnaResultId: const Value(null),
      updatedAt: Value(DateTime.now()),
    ));

    // Invalidate
    ref
      ..invalidate(allRoomsProvider)
      ..invalidate(latestColourDnaProvider);
  }
}
