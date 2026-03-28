import 'package:palette/core/constants/renter_constraints.dart';

/// Encapsulates all mode-specific text, labels, and behaviour flags.
///
/// Three modes:
///   - [owner] — full paint-first 70/20/10 canvas
///   - [renterCanPaint] — renter who can paint, wall is "fixed" but choosable
///   - [renterCantPaint] — renter who can't paint, canvas shifts to textiles
///
/// Screens read from this config instead of branching on booleans.
class RoomModeConfig {
  const RoomModeConfig._({
    required this.modeBadge,
    required this.showWallAsFixedContext,
    required this.heroPrompt,
    required this.heroButtonLabel,
    required this.showLandlordPresets,
    required this.heroLabel,
    required this.heroDescription,
    required this.betaLabel,
    required this.betaDescription,
    required this.surpriseLabel,
    required this.surpriseDescription,
    required this.checklistHeroLabel,
    required this.checklistPlanLabel,
    required this.checklistWhiteLabel,
    required this.checklistWhiteAction,
    required this.finderTitle,
    required this.finderIntro,
    required this.finderSwatchAction,
    required this.moodSentenceTemplate,
    required this.redThreadMedium,
    required this.previewHeroLabel,
    required this.previewBetaLabel,
    required this.previewSurpriseLabel,
  });

  /// The single decision point for mode selection.
  factory RoomModeConfig.forRoom({
    required bool isRenterMode,
    required RenterConstraints constraints,
  }) {
    if (!isRenterMode) return owner;
    if (constraints.wallsAreLocked) return renterCantPaint;
    return renterCanPaint;
  }

  // ---------------------------------------------------------------------------
  // Three const instances
  // ---------------------------------------------------------------------------

  static const owner = RoomModeConfig._(
    modeBadge: null,
    showWallAsFixedContext: false,
    heroPrompt:
        'Pick one colour you love — this will set '
        'the tone for the whole room.',
    heroButtonLabel: 'Choose your hero colour',
    showLandlordPresets: false,
    heroLabel: 'Hero (70 %)',
    heroDescription: 'Walls & dominant surfaces',
    betaLabel: 'Supporting (20 %)',
    betaDescription: 'Large furnishings & upholstery',
    surpriseLabel: 'Surprise (10 %)',
    surpriseDescription: 'Accessories, artwork & accents',
    checklistHeroLabel: 'Hero colour chosen',
    checklistPlanLabel: '70 / 20 / 10 complete',
    checklistWhiteLabel: 'White considered',
    checklistWhiteAction: 'Find',
    finderTitle: 'White Finder',
    finderIntro: 'Find the right white for your walls',
    finderSwatchAction: 'Buy this paint',
    moodSentenceTemplate: '',
    redThreadMedium: 'paint and furnishings',
    previewHeroLabel: 'Walls & curtains',
    previewBetaLabel: 'Sofa & rug',
    previewSurpriseLabel: 'Cushions & art',
  );

  static const renterCanPaint = RoomModeConfig._(
    modeBadge: 'Renter',
    showWallAsFixedContext: false,
    heroPrompt:
        'Match your existing wall colour, or pick one '
        'your landlord has approved.',
    heroButtonLabel: 'Match your wall colour',
    showLandlordPresets: true,
    heroLabel: 'Wall (fixed)',
    heroDescription: 'Your existing wall colour',
    betaLabel: 'Furnishings',
    betaDescription: 'Large items you can swap',
    surpriseLabel: 'Accents',
    surpriseDescription: 'Cushions, throws & accessories',
    checklistHeroLabel: 'Wall colour matched',
    checklistPlanLabel: 'Colour plan complete',
    checklistWhiteLabel: 'White considered',
    checklistWhiteAction: 'Find',
    finderTitle: 'White Finder',
    finderIntro: 'Find the right white for your walls',
    finderSwatchAction: 'Buy this paint',
    moodSentenceTemplate:
        'paint and furnishings you can update '
        'within your rental',
    redThreadMedium: 'paint and furnishings',
    previewHeroLabel: 'Fixed walls',
    previewBetaLabel: 'Furnishings',
    previewSurpriseLabel: 'Accents & throws',
  );

  static const renterCantPaint = RoomModeConfig._(
    modeBadge: 'Renter Edition',
    showWallAsFixedContext: true,
    heroPrompt:
        'Choose the colour of your largest textile — '
        'a rug, sofa, or bedding.',
    heroButtonLabel: 'Choose your key textile colour',
    showLandlordPresets: false,
    heroLabel: 'Key textile (70 %)',
    heroDescription: 'Your anchor rug, sofa, or bedding',
    betaLabel: 'Soft furnishings (20 %)',
    betaDescription: 'Cushions, throws & curtains',
    surpriseLabel: 'Accents (10 %)',
    surpriseDescription: 'Art, lamps & accessories',
    checklistHeroLabel: 'Key textile colour chosen',
    checklistPlanLabel: 'Colour plan complete',
    checklistWhiteLabel: 'Neutral considered',
    checklistWhiteAction: 'Find',
    finderTitle: 'Neutral Finder',
    finderIntro: 'Find a neutral base for your textiles',
    finderSwatchAction: 'Use this neutral',
    moodSentenceTemplate:
        'all through furniture and textiles '
        'you can take with you',
    redThreadMedium: 'furnishings and textiles',
    previewHeroLabel: 'Rug, sofa or bedding',
    previewBetaLabel: 'Cushions & throws',
    previewSurpriseLabel: 'Art & accessories',
  );

  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------

  /// Badge text shown beside the room name, or null for owners.
  final String? modeBadge;

  /// When true, show the wall colour as locked context above the planner.
  final bool showWallAsFixedContext;

  // --- Pre-hero prompts ---
  final String heroPrompt;
  final String heroButtonLabel;
  final bool showLandlordPresets;

  // --- 70/20/10 tier labels ---
  final String heroLabel;
  final String heroDescription;
  final String betaLabel;
  final String betaDescription;
  final String surpriseLabel;
  final String surpriseDescription;

  // --- Checklist ---
  final String checklistHeroLabel;
  final String checklistPlanLabel;
  final String checklistWhiteLabel;
  final String checklistWhiteAction;

  // --- White Finder / Neutral Finder ---
  final String finderTitle;
  final String finderIntro;
  final String finderSwatchAction;

  // --- Room story ---
  final String moodSentenceTemplate;

  // --- Red Thread ---
  final String redThreadMedium;

  // --- Room Preview colour-block labels ---
  final String previewHeroLabel;
  final String previewBetaLabel;
  final String previewSurpriseLabel;
}
