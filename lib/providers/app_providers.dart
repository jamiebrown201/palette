import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/constants/renter_constraints.dart';
import 'package:palette/core/constants/room_mode_config.dart';

/// Whether the user has completed the Colour DNA onboarding quiz.
final hasCompletedOnboardingProvider = StateProvider<bool>((_) => false);

/// The current subscription tier for the user.
final subscriptionTierProvider = StateProvider<SubscriptionTier>(
  (_) => SubscriptionTier.free,
);

/// Whether Colour Blind Mode is active.
final colourBlindModeProvider = StateProvider<bool>((_) => false);

/// Home-level renter constraints, built from profile + DNA tenure.
final renterConstraintsProvider = StateProvider<RenterConstraints>(
  (_) => RenterConstraints.none,
);

/// Mode config for a room, keyed by the room's [isRenterMode] flag.
/// Combines the per-room flag with the global [renterConstraintsProvider].
final roomModeConfigProvider = Provider.family<RoomModeConfig, bool>((
  ref,
  isRenterMode,
) {
  final constraints = ref.watch(renterConstraintsProvider);
  return RoomModeConfig.forRoom(
    isRenterMode: isRenterMode,
    constraints: constraints,
  );
});
