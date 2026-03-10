import 'package:palette/core/constants/enums.dart';

/// The local user profile and preferences.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.hasCompletedOnboarding,
    required this.subscriptionTier,
    required this.colourBlindMode,
    required this.createdAt,
    required this.updatedAt,
    this.colourDnaResultId,
    this.driftPromptDismissedAt,
    this.canPaint,
    this.canDrill,
    this.keepingFlooring,
    this.isTemporaryHome,
    this.reversibleOnly,
  });

  final String id;
  final bool hasCompletedOnboarding;
  final SubscriptionTier subscriptionTier;
  final bool colourBlindMode;
  final String? colourDnaResultId;
  final DateTime? driftPromptDismissedAt;
  final bool? canPaint;
  final bool? canDrill;
  final bool? keepingFlooring;
  final bool? isTemporaryHome;
  final bool? reversibleOnly;
  final DateTime createdAt;
  final DateTime updatedAt;
}
