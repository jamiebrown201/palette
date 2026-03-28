/// Typed event name constants for analytics instrumentation.
///
/// Follows the event taxonomy from SPEC 1E.1.
abstract final class AnalyticsEvents {
  // ── Onboarding ──────────────────────────────────────────────
  static const quizStarted = 'quiz_started';
  static const quizStageCompleted = 'quiz_stage_completed';
  static const quizSkipped = 'quiz_skipped';
  static const quizCompleted = 'quiz_completed';
  static const quizShared = 'quiz_shared';
  static const archetypeAssigned = 'archetype_assigned';
  static const quizDropOffStage = 'quiz_drop_off_stage';

  // ── Rooms ───────────────────────────────────────────────────
  static const roomCreated = 'room_created';
  static const roomStepCompleted = 'room_step_completed';
  static const roomDeleted = 'room_deleted';
  static const roomChecklistItemTapped = 'room_checklist_item_tapped';
  static const roomCompletionScoreChanged = 'room_completion_score_changed';
  static const redThreadCreated = 'red_thread_created';
  static const redThreadRoomConnected = 'red_thread_room_connected';

  // ── Conversion ──────────────────────────────────────────────
  static const paywallViewed = 'paywall_viewed';
  static const paywallDismissed = 'paywall_dismissed';
  static const upgradeTapped = 'upgrade_tapped';
  static const upgradeCompleted = 'upgrade_completed';
  static const trialStarted = 'trial_started';
  static const trialConverted = 'trial_converted';
  static const trialExpired = 'trial_expired';
  static const blurredPreviewViewed = 'blurred_preview_viewed';
  static const projectPassViewed = 'project_pass_viewed';
  static const projectPassPurchased = 'project_pass_purchased';

  // ── Commerce ────────────────────────────────────────────────
  static const buyPaintTapped = 'buy_paint_tapped';
  static const buyPaintCompleted = 'buy_paint_completed';
  static const productRecViewed = 'product_rec_viewed';
  static const productRecTapped = 'product_rec_tapped';
  static const productRecDismissed = 'product_rec_dismissed';
  static const productRecSaved = 'product_rec_saved';
  static const recommendationBought = 'recommendation_bought';
  static const affiliateLinkTapped = 'affiliate_link_tapped';

  // ── Recommendation Intelligence ────────────────────────────
  static const gapIdentified = 'gap_identified';
  static const filterApplied = 'filter_applied';
  static const filterCleared = 'filter_cleared';

  // ── Engagement ──────────────────────────────────────────────
  static const colourWheelOpened = 'colour_wheel_opened';
  static const whiteFinderOpened = 'white_finder_opened';
  static const paintLibraryFiltered = 'paint_library_filtered';
  static const paletteEdited = 'palette_edited';
  static const exploreLearnCardOpened = 'explore_learn_card_opened';
  static const screenViewed = 'screen_viewed';

  // ── Seasonal Refresh ────────────────────────────────────────
  static const seasonalRefreshViewed = 'seasonal_refresh_viewed';
  static const seasonalRefreshProductTapped = 'seasonal_refresh_product_tapped';

  // ── Whole-Home Bundles ───────────────────────────────────────
  static const wholeHomeBundleViewed = 'whole_home_bundle_viewed';
  static const wholeHomeBundleProductTapped =
      'whole_home_bundle_product_tapped';

  // ── Retention ───────────────────────────────────────────────
  static const sessionStarted = 'session_started';
  static const sessionDuration = 'session_duration';
  static const daysSinceLastSession = 'days_since_last_session';
  static const timeOnScreen = 'time_on_screen';
  static const notificationOptIn = 'notification_opt_in';
  static const notificationTapped = 'notification_tapped';
}
