import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/locked_furniture.dart';
import 'package:palette/data/models/room.dart';

/// A single design rule check in the room audit.
class AuditRule {
  const AuditRule({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.detail,
    this.suggestion,
  });

  /// Unique rule identifier (e.g. 'texture_layering').
  final String id;

  /// Short name of the rule.
  final String title;

  /// One-line explanation of why this rule matters.
  final String description;

  /// Whether this rule is satisfied, partially met, or not met.
  final AuditStatus status;

  /// Contextual detail about what was found.
  final String? detail;

  /// Actionable suggestion to improve.
  final String? suggestion;
}

/// Status of a single audit rule.
enum AuditStatus {
  /// Rule fully satisfied.
  pass,

  /// Partially met or could be improved.
  partial,

  /// Not met; needs attention.
  needsWork,

  /// Not enough data to evaluate.
  unknown,
}

extension AuditStatusX on AuditStatus {
  String get label => switch (this) {
    AuditStatus.pass => 'Looking good',
    AuditStatus.partial => 'Almost there',
    AuditStatus.needsWork => 'Needs attention',
    AuditStatus.unknown => 'Add more data',
  };
}

/// Complete audit report for a room.
class RoomAuditReport {
  const RoomAuditReport({
    required this.roomName,
    required this.rules,
    required this.score,
    required this.totalPossible,
    required this.summary,
  });

  final String roomName;
  final List<AuditRule> rules;

  /// Score out of [totalPossible].
  final int score;
  final int totalPossible;

  /// One-line verdict.
  final String summary;

  double get percentage => totalPossible > 0 ? score / totalPossible : 0;

  int get passCount => rules.where((r) => r.status == AuditStatus.pass).length;

  int get partialCount =>
      rules.where((r) => r.status == AuditStatus.partial).length;

  int get needsWorkCount =>
      rules.where((r) => r.status == AuditStatus.needsWork).length;
}

/// Runs Watson-Smyth's design rules against a room and its furniture.
///
/// Evaluates:
/// 1. Something Old, Something New, Something Black, Something Gold
/// 2. Rule of Odd Numbers (3-5-7) for accessories
/// 3. Texture Layering (3-4 textures needed)
/// 4. Layered Lighting (ambient / task / accent)
/// 5. Material Balance (warm + cool materials)
/// 6. The Wood Tone Rule (variety without clash)
/// 7. Metal Finish Consistency (one dominant, one accent max)
/// 8. Visual Weight Distribution (balanced light + heavy)
/// 9. Colour Plan Completeness (hero, beta, surprise chosen)
RoomAuditReport auditRoom({
  required Room room,
  required List<LockedFurniture> furniture,
}) {
  final rules = <AuditRule>[
    _checkSomethingOldNewBlackGold(furniture),
    _checkOddNumbers(furniture),
    _checkTextureLayering(furniture),
    _checkLayeredLighting(furniture),
    _checkMaterialBalance(furniture),
    _checkWoodToneRule(furniture),
    _checkMetalConsistency(furniture),
    _checkVisualWeight(furniture),
    _checkColourPlan(room),
  ];

  var score = 0;
  var totalPossible = 0;
  for (final rule in rules) {
    if (rule.status == AuditStatus.unknown) continue;
    totalPossible += 2;
    if (rule.status == AuditStatus.pass) {
      score += 2;
    } else if (rule.status == AuditStatus.partial) {
      score += 1;
    }
  }

  final summary = _buildSummary(score, totalPossible, rules);

  return RoomAuditReport(
    roomName: room.name,
    rules: rules,
    score: score,
    totalPossible: totalPossible,
    summary: summary,
  );
}

// ── Rule 1: Something Old, Something New, Something Black, Something Gold ──

AuditRule _checkSomethingOldNewBlackGold(List<LockedFurniture> furniture) {
  if (furniture.isEmpty) {
    return const AuditRule(
      id: 'old_new_black_gold',
      title: 'Old, New, Black, Gold',
      description:
          'A mix of old and new items with black and metallic accents creates depth.',
      status: AuditStatus.unknown,
      detail: 'Lock some furniture to evaluate this rule.',
    );
  }

  var hits = 0;
  final found = <String>[];

  // "Something old" = traditional style
  if (furniture.any((f) => f.style == FurnitureStyle.traditional)) {
    hits++;
    found.add('traditional piece');
  }

  // "Something new" = modern style
  if (furniture.any((f) => f.style == FurnitureStyle.modern)) {
    hits++;
    found.add('modern piece');
  }

  // "Something black" = dark anchor colour or matte black metal
  final hasBlack = furniture.any(
    (f) =>
        f.metalFinish == MetalFinish.matteBlack || _isDarkColour(f.colourHex),
  );
  if (hasBlack) {
    hits++;
    found.add('dark accent');
  }

  // "Something gold" = brass, gold, or copper metallic
  final hasGold = furniture.any(
    (f) =>
        f.metalFinish == MetalFinish.antiqueBrass ||
        f.metalFinish == MetalFinish.brushedGold ||
        f.metalFinish == MetalFinish.polishedBrass ||
        f.metalFinish == MetalFinish.roseGold ||
        f.metalFinish == MetalFinish.copper,
  );
  if (hasGold) {
    hits++;
    found.add('metallic warmth');
  }

  final AuditStatus status;
  final String? suggestion;
  if (hits >= 3) {
    status = AuditStatus.pass;
    suggestion = null;
  } else if (hits >= 2) {
    status = AuditStatus.partial;
    suggestion = _oldNewBlackGoldSuggestion(
      hasBlack: hasBlack,
      hasGold: hasGold,
      hasOld: found.contains('traditional piece'),
      hasNew: found.contains('modern piece'),
    );
  } else {
    status = AuditStatus.needsWork;
    suggestion =
        'Try mixing traditional and modern pieces, and add a dark accent and a warm metallic touch.';
  }

  return AuditRule(
    id: 'old_new_black_gold',
    title: 'Old, New, Black, Gold',
    description:
        'A mix of old and new items with black and metallic accents creates depth.',
    status: status,
    detail:
        found.isEmpty
            ? 'No characteristic items detected yet.'
            : 'Found: ${found.join(', ')}.',
    suggestion: suggestion,
  );
}

String _oldNewBlackGoldSuggestion({
  required bool hasOld,
  required bool hasNew,
  required bool hasBlack,
  required bool hasGold,
}) {
  final missing = <String>[];
  if (!hasOld) missing.add('a vintage or traditional piece');
  if (!hasNew) missing.add('a contemporary item');
  if (!hasBlack) {
    missing.add('a dark accent (matte black frame or dark cushion)');
  }
  if (!hasGold) missing.add('a warm metallic touch (brass, gold, or copper)');
  return 'Consider adding ${missing.join(' and ')}.';
}

// ── Rule 2: Odd Numbers (3-5-7) ─────────────────────────────────────────

AuditRule _checkOddNumbers(List<LockedFurniture> furniture) {
  final accessories = furniture.where(
    (f) =>
        f.category == FurnitureCategory.other ||
        f.category == FurnitureCategory.lighting,
  );

  if (accessories.isEmpty) {
    return const AuditRule(
      id: 'odd_numbers',
      title: 'Rule of Odd Numbers',
      description:
          'Objects grouped in 3s, 5s, or 7s are more visually appealing.',
      status: AuditStatus.unknown,
      detail: 'Add accessories to evaluate this rule.',
    );
  }

  final count = accessories.length;
  final isOdd = count % 2 != 0;

  return AuditRule(
    id: 'odd_numbers',
    title: 'Rule of Odd Numbers',
    description:
        'Objects grouped in 3s, 5s, or 7s are more visually appealing.',
    status: isOdd ? AuditStatus.pass : AuditStatus.partial,
    detail: '$count accessory items locked.',
    suggestion:
        isOdd
            ? null
            : 'You have an even number of accessories. Adding or removing one creates a more dynamic arrangement.',
  );
}

// ── Rule 3: Texture Layering ────────────────────────────────────────────

AuditRule _checkTextureLayering(List<LockedFurniture> furniture) {
  final textures =
      furniture
          .where((f) => f.textureFeel != null)
          .map((f) => f.textureFeel!)
          .toSet();

  if (textures.isEmpty) {
    return const AuditRule(
      id: 'texture_layering',
      title: 'Texture Layering',
      description:
          'At least 3 different textures prevent a room from feeling flat.',
      status: AuditStatus.unknown,
      detail: 'Add texture data to furniture for better evaluation.',
    );
  }

  final AuditStatus status;
  final String? suggestion;
  if (textures.length >= 3) {
    status = AuditStatus.pass;
    suggestion = null;
  } else if (textures.length == 2) {
    status = AuditStatus.partial;
    final missing = _suggestMissingTexture(textures);
    suggestion = 'You have 2 textures. Add $missing for more depth.';
  } else {
    status = AuditStatus.needsWork;
    suggestion =
        'All items share the same texture. Mix smooth, chunky, and woven items for visual interest.';
  }

  return AuditRule(
    id: 'texture_layering',
    title: 'Texture Layering',
    description:
        'At least 3 different textures prevent a room from feeling flat.',
    status: status,
    detail:
        '${textures.length} texture types found: ${textures.map((t) => t.displayName.toLowerCase()).join(', ')}.',
    suggestion: suggestion,
  );
}

String _suggestMissingTexture(Set<TextureFeel> existing) {
  if (!existing.contains(TextureFeel.chunky)) {
    return 'something chunky (a knit throw or woven basket)';
  }
  if (!existing.contains(TextureFeel.smooth)) {
    return 'something smooth (glass, polished ceramic, or leather)';
  }
  return 'a contrasting texture (high-texture linen or a ribbed vase)';
}

// ── Rule 4: Layered Lighting ────────────────────────────────────────────

AuditRule _checkLayeredLighting(List<LockedFurniture> furniture) {
  final lightingItems = furniture.where(
    (f) => f.category == FurnitureCategory.lighting,
  );

  if (lightingItems.isEmpty) {
    return const AuditRule(
      id: 'layered_lighting',
      title: 'Layered Lighting',
      description:
          'Every room needs ambient, task, and accent light for balance.',
      status: AuditStatus.needsWork,
      detail: 'No lighting locked. Most rooms need at least 3 light sources.',
      suggestion:
          'Start with a main ceiling light, a reading lamp, and a table lamp or candles.',
    );
  }

  // Classify lighting by name heuristics
  final hasAmbient = lightingItems.any(
    (f) => _matchesAny(f.name, ['ceiling', 'pendant', 'chandelier', 'main']),
  );
  final hasTask = lightingItems.any(
    (f) => _matchesAny(f.name, ['desk', 'reading', 'floor', 'study']),
  );
  final hasAccent = lightingItems.any(
    (f) => _matchesAny(f.name, [
      'table lamp',
      'strip',
      'candle',
      'wall',
      'fairy',
      'accent',
    ]),
  );

  final layers = [hasAmbient, hasTask, hasAccent].where((v) => v).length;

  final AuditStatus status;
  if (layers == 3) {
    status = AuditStatus.pass;
  } else if (layers == 2) {
    status = AuditStatus.partial;
  } else {
    status = AuditStatus.needsWork;
  }

  final missing = <String>[];
  if (!hasAmbient) missing.add('ambient (ceiling or pendant)');
  if (!hasTask) missing.add('task (floor or desk lamp)');
  if (!hasAccent) missing.add('accent (table lamp or candles)');

  return AuditRule(
    id: 'layered_lighting',
    title: 'Layered Lighting',
    description:
        'Every room needs ambient, task, and accent light for balance.',
    status: status,
    detail: '$layers of 3 lighting layers covered.',
    suggestion:
        missing.isEmpty ? null : 'Add ${missing.join(' and ')} lighting.',
  );
}

// ── Rule 5: Material Balance ────────────────────────────────────────────

AuditRule _checkMaterialBalance(List<LockedFurniture> furniture) {
  final materials =
      furniture
          .where((f) => f.material != null)
          .map((f) => f.material!)
          .toSet();

  if (materials.isEmpty) {
    return const AuditRule(
      id: 'material_balance',
      title: 'Material Balance',
      description:
          'Mix warm materials (wood, fabric) with cool (metal, glass).',
      status: AuditStatus.unknown,
      detail: 'Add material data to furniture for evaluation.',
    );
  }

  const warmMaterials = {
    FurnitureMaterial.wood,
    FurnitureMaterial.fabric,
    FurnitureMaterial.leather,
    FurnitureMaterial.wickerRattan,
  };
  const coolMaterials = {
    FurnitureMaterial.metal,
    FurnitureMaterial.glass,
    FurnitureMaterial.stone,
  };

  final hasWarm = materials.any((m) => warmMaterials.contains(m));
  final hasCool = materials.any((m) => coolMaterials.contains(m));

  final AuditStatus status;
  final String? suggestion;
  if (hasWarm && hasCool) {
    status = AuditStatus.pass;
    suggestion = null;
  } else if (hasWarm) {
    status = AuditStatus.partial;
    suggestion =
        'All materials are warm. Introduce a cool element like glass, metal, or stone for contrast.';
  } else if (hasCool) {
    status = AuditStatus.partial;
    suggestion =
        'All materials are cool. Add warmth with wood, fabric, or leather.';
  } else {
    status = AuditStatus.needsWork;
    suggestion =
        'Mix warm (wood, fabric, leather) and cool (metal, glass, stone) materials.';
  }

  return AuditRule(
    id: 'material_balance',
    title: 'Material Balance',
    description: 'Mix warm materials (wood, fabric) with cool (metal, glass).',
    status: status,
    detail:
        'Materials found: ${materials.map((m) => m.displayName.toLowerCase()).join(', ')}.',
    suggestion: suggestion,
  );
}

// ── Rule 6: Wood Tone Rule ──────────────────────────────────────────────

AuditRule _checkWoodToneRule(List<LockedFurniture> furniture) {
  final woodTones =
      furniture
          .where((f) => f.woodTone != null)
          .map((f) => f.woodTone!)
          .toSet();

  if (woodTones.isEmpty) {
    return const AuditRule(
      id: 'wood_tone',
      title: 'Wood Tone Harmony',
      description:
          'Pick a dominant wood tone and one accent; never match all wood exactly.',
      status: AuditStatus.unknown,
      detail: 'No wood tones recorded. Add wood data to furniture.',
    );
  }

  if (woodTones.length == 1) {
    return AuditRule(
      id: 'wood_tone',
      title: 'Wood Tone Harmony',
      description:
          'Pick a dominant wood tone and one accent; never match all wood exactly.',
      status: AuditStatus.partial,
      detail: 'Only one wood tone: ${woodTones.first.displayName}.',
      suggestion:
          'All wood matches perfectly, which can feel flat. Consider a contrasting accent wood.',
    );
  }

  // Check for warm/cool clash
  final hasWarmWood = woodTones.any(_isWarmWood);
  final hasCoolWood = woodTones.any((w) => !_isWarmWood(w));

  if (hasWarmWood && hasCoolWood) {
    return AuditRule(
      id: 'wood_tone',
      title: 'Wood Tone Harmony',
      description:
          'Pick a dominant wood tone and one accent; never match all wood exactly.',
      status: AuditStatus.needsWork,
      detail:
          'Warm and cool wood tones mixed: ${woodTones.map((w) => w.displayName).join(', ')}.',
      suggestion:
          'Warm and cool-toned woods can clash. Try replacing one with a wood from the same undertone family, or bridge with a neutral material.',
    );
  }

  return AuditRule(
    id: 'wood_tone',
    title: 'Wood Tone Harmony',
    description:
        'Pick a dominant wood tone and one accent; never match all wood exactly.',
    status: AuditStatus.pass,
    detail:
        'Wood tones: ${woodTones.map((w) => w.displayName).join(', ')}. Compatible undertones with good variety.',
  );
}

bool _isWarmWood(WoodTone tone) {
  return const {
    WoodTone.honeyOak,
    WoodTone.walnut,
    WoodTone.darkStain,
    WoodTone.reclaimed,
    WoodTone.teak,
  }.contains(tone);
}

// ── Rule 7: Metal Finish Consistency ────────────────────────────────────

AuditRule _checkMetalConsistency(List<LockedFurniture> furniture) {
  final metals =
      furniture
          .where((f) => f.metalFinish != null)
          .map((f) => f.metalFinish!)
          .toSet();

  if (metals.isEmpty) {
    return const AuditRule(
      id: 'metal_consistency',
      title: 'Metal Finish Consistency',
      description:
          'One dominant metal finish plus one accent at most keeps metals harmonious.',
      status: AuditStatus.unknown,
      detail: 'No metal finishes recorded.',
    );
  }

  if (metals.length <= 2) {
    return AuditRule(
      id: 'metal_consistency',
      title: 'Metal Finish Consistency',
      description:
          'One dominant metal finish plus one accent at most keeps metals harmonious.',
      status: AuditStatus.pass,
      detail: 'Metal finishes: ${metals.map((m) => m.displayName).join(', ')}.',
    );
  }

  return AuditRule(
    id: 'metal_consistency',
    title: 'Metal Finish Consistency',
    description:
        'One dominant metal finish plus one accent at most keeps metals harmonious.',
    status: AuditStatus.needsWork,
    detail:
        '${metals.length} different metals: ${metals.map((m) => m.displayName).join(', ')}.',
    suggestion:
        'Too many competing metals. Pick one dominant and one accent finish, then swap the rest.',
  );
}

// ── Rule 8: Visual Weight Distribution ──────────────────────────────────

AuditRule _checkVisualWeight(List<LockedFurniture> furniture) {
  final weights =
      furniture
          .where((f) => f.visualWeight != null)
          .map((f) => f.visualWeight!)
          .toList();

  if (weights.isEmpty) {
    return const AuditRule(
      id: 'visual_weight',
      title: 'Visual Weight Balance',
      description:
          'Balance heavy, dark items with lighter ones so the room feels stable.',
      status: AuditStatus.unknown,
      detail: 'Add visual weight data to furniture for evaluation.',
    );
  }

  final heavyCount = weights.where((w) => w == VisualWeight.heavy).length;
  final lightCount = weights.where((w) => w == VisualWeight.light).length;
  final mediumCount = weights.where((w) => w == VisualWeight.medium).length;

  final AuditStatus status;
  final String? suggestion;
  if (heavyCount > 0 && lightCount > 0) {
    status = AuditStatus.pass;
    suggestion = null;
  } else if (heavyCount > 0 && mediumCount > 0) {
    status = AuditStatus.partial;
    suggestion =
        'Good range but consider a lighter piece (glass side table, sheer curtain) to lift the room.';
  } else if (lightCount > 0 && mediumCount > 0 && heavyCount == 0) {
    status = AuditStatus.partial;
    suggestion =
        'The room may feel too airy. A heavier anchor piece (dark bookshelf, substantial rug) would add grounding.';
  } else {
    status = AuditStatus.needsWork;
    suggestion =
        heavyCount > 0
            ? 'Too much visual weight. Add lighter, open pieces to give the room breathing space.'
            : 'The room lacks grounding. Add a substantial piece to anchor the space.';
  }

  return AuditRule(
    id: 'visual_weight',
    title: 'Visual Weight Balance',
    description:
        'Balance heavy, dark items with lighter ones so the room feels stable.',
    status: status,
    detail: 'Heavy: $heavyCount, Medium: $mediumCount, Light: $lightCount.',
    suggestion: suggestion,
  );
}

// ── Rule 9: Colour Plan Completeness ────────────────────────────────────

AuditRule _checkColourPlan(Room room) {
  final hasHero = room.heroColourHex != null;
  final hasBeta = room.betaColourHex != null;
  final hasSurprise = room.surpriseColourHex != null;

  final completeParts = [hasHero, hasBeta, hasSurprise].where((v) => v).length;

  final AuditStatus status;
  final String? suggestion;
  if (completeParts == 3) {
    status = AuditStatus.pass;
    suggestion = null;
  } else if (hasHero) {
    status = AuditStatus.partial;
    suggestion =
        'Hero colour is set but your full 70/20/10 plan is incomplete. Complete it for maximum impact.';
  } else {
    status = AuditStatus.needsWork;
    suggestion =
        'Choose a hero colour to anchor the room and unlock the colour plan.';
  }

  return AuditRule(
    id: 'colour_plan',
    title: 'Colour Plan',
    description:
        'A complete 70/20/10 plan ensures intentional colour balance across the room.',
    status: status,
    detail: '$completeParts of 3 colour tiers defined.',
    suggestion: suggestion,
  );
}

// ── Helpers ─────────────────────────────────────────────────────────────

bool _matchesAny(String text, List<String> terms) {
  final lower = text.toLowerCase();
  return terms.any(lower.contains);
}

bool _isDarkColour(String hex) {
  final clean = hex.replaceFirst('#', '');
  if (clean.length < 6) return false;
  final r = int.tryParse(clean.substring(0, 2), radix: 16) ?? 128;
  final g = int.tryParse(clean.substring(2, 4), radix: 16) ?? 128;
  final b = int.tryParse(clean.substring(4, 6), radix: 16) ?? 128;
  // Relative luminance approximation
  final luminance = 0.299 * r + 0.587 * g + 0.114 * b;
  return luminance < 60;
}

String _buildSummary(int score, int totalPossible, List<AuditRule> rules) {
  if (totalPossible == 0) {
    return 'Add furniture data to unlock your room audit.';
  }

  final pct = score / totalPossible;
  if (pct >= 0.85) {
    return 'This room is well balanced. Small tweaks could make it exceptional.';
  } else if (pct >= 0.6) {
    return 'Good foundations. A few adjustments will bring this room together.';
  } else if (pct >= 0.35) {
    return 'This room has potential but several design rules need attention.';
  } else {
    return 'Early days. Lock more furniture and complete your colour plan to see progress.';
  }
}
