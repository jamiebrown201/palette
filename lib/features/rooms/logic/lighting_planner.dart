import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/locked_furniture.dart';
import 'package:palette/data/models/product.dart';
import 'package:palette/data/models/room.dart';

/// A single layer in a room's lighting plan.
class LightingLayer {
  const LightingLayer({
    required this.type,
    required this.title,
    required this.description,
    required this.whyItMatters,
    required this.isCovered,
    this.coveredBy,
    this.recommendations,
    this.renterNote,
  });

  final LightingSubcategory type;
  final String title;
  final String description;
  final String whyItMatters;
  final bool isCovered;

  /// The locked furniture item covering this layer, if any.
  final LockedFurniture? coveredBy;

  /// Product recommendations for this layer, if not covered.
  final List<Product>? recommendations;

  /// Special note for renters (e.g. "plug-in only").
  final String? renterNote;
}

/// Complete lighting plan for a room.
class LightingPlan {
  const LightingPlan({
    required this.roomName,
    required this.layers,
    required this.summary,
    required this.layersCovered,
    required this.layersTotal,
    this.overallNote,
  });

  final String roomName;
  final List<LightingLayer> layers;
  final String summary;
  final int layersCovered;
  final int layersTotal;
  final String? overallNote;

  bool get isComplete => layersCovered == layersTotal;
  bool get hasGaps => layersCovered < layersTotal;
}

/// Generates a three-layer lighting plan for a room.
///
/// Analyses locked furniture to determine which lighting layers are covered,
/// and recommends products from the catalogue for missing layers. Adapts
/// advice based on room direction, usage time, mood, and renter constraints.
LightingPlan generateLightingPlan({
  required Room room,
  required List<LockedFurniture> furniture,
  required List<Product> catalogue,
}) {
  // Determine which lighting is already present
  final ambientItems = _furnitureForLayer(
    furniture,
    LightingSubcategory.ambient,
  );
  final taskItems = _furnitureForLayer(furniture, LightingSubcategory.task);
  final accentItems = _furnitureForLayer(furniture, LightingSubcategory.accent);

  final hasAmbient = ambientItems.isNotEmpty;
  final hasTask = taskItems.isNotEmpty;
  final hasAccent = accentItems.isNotEmpty;

  // Filter catalogue to lighting products only, respecting renter constraints
  final lightingProducts =
      catalogue
          .where((p) => p.isLighting && p.available)
          .where((p) => !room.isRenterMode || p.renterSafe)
          .toList();

  // Build each layer
  final layers = [
    _buildAmbientLayer(
      room: room,
      isCovered: hasAmbient,
      coveredBy: hasAmbient ? ambientItems.first : null,
      catalogue: lightingProducts,
    ),
    _buildTaskLayer(
      room: room,
      isCovered: hasTask,
      coveredBy: hasTask ? taskItems.first : null,
      catalogue: lightingProducts,
    ),
    _buildAccentLayer(
      room: room,
      isCovered: hasAccent,
      coveredBy: hasAccent ? accentItems.first : null,
      catalogue: lightingProducts,
    ),
  ];

  final covered = layers.where((l) => l.isCovered).length;

  return LightingPlan(
    roomName: room.name,
    layers: layers,
    summary: _buildSummary(room, covered),
    layersCovered: covered,
    layersTotal: 3,
    overallNote: _buildOverallNote(room),
  );
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

List<LockedFurniture> _furnitureForLayer(
  List<LockedFurniture> furniture,
  LightingSubcategory layer,
) {
  return furniture.where((f) {
    if (f.category == null) return false;
    if (!f.isKeeping) return false;
    return switch (layer) {
      LightingSubcategory.ambient =>
        f.category == FurnitureCategory.lighting &&
            (f.name.toLowerCase().contains('pendant') ||
                f.name.toLowerCase().contains('ceiling') ||
                f.name.toLowerCase().contains('chandelier') ||
                f.name.toLowerCase().contains('overhead')),
      LightingSubcategory.task =>
        f.category == FurnitureCategory.lighting &&
            (f.name.toLowerCase().contains('floor') ||
                f.name.toLowerCase().contains('desk') ||
                f.name.toLowerCase().contains('reading') ||
                f.name.toLowerCase().contains('task')),
      LightingSubcategory.accent =>
        f.category == FurnitureCategory.lighting &&
            (f.name.toLowerCase().contains('table lamp') ||
                f.name.toLowerCase().contains('accent') ||
                f.name.toLowerCase().contains('candle') ||
                f.name.toLowerCase().contains('strip') ||
                f.name.toLowerCase().contains('fairy')),
    };
  }).toList();
}

LightingLayer _buildAmbientLayer({
  required Room room,
  required bool isCovered,
  required List<Product> catalogue,
  LockedFurniture? coveredBy,
}) {
  final recs =
      isCovered
          ? null
          : _recommendationsForLayer(
            catalogue,
            LightingSubcategory.ambient,
            room,
          );

  final why = _ambientWhyItMatters(room);
  final renterNote =
      room.isRenterMode
          ? 'Look for plug-in pendants or large floor lamps as a hardwire-free alternative.'
          : null;

  return LightingLayer(
    type: LightingSubcategory.ambient,
    title: 'Ambient lighting',
    description:
        'General overhead illumination that fills the room evenly. '
        'This is the base layer everything else builds on.',
    whyItMatters: why,
    isCovered: isCovered,
    coveredBy: coveredBy,
    recommendations: recs,
    renterNote: renterNote,
  );
}

LightingLayer _buildTaskLayer({
  required Room room,
  required bool isCovered,
  required List<Product> catalogue,
  LockedFurniture? coveredBy,
}) {
  final recs =
      isCovered
          ? null
          : _recommendationsForLayer(catalogue, LightingSubcategory.task, room);

  final why = _taskWhyItMatters(room);

  return LightingLayer(
    type: LightingSubcategory.task,
    title: 'Task lighting',
    description:
        'Directed light for activities like reading, cooking, or '
        'working. Floor lamps and desk lamps are the usual choices.',
    whyItMatters: why,
    isCovered: isCovered,
    coveredBy: coveredBy,
    recommendations: recs,
  );
}

LightingLayer _buildAccentLayer({
  required Room room,
  required bool isCovered,
  required List<Product> catalogue,
  LockedFurniture? coveredBy,
}) {
  final recs =
      isCovered
          ? null
          : _recommendationsForLayer(
            catalogue,
            LightingSubcategory.accent,
            room,
          );

  final why = _accentWhyItMatters(room);

  return LightingLayer(
    type: LightingSubcategory.accent,
    title: 'Accent lighting',
    description:
        'Decorative light that creates mood and highlights features. '
        'Table lamps, LED strips, and candle-style lights work well.',
    whyItMatters: why,
    isCovered: isCovered,
    coveredBy: coveredBy,
    recommendations: recs,
  );
}

List<Product> _recommendationsForLayer(
  List<Product> catalogue,
  LightingSubcategory layer,
  Room room,
) {
  final categories = switch (layer) {
    LightingSubcategory.ambient => [
      ProductCategory.pendantLight,
      ProductCategory.plugInPendant,
    ],
    LightingSubcategory.task => [ProductCategory.floorLamp],
    LightingSubcategory.accent => [ProductCategory.tableLamp],
  };

  var candidates =
      catalogue.where((p) => categories.contains(p.category)).toList();

  // Prefer budget-appropriate items
  final budgetTier = switch (room.budget) {
    BudgetBracket.affordable => PriceTier.affordable,
    BudgetBracket.midRange => PriceTier.midRange,
    BudgetBracket.investment => PriceTier.investment,
  };
  final budgetMatches =
      candidates.where((p) => p.priceTier == budgetTier).toList();
  if (budgetMatches.isNotEmpty) {
    candidates = budgetMatches;
  }

  // Sort by price ascending for predictability
  candidates.sort((a, b) => a.priceGbp.compareTo(b.priceGbp));

  return candidates.take(3).toList();
}

String _ambientWhyItMatters(Room room) {
  if (room.direction == CompassDirection.north) {
    return 'Your north-facing ${room.name} receives limited natural light. '
        'Strong ambient lighting prevents the room from feeling dim, '
        'especially in the afternoon and evening.';
  }
  if (room.usageTime == UsageTime.evening) {
    return 'You use this room mainly in the evening when natural light fades. '
        'A warm ambient source keeps the space inviting without harsh shadows.';
  }
  return 'Ambient lighting sets the overall brightness and feel of the room. '
      'Without it, other layers create pools of light with dark gaps.';
}

String _taskWhyItMatters(Room room) {
  if (room.moods.any((m) => m == RoomMood.energising || m == RoomMood.fresh)) {
    return 'An energising room benefits from focused task light that supports '
        'concentration and activity without relying solely on overhead glare.';
  }
  return 'Task lighting lets you read, work, or cook comfortably without '
      'straining your eyes. It adds a functional layer that ambient '
      'lighting alone cannot provide.';
}

String _accentWhyItMatters(Room room) {
  if (room.moods.any(
    (m) => m == RoomMood.cocooning || m == RoomMood.dramatic,
  )) {
    return 'A cocooning or dramatic mood relies on accent lighting to create '
        'warmth and depth. Table lamps and soft glow add the layered '
        'intimacy this room needs.';
  }
  if (room.direction == CompassDirection.south) {
    return 'Your south-facing room is bright during the day, but accent '
        'lighting transforms it in the evening, adding personality and warmth.';
  }
  return 'Accent lighting adds atmosphere and visual interest. It is the '
      'layer that turns a well-lit room into a room that feels designed.';
}

String _buildSummary(Room room, int covered) {
  if (covered == 3) {
    return 'Your ${room.name} has all three lighting layers covered. '
        'Great job creating a well-lit, layered space.';
  }
  if (covered == 0) {
    return 'No lighting layers are covered yet. Adding all three will '
        'transform how your ${room.name} feels day and night.';
  }
  final missing = 3 - covered;
  return '$covered of 3 layers covered. Adding the remaining $missing '
      'will complete the lighting plan for your ${room.name}.';
}

String? _buildOverallNote(Room room) {
  if (room.direction == CompassDirection.north &&
      room.usageTime == UsageTime.evening) {
    return 'North-facing rooms used in the evening need strong, warm-toned '
        'lighting across all three layers to feel comfortable. '
        'Consider warm white bulbs (2700K) throughout.';
  }
  if (room.roomSize == RoomSize.large) {
    return 'Large rooms often need multiple light sources per layer. '
        'Consider two floor lamps or a pendant plus a plug-in pendant '
        'to avoid dark corners.';
  }
  return null;
}
