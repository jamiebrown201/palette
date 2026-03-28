/// Defines an A/B test experiment with named variants.
///
/// Each experiment has a unique [id], a list of [variants] (first is control),
/// and an optional [description] for documentation.
class Experiment {
  const Experiment({
    required this.id,
    required this.variants,
    this.description = '',
  });

  /// Unique identifier for the experiment (e.g. 'paywall_copy').
  final String id;

  /// Ordered list of variant names. Index 0 is always the control group.
  final List<String> variants;

  /// Human-readable description for logging / dashboards.
  final String description;

  /// The control variant name (first in the list).
  String get control => variants.first;
}

/// All active experiments in the app.
///
/// Experiments listed in the spec (1E.2):
/// - Different paywall copy and layouts
/// - Different entry points for upgrade prompts (after room 2 vs. room 3)
/// - Annual vs. monthly default selection
/// - Blurred preview intensity
/// - Trial length (7-day vs. 14-day)
/// - Next-action card copy variations
abstract final class Experiments {
  static const paywallCopy = Experiment(
    id: 'paywall_copy',
    variants: ['outcome_led', 'feature_list', 'social_proof'],
    description: 'Paywall headline and layout style',
  );

  static const upgradePromptTiming = Experiment(
    id: 'upgrade_prompt_timing',
    variants: ['after_room_2', 'after_room_3'],
    description: 'When to show the first upgrade prompt',
  );

  static const defaultBillingPeriod = Experiment(
    id: 'default_billing_period',
    variants: ['annual', 'monthly'],
    description: 'Which billing period is pre-selected on paywall',
  );

  static const blurIntensity = Experiment(
    id: 'blur_intensity',
    variants: ['medium', 'heavy', 'light'],
    description: 'Blur sigma for premium preview gates',
  );

  static const trialLength = Experiment(
    id: 'trial_length',
    variants: ['14_day', '7_day'],
    description: 'Free trial duration',
  );

  static const nextActionCopy = Experiment(
    id: 'next_action_copy',
    variants: ['outcome_led', 'task_led'],
    description: 'Next-action card copy style on home screen',
  );

  /// All registered experiments for batch initialisation.
  static const all = [
    paywallCopy,
    upgradePromptTiming,
    defaultBillingPeriod,
    blurIntensity,
    trialLength,
    nextActionCopy,
  ];
}
