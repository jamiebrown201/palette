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

  // ── Experiments (A/B Testing) ────────────────────────────────
  static const experimentAssigned = 'experiment_assigned';
  static const experimentOverridden = 'experiment_overridden';
  static const experimentExposure = 'experiment_exposure';

  // ── Colour Capture (1D.1) ─────────────────────────────────────
  static const colourCaptured = 'colour_captured';
  static const colourCaptureNudged = 'colour_capture_nudged';
  static const colourCaptureSavedToMoodboard =
      'colour_capture_saved_to_moodboard';
  static const colourCaptureSavedToPalette = 'colour_capture_saved_to_palette';

  // ── Moodboards ──────────────────────────────────────────────
  static const moodboardCreated = 'moodboard_created';
  static const moodboardDeleted = 'moodboard_deleted';
  static const moodboardItemAdded = 'moodboard_item_added';
  static const moodboardItemRemoved = 'moodboard_item_removed';

  // ── Sample Ordering ─────────────────────────────────────────
  static const sampleAdded = 'sample_added';
  static const sampleRemoved = 'sample_removed';
  static const sampleMarkedOrdered = 'sample_marked_ordered';
  static const sampleMarkedArrived = 'sample_marked_arrived';
  static const sampleListViewed = 'sample_list_viewed';
  static const sampleTestingGuideOpened = 'sample_testing_guide_opened';

  // ── Retention ───────────────────────────────────────────────
  static const sessionStarted = 'session_started';
  static const sessionDuration = 'session_duration';
  static const daysSinceLastSession = 'days_since_last_session';
  static const timeOnScreen = 'time_on_screen';
  static const notificationOptIn = 'notification_opt_in';
  static const notificationTapped = 'notification_tapped';

  // ── In-App Prompts (1D.4) ──────────────────────────────────
  static const promptViewed = 'prompt_viewed';
  static const promptDismissed = 'prompt_dismissed';
  static const promptActioned = 'prompt_actioned';
  static const movingDateSet = 'moving_date_set';
  static const notificationFrequencyChanged = 'notification_frequency_changed';

  // ── Lighting Planner (Phase 4) ────────────────────────────
  static const lightingPlannerViewed = 'lighting_planner_viewed';
  static const lightingLayerTapped = 'lighting_layer_tapped';

  // ── Room Audit (Phase 4) ──────────────────────────────────
  static const roomAuditViewed = 'room_audit_viewed';
  static const roomAuditRuleTapped = 'room_audit_rule_tapped';

  // ── AI Room Visualiser (3.1) ──────────────────────────────
  static const visualiserOpened = 'visualiser_opened';
  static const visualiserPhotoSelected = 'visualiser_photo_selected';
  static const visualiserGenerated = 'visualiser_generated';
  static const visualiserCreditsPurchased = 'visualiser_credits_purchased';
}
