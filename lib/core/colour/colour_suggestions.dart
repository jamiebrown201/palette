import 'dart:math';

import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/colour_relationships.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/core/colour/lab_colour.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/features/onboarding/models/dna_anchors.dart';
import 'package:palette/features/rooms/logic/light_recommendations.dart';

/// The role of the colour being picked.
enum PickerRole { hero, beta, surprise, paletteAdd, redThread }

/// Category of suggestion for display grouping.
enum SuggestionCategory {
  dnaMatch,
  complementary,
  analogous,
  triadic,
  splitComplementary,
  directionAppropriate,
  familyComplement,
  redThread,
  tonalNeighbour,
}

/// A single colour suggestion with reason text.
class ColourSuggestion {
  const ColourSuggestion({
    required this.paint,
    required this.reason,
    required this.category,
    this.score = 0.0,
  });

  final PaintColour paint;
  final String reason;
  final SuggestionCategory category;
  final double score;
}

/// Context for generating suggestions — populated differently per picker.
class PickerContext {
  const PickerContext({
    this.pickerRole = PickerRole.hero,
    this.heroColourHex,
    this.betaColourHex,
    this.direction,
    this.usageTime,
    this.budget,
    this.moods = const [],
    this.dnaHexes = const [],
    this.redThreadHexes = const [],
    this.existingPaletteHexes = const [],
    this.roomHexes = const [],
    this.undertoneTemperature,
    this.dnaAnchors,
  });

  final PickerRole pickerRole;
  final String? heroColourHex;
  final String? betaColourHex;
  final CompassDirection? direction;
  final UsageTime? usageTime;
  final BudgetBracket? budget;
  final List<RoomMood> moods;
  final List<String> dnaHexes;
  final List<String> redThreadHexes;
  final List<String> existingPaletteHexes;

  /// All hero/beta/surprise hexes across all rooms (for red thread suggestions).
  final List<String> roomHexes;

  /// User's derived undertone temperature from quiz.
  final Undertone? undertoneTemperature;

  /// Key anchor colours from the DNA system palette.
  final DnaAnchors? dnaAnchors;
}

/// Generate contextual colour suggestions for a picker.
///
/// Returns up to [maxSuggestions] ranked suggestions based on the
/// [context] and available [allPaints]. Uses slot-based allocation
/// to guarantee a mix of suggestion categories.
List<ColourSuggestion> generateSuggestions({
  required PickerContext context,
  required List<PaintColour> allPaints,
  int maxSuggestions = 5,
}) {
  if (allPaints.isEmpty) return [];

  // Filter by budget if set
  final paints = context.budget != null
      ? _filterByBudget(allPaints, context.budget!)
      : allPaints;
  final candidatePaints = paints.length >= 10 ? paints : allPaints;

  final suggestions = switch (context.pickerRole) {
    PickerRole.hero =>
      _heroSuggestions(context, candidatePaints, maxSuggestions),
    PickerRole.beta =>
      _betaSuggestions(context, candidatePaints, maxSuggestions),
    PickerRole.surprise =>
      _surpriseSuggestions(context, candidatePaints, maxSuggestions),
    PickerRole.paletteAdd =>
      _paletteAddSuggestions(context, candidatePaints, maxSuggestions),
    PickerRole.redThread =>
      _redThreadSuggestions(context, candidatePaints, maxSuggestions),
  };

  return suggestions.take(maxSuggestions).toList();
}

// ---------------------------------------------------------------------------
// Strategy: Hero colour suggestions
// Slot-based: DNA + complementary + direction + analogous + red thread
// ---------------------------------------------------------------------------

List<ColourSuggestion> _heroSuggestions(
  PickerContext context,
  List<PaintColour> paints,
  int maxSuggestions,
) {
  final slots = <ColourSuggestion>[];
  final usedIds = <String>{};
  final selectedLabs = <LabColour>[];

  void addSlot(ColourSuggestion? s) {
    if (s == null) return;
    slots.add(s);
    usedIds.add(s.paint.id);
    selectedLabs.add(LabColour(s.paint.labL, s.paint.labA, s.paint.labB));
  }

  // Slot 1: Best DNA match (personal preference anchor)
  if (context.dnaHexes.isNotEmpty) {
    final match = _findClosestPaint(
      context.dnaHexes.first, paints, exclude: usedIds,
    );
    if (match != null) {
      addSlot(ColourSuggestion(
        paint: match,
        reason: 'From your Colour DNA',
        category: SuggestionCategory.dnaMatch,
        score: 90,
      ));
    }
  }

  // Slot 2: Complementary to DNA anchor (colour theory)
  if (context.dnaHexes.isNotEmpty) {
    final anchorLab = hexToLab(context.dnaHexes.first);
    final compTarget = complementary(anchorLab);
    final match = _findClosestLabPaintDiverse(
      compTarget, paints,
      exclude: usedIds, diverseFrom: selectedLabs,
    );
    if (match != null) {
      addSlot(ColourSuggestion(
        paint: match,
        reason: 'Complementary contrast',
        category: SuggestionCategory.complementary,
        score: 85,
      ));
    }
  }

  // Slot 3: Direction-appropriate (room context + mood)
  if (context.direction != null) {
    final dirMatch = _findDirectionAppropriate(
      context.direction!,
      context.usageTime ?? UsageTime.allDay,
      paints,
      exclude: usedIds,
      diverseFrom: selectedLabs,
      moods: context.moods,
    );
    if (dirMatch != null) addSlot(dirMatch);
  }

  // Slot 4: Analogous to DNA anchor (harmonious option)
  if (context.dnaHexes.isNotEmpty) {
    final anchorLab = hexToLab(context.dnaHexes.first);
    final analogousTargets = analogous(anchorLab);
    final match = _findClosestLabPaintDiverse(
      analogousTargets.left, paints,
      exclude: usedIds, diverseFrom: selectedLabs,
    );
    if (match != null) {
      addSlot(ColourSuggestion(
        paint: match,
        reason: 'Analogous harmony',
        category: SuggestionCategory.analogous,
        score: 75,
      ));
    }
  }

  // Slot 5: Red thread echo, or second DNA match as fallback
  ColourSuggestion? slot5;
  if (context.redThreadHexes.isNotEmpty) {
    final match = _findClosestPaintDiverse(
      context.redThreadHexes.first, paints,
      exclude: usedIds, diverseFrom: selectedLabs,
    );
    if (match != null) {
      slot5 = ColourSuggestion(
        paint: match,
        reason: 'Echoes your red thread',
        category: SuggestionCategory.redThread,
        score: 70,
      );
    }
  }
  if (slot5 == null && context.dnaHexes.length > 1) {
    final match = _findClosestPaintDiverse(
      context.dnaHexes[1], paints,
      exclude: usedIds, diverseFrom: selectedLabs,
    );
    if (match != null) {
      slot5 = ColourSuggestion(
        paint: match,
        reason: 'From your Colour DNA',
        category: SuggestionCategory.dnaMatch,
        score: 65,
      );
    }
  }
  if (slot5 != null) addSlot(slot5);

  return slots;
}

// ---------------------------------------------------------------------------
// Strategy: Beta (supporting) colour suggestions
// Slot-based: analogous L + analogous R + tonal + direction + split-comp
// ---------------------------------------------------------------------------

List<ColourSuggestion> _betaSuggestions(
  PickerContext context,
  List<PaintColour> paints,
  int maxSuggestions,
) {
  if (context.heroColourHex == null) return [];

  final heroLab = hexToLab(context.heroColourHex!);
  final heroPaint =
      _findClosestPaint(context.heroColourHex!, paints, exclude: {});

  final slots = <ColourSuggestion>[];
  final usedIds = <String>{};
  final selectedLabs = <LabColour>[];
  if (heroPaint != null) usedIds.add(heroPaint.id);

  void addSlot(ColourSuggestion? s) {
    if (s == null) return;
    slots.add(s);
    usedIds.add(s.paint.id);
    selectedLabs.add(LabColour(s.paint.labL, s.paint.labA, s.paint.labB));
  }

  // Slot 1: Analogous left
  final analogousTargets = analogous(heroLab);
  final analogLeft = _findClosestLabPaintDiverse(
    analogousTargets.left, paints,
    exclude: usedIds, diverseFrom: selectedLabs,
  );
  if (analogLeft != null) {
    addSlot(ColourSuggestion(
      paint: analogLeft,
      reason: 'Harmonises with your hero',
      category: SuggestionCategory.analogous,
      score: 90,
    ));
  }

  // Slot 2: Analogous right
  final analogRight = _findClosestLabPaintDiverse(
    analogousTargets.right, paints,
    exclude: usedIds, diverseFrom: selectedLabs,
  );
  if (analogRight != null) {
    addSlot(ColourSuggestion(
      paint: analogRight,
      reason: 'Harmonises with your hero',
      category: SuggestionCategory.analogous,
      score: 85,
    ));
  }

  // Slot 3: Tonal neighbour (same family, dE 10-35)
  if (heroPaint != null) {
    final tonalCandidates = paints.where((p) {
      if (usedIds.contains(p.id)) return false;
      if (p.paletteFamily != heroPaint.paletteFamily) return false;
      final lab = LabColour(p.labL, p.labA, p.labB);
      final dE = deltaE2000(heroLab, lab);
      return dE >= 10 && dE <= 35;
    }).toList()
      ..sort((a, b) {
        final labForA = LabColour(a.labL, a.labA, a.labB);
        final labForB = LabColour(b.labL, b.labA, b.labB);
        final dA = (deltaE2000(heroLab, labForA) - 20).abs();
        final dB = (deltaE2000(heroLab, labForB) - 20).abs();
        return dA.compareTo(dB);
      });
    final tonal = tonalCandidates.firstOrNull;
    if (tonal != null) {
      addSlot(ColourSuggestion(
        paint: tonal,
        reason: 'Tonal variation on ${tonal.paletteFamily.displayName}',
        category: SuggestionCategory.tonalNeighbour,
        score: 75,
      ));
    }
  }

  // Slot 4: Direction-appropriate (+ mood)
  if (context.direction != null) {
    final dirMatch = _findDirectionAppropriate(
      context.direction!,
      context.usageTime ?? UsageTime.allDay,
      paints,
      exclude: usedIds,
      diverseFrom: selectedLabs,
      moods: context.moods,
    );
    if (dirMatch != null) {
      addSlot(ColourSuggestion(
        paint: dirMatch.paint,
        reason: 'Complements '
            '${context.direction!.displayName.toLowerCase()}-facing light',
        category: SuggestionCategory.directionAppropriate,
        score: 70,
      ));
    }
  }

  // Slot 5: Split-complementary of hero
  final splitTargets = splitComplementary(heroLab);
  final splitMatch = _findClosestLabPaintDiverse(
    splitTargets.left, paints,
    exclude: usedIds, diverseFrom: selectedLabs,
  );
  if (splitMatch != null) {
    addSlot(ColourSuggestion(
      paint: splitMatch,
      reason: 'Split-complementary balance',
      category: SuggestionCategory.splitComplementary,
      score: 65,
    ));
  }

  return slots;
}

// ---------------------------------------------------------------------------
// Strategy: Surprise (accent) colour suggestions
// Slot-based: complementary + split-comp L + split-comp R + triadic + family
// ---------------------------------------------------------------------------

List<ColourSuggestion> _surpriseSuggestions(
  PickerContext context,
  List<PaintColour> paints,
  int maxSuggestions,
) {
  if (context.heroColourHex == null) return [];

  final heroLab = hexToLab(context.heroColourHex!);
  final heroPaint =
      _findClosestPaint(context.heroColourHex!, paints, exclude: {});

  final slots = <ColourSuggestion>[];
  final usedIds = <String>{};
  final selectedLabs = <LabColour>[];
  if (heroPaint != null) usedIds.add(heroPaint.id);

  void addSlot(ColourSuggestion? s) {
    if (s == null) return;
    slots.add(s);
    usedIds.add(s.paint.id);
    selectedLabs.add(LabColour(s.paint.labL, s.paint.labA, s.paint.labB));
  }

  // Slot 1: Complementary
  final compTarget = complementary(heroLab);
  final compMatch = _findClosestLabPaintDiverse(
    compTarget, paints, exclude: usedIds, diverseFrom: selectedLabs,
  );
  if (compMatch != null) {
    addSlot(ColourSuggestion(
      paint: compMatch,
      reason: 'Complementary to your hero',
      category: SuggestionCategory.complementary,
      score: 90,
    ));
  }

  // Slot 2: Split-complementary left
  final splitTargets = splitComplementary(heroLab);
  final splitLeft = _findClosestLabPaintDiverse(
    splitTargets.left, paints, exclude: usedIds, diverseFrom: selectedLabs,
  );
  if (splitLeft != null) {
    addSlot(ColourSuggestion(
      paint: splitLeft,
      reason: 'Split-complementary contrast',
      category: SuggestionCategory.splitComplementary,
      score: 85,
    ));
  }

  // Slot 3: Split-complementary right
  final splitRight = _findClosestLabPaintDiverse(
    splitTargets.right, paints, exclude: usedIds, diverseFrom: selectedLabs,
  );
  if (splitRight != null) {
    addSlot(ColourSuggestion(
      paint: splitRight,
      reason: 'Split-complementary contrast',
      category: SuggestionCategory.splitComplementary,
      score: 80,
    ));
  }

  // Slot 4: Triadic
  final triadicTargets = triadic(heroLab);
  final triadicMatch = _findClosestLabPaintDiverse(
    triadicTargets.second, paints,
    exclude: usedIds, diverseFrom: selectedLabs,
  );
  if (triadicMatch != null) {
    addSlot(ColourSuggestion(
      paint: triadicMatch,
      reason: 'Triadic accent',
      category: SuggestionCategory.triadic,
      score: 75,
    ));
  }

  // Slot 5: From complementary palette family
  if (heroPaint != null) {
    final compFamily = _getComplementaryFamily(heroPaint.paletteFamily);
    final familyPaint = paints
        .where((p) =>
            p.paletteFamily == compFamily && !usedIds.contains(p.id))
        .firstOrNull;
    if (familyPaint != null) {
      addSlot(ColourSuggestion(
        paint: familyPaint,
        reason: 'Bold contrast from ${compFamily.displayName}',
        category: SuggestionCategory.familyComplement,
        score: 70,
      ));
    }
  }

  return slots;
}

// ---------------------------------------------------------------------------
// Strategy: Palette add suggestions (unchanged — already diverse)
// ---------------------------------------------------------------------------

List<ColourSuggestion> _paletteAddSuggestions(
  PickerContext context,
  List<PaintColour> paints,
  int maxSuggestions,
) {
  final results = <ColourSuggestion>[];

  final existingHexes = context.existingPaletteHexes;
  final existingIds = <String>{};

  for (final hex in existingHexes) {
    final match = _findClosestPaint(hex, paints, exclude: {});
    if (match != null) existingIds.add(match.id);
  }

  // 1. Complementary to existing palette colours
  for (final hex in existingHexes.take(3)) {
    final lab = hexToLab(hex);
    final compTarget = complementary(lab);
    final match = _findClosestLabPaint(compTarget, paints,
        exclude: existingIds);
    if (match != null) {
      results.add(ColourSuggestion(
        paint: match,
        reason: 'Complementary to ${hex.toUpperCase()}',
        category: SuggestionCategory.complementary,
        score: 80,
      ));
    }
  }

  // 2. Gap filler — families not in palette
  final existingFamilies = <PaletteFamily>{};
  for (final hex in existingHexes) {
    final match = _findClosestPaint(hex, paints, exclude: {});
    if (match != null) existingFamilies.add(match.paletteFamily);
  }
  for (final family in PaletteFamily.values) {
    if (existingFamilies.contains(family)) continue;
    final familyPaint = paints
        .where((p) =>
            p.paletteFamily == family && !existingIds.contains(p.id))
        .firstOrNull;
    if (familyPaint != null) {
      results.add(ColourSuggestion(
        paint: familyPaint,
        reason: 'Adds ${family.displayName} to your palette',
        category: SuggestionCategory.familyComplement,
        score: 75,
      ));
    }
  }

  // 3. DNA colours not yet in palette
  for (final dnaHex in context.dnaHexes) {
    final alreadyInPalette = existingHexes.any(
        (h) => h.toLowerCase() == dnaHex.toLowerCase());
    if (alreadyInPalette) continue;
    final match = _findClosestPaint(dnaHex, paints, exclude: existingIds);
    if (match != null) {
      results.add(ColourSuggestion(
        paint: match,
        reason: 'From your Colour DNA',
        category: SuggestionCategory.dnaMatch,
        score: 65,
      ));
    }
  }

  // Deduplicate by paint ID, keeping highest score
  final seen = <String, ColourSuggestion>{};
  for (final s in results) {
    final existing = seen[s.paint.id];
    if (existing == null || s.score > existing.score) {
      seen[s.paint.id] = s;
    }
  }

  final deduped = seen.values.toList()
    ..sort((a, b) => b.score.compareTo(a.score));

  return deduped.take(maxSuggestions).toList();
}

// ---------------------------------------------------------------------------
// Strategy: Red Thread suggestions
// Slot-based: DNA + analogous to thread + complementary to rooms + tonal
//             bridge + direction-appropriate
// ---------------------------------------------------------------------------

List<ColourSuggestion> _redThreadSuggestions(
  PickerContext context,
  List<PaintColour> paints,
  int maxSuggestions,
) {
  final slots = <ColourSuggestion>[];
  final usedIds = <String>{};
  final selectedLabs = <LabColour>[];

  void addSlot(ColourSuggestion? s) {
    if (s == null) return;
    slots.add(s);
    usedIds.add(s.paint.id);
    selectedLabs.add(LabColour(s.paint.labL, s.paint.labA, s.paint.labB));
  }

  // Exclude existing thread colours from suggestions
  for (final hex in context.redThreadHexes) {
    final match = _findClosestPaint(hex, paints, exclude: {});
    if (match != null) usedIds.add(match.id);
  }

  // Slot 1: DNA colour not already used in any room
  if (context.dnaHexes.isNotEmpty) {
    for (final dnaHex in context.dnaHexes) {
      final alreadyInRoom = context.roomHexes.any(
        (h) => h.toLowerCase() == dnaHex.toLowerCase(),
      );
      if (alreadyInRoom) continue;
      final match = _findClosestPaintDiverse(
        dnaHex, paints,
        exclude: usedIds, diverseFrom: selectedLabs,
      );
      if (match != null) {
        addSlot(ColourSuggestion(
          paint: match,
          reason: 'From your Colour DNA',
          category: SuggestionCategory.dnaMatch,
          score: 90,
        ));
        break;
      }
    }
  }

  // Slot 2: Analogous to existing thread (harmonises)
  if (context.redThreadHexes.isNotEmpty) {
    final threadLab = hexToLab(context.redThreadHexes.first);
    final analogousTargets = analogous(threadLab);
    final match = _findClosestLabPaintDiverse(
      analogousTargets.left, paints,
      exclude: usedIds, diverseFrom: selectedLabs,
    );
    if (match != null) {
      addSlot(ColourSuggestion(
        paint: match,
        reason: 'Harmonises with your thread',
        category: SuggestionCategory.analogous,
        score: 85,
      ));
    }
  }

  // Slot 3: Complementary to the most common room hue
  if (context.roomHexes.isNotEmpty) {
    // Use the first room hex as the "dominant" room colour
    final dominantLab = hexToLab(context.roomHexes.first);
    final compTarget = complementary(dominantLab);
    final match = _findClosestLabPaintDiverse(
      compTarget, paints,
      exclude: usedIds, diverseFrom: selectedLabs,
    );
    if (match != null) {
      addSlot(ColourSuggestion(
        paint: match,
        reason: 'Ties your rooms together',
        category: SuggestionCategory.complementary,
        score: 80,
      ));
    }
  }

  // Slot 4: Tonal bridge — colour perceptually between existing rooms
  if (context.roomHexes.length >= 2) {
    final labA = hexToLab(context.roomHexes[0]);
    final labB = hexToLab(context.roomHexes[1]);
    final midpoint = LabColour(
      (labA.l + labB.l) / 2,
      (labA.a + labB.a) / 2,
      (labA.b + labB.b) / 2,
    );
    final match = _findClosestLabPaintDiverse(
      midpoint, paints,
      exclude: usedIds, diverseFrom: selectedLabs,
    );
    if (match != null) {
      addSlot(ColourSuggestion(
        paint: match,
        reason: 'Bridges your room colours',
        category: SuggestionCategory.tonalNeighbour,
        score: 75,
      ));
    }
  }

  // Slot 5: Direction-appropriate for the most common direction
  if (context.direction != null) {
    final dirMatch = _findDirectionAppropriate(
      context.direction!,
      context.usageTime ?? UsageTime.allDay,
      paints,
      exclude: usedIds,
      diverseFrom: selectedLabs,
    );
    if (dirMatch != null) addSlot(dirMatch);
  }

  // Fallback: if we have fewer than 2 slots filled, add DNA matches
  if (slots.length < 2 && context.dnaHexes.isNotEmpty) {
    for (final dnaHex in context.dnaHexes) {
      if (slots.length >= maxSuggestions) break;
      final match = _findClosestPaintDiverse(
        dnaHex, paints,
        exclude: usedIds, diverseFrom: selectedLabs,
      );
      if (match != null) {
        addSlot(ColourSuggestion(
          paint: match,
          reason: 'From your Colour DNA',
          category: SuggestionCategory.dnaMatch,
          score: 60,
        ));
      }
    }
  }

  return slots;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Find the closest paint to a hex colour.
PaintColour? _findClosestPaint(
  String hex,
  List<PaintColour> paints, {
  required Set<String> exclude,
}) {
  final lab = hexToLab(hex);
  return _findClosestLabPaint(lab, paints, exclude: exclude);
}

/// Find the closest paint to a hex, enforcing diversity.
PaintColour? _findClosestPaintDiverse(
  String hex,
  List<PaintColour> paints, {
  required Set<String> exclude,
  List<LabColour> diverseFrom = const [],
  double minDeltaE = 10.0,
}) {
  final lab = hexToLab(hex);
  return _findClosestLabPaintDiverse(
    lab, paints,
    exclude: exclude, diverseFrom: diverseFrom, minDeltaE: minDeltaE,
  );
}

/// Find the closest paint to a Lab colour target.
PaintColour? _findClosestLabPaint(
  LabColour target,
  List<PaintColour> paints, {
  required Set<String> exclude,
}) {
  PaintColour? best;
  var bestDeltaE = double.infinity;

  for (final pc in paints) {
    if (exclude.contains(pc.id)) continue;
    final lab = LabColour(pc.labL, pc.labA, pc.labB);
    final dE = deltaE2000(target, lab);
    if (dE < bestDeltaE) {
      bestDeltaE = dE;
      best = pc;
    }
  }
  return best;
}

/// Find the closest paint to a Lab target that is perceptually distinct
/// from all previously selected paints.
///
/// Falls back to the plain closest if no diverse candidate exists.
PaintColour? _findClosestLabPaintDiverse(
  LabColour target,
  List<PaintColour> paints, {
  required Set<String> exclude,
  List<LabColour> diverseFrom = const [],
  double minDeltaE = 10.0,
}) {
  PaintColour? best;
  var bestDeltaE = double.infinity;
  PaintColour? fallback;
  var fallbackDeltaE = double.infinity;

  for (final pc in paints) {
    if (exclude.contains(pc.id)) continue;
    final lab = LabColour(pc.labL, pc.labA, pc.labB);
    final dE = deltaE2000(target, lab);

    // Track overall closest as fallback
    if (dE < fallbackDeltaE) {
      fallbackDeltaE = dE;
      fallback = pc;
    }

    // Check diversity: must be >= minDeltaE from every selected paint
    final isDiverse = diverseFrom.every(
      (existing) => deltaE2000(lab, existing) >= minDeltaE,
    );

    if (isDiverse && dE < bestDeltaE) {
      bestDeltaE = dE;
      best = pc;
    }
  }

  return best ?? fallback;
}

/// Find a direction-appropriate paint using soft scoring.
///
/// Instead of hard-filtering by undertone, scores paints on:
/// - Undertone compatibility (preferred > neutral > avoid)
/// - Warmth proximity to the ideal for this compass direction
/// - Room mood preferences (lightness, chroma, family)
/// - Diversity from already-selected paints
ColourSuggestion? _findDirectionAppropriate(
  CompassDirection direction,
  UsageTime usageTime,
  List<PaintColour> paints, {
  required Set<String> exclude,
  List<LabColour> diverseFrom = const [],
  List<RoomMood> moods = const [],
}) {
  final rec = getLightRecommendation(
    direction: direction,
    usageTime: usageTime,
  );

  final idealWarmth = _idealWarmthForDirection(direction);
  PaintColour? best;
  var bestScore = double.negativeInfinity;

  for (final p in paints) {
    if (exclude.contains(p.id)) continue;
    final lab = LabColour(p.labL, p.labA, p.labB);

    var score = 0.0;

    // Undertone match: preferred=30, neutral=15, avoided=-20
    if (p.undertone == rec.preferredUndertone) {
      score += 30;
    } else if (p.undertone == Undertone.neutral) {
      score += 15;
    } else if (rec.avoidUndertone != null &&
        p.undertone == rec.avoidUndertone) {
      score -= 20;
    }

    // Warmth proximity: continuous gradient
    final warmth = lab.b * 0.7 + lab.a * 0.3;
    final warmthDistance = (warmth - idealWarmth).abs();
    score += max(0, 20 - warmthDistance);

    // Mid-range lightness bonus (versatile for walls)
    if (p.labL >= 40 && p.labL <= 80) score += 5;

    // Mood scoring
    score += _moodScore(p, lab, moods);

    // Diversity penalty
    if (diverseFrom.any((e) => deltaE2000(lab, e) < 10)) {
      score -= 15;
    }

    if (score > bestScore) {
      bestScore = score;
      best = p;
    }
  }

  if (best == null || bestScore <= 0) return null;

  return ColourSuggestion(
    paint: best,
    reason: 'Suits ${direction.displayName.toLowerCase()}-facing light',
    category: SuggestionCategory.directionAppropriate,
    score: 80,
  );
}

/// Ideal warmth score for each compass direction.
/// Positive = warm, negative = cool.
double _idealWarmthForDirection(CompassDirection direction) {
  return switch (direction) {
    CompassDirection.north => 10.0, // wants warm paints
    CompassDirection.south => 0.0, // flexible, neutral ideal
    CompassDirection.east => 5.0, // slightly warm
    CompassDirection.west => 3.0, // slightly warm, flexible
  };
}

/// Score a paint colour based on room moods.
///
/// Each mood biases towards certain colour characteristics:
/// - calm: lighter, neutral/cool, lower chroma
/// - energising: medium lightness, warmer, higher chroma
/// - cocooning: darker, warm, soft
/// - elegant: mid-range lightness, neutral, moderate chroma
/// - fresh: lighter, cool, moderate chroma
/// - grounded: warm, earth tones
/// - dramatic: darker, jewel tones
/// - playful: brighter, pastels
double _moodScore(PaintColour paint, LabColour lab, List<RoomMood> moods) {
  if (moods.isEmpty) return 0.0;

  var score = 0.0;
  final chroma = sqrt(lab.a * lab.a + lab.b * lab.b);

  for (final mood in moods) {
    score += switch (mood) {
      RoomMood.calm => (lab.l > 60 ? 5.0 : 0.0) +
          (paint.undertone == Undertone.cool ? 3.0 : 0.0) +
          (chroma < 20 ? 4.0 : 0.0),
      RoomMood.energising => (chroma > 30 ? 5.0 : 0.0) +
          (paint.undertone == Undertone.warm ? 3.0 : 0.0) +
          (lab.l >= 40 && lab.l <= 70 ? 4.0 : 0.0),
      RoomMood.cocooning => (lab.l < 60 ? 5.0 : 0.0) +
          (paint.undertone == Undertone.warm ? 4.0 : 0.0) +
          (chroma < 25 ? 3.0 : 0.0),
      RoomMood.elegant => (lab.l >= 35 && lab.l <= 65 ? 5.0 : 0.0) +
          (paint.undertone == Undertone.neutral ? 4.0 : 0.0) +
          (chroma >= 10 && chroma <= 30 ? 3.0 : 0.0),
      RoomMood.fresh => (lab.l > 65 ? 5.0 : 0.0) +
          (paint.undertone == Undertone.cool ? 4.0 : 0.0) +
          (chroma >= 15 && chroma <= 35 ? 3.0 : 0.0),
      RoomMood.grounded => (paint.undertone == Undertone.warm ? 4.0 : 0.0) +
          (paint.paletteFamily == PaletteFamily.earthTones ? 5.0 : 0.0) +
          (paint.paletteFamily == PaletteFamily.warmNeutrals ? 3.0 : 0.0),
      RoomMood.dramatic => (lab.l < 45 ? 5.0 : 0.0) +
          (paint.paletteFamily == PaletteFamily.jewelTones ? 4.0 : 0.0) +
          (paint.paletteFamily == PaletteFamily.darks ? 3.0 : 0.0),
      RoomMood.playful => (lab.l > 60 ? 4.0 : 0.0) +
          (paint.paletteFamily == PaletteFamily.brights ? 5.0 : 0.0) +
          (paint.paletteFamily == PaletteFamily.pastels ? 4.0 : 0.0),
    };
  }

  return score;
}

/// Filter paints by budget bracket.
List<PaintColour> _filterByBudget(
  List<PaintColour> paints,
  BudgetBracket budget,
) {
  return paints.where((p) {
    final price = p.approximatePricePerLitre;
    if (price == null) return true;
    return switch (budget) {
      BudgetBracket.affordable => price <= 25,
      BudgetBracket.midRange => price > 15 && price <= 50,
      BudgetBracket.investment => price > 30,
    };
  }).toList();
}

/// Get the complementary palette family.
PaletteFamily _getComplementaryFamily(PaletteFamily primary) {
  return switch (primary) {
    PaletteFamily.pastels => PaletteFamily.jewelTones,
    PaletteFamily.brights => PaletteFamily.coolNeutrals,
    PaletteFamily.jewelTones => PaletteFamily.pastels,
    PaletteFamily.earthTones => PaletteFamily.coolNeutrals,
    PaletteFamily.darks => PaletteFamily.pastels,
    PaletteFamily.warmNeutrals => PaletteFamily.jewelTones,
    PaletteFamily.coolNeutrals => PaletteFamily.earthTones,
  };
}
