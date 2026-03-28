import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/locked_furniture.dart';
import 'package:palette/data/models/product.dart';
import 'package:palette/data/models/room.dart';

/// Configurable scoring weights for the recommendation engine.
///
/// Loaded from `assets/data/scoring_weights.json` at runtime. Supports
/// per-category overrides so that, e.g., rug recommendations can weight
/// `budgetFit` more heavily if feedback data shows price is the dominant
/// dismiss reason for rugs.
class ScoringWeights {
  const ScoringWeights({
    this.colourCompatibility = 0.22,
    this.undertoneCompatibility = 0.15,
    this.finishMaterialHarmony = 0.13,
    this.budgetFit = 0.13,
    this.styleFit = 0.12,
    this.materialBalance = 0.10,
    this.scaleFit = 0.10,
    this.renterSuitability = 0.05,
  });

  /// Create from a JSON map (e.g. from scoring_weights.json).
  factory ScoringWeights.fromJson(Map<String, dynamic> json) => ScoringWeights(
    colourCompatibility:
        (json['colourCompatibility'] as num?)?.toDouble() ?? 0.22,
    undertoneCompatibility:
        (json['undertoneCompatibility'] as num?)?.toDouble() ?? 0.15,
    finishMaterialHarmony:
        (json['finishMaterialHarmony'] as num?)?.toDouble() ?? 0.13,
    budgetFit: (json['budgetFit'] as num?)?.toDouble() ?? 0.13,
    styleFit: (json['styleFit'] as num?)?.toDouble() ?? 0.12,
    materialBalance: (json['materialBalance'] as num?)?.toDouble() ?? 0.10,
    scaleFit: (json['scaleFit'] as num?)?.toDouble() ?? 0.10,
    renterSuitability: (json['renterSuitability'] as num?)?.toDouble() ?? 0.05,
  );

  final double colourCompatibility;
  final double undertoneCompatibility;
  final double finishMaterialHarmony;
  final double budgetFit;
  final double styleFit;
  final double materialBalance;
  final double scaleFit;
  final double renterSuitability;

  Map<String, double> toJson() => {
    'colourCompatibility': colourCompatibility,
    'undertoneCompatibility': undertoneCompatibility,
    'finishMaterialHarmony': finishMaterialHarmony,
    'budgetFit': budgetFit,
    'styleFit': styleFit,
    'materialBalance': materialBalance,
    'scaleFit': scaleFit,
    'renterSuitability': renterSuitability,
  };
}

/// Default weights from the spec.
const kDefaultWeights = ScoringWeights();

/// Versioned scoring weights configuration loaded from JSON asset.
///
/// Supports global weights and per-category overrides.
class ScoringWeightsConfig {
  const ScoringWeightsConfig({
    required this.version,
    required this.global,
    required this.categoryOverrides,
  });

  factory ScoringWeightsConfig.fromJson(Map<String, dynamic> json) {
    final global =
        json['global'] is Map<String, dynamic>
            ? ScoringWeights.fromJson(json['global'] as Map<String, dynamic>)
            : kDefaultWeights;

    final overrides = <String, ScoringWeights>{};
    final overridesJson = json['categoryOverrides'];
    if (overridesJson is Map<String, dynamic>) {
      for (final entry in overridesJson.entries) {
        if (entry.value is Map<String, dynamic>) {
          overrides[entry.key] = ScoringWeights.fromJson(
            entry.value as Map<String, dynamic>,
          );
        }
      }
    }

    return ScoringWeightsConfig(
      version: (json['version'] as num?)?.toInt() ?? 0,
      global: global,
      categoryOverrides: overrides,
    );
  }

  final int version;
  final ScoringWeights global;

  /// Category name -> override weights for that category.
  final Map<String, ScoringWeights> categoryOverrides;

  /// Get the weights for a specific product category, falling back to global.
  ScoringWeights forCategory(String category) =>
      categoryOverrides[category] ?? global;

  /// Load from the bundled JSON asset.
  static Future<ScoringWeightsConfig> load() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/data/scoring_weights.json',
      );
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return ScoringWeightsConfig.fromJson(json);
    } catch (_) {
      return const ScoringWeightsConfig(
        version: 0,
        global: kDefaultWeights,
        categoryOverrides: {},
      );
    }
  }
}

/// A scored product recommendation with explanation.
class ScoredProduct {
  const ScoredProduct({
    required this.product,
    required this.totalScore,
    required this.primaryReason,
    required this.secondaryReason,
    required this.confidenceLabel,
    this.finishNote,
    this.materialNote,
    this.tradeoffNote,
  });

  final Product product;
  final double totalScore;
  final String primaryReason;
  final String secondaryReason;
  final String confidenceLabel;
  final String? finishNote;
  final String? materialNote;
  final String? tradeoffNote;
}

/// The recommendation slot label for diversity.
enum RecommendationSlot {
  recommended,
  bestValue,
  somethingDifferent,
  safeChoice,
}

extension RecommendationSlotX on RecommendationSlot {
  String get displayName => switch (this) {
    RecommendationSlot.recommended => 'Recommended',
    RecommendationSlot.bestValue => 'Best value',
    RecommendationSlot.somethingDifferent => 'Something different',
    RecommendationSlot.safeChoice => 'Safe choice',
  };
}

/// Score and rank products for a given room context.
///
/// Returns up to [limit] recommendations, with hard filters applied first
/// then soft scoring. Uses the spec's scoring dimensions.
List<ScoredProduct> scoreProducts({
  required List<Product> candidates,
  required Room room,
  required List<LockedFurniture> lockedFurniture,
  required ColourArchetype? archetype,
  ScoringWeights weights = kDefaultWeights,
  int limit = 4,
}) {
  // ── Hard filters (pass/fail) ──
  final filtered =
      candidates.where((p) {
        // Budget check
        if (!_budgetPasses(p, room.budget)) return false;

        // Renter safety check
        if (room.isRenterMode && !p.renterSafe) return false;

        // Availability
        if (!p.available) return false;

        // Metal clash: reject if it would introduce a 3rd metal finish
        if (p.metalFinish != null) {
          final existingMetals =
              lockedFurniture
                  .where((f) => f.metalFinish != null)
                  .map((f) => f.metalFinish!)
                  .toSet();
          if (existingMetals.length >= 2 &&
              !existingMetals.contains(p.metalFinish)) {
            return false;
          }
        }

        // Wood tone undertone clash with existing locked wood
        if (p.woodTone != null) {
          final existingWoods =
              lockedFurniture
                  .where((f) => f.woodTone != null)
                  .map((f) => f.woodTone!)
                  .toSet();
          if (existingWoods.isNotEmpty) {
            final pUndertone = p.woodTone!.undertone;
            final hasClash = existingWoods.any(
              (w) =>
                  w.undertone != Undertone.neutral &&
                  pUndertone != Undertone.neutral &&
                  w.undertone != pUndertone,
            );
            if (hasClash) return false;
          }
        }

        return true;
      }).toList();

  // ── Soft scoring ──
  final scored = <ScoredProduct>[];

  for (final product in filtered) {
    final scores = _computeScores(
      product: product,
      room: room,
      lockedFurniture: lockedFurniture,
      archetype: archetype,
      weights: weights,
    );

    scored.add(scores);
  }

  // Sort by total score descending
  scored.sort((a, b) => b.totalScore.compareTo(a.totalScore));

  // Return top N
  return scored.take(limit).toList();
}

/// Build a diverse recommendation set with variety slots.
List<(RecommendationSlot, ScoredProduct)> diverseRecommendations({
  required List<ScoredProduct> scored,
}) {
  if (scored.isEmpty) return [];

  final results = <(RecommendationSlot, ScoredProduct)>[];

  // Best overall fit
  results.add((RecommendationSlot.recommended, scored.first));

  // Best budget option: cheapest with decent score
  final budgetPick =
      scored.skip(1).where((s) => s.totalScore > 0.3).toList()
        ..sort((a, b) => a.product.priceGbp.compareTo(b.product.priceGbp));
  if (budgetPick.isNotEmpty &&
      budgetPick.first.product.id != scored.first.product.id) {
    results.add((RecommendationSlot.bestValue, budgetPick.first));
  }

  // Something different: most different undertone from top pick
  final differentPick = scored
      .skip(1)
      .where(
        (s) =>
            s.product.undertone != scored.first.product.undertone &&
            !results.any((r) => r.$2.product.id == s.product.id),
      );
  if (differentPick.isNotEmpty) {
    results.add((RecommendationSlot.somethingDifferent, differentPick.first));
  }

  // Safe choice: highest undertone compatibility (neutral or matching)
  final safePick = scored
      .skip(1)
      .where(
        (s) =>
            s.product.undertone == Undertone.neutral &&
            !results.any((r) => r.$2.product.id == s.product.id),
      );
  if (safePick.isNotEmpty) {
    results.add((RecommendationSlot.safeChoice, safePick.first));
  }

  return results;
}

// ── Private scoring helpers ──

bool _budgetPasses(Product p, BudgetBracket roomBudget) {
  final tier = p.priceTier;
  return switch (roomBudget) {
    BudgetBracket.affordable => tier == PriceTier.affordable,
    BudgetBracket.midRange =>
      tier == PriceTier.affordable || tier == PriceTier.midRange,
    BudgetBracket.investment => true,
  };
}

ScoredProduct _computeScores({
  required Product product,
  required Room room,
  required List<LockedFurniture> lockedFurniture,
  required ColourArchetype? archetype,
  required ScoringWeights weights,
}) {
  // 1. Colour compatibility (delta-E against palette)
  final colourScore = _scoreColour(product, room);

  // 2. Undertone compatibility
  final undertoneScore = _scoreUndertone(product, room);

  // 3. Finish/material harmony with locked items
  final harmonyScore = _scoreHarmony(product, lockedFurniture);

  // 4. Budget fit (already hard-filtered, but reward exact bracket match)
  final budgetScore = _scoreBudget(product, room.budget);

  // 5. Style fit (archetype alignment)
  final styleScore = _scoreStyle(product, archetype);

  // 6. Material balance (fills texture/material gaps)
  final materialScore = _scoreMaterialBalance(product, lockedFurniture);

  // 7. Scale fit (appropriate for room size)
  final scaleScore = _scoreScale(product, room);

  // 8. Renter suitability
  final renterScore =
      room.isRenterMode ? (product.renterSafe ? 1.0 : 0.0) : 1.0;

  final total =
      colourScore * weights.colourCompatibility +
      undertoneScore * weights.undertoneCompatibility +
      harmonyScore * weights.finishMaterialHarmony +
      budgetScore * weights.budgetFit +
      styleScore * weights.styleFit +
      materialScore * weights.materialBalance +
      scaleScore * weights.scaleFit +
      renterScore * weights.renterSuitability;

  // Generate explanation
  final explanation = _generateExplanation(
    product: product,
    room: room,
    lockedFurniture: lockedFurniture,
    colourScore: colourScore,
    undertoneScore: undertoneScore,
    harmonyScore: harmonyScore,
    materialScore: materialScore,
  );

  return ScoredProduct(
    product: product,
    totalScore: total,
    primaryReason: explanation.primary,
    secondaryReason: explanation.secondary,
    confidenceLabel:
        total > 0.7
            ? 'Strong match'
            : total > 0.5
            ? 'Good alternative'
            : 'Worth considering',
    finishNote: explanation.finishNote,
    materialNote: explanation.materialNote,
    tradeoffNote: explanation.tradeoffNote,
  );
}

double _scoreColour(Product product, Room room) {
  if (room.heroColourHex == null) return 0.5;

  final productLab = hexToLab(product.primaryColourHex);
  final heroLab = hexToLab(room.heroColourHex!);
  final deltaE = deltaE2000(productLab, heroLab);

  // Check against all 70/20/10 colours, use best match
  var bestDelta = deltaE;
  if (room.betaColourHex != null) {
    final betaDelta = deltaE2000(productLab, hexToLab(room.betaColourHex!));
    if (betaDelta < bestDelta) bestDelta = betaDelta;
  }
  if (room.surpriseColourHex != null) {
    final surpriseDelta = deltaE2000(
      productLab,
      hexToLab(room.surpriseColourHex!),
    );
    if (surpriseDelta < bestDelta) bestDelta = surpriseDelta;
  }

  // Score: perfect match at 0 delta-E → 1.0, terrible at 50+ → 0.0
  return (1.0 - (bestDelta / 50.0)).clamp(0.0, 1.0);
}

double _scoreUndertone(Product product, Room room) {
  // Check if room direction suggests warm/cool preference
  final directionPref = switch (room.direction) {
    CompassDirection.north => Undertone.warm,
    CompassDirection.south => Undertone.cool,
    _ => null,
  };

  if (product.undertone == Undertone.neutral) return 0.8;

  if (directionPref != null && product.undertone == directionPref) return 1.0;
  if (directionPref != null && product.undertone != directionPref) return 0.4;

  return 0.7;
}

double _scoreHarmony(Product product, List<LockedFurniture> locked) {
  if (locked.isEmpty) return 0.7;

  var score = 0.7;

  // Metal consistency
  if (product.metalFinish != null) {
    final existingMetals =
        locked
            .where((f) => f.metalFinish != null)
            .map((f) => f.metalFinish!)
            .toSet();
    if (existingMetals.isNotEmpty) {
      if (existingMetals.contains(product.metalFinish)) {
        score += 0.2; // Same metal = consistent
      } else if (existingMetals.length == 1) {
        score += 0.1; // One accent is fine
      }
    }
  }

  // Wood tone compatibility
  if (product.woodTone != null) {
    final existingWoods =
        locked.where((f) => f.woodTone != null).map((f) => f.woodTone!).toSet();
    if (existingWoods.isNotEmpty) {
      final sameUndertone = existingWoods.any(
        (w) => w.undertone == product.woodTone!.undertone,
      );
      if (sameUndertone) score += 0.15;
    }
  }

  return score.clamp(0.0, 1.0);
}

double _scoreBudget(Product product, BudgetBracket budget) {
  final tier = product.priceTier;
  return switch (budget) {
    BudgetBracket.affordable => tier == PriceTier.affordable ? 1.0 : 0.5,
    BudgetBracket.midRange => tier == PriceTier.midRange ? 1.0 : 0.7,
    BudgetBracket.investment => 1.0,
  };
}

double _scoreStyle(Product product, ColourArchetype? archetype) {
  if (archetype == null) return 0.5;

  // Map archetype families to preferred product styles
  final preferredStyles = _archetypeToStyles(archetype);
  final overlap = product.styles.where(preferredStyles.contains).length;

  if (overlap == 0) return 0.3;
  return (0.5 + overlap * 0.25).clamp(0.0, 1.0);
}

List<ProductStyle> _archetypeToStyles(
  ColourArchetype archetype,
) => switch (archetype) {
  ColourArchetype.theCocooner => [
    ProductStyle.traditional,
    ProductStyle.scandi,
  ],
  ColourArchetype.theGoldenHour => [
    ProductStyle.bohemian,
    ProductStyle.midCentury,
  ],
  ColourArchetype.theCurator => [
    ProductStyle.minimalist,
    ProductStyle.midCentury,
  ],
  ColourArchetype.theMonochromeModernist => [
    ProductStyle.modern,
    ProductStyle.minimalist,
  ],
  ColourArchetype.theRomantic => [
    ProductStyle.traditional,
    ProductStyle.bohemian,
  ],
  ColourArchetype.theColourOptimist => [
    ProductStyle.modern,
    ProductStyle.bohemian,
  ],
  ColourArchetype.theNatureLover => [
    ProductStyle.scandi,
    ProductStyle.bohemian,
  ],
  ColourArchetype.theStoryteller => [
    ProductStyle.bohemian,
    ProductStyle.traditional,
  ],
  ColourArchetype.theVelvetWhisper => [
    ProductStyle.modern,
    ProductStyle.midCentury,
  ],
  ColourArchetype.theMaximalist => [
    ProductStyle.bohemian,
    ProductStyle.traditional,
  ],
  ColourArchetype.theBrightener => [ProductStyle.modern, ProductStyle.scandi],
  ColourArchetype.theDramatist => [
    ProductStyle.modern,
    ProductStyle.industrial,
  ],
  ColourArchetype.theMidnightArchitect => [
    ProductStyle.modern,
    ProductStyle.industrial,
  ],
  ColourArchetype.theMinimalist => [
    ProductStyle.minimalist,
    ProductStyle.scandi,
  ],
};

double _scoreMaterialBalance(Product product, List<LockedFurniture> locked) {
  if (locked.isEmpty) return 0.6;

  final textures =
      locked
          .where((f) => f.textureFeel != null)
          .map((f) => f.textureFeel!)
          .toList();

  if (textures.isEmpty) return 0.6;

  final allSmooth = textures.every((t) => t == TextureFeel.smooth);
  final allSoft = textures.every(
    (t) => t == TextureFeel.highTexture || t == TextureFeel.chunky,
  );

  // Reward products that fill texture gaps
  if (allSmooth &&
      (product.textureFeel == TextureFeel.highTexture ||
          product.textureFeel == TextureFeel.chunky)) {
    return 1.0;
  }
  if (allSoft && product.textureFeel == TextureFeel.smooth) {
    return 1.0;
  }

  return 0.6;
}

double _scoreScale(Product product, Room room) {
  // For rugs, match rug size bracket to room dimensions.
  if (product.category == ProductCategory.rug && product.rugSize != null) {
    final roomSize = room.roomSize;
    if (roomSize != null) {
      final recommended = roomSize.recommendedRugSizes;
      if (recommended.contains(product.rugSize)) return 1.0;
      // One bracket off = acceptable
      final rugIndex = RugSize.values.indexOf(product.rugSize!);
      for (final rec in recommended) {
        if ((RugSize.values.indexOf(rec) - rugIndex).abs() == 1) return 0.6;
      }
      // Too small for large room or too large for small room
      return 0.2;
    }
    // Manual dimensions: compare rug area to room area
    final area = room.areaMetres;
    if (area != null) {
      final rugArea = _rugAreaM2(product.rugSize!);
      final ratio = rugArea / area;
      // Ideal: rug covers 30-60% of floor area
      if (ratio >= 0.25 && ratio <= 0.65) return 1.0;
      if (ratio >= 0.15 && ratio <= 0.75) return 0.6;
      return 0.2;
    }
  }
  // Non-rug products or no room size: neutral score.
  return 0.7;
}

double _rugAreaM2(RugSize size) => switch (size) {
  RugSize.small120x170 => 1.2 * 1.7,
  RugSize.medium160x230 => 1.6 * 2.3,
  RugSize.large200x290 => 2.0 * 2.9,
  RugSize.extraLarge240x340 => 2.4 * 3.4,
};

// ── Explanation generation ──

({
  String primary,
  String secondary,
  String? finishNote,
  String? materialNote,
  String? tradeoffNote,
})
_generateExplanation({
  required Product product,
  required Room room,
  required List<LockedFurniture> lockedFurniture,
  required double colourScore,
  required double undertoneScore,
  required double harmonyScore,
  required double materialScore,
}) {
  final primary = _buildPrimaryReason(product, room, colourScore);
  final secondary = _buildSecondaryReason(
    product,
    room,
    undertoneScore,
    harmonyScore,
  );

  String? finishNote;
  if (product.metalFinish != null) {
    final existingMetals =
        lockedFurniture
            .where((f) => f.metalFinish != null)
            .map((f) => f.metalFinish!.displayName)
            .toSet();
    if (existingMetals.isNotEmpty) {
      finishNote =
          'The ${product.metalFinish!.displayName.toLowerCase()} '
          'finish complements your existing '
          '${existingMetals.first.toLowerCase()} pieces.';
    }
  }

  String? materialNote;
  if (materialScore > 0.8) {
    final textures =
        lockedFurniture
            .where((f) => f.textureFeel != null)
            .map((f) => f.textureFeel!)
            .toList();
    final allSmooth =
        textures.isNotEmpty && textures.every((t) => t == TextureFeel.smooth);
    if (allSmooth) {
      materialNote =
          'The ${product.textureFeel.displayName.toLowerCase()} '
          'texture adds the contrast your room needs — all your current '
          'surfaces are smooth.';
    }
  }

  String? tradeoffNote;
  final tier = product.priceTier;
  if (tier != PriceTier.affordable && room.budget == BudgetBracket.affordable) {
    tradeoffNote =
        'Slightly above your budget bracket but exceptional colour match.';
  }

  return (
    primary: primary,
    secondary: secondary,
    finishNote: finishNote,
    materialNote: materialNote,
    tradeoffNote: tradeoffNote,
  );
}

String _buildPrimaryReason(Product product, Room room, double colourScore) {
  if (product.category == ProductCategory.rug) {
    return 'Grounds your seating area with the right scale and colour.';
  }
  if (product.isLighting) {
    final sub = product.category.lightingSubcategory?.displayName.toLowerCase();
    return "Adds ${sub ?? 'layered'} lighting to complete the room's "
        'atmosphere.';
  }
  if (colourScore > 0.8) {
    return "Excellent colour match with your room's palette.";
  }
  return "Complements your room's colour plan with a harmonious tone.";
}

String _buildSecondaryReason(
  Product product,
  Room room,
  double undertoneScore,
  double harmonyScore,
) {
  final direction = room.direction?.displayName ?? '';
  final facing = direction.isNotEmpty ? '$direction-facing ' : '';

  if (undertoneScore > 0.8) {
    return '${product.undertone.displayName} undertone harmonises with '
        "your ${facing}room's natural light.";
  }
  if (harmonyScore > 0.8) {
    return 'The materials work well with your existing furniture pieces.';
  }
  return "Suits the mood and atmosphere you're building in this room.";
}
