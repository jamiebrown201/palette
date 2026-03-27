import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/core/colour/lab_colour.dart';
import 'package:palette/core/constants/enums.dart';

/// A detected relationship between two colours in the plan.
class DetectedRelationship {
  const DetectedRelationship({
    required this.type,
    required this.labelA,
    required this.labelB,
  });

  final ColourRelationship type;
  final String labelA;
  final String labelB;
}

/// The result of analysing a 70/20/10 colour plan's harmony.
class ColourPlanHarmony {
  const ColourPlanHarmony({
    required this.verdict,
    required this.explanation,
    required this.relationships,
    this.warning,
  });

  final String verdict;
  final String explanation;
  final List<DetectedRelationship> relationships;
  final String? warning;

  bool get hasWarning => warning != null;
}

/// Analyse the harmony of a 70/20/10 colour plan.
///
/// Returns educational feedback about how the colours relate to each other,
/// or warnings when colours are too similar or lack a recognised relationship.
ColourPlanHarmony analyseColourPlanHarmony({
  required String heroHex,
  String? betaHex,
  String? surpriseHex,
}) {
  final pairs = <_ColourPair>[];
  final heroLab = hexToLab(heroHex);

  if (betaHex != null) {
    pairs.add(_ColourPair(
      labA: heroLab,
      labB: hexToLab(betaHex),
      labelA: 'hero',
      labelB: 'supporting',
    ));
  }

  if (surpriseHex != null) {
    pairs.add(_ColourPair(
      labA: heroLab,
      labB: hexToLab(surpriseHex),
      labelA: 'hero',
      labelB: 'accent',
    ));
  }

  if (betaHex != null && surpriseHex != null) {
    pairs.add(_ColourPair(
      labA: hexToLab(betaHex),
      labB: hexToLab(surpriseHex),
      labelA: 'supporting',
      labelB: 'accent',
    ));
  }

  if (pairs.isEmpty) {
    return const ColourPlanHarmony(
      verdict: 'Getting started',
      explanation: 'Add a supporting or accent colour to see how they work '
          'together.',
      relationships: [],
    );
  }

  // Classify each pair
  final relationships = <DetectedRelationship>[];
  String? warning;

  for (final pair in pairs) {
    final rel = _classifyPair(pair);
    if (rel != null) relationships.add(rel);

    // Check for problems
    final dE = deltaE2000(pair.labA, pair.labB);
    if (dE < 5) {
      warning ??= 'Your ${pair.labelA} and ${pair.labelB} are very similar '
          '— the ${pair.labelB} may not stand out.';
    }
  }

  // Check for bold unrecognised combinations
  if (relationships.isEmpty && warning == null) {
    final heroToBeta = betaHex != null
        ? deltaE2000(heroLab, hexToLab(betaHex))
        : 0.0;
    final heroToSurprise = surpriseHex != null
        ? deltaE2000(heroLab, hexToLab(surpriseHex))
        : 0.0;
    if (heroToBeta > 50 || heroToSurprise > 50) {
      warning = 'These colours are bold together — a bridging tone could '
          'help them feel connected.';
    }
  }

  // Build verdict and explanation
  final types = relationships.map((r) => r.type).toSet();
  final verdict = _buildVerdict(types);
  final explanation = _buildExplanation(relationships, pairs);

  return ColourPlanHarmony(
    verdict: verdict,
    explanation: explanation,
    relationships: relationships,
    warning: warning,
  );
}

/// Classify the relationship between a pair of colours by hue difference.
ColourRelationship? classifyHuePair(LabColour a, LabColour b) {
  var hueDiff = (a.hueAngle - b.hueAngle).abs();
  if (hueDiff > 180) hueDiff = 360 - hueDiff;

  if (hueDiff >= 165 && hueDiff <= 195) return ColourRelationship.complementary;
  if (hueDiff <= 35) return ColourRelationship.analogous;
  if (hueDiff >= 110 && hueDiff <= 130) return ColourRelationship.triadic;
  if (hueDiff >= 140 && hueDiff <= 160) {
    return ColourRelationship.splitComplementary;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

class _ColourPair {
  const _ColourPair({
    required this.labA,
    required this.labB,
    required this.labelA,
    required this.labelB,
  });

  final LabColour labA;
  final LabColour labB;
  final String labelA;
  final String labelB;
}

DetectedRelationship? _classifyPair(_ColourPair pair) {
  final rel = classifyHuePair(pair.labA, pair.labB);
  if (rel == null) return null;

  return DetectedRelationship(
    type: rel,
    labelA: pair.labelA,
    labelB: pair.labelB,
  );
}

String _buildVerdict(Set<ColourRelationship> types) {
  if (types.isEmpty) return 'Bold mix';
  if (types.length == 1) {
    return switch (types.first) {
      ColourRelationship.complementary => 'Complementary contrast',
      ColourRelationship.analogous => 'Analogous harmony',
      ColourRelationship.triadic => 'Triadic balance',
      ColourRelationship.splitComplementary => 'Split-complementary scheme',
    };
  }
  if (types.contains(ColourRelationship.analogous) &&
      types.contains(ColourRelationship.complementary)) {
    return 'Analogous with accent';
  }
  return 'Mixed colour scheme';
}

String _buildExplanation(
  List<DetectedRelationship> relationships,
  List<_ColourPair> pairs,
) {
  if (relationships.isEmpty) {
    return 'Your colours create an eclectic, statement-making combination.';
  }

  // Use the hero-to-beta relationship as the primary explanation
  final primary = relationships.first;
  return switch (primary.type) {
    ColourRelationship.complementary =>
      'Your ${primary.labelA} and ${primary.labelB} sit opposite each other '
          'on the colour wheel, creating vibrant contrast that energises '
          'the room.',
    ColourRelationship.analogous =>
      'Your ${primary.labelA} and ${primary.labelB} sit next to each other '
          'on the colour wheel, creating a calm, cohesive feel.',
    ColourRelationship.triadic =>
      'Your ${primary.labelA} and ${primary.labelB} form a triadic '
          'relationship — evenly spaced on the colour wheel for balanced '
          'vibrancy.',
    ColourRelationship.splitComplementary =>
      'Your ${primary.labelA} and ${primary.labelB} are split-complementary '
          '— softer contrast than a direct complement, but still dynamic.',
  };
}
