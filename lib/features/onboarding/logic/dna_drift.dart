import 'package:palette/core/colour/chroma_band.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/palette_family.dart';
import 'package:palette/core/colour/undertone.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/colour_dna_result.dart';
import 'package:palette/data/models/colour_interaction.dart';

/// Result of computing how far a user's recent colour choices have drifted
/// from their original DNA profile.
class DnaDrift {
  const DnaDrift({
    required this.familyDrift,
    required this.chromaDrift,
    required this.undertoneDrift,
    required this.overallDrift,
    this.suggestedFamily,
    this.suggestedSaturation,
    this.suggestedUndertone,
  });

  /// How much the family distribution has shifted (0.0–1.0).
  final double familyDrift;

  /// How much the chroma preference has shifted (0.0–1.0).
  final double chromaDrift;

  /// How much the undertone preference has shifted (0.0–1.0).
  final double undertoneDrift;

  /// Weighted overall drift score (0.0–1.0).
  final double overallDrift;

  /// The family the user's recent choices lean towards, if drifting.
  final PaletteFamily? suggestedFamily;

  /// The chroma band the user's recent choices lean towards, if drifting.
  final ChromaBand? suggestedSaturation;

  /// The undertone the user's recent choices lean towards, if drifting.
  final Undertone? suggestedUndertone;
}

/// Compute how far recent colour interactions have drifted from the user's
/// DNA result. Returns a [DnaDrift] with per-dimension and overall scores.
///
/// Pure function — no side effects.
DnaDrift computeDrift(
  ColourDnaResult dna,
  List<ColourInteraction> recentInteractions,
) {
  // Filter to only hex-bearing, colour-selection interactions
  // (exclude removals — they don't indicate preference *for* a colour)
  final interactions = recentInteractions
      .where((i) => i.interactionType != 'colourRemoved')
      .toList();

  if (interactions.isEmpty) {
    return const DnaDrift(
      familyDrift: 0,
      chromaDrift: 0,
      undertoneDrift: 0,
      overallDrift: 0,
    );
  }

  // Classify each interaction's hex
  final labs = interactions.map((i) => hexToLab(i.hex)).toList();
  final families = labs.map(classifyPaletteFamily).toList();
  final undertones = labs.map(classifyUndertone).toList();
  final chromas = labs.map((lab) => classifyChromaBand(lab.chroma)).toList();

  // --- Family drift ---
  final familyCounts = <PaletteFamily, int>{};
  for (final f in families) {
    familyCounts[f] = (familyCounts[f] ?? 0) + 1;
  }
  final topFamily = (familyCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
      .first
      .key;

  // Drift = proportion of interactions NOT in the DNA primary or secondary family
  final dnaFamilies = {dna.primaryFamily, if (dna.secondaryFamily != null) dna.secondaryFamily!};
  final matchingCount =
      families.where(dnaFamilies.contains).length;
  final familyDrift = 1.0 - (matchingCount / families.length);

  // --- Chroma drift ---
  final chromaCounts = <ChromaBand, int>{};
  for (final c in chromas) {
    chromaCounts[c] = (chromaCounts[c] ?? 0) + 1;
  }
  final topChroma = (chromaCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
      .first
      .key;

  double chromaDrift = 0;
  if (dna.saturationPreference != null) {
    final dnaSatIndex = dna.saturationPreference!.index;
    final interactionSatIndex = topChroma.index;
    // Max distance is 2 (muted→bold or bold→muted)
    chromaDrift = (dnaSatIndex - interactionSatIndex).abs() / 2.0;
  }

  // --- Undertone drift ---
  final undertoneCounts = <Undertone, int>{};
  for (final u in undertones) {
    undertoneCounts[u.classification] =
        (undertoneCounts[u.classification] ?? 0) + 1;
  }
  final topUndertone = (undertoneCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
      .first
      .key;

  double undertoneDrift = 0;
  if (dna.undertoneTemperature != null) {
    if (dna.undertoneTemperature == topUndertone) {
      undertoneDrift = 0;
    } else if (dna.undertoneTemperature == Undertone.neutral ||
        topUndertone == Undertone.neutral) {
      // Neutral to warm/cool is a moderate drift
      undertoneDrift = 0.5;
    } else {
      // Warm to cool (or vice versa) is full drift
      undertoneDrift = 1.0;
    }
  }

  // --- Overall drift ---
  final overallDrift =
      familyDrift * 0.4 + chromaDrift * 0.3 + undertoneDrift * 0.3;

  return DnaDrift(
    familyDrift: familyDrift,
    chromaDrift: chromaDrift,
    undertoneDrift: undertoneDrift,
    overallDrift: overallDrift,
    suggestedFamily: familyDrift > 0.4 ? topFamily : null,
    suggestedSaturation: chromaDrift > 0.4 ? topChroma : null,
    suggestedUndertone: undertoneDrift > 0.4 ? topUndertone : null,
  );
}
