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
    this.supabaseUserId,
    this.colourDnaResultId,
    this.driftPromptDismissedAt,
    this.canPaint,
    this.canDrill,
    this.keepingFlooring,
    this.isTemporaryHome,
    this.reversibleOnly,
    this.notificationsEnabled,
    this.notificationFrequency,
    this.notificationOptInPromptShownAt,
    this.movingDate,
    this.lastPromptDismissedAt,
  });

  final String id;
  final String? supabaseUserId;
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

  /// Whether in-app prompts and notifications are enabled.
  /// Null = not yet asked, false = opted out, true = opted in.
  final bool? notificationsEnabled;

  /// Notification frequency: 'daily', 'weekly', or 'off'.
  final NotificationFrequency? notificationFrequency;

  /// When the opt-in prompt was first shown (to avoid re-showing).
  final DateTime? notificationOptInPromptShownAt;

  /// User's target move-in / completion date for life-event prompts.
  final DateTime? movingDate;

  /// Last time the user dismissed an in-app prompt (rate-limit).
  final DateTime? lastPromptDismissedAt;

  final DateTime createdAt;
  final DateTime updatedAt;
}
