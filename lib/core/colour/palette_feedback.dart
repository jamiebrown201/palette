import 'dart:math';

import 'package:palette/core/colour/chroma_band.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/core/colour/lab_colour.dart';
import 'package:palette/core/colour/palette_family.dart';
import 'package:palette/core/colour/undertone.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/features/rooms/logic/colour_plan_harmony.dart';

// ---------------------------------------------------------------------------
// 1. Add/Swap feedback
// ---------------------------------------------------------------------------

/// Look up a display name for a hex, falling back to the uppercase hex code.
String _display(String hex, Map<String, String>? nameMap) {
  if (nameMap == null) return hex.toUpperCase();
  return nameMap[hex.toLowerCase()] ?? hex.toUpperCase();
}

/// Describe how a newly added colour relates to the existing palette.
/// Returns a concise one-line string for a SnackBar.
///
/// [nameMap] maps lowercase hex → paint name for user-friendly output.
String describePaletteImpact({
  required String newHex,
  required List<String> existingHexes,
  Map<String, String>? nameMap,
}) {
  if (existingHexes.isEmpty) return 'Your palette begins!';

  final newLab = hexToLab(newHex);

  // Find the strongest named relationship and the closest colour.
  ColourRelationship? bestRelationship;
  String? bestPartnerHex;
  double closestDe = double.infinity;
  String? closestHex;

  // Priority ranking for relationships.
  const priority = {
    ColourRelationship.complementary: 4,
    ColourRelationship.triadic: 3,
    ColourRelationship.splitComplementary: 2,
    ColourRelationship.analogous: 1,
  };

  for (final hex in existingHexes) {
    final lab = hexToLab(hex);
    final dE = deltaE2000(newLab, lab);

    if (dE < closestDe) {
      closestDe = dE;
      closestHex = hex;
    }

    final rel = classifyHuePair(newLab, lab);
    if (rel != null) {
      final newPriority = priority[rel] ?? 0;
      final oldPriority =
          bestRelationship != null ? (priority[bestRelationship] ?? 0) : -1;
      if (newPriority > oldPriority) {
        bestRelationship = rel;
        bestPartnerHex = hex;
      }
    }
  }

  // Build feedback string.
  if (bestRelationship != null && bestPartnerHex != null) {
    final desc = switch (bestRelationship) {
      ColourRelationship.complementary => 'vibrant contrast',
      ColourRelationship.triadic => 'balanced vibrancy',
      ColourRelationship.splitComplementary => 'dynamic contrast',
      ColourRelationship.analogous => 'calm harmony',
    };
    final partnerName = _display(bestPartnerHex, nameMap);
    final relLabel =
        '${bestRelationship.name[0].toUpperCase()}${bestRelationship.name.substring(1)}';
    return '$relLabel to $partnerName — $desc';
  }

  // Fallback: undertone observation.
  final newUndertone = classifyUndertone(newLab).classification;
  final existingUndertones =
      existingHexes
          .map((h) => classifyUndertone(hexToLab(h)).classification)
          .toList();

  final warmCount = existingUndertones.where((u) => u == Undertone.warm).length;
  final coolCount = existingUndertones.where((u) => u == Undertone.cool).length;

  if (newUndertone == Undertone.cool && warmCount > coolCount) {
    return 'Adds cool balance to a warm-leaning palette';
  }
  if (newUndertone == Undertone.warm && coolCount > warmCount) {
    return 'Adds warm balance to a cool-leaning palette';
  }

  if (closestDe < 10 && closestHex != null) {
    return 'Tonal neighbour to ${_display(closestHex, nameMap)} — cohesive and calm';
  }

  return 'Adds depth and range to your palette';
}

// ---------------------------------------------------------------------------
// 2. Remove context
// ---------------------------------------------------------------------------

/// Describe the role a colour plays in the palette, for removal confirmation.
({String role, String? warning}) describeColourRole({
  required String hex,
  required List<String> paletteHexes,
}) {
  final otherHexes =
      paletteHexes.where((h) => h.toLowerCase() != hex.toLowerCase()).toList();

  if (otherHexes.isEmpty) {
    return (role: 'Your only palette colour', warning: null);
  }

  final lab = hexToLab(hex);

  // Count named relationships with other palette colours.
  var relationshipCount = 0;
  ColourRelationship? primaryRelationship;
  for (final otherHex in otherHexes) {
    final rel = classifyHuePair(lab, hexToLab(otherHex));
    if (rel != null) {
      relationshipCount++;
      primaryRelationship ??= rel;
    }
  }

  // Undertone analysis.
  final undertone = classifyUndertone(lab).classification;
  final otherUndertones = otherHexes.map(
    (h) => classifyUndertone(hexToLab(h)).classification,
  );
  final isOnlyOfUndertone =
      undertone != Undertone.neutral && !otherUndertones.contains(undertone);

  // Chroma band analysis.
  final chroma = classifyChromaBand(lab.chroma);
  final otherChromas = otherHexes.map(
    (h) => classifyChromaBand(hexToLab(h).chroma),
  );
  final isOnlyOfChroma =
      chroma != ChromaBand.mid && !otherChromas.contains(chroma);

  // Build role string.
  String role;
  if (relationshipCount > 0 && primaryRelationship != null) {
    final relName = switch (primaryRelationship) {
      ColourRelationship.complementary => 'Complementary',
      ColourRelationship.triadic => 'Triadic',
      ColourRelationship.splitComplementary => 'Split-complementary',
      ColourRelationship.analogous => 'Analogous',
    };
    role =
        relationshipCount == 1
            ? '$relName partner to another colour'
            : '$relName anchor to $relationshipCount colours';
  } else if (isOnlyOfUndertone) {
    role = 'Your only ${undertone.displayName.toLowerCase()}-toned colour';
  } else if (isOnlyOfChroma) {
    final chromaName = switch (chroma) {
      ChromaBand.muted => 'muted',
      ChromaBand.mid => 'mid-tone',
      ChromaBand.bold => 'bold',
    };
    role = 'Your only $chromaName colour';
  } else {
    role = 'Part of your palette\'s tonal range';
  }

  // Build warning string.
  String? warning;
  if (isOnlyOfUndertone) {
    final remainingTone = undertone == Undertone.warm ? 'cool' : 'warm';
    warning = 'Removing it leaves your palette entirely $remainingTone-toned';
  } else if (otherHexes.length == 1) {
    warning = 'You\'ll be left with just one colour';
  }

  return (role: role, warning: warning);
}

// ---------------------------------------------------------------------------
// 3. Palette health summary
// ---------------------------------------------------------------------------

/// Holistic analysis of a full palette.
class PaletteHealthSummary {
  const PaletteHealthSummary({
    required this.verdict,
    required this.explanation,
    required this.clashes,
    required this.strengths,
    required this.insights,
    this.suggestion,
  });

  final String verdict;
  final String explanation;
  final List<String> clashes;
  final List<String> strengths;
  final List<String> insights;
  final String? suggestion;

  bool get hasIssues => clashes.isNotEmpty;
}

/// Compute the hue difference between two Lab colours (0-180°).
double _hueDiff(LabColour a, LabColour b) {
  var diff = (a.hueAngle - b.hueAngle).abs();
  if (diff > 180) diff = 360 - diff;
  return diff;
}

/// Human-readable label for a [PaletteFamily].
String _familyLabel(PaletteFamily f) => switch (f) {
  PaletteFamily.pastels => 'pastels',
  PaletteFamily.brights => 'brights',
  PaletteFamily.jewelTones => 'jewel tones',
  PaletteFamily.earthTones => 'earth tones',
  PaletteFamily.darks => 'darks',
  PaletteFamily.warmNeutrals => 'warm neutrals',
  PaletteFamily.coolNeutrals => 'cool neutrals',
};

/// Analyse the overall harmony of a palette of hex colours.
///
/// Examines hue relationships, lightness spread, chroma diversity,
/// palette family coherence, and undertone balance.
///
/// [nameMap] maps lowercase hex → paint name for user-friendly output.
PaletteHealthSummary analysePaletteHealth(
  List<String> hexes, {
  Map<String, String>? nameMap,
}) {
  if (hexes.length < 2) {
    return const PaletteHealthSummary(
      verdict: 'Getting started',
      explanation: 'Add more colours to see how your palette works together.',
      clashes: [],
      strengths: [],
      insights: [],
    );
  }

  final labs = hexes.map(hexToLab).toList();
  final clashes = <String>[];
  final strengths = <String>[];
  final insights = <String>[];
  final relationshipCounts = <ColourRelationship, int>{};
  var moderateContrastPairs = 0;

  // ── Pairwise hue analysis ──────────────────────────────────────────────
  for (var i = 0; i < labs.length; i++) {
    for (var j = i + 1; j < labs.length; j++) {
      final dE = deltaE2000(labs[i], labs[j]);
      final rel = classifyHuePair(labs[i], labs[j]);
      final hd = _hueDiff(labs[i], labs[j]);

      if (dE < 5) {
        final nameA = _display(hexes[i], nameMap);
        final nameB = _display(hexes[j], nameMap);
        if (nameA == nameB) {
          clashes.add(
            'Two colours near $nameA are nearly identical '
            '— one may not add much',
          );
        } else {
          clashes.add(
            '$nameA and $nameB are nearly identical '
            '— one may not add much',
          );
        }
      } else if (dE > 50 && rel == null && hd > 120) {
        // Only flag as disconnected when hue separation is also extreme.
        clashes.add(
          '${_display(hexes[i], nameMap)} and ${_display(hexes[j], nameMap)} are '
          'bold together — a bridging tone could help connect them',
        );
      }

      if (rel != null) {
        relationshipCounts[rel] = (relationshipCounts[rel] ?? 0) + 1;
      } else if (hd >= 60 && hd <= 100) {
        // Pairs in the 60-100° gap — meaningful contrast but not a named
        // colour-wheel relationship.
        moderateContrastPairs++;
      }
    }
  }

  // Build strengths list from hue relationships.
  for (final entry in relationshipCounts.entries) {
    final name = switch (entry.key) {
      ColourRelationship.complementary => 'Complementary',
      ColourRelationship.triadic => 'Triadic',
      ColourRelationship.splitComplementary => 'Split-complementary',
      ColourRelationship.analogous => 'Analogous',
    };
    final pairs = entry.value == 1 ? 'pair' : 'pairs';
    strengths.add('$name $pairs anchor your palette');
  }

  if (moderateContrastPairs > 0 && relationshipCounts.isEmpty) {
    insights.add(
      'Your colours sit at moderate contrast — not a classic colour-wheel '
      'scheme, but enough separation to feel intentional',
    );
  }

  // ── Lightness spread ───────────────────────────────────────────────────
  final lightnesses = labs.map((l) => l.l).toList();
  final minL = lightnesses.reduce(min);
  final maxL = lightnesses.reduce(max);
  final lightnessRange = maxL - minL;

  if (lightnessRange < 15) {
    final avgL = lightnesses.reduce((a, b) => a + b) / lightnesses.length;
    final zone =
        avgL > 65
            ? 'light tones'
            : avgL < 35
            ? 'dark tones'
            : 'mid-tones';
    clashes.add(
      'Your colours cluster around $zone — a lighter or darker accent '
      'would add depth',
    );
  } else if (lightnessRange > 50) {
    strengths.add('Good tonal range from dark to light');
  } else {
    strengths.add('Consistent tonal range');
  }

  // ── Chroma diversity ───────────────────────────────────────────────────
  final chromaBands = labs.map((l) => classifyChromaBand(l.chroma)).toList();
  final mutedCount = chromaBands.where((b) => b == ChromaBand.muted).length;
  final boldCount = chromaBands.where((b) => b == ChromaBand.bold).length;
  final allSameBand = chromaBands.toSet().length == 1;

  if (allSameBand && hexes.length >= 3) {
    if (chromaBands.first == ChromaBand.muted) {
      clashes.add(
        'Your palette leans muted — a bolder colour could be a focal point',
      );
    } else if (chromaBands.first == ChromaBand.bold) {
      clashes.add(
        'All bold tones can compete — a quieter colour could let them breathe',
      );
    }
  } else if (mutedCount > 0 && boldCount > 0) {
    strengths.add('Mix of muted and bold gives visual rhythm');
  }

  // ── Palette family coherence ───────────────────────────────────────────
  final families = labs.map(classifyPaletteFamily).toList();
  final familyCounts = <PaletteFamily, int>{};
  for (final f in families) {
    familyCounts[f] = (familyCounts[f] ?? 0) + 1;
  }
  final dominantEntry = familyCounts.entries.reduce(
    (a, b) => a.value >= b.value ? a : b,
  );
  final dominantFraction = dominantEntry.value / hexes.length;

  if (dominantFraction >= 0.6) {
    strengths.add('Rooted in ${_familyLabel(dominantEntry.key)}');
  } else if (familyCounts.length >= hexes.length && hexes.length >= 3) {
    insights.add('Eclectic mix of colour families');
  }

  // ── Undertone balance ──────────────────────────────────────────────────
  final undertones = labs.map((l) => classifyUndertone(l).classification);
  final warmCount = undertones.where((u) => u == Undertone.warm).length;
  final coolCount = undertones.where((u) => u == Undertone.cool).length;
  final neutralCount = undertones.where((u) => u == Undertone.neutral).length;
  final total = hexes.length;

  if (warmCount > 0 && coolCount > 0) {
    strengths.add('Warm and cool tones in balance');
  } else if (warmCount == total) {
    insights.add('All warm-toned');
  } else if (coolCount == total) {
    insights.add('All cool-toned');
  }

  // ── Build suggestion (pick most impactful) ─────────────────────────────
  String? suggestion;
  if (lightnessRange < 15) {
    final avgL = lightnesses.reduce((a, b) => a + b) / lightnesses.length;
    suggestion =
        avgL > 50
            ? 'A deeper shade would ground the palette'
            : 'A lighter tone would open the palette up';
  } else if (allSameBand && hexes.length >= 3) {
    suggestion =
        chromaBands.first == ChromaBand.muted
            ? 'A saturated accent would give the eye a place to land'
            : 'A softer neutral would let your bold colours shine';
  } else if (warmCount > total * 0.8 && total >= 3) {
    suggestion = 'A cool accent could add contrast and depth';
  } else if (coolCount > total * 0.8 && total >= 3) {
    suggestion = 'A warm accent could add energy and balance';
  } else if (relationshipCounts.isEmpty &&
      moderateContrastPairs == 0 &&
      clashes.where((c) => c.contains('nearly identical')).isEmpty) {
    suggestion =
        'An analogous or complementary partner could strengthen the story';
  }

  // ── Build verdict ──────────────────────────────────────────────────────
  final hasAnalogous =
      (relationshipCounts[ColourRelationship.analogous] ?? 0) > 0;
  final hasCompOrTriadic =
      (relationshipCounts[ColourRelationship.complementary] ?? 0) > 0 ||
      (relationshipCounts[ColourRelationship.triadic] ?? 0) > 0;
  final hasNamedRels = relationshipCounts.isNotEmpty;
  final identicalClashes =
      clashes.where((c) => c.contains('nearly identical')).length;

  String verdict;
  String explanation;

  if (identicalClashes > 0 && !hasNamedRels) {
    verdict = 'Needs differentiation';
    explanation =
        'Some colours are so close they read as one. Swapping a duplicate '
        'for something with more contrast would strengthen the palette.';
  } else if (clashes.isNotEmpty && !hasNamedRels) {
    verdict = 'Needs attention';
    explanation =
        'Some colour pairs may feel disconnected or too similar. '
        'Consider swapping to strengthen the relationships.';
  } else if (clashes.isNotEmpty) {
    verdict = 'Mixed harmony';
    explanation =
        'Your palette has strong relationships but a couple of pairs '
        'could work harder together.';
  } else if (hasAnalogous && hasCompOrTriadic) {
    final familyNote =
        dominantFraction >= 0.6
            ? ' through ${_familyLabel(dominantEntry.key)}'
            : '';
    verdict = 'Dynamic balance';
    explanation =
        'Your palette blends calm harmony with vibrant contrast$familyNote '
        '— versatile and engaging.';
  } else if (hasAnalogous && !hasCompOrTriadic) {
    verdict = 'Harmonious flow';
    explanation =
        lightnessRange > 30
            ? 'Neighbouring hues with good tonal range create a rich, '
                'layered feel.'
            : 'Your colours sit close on the colour wheel, creating a '
                'calm, cohesive feel throughout.';
  } else if (hasCompOrTriadic) {
    verdict = 'Vibrant contrast';
    explanation =
        'Your palette uses opposite or evenly spaced colours for '
        'energy and visual interest.';
  } else if (moderateContrastPairs > 0) {
    verdict = 'Balanced mix';
    explanation =
        'Your colours have enough hue separation to feel distinct '
        'while still reading as a considered palette.';
  } else if (neutralCount == total) {
    verdict = 'Tonal palette';
    explanation =
        'A neutral, grounded palette — versatile for layering with '
        'accent colours in a room.';
  } else {
    verdict = 'Eclectic palette';
    explanation =
        'Your colours are boldly independent — consider a bridging '
        'neutral to tie them together.';
  }

  return PaletteHealthSummary(
    verdict: verdict,
    explanation: explanation,
    clashes: clashes,
    strengths: strengths,
    insights: insights,
    suggestion: suggestion,
  );
}
