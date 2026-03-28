import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/core/colour/lab_colour.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/data/models/room.dart';

class PaintMatchResult {
  const PaintMatchResult({
    required this.paint,
    this.bestDeltaE,
    this.matchReason,
    this.roomBadges = const [],
  });

  final PaintColour paint;
  final double? bestDeltaE;
  final String? matchReason;
  final List<String> roomBadges;

  bool get isPaletteMatch => matchReason != null;
}

/// Compute palette match data and room badges for a list of paints.
List<PaintMatchResult> computePaintMatches({
  required List<PaintColour> paints,
  required List<String> paletteHexes,
  required Undertone? dnaUndertone,
  required String? archetypeName,
  required List<Room> rooms,
}) {
  // Pre-compute Lab values for palette hexes once.
  final paletteLabs = paletteHexes.map(hexToLab).toList();

  return paints.map((paint) {
    final paintLab = LabColour(paint.labL, paint.labA, paint.labB);

    // Find best delta-E to any palette colour.
    double? bestDe;
    if (paletteLabs.isNotEmpty) {
      for (final lab in paletteLabs) {
        final de = deltaE2000(paintLab, lab);
        if (bestDe == null || de < bestDe) bestDe = de;
      }
    }

    // Determine match reason.
    String? reason;
    if (bestDe != null && bestDe < 10) {
      reason = 'Close match to your palette';
    } else if (bestDe != null && bestDe < 25) {
      final label = archetypeName ?? 'your';
      reason = 'Harmonises with $label palette';
    } else if (dnaUndertone != null && paint.undertone == dnaUndertone) {
      reason =
          'Shares your ${dnaUndertone.displayName.toLowerCase()} undertone';
    }

    // Room direction badges.
    final badges = <String>[];
    for (final room in rooms) {
      if (room.direction == null) continue;
      if (_undertoneSuitsDirection(paint.undertone, room.direction!)) {
        badges.add(
          'Good for your ${room.direction!.displayName.toLowerCase()}-facing ${room.name}',
        );
      }
      if (badges.length >= 2) break;
    }

    return PaintMatchResult(
      paint: paint,
      bestDeltaE: bestDe,
      matchReason: reason,
      roomBadges: badges,
    );
  }).toList();
}

bool _undertoneSuitsDirection(Undertone undertone, CompassDirection direction) {
  return switch (direction) {
    CompassDirection.north ||
    CompassDirection.east => undertone == Undertone.cool,
    CompassDirection.south ||
    CompassDirection.west => undertone == Undertone.warm,
  };
}
