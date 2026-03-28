import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/colour_dna_result.dart';

/// Comparison result between user's and partner's Colour DNA.
class PartnerComparison {
  const PartnerComparison({
    required this.sharedFamilies,
    required this.userOnlyFamilies,
    required this.partnerOnlyFamilies,
    required this.undertoneMatch,
    required this.overlapColours,
    required this.compatibilityScore,
    required this.summaryText,
    required this.tips,
  });

  /// Palette families both share (primary or secondary).
  final List<PaletteFamily> sharedFamilies;

  /// Families unique to the user.
  final List<PaletteFamily> userOnlyFamilies;

  /// Families unique to the partner.
  final List<PaletteFamily> partnerOnlyFamilies;

  /// Whether undertone temperature matches (both warm, both cool, etc).
  final bool undertoneMatch;

  /// Hex colours that appear in both palettes (within reasonable delta-E).
  final List<String> overlapColours;

  /// 0-100 score summarising compatibility.
  final int compatibilityScore;

  /// Human-readable summary.
  final String summaryText;

  /// Actionable tips for decorating together.
  final List<String> tips;
}

/// Compare user and partner DNA to generate overlap/divergence report.
PartnerComparison comparePartnerDna({
  required ColourDnaResult userDna,
  required PartnerProfile partner,
}) {
  // Collect families for each
  final userFamilies = <PaletteFamily>{
    userDna.primaryFamily,
    if (userDna.secondaryFamily != null) userDna.secondaryFamily!,
  };

  final partnerFamilies = <PaletteFamily>{
    if (partner.primaryFamily != null) partner.primaryFamily!,
    if (partner.secondaryFamily != null) partner.secondaryFamily!,
  };

  final shared = userFamilies.intersection(partnerFamilies).toList();
  final userOnly = userFamilies.difference(partnerFamilies).toList();
  final partnerOnly = partnerFamilies.difference(userFamilies).toList();

  // Undertone match
  final undertoneMatch =
      userDna.undertoneTemperature != null &&
      partner.undertone != null &&
      userDna.undertoneTemperature == partner.undertone;

  // Find overlapping hex colours (exact match for simplicity in v1)
  final userHexSet = userDna.colourHexes.map((h) => h.toUpperCase()).toSet();
  final partnerHexSet =
      (partner.colourHexes ?? []).map((h) => h.toUpperCase()).toSet();
  final overlapColours = userHexSet.intersection(partnerHexSet).toList();

  // Compatibility score (weighted)
  var score = 0;

  // Family overlap (40 points max)
  if (shared.isNotEmpty) {
    score += 20 + (shared.length > 1 ? 20 : 0);
  }

  // Undertone match (25 points)
  if (undertoneMatch) {
    score += 25;
  } else if (userDna.undertoneTemperature == null ||
      partner.undertone == null) {
    score += 12; // Unknown — give benefit of the doubt
  }

  // Archetype compatibility (20 points)
  if (userDna.archetype != null && partner.archetype != null) {
    if (userDna.archetype == partner.archetype) {
      score += 20;
    } else if (_archetypeGroup(userDna.archetype!) ==
        _archetypeGroup(partner.archetype!)) {
      score += 12;
    }
  }

  // Saturation alignment (15 points)
  if (userDna.saturationPreference != null && partner.saturation != null) {
    if (userDna.saturationPreference == partner.saturation) {
      score += 15;
    } else if ((userDna.saturationPreference!.index - partner.saturation!.index)
            .abs() <=
        1) {
      score += 8;
    }
  }

  // Generate summary text
  final summary = _buildSummary(
    score: score,
    shared: shared,
    undertoneMatch: undertoneMatch,
    userArchetype: userDna.archetype,
    partnerArchetype: partner.archetype,
  );

  // Generate tips
  final tips = _buildTips(
    score: score,
    shared: shared,
    userOnly: userOnly,
    partnerOnly: partnerOnly,
    undertoneMatch: undertoneMatch,
  );

  return PartnerComparison(
    sharedFamilies: shared,
    userOnlyFamilies: userOnly,
    partnerOnlyFamilies: partnerOnly,
    undertoneMatch: undertoneMatch,
    overlapColours: overlapColours,
    compatibilityScore: score.clamp(0, 100),
    summaryText: summary,
    tips: tips,
  );
}

/// Group archetypes into broad style categories for compatibility.
int _archetypeGroup(ColourArchetype archetype) => switch (archetype) {
  // Warm, cosy group
  ColourArchetype.theCocooner ||
  ColourArchetype.theGoldenHour ||
  ColourArchetype.theVelvetWhisper => 0,
  // Clean, modern group
  ColourArchetype.theMonochromeModernist ||
  ColourArchetype.theMinimalist ||
  ColourArchetype.theMidnightArchitect => 1,
  // Rich, layered group
  ColourArchetype.theCurator ||
  ColourArchetype.theStoryteller ||
  ColourArchetype.theDramatist => 2,
  // Natural, organic group
  ColourArchetype.theNatureLover || ColourArchetype.theRomantic => 3,
  // Bold, expressive group
  ColourArchetype.theBrightener ||
  ColourArchetype.theColourOptimist ||
  ColourArchetype.theMaximalist => 4,
};

String _buildSummary({
  required int score,
  required List<PaletteFamily> shared,
  required bool undertoneMatch,
  required ColourArchetype? userArchetype,
  required ColourArchetype? partnerArchetype,
}) {
  if (score >= 70) {
    return 'You and your partner are naturally aligned. '
        "You share a love of ${shared.isNotEmpty ? shared.first.displayName.toLowerCase() : 'similar tones'}, "
        'which means decorating together should feel effortless. '
        'Trust your shared instincts.';
  }
  if (score >= 40) {
    return 'You and your partner have overlapping taste with some creative tension. '
        'This is actually ideal for decorating — you will push each other '
        'towards a more interesting, layered result than either of you '
        'would choose alone.';
  }
  return 'You and your partner have very different colour personalities. '
      'This is not a problem — it is an opportunity. The best-designed homes '
      'balance different perspectives. Focus on finding a shared Red Thread '
      'that honours both instincts.';
}

List<String> _buildTips({
  required int score,
  required List<PaletteFamily> shared,
  required List<PaletteFamily> userOnly,
  required List<PaletteFamily> partnerOnly,
  required bool undertoneMatch,
}) {
  final tips = <String>[];

  if (shared.isNotEmpty) {
    tips.add(
      "Start with your shared ground: ${shared.map((f) => f.displayName).join(' and ')}. "
      'Use these in communal spaces like the living room and hallway.',
    );
  }

  if (userOnly.isNotEmpty && partnerOnly.isNotEmpty) {
    tips.add(
      'Let personal spaces reflect individual taste — '
      '${userOnly.first.displayName} in your study, '
      '${partnerOnly.first.displayName} in theirs.',
    );
  }

  if (undertoneMatch) {
    tips.add(
      'You both lean towards the same undertone temperature, '
      'so choosing whites and neutrals will be straightforward. '
      'Pick one white you both love and use it throughout.',
    );
  } else {
    tips.add(
      'Your undertone preferences differ. Bridge the gap with neutrals '
      'that sit between warm and cool — greige, mushroom, and putty '
      'work for both.',
    );
  }

  if (score < 40) {
    tips.add(
      'Choose 2 Red Thread colours together — one each. '
      'Then build every room around those shared colours. '
      'The compromise creates cohesion.',
    );
  }

  tips.add(
    "Use the 70/20/10 rule to give each person's preference "
    "a clear role in the room. One person's choice at 70%, "
    "the other's at 20%, and agree on the 10% accent together.",
  );

  return tips;
}
