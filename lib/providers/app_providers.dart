import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/constants/enums.dart';

/// Whether the user has completed the Colour DNA onboarding quiz.
/// Will be wired to the database in Step 5.
final hasCompletedOnboardingProvider = StateProvider<bool>((_) => false);

/// The current subscription tier for the user.
/// Will be wired to the database in Step 5.
final subscriptionTierProvider =
    StateProvider<SubscriptionTier>((_) => SubscriptionTier.free);

/// Whether Colour Blind Mode is active.
final colourBlindModeProvider = StateProvider<bool>((_) => false);
