import 'dart:math' as math;

import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/data/models/room.dart';

// ---------------------------------------------------------------------------
// Paint Finish Recommender (Phase 2B.3)
//
// Recommends paint finishes per surface based on Sowerby's guide, light
// direction, and colour LRV. Also computes paint quantities from room
// dimensions.
// ---------------------------------------------------------------------------

/// A surface in the room that needs paint.
enum PaintSurface {
  walls,
  woodwork,
  ceiling;

  String get displayName {
    switch (this) {
      case PaintSurface.walls:
        return 'Walls';
      case PaintSurface.woodwork:
        return 'Woodwork (skirting & architraves)';
      case PaintSurface.ceiling:
        return 'Ceiling';
    }
  }
}

/// Paint finish types available in the UK market.
enum PaintFinish {
  matt,
  eggshell,
  softSheen,
  satin,
  gloss;

  String get displayName {
    switch (this) {
      case PaintFinish.matt:
        return 'Matt';
      case PaintFinish.eggshell:
        return 'Eggshell';
      case PaintFinish.softSheen:
        return 'Soft Sheen';
      case PaintFinish.satin:
        return 'Satin';
      case PaintFinish.gloss:
        return 'Gloss';
    }
  }

  String get emulsionLabel {
    switch (this) {
      case PaintFinish.matt:
        return 'Matt Emulsion';
      case PaintFinish.eggshell:
        return 'Eggshell';
      case PaintFinish.softSheen:
        return 'Soft Sheen Emulsion';
      case PaintFinish.satin:
        return 'Satin';
      case PaintFinish.gloss:
        return 'Gloss';
    }
  }
}

/// A single finish recommendation for one surface in a room.
class FinishRecommendation {
  const FinishRecommendation({
    required this.surface,
    required this.finish,
    required this.reason,
    this.alternativeFinish,
    this.alternativeReason,
  });

  final PaintSurface surface;
  final PaintFinish finish;
  final String reason;
  final PaintFinish? alternativeFinish;
  final String? alternativeReason;
}

/// Full paint plan for a room: finishes + quantities per surface.
class RoomPaintPlan {
  const RoomPaintPlan({
    required this.finishRecommendations,
    required this.quantities,
    required this.lightDirectionNote,
    required this.colourNote,
  });

  final List<FinishRecommendation> finishRecommendations;
  final Map<PaintSurface, PaintQuantity> quantities;
  final String? lightDirectionNote;
  final String? colourNote;
}

/// Paint quantity estimate for a surface.
class PaintQuantity {
  const PaintQuantity({
    required this.litres,
    required this.tinSize,
    required this.tinsNeeded,
    required this.estimatedCost,
  });

  /// Litres needed (for two coats).
  final double litres;

  /// Recommended tin size in litres.
  final double tinSize;

  /// Number of tins to buy.
  final int tinsNeeded;

  /// Estimated cost (nullable if no price data).
  final double? estimatedCost;

  String get tinLabel {
    if (tinSize >= 1) {
      return '${tinSize.toStringAsFixed(tinSize == tinSize.roundToDouble() ? 0 : 1)}L';
    }
    return '${(tinSize * 1000).round()}ml';
  }
}

// ---------------------------------------------------------------------------
// Room type classification from room name
// ---------------------------------------------------------------------------

enum _RoomType {
  livingRoom,
  bedroom,
  kitchen,
  bathroom,
  hallway,
  childrenRoom,
  homeOffice,
  diningRoom,
  other,
}

_RoomType _classifyRoom(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('living') || lower.contains('lounge')) {
    return _RoomType.livingRoom;
  }
  if (lower.contains('kitchen')) return _RoomType.kitchen;
  if (lower.contains('bathroom') ||
      lower.contains('shower') ||
      lower.contains('en-suite') ||
      lower.contains('ensuite')) {
    return _RoomType.bathroom;
  }
  if (lower.contains('hall') || lower.contains('landing')) {
    return _RoomType.hallway;
  }
  if (lower.contains('nursery') ||
      lower.contains('child') ||
      lower.contains('kid')) {
    return _RoomType.childrenRoom;
  }
  if (lower.contains('office') || lower.contains('study')) {
    return _RoomType.homeOffice;
  }
  if (lower.contains('dining')) return _RoomType.diningRoom;
  if (lower.contains('bed') || lower.contains('guest')) {
    return _RoomType.bedroom;
  }
  return _RoomType.other;
}

// ---------------------------------------------------------------------------
// Surface-to-finish mapping (from spec table)
// ---------------------------------------------------------------------------

List<FinishRecommendation> _baseFinishesForRoom(_RoomType type) {
  switch (type) {
    case _RoomType.livingRoom:
    case _RoomType.diningRoom:
      return const [
        FinishRecommendation(
          surface: PaintSurface.walls,
          finish: PaintFinish.matt,
          reason:
              'Absorbs light evenly across large surfaces, hides imperfections, '
              'creates a calm backdrop',
        ),
        FinishRecommendation(
          surface: PaintSurface.woodwork,
          finish: PaintFinish.eggshell,
          reason:
              'More durable than matt, easier to clean, subtle sheen creates '
              'definition between wall and trim',
        ),
        FinishRecommendation(
          surface: PaintSurface.ceiling,
          finish: PaintFinish.matt,
          reason:
              'Reduces glare from overhead light, recedes visually to make '
              'the room feel taller',
        ),
      ];
    case _RoomType.bedroom:
      return const [
        FinishRecommendation(
          surface: PaintSurface.walls,
          finish: PaintFinish.matt,
          reason:
              'Soft, restful quality with no reflective glare from bedside '
              'lighting',
        ),
        FinishRecommendation(
          surface: PaintSurface.woodwork,
          finish: PaintFinish.eggshell,
          reason: 'Durable for skirting boards, easy to wipe clean',
        ),
        FinishRecommendation(
          surface: PaintSurface.ceiling,
          finish: PaintFinish.matt,
          reason:
              'Hides any ceiling imperfections, keeps the space feeling calm',
        ),
      ];
    case _RoomType.kitchen:
      return const [
        FinishRecommendation(
          surface: PaintSurface.walls,
          finish: PaintFinish.satin,
          reason:
              'Wipeable, resists moisture and grease, holds up to daily wear',
          alternativeFinish: PaintFinish.softSheen,
          alternativeReason:
              'Slightly softer look while still moisture-resistant',
        ),
        FinishRecommendation(
          surface: PaintSurface.woodwork,
          finish: PaintFinish.satin,
          reason:
              'Maximum durability in high-traffic, high-moisture environment',
        ),
        FinishRecommendation(
          surface: PaintSurface.ceiling,
          finish: PaintFinish.matt,
          reason: 'Hides condensation marks better than sheen finishes',
        ),
      ];
    case _RoomType.bathroom:
      return const [
        FinishRecommendation(
          surface: PaintSurface.walls,
          finish: PaintFinish.satin,
          reason:
              'Essential for moisture resistance, prevents peeling and mould',
          alternativeFinish: PaintFinish.softSheen,
          alternativeReason:
              'Softer look while still handling bathroom humidity',
        ),
        FinishRecommendation(
          surface: PaintSurface.woodwork,
          finish: PaintFinish.satin,
          reason: 'Maximum moisture protection for trim and frames',
          alternativeFinish: PaintFinish.gloss,
          alternativeReason: 'Even more moisture-resistant, traditional look',
        ),
        FinishRecommendation(
          surface: PaintSurface.ceiling,
          finish: PaintFinish.softSheen,
          reason: 'Moisture resistance on the surface most exposed to steam',
          alternativeFinish: PaintFinish.satin,
          alternativeReason:
              'Stronger protection for bathrooms without extraction fans',
        ),
      ];
    case _RoomType.hallway:
      return const [
        FinishRecommendation(
          surface: PaintSurface.walls,
          finish: PaintFinish.eggshell,
          reason:
              'High-traffic area, needs to withstand scuffs and be wipeable. '
              'Use matt on the upper half for a softer look',
          alternativeFinish: PaintFinish.satin,
          alternativeReason: 'Even tougher for busy family hallways',
        ),
        FinishRecommendation(
          surface: PaintSurface.woodwork,
          finish: PaintFinish.eggshell,
          reason: 'Durability for high-traffic zones',
        ),
        FinishRecommendation(
          surface: PaintSurface.ceiling,
          finish: PaintFinish.matt,
          reason: 'Stays clean-looking and recedes visually in a narrow space',
        ),
      ];
    case _RoomType.childrenRoom:
      return const [
        FinishRecommendation(
          surface: PaintSurface.walls,
          finish: PaintFinish.eggshell,
          reason: 'Wipeable for inevitable handprints and marks',
          alternativeFinish: PaintFinish.softSheen,
          alternativeReason: 'Slightly softer feel while still easy to clean',
        ),
        FinishRecommendation(
          surface: PaintSurface.woodwork,
          finish: PaintFinish.satin,
          reason: 'Maximum durability for the most active room in the house',
        ),
        FinishRecommendation(
          surface: PaintSurface.ceiling,
          finish: PaintFinish.matt,
          reason: 'Hides imperfections, calm overhead surface',
        ),
      ];
    case _RoomType.homeOffice:
      return const [
        FinishRecommendation(
          surface: PaintSurface.walls,
          finish: PaintFinish.matt,
          reason: 'Reduces screen glare, calm visual environment for focus',
        ),
        FinishRecommendation(
          surface: PaintSurface.woodwork,
          finish: PaintFinish.eggshell,
          reason: 'Clean definition between wall and trim',
        ),
        FinishRecommendation(
          surface: PaintSurface.ceiling,
          finish: PaintFinish.matt,
          reason: 'No overhead glare on screens',
        ),
      ];
    case _RoomType.other:
      return const [
        FinishRecommendation(
          surface: PaintSurface.walls,
          finish: PaintFinish.matt,
          reason: 'Versatile, hides imperfections, works in most rooms',
        ),
        FinishRecommendation(
          surface: PaintSurface.woodwork,
          finish: PaintFinish.eggshell,
          reason: 'Durable and easy to clean',
        ),
        FinishRecommendation(
          surface: PaintSurface.ceiling,
          finish: PaintFinish.matt,
          reason: 'Clean, receding finish for any ceiling',
        ),
      ];
  }
}

// ---------------------------------------------------------------------------
// Light direction adjustments
// ---------------------------------------------------------------------------

String? _lightDirectionNote(CompassDirection? direction, _RoomType roomType) {
  if (direction == null) return null;
  switch (direction) {
    case CompassDirection.north:
      return 'A soft sheen on one feature wall will help bounce the limited '
          'northern light around the room.';
    case CompassDirection.south:
      return 'Matt is ideal here because your generous southern light means '
          "you don't need the finish to do any work reflecting light.";
    case CompassDirection.east:
      return 'Strong morning light compensates well — matt works beautifully '
          'on most surfaces.';
    case CompassDirection.west:
      return 'Evening light is warm and soft. Matt enhances the effect without '
          'glare.';
  }
}

// ---------------------------------------------------------------------------
// Colour-LRV interaction note
// ---------------------------------------------------------------------------

String? _colourNote(PaintColour? paint, Room room) {
  if (paint == null) return null;

  // LRV < 25 is considered "dark"; rooms < ~12m² are "small".
  final area = room.areaMetres;
  final isSmall =
      (area != null && area < 12) ||
      (area == null && room.roomSize == RoomSize.small);

  if (paint.lrv < 25 && isSmall) {
    return 'This deep colour in matt will absorb a lot of light. Consider '
        'using it on a single feature wall rather than all four walls.';
  }

  if (paint.lrv > 80) {
    return 'Light colours almost always look best in matt or flat — a satin '
        'finish on light colours can look plasticky.';
  }

  return null;
}

// ---------------------------------------------------------------------------
// Paint quantity calculator
// ---------------------------------------------------------------------------

/// Standard wall height in UK homes (metres).
const _defaultWallHeight = 2.4;

/// Door area (standard UK internal door, m²).
const _doorArea = 1.6;

/// Window area (approximate average UK window, m²).
const _windowArea = 1.2;

/// Default number of doors per room.
const _defaultDoors = 1;

/// Default number of windows per room.
const _defaultWindows = 1;

/// Coverage rate: sqm per litre for one coat (industry average).
const _coveragePerLitre = 12.0;

/// Number of coats for a good finish.
const _coats = 2;

/// Standard UK tin sizes (litres).
const _tinSizes = [0.75, 1.0, 2.5, 5.0];

/// Fallback area estimates by room size (m²).
const _fallbackArea = {
  RoomSize.small: 9.0, // ~3m x 3m
  RoomSize.medium: 16.0, // ~4m x 4m
  RoomSize.large: 25.0, // ~5m x 5m
};

PaintQuantity _calculateWallQuantity(Room room, double? pricePerLitre) {
  final double length;
  final double width;

  if (room.widthMetres != null && room.lengthMetres != null) {
    length = room.lengthMetres!;
    width = room.widthMetres!;
  } else {
    final area = _fallbackArea[room.roomSize ?? RoomSize.medium]!;
    final side = math.sqrt(area);
    length = side;
    width = side;
  }

  final perimeter = 2 * (length + width);
  final grossArea = perimeter * _defaultWallHeight;
  const deductions =
      (_defaultDoors * _doorArea) + (_defaultWindows * _windowArea);
  final netArea = grossArea - deductions;

  final litresNeeded = (netArea / _coveragePerLitre) * _coats;

  return _selectTin(litresNeeded, pricePerLitre);
}

PaintQuantity _calculateCeilingQuantity(Room room, double? pricePerLitre) {
  final double area;
  if (room.widthMetres != null && room.lengthMetres != null) {
    area = room.widthMetres! * room.lengthMetres!;
  } else {
    area = _fallbackArea[room.roomSize ?? RoomSize.medium]!;
  }

  final litresNeeded = (area / _coveragePerLitre) * _coats;
  return _selectTin(litresNeeded, pricePerLitre);
}

PaintQuantity _calculateWoodworkQuantity(Room room, double? pricePerLitre) {
  // Woodwork = skirting boards + architraves.
  // Estimate: perimeter × 0.15m (skirting) + 2 door frames × 0.5m² each.
  final double length;
  final double width;
  if (room.widthMetres != null && room.lengthMetres != null) {
    length = room.lengthMetres!;
    width = room.widthMetres!;
  } else {
    final area = _fallbackArea[room.roomSize ?? RoomSize.medium]!;
    final side = math.sqrt(area);
    length = side;
    width = side;
  }

  final perimeter = 2 * (length + width);
  final skirtingArea = perimeter * 0.15;
  const architraveArea = _defaultDoors * 0.5;
  final totalArea = skirtingArea + architraveArea;

  final litresNeeded = (totalArea / _coveragePerLitre) * _coats;
  return _selectTin(litresNeeded, pricePerLitre);
}

PaintQuantity _selectTin(double litresNeeded, double? pricePerLitre) {
  // Find smallest tin size that covers the requirement.
  var bestTin = _tinSizes.last;
  var tinsNeeded = 1;

  for (final tin in _tinSizes) {
    final needed = (litresNeeded / tin).ceil();
    if (needed * tin >= litresNeeded) {
      bestTin = tin;
      tinsNeeded = needed;
      break;
    }
  }

  // If large area, prefer fewer big tins.
  if (litresNeeded > 5) {
    bestTin = 5.0;
    tinsNeeded = (litresNeeded / bestTin).ceil();
  } else if (litresNeeded > 2.5) {
    bestTin = 2.5;
    tinsNeeded = (litresNeeded / bestTin).ceil();
  }

  final double? cost;
  if (pricePerLitre != null) {
    cost = pricePerLitre * bestTin * tinsNeeded;
  } else {
    cost = null;
  }

  return PaintQuantity(
    litres: litresNeeded,
    tinSize: bestTin,
    tinsNeeded: tinsNeeded,
    estimatedCost: cost,
  );
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Generate a complete paint plan for a room.
///
/// Returns finish recommendations per surface, quantity estimates, and
/// contextual notes about light direction and colour interactions.
RoomPaintPlan generatePaintPlan({required Room room, PaintColour? heroPaint}) {
  final roomType = _classifyRoom(room.name);
  final finishes = _baseFinishesForRoom(roomType);
  final dirNote = _lightDirectionNote(room.direction, roomType);
  final colNote = _colourNote(heroPaint, room);

  final pricePerLitre = heroPaint?.approximatePricePerLitre;

  final quantities = <PaintSurface, PaintQuantity>{
    PaintSurface.walls: _calculateWallQuantity(room, pricePerLitre),
    PaintSurface.woodwork: _calculateWoodworkQuantity(room, pricePerLitre),
    PaintSurface.ceiling: _calculateCeilingQuantity(room, pricePerLitre),
  };

  return RoomPaintPlan(
    finishRecommendations: finishes,
    quantities: quantities,
    lightDirectionNote: dirNote,
    colourNote: colNote,
  );
}

/// Format a paint shopping list line item.
///
/// E.g. "Add 2.5L of Savage Ground in Matt Emulsion for your living room
/// walls (£42)"
String formatPaintListEntry({
  required String paintName,
  required PaintFinish finish,
  required PaintSurface surface,
  required PaintQuantity quantity,
  required String roomName,
}) {
  final costStr =
      quantity.estimatedCost != null
          ? ' (~£${quantity.estimatedCost!.toStringAsFixed(0)})'
          : '';
  return 'Add ${quantity.tinsNeeded}× ${quantity.tinLabel} of $paintName in '
      '${finish.emulsionLabel} for your ${roomName.toLowerCase()} '
      '${surface.displayName.toLowerCase()}$costStr';
}
