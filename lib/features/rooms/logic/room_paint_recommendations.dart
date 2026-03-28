import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/core/colour/lab_colour.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/rooms/logic/light_recommendations.dart';

/// A scored paint recommendation for a specific room.
class RoomPaintRecommendation {
  const RoomPaintRecommendation({
    required this.paint,
    required this.score,
    required this.deltaE,
    required this.reason,
  });

  final PaintColour paint;
  final double score;
  final double deltaE;
  final String reason;
}

/// Budget bracket price ranges (£/litre).
const _budgetMaxPrice = {
  BudgetBracket.affordable: 25.0,
  BudgetBracket.midRange: 50.0,
  BudgetBracket.investment: double.infinity,
};

/// Compute the best paint recommendations for a room.
///
/// Filters and scores paints from the library based on:
/// 1. Colour match to hero colour (delta-E)
/// 2. Undertone compatibility with room direction + usage time
/// 3. Budget bracket fit
///
/// Returns up to [limit] recommendations sorted by combined score.
List<RoomPaintRecommendation> computeRoomPaintRecommendations({
  required List<PaintColour> allPaints,
  required Room room,
  int limit = 4,
}) {
  final heroHex = room.heroColourHex;
  if (heroHex == null) return [];

  final heroLab = hexToLab(heroHex);

  // Get preferred undertone from light direction.
  final Undertone? preferredUndertone;
  if (room.direction != null) {
    final lightRec = getLightRecommendation(
      direction: room.direction!,
      usageTime: room.usageTime,
    );
    preferredUndertone = lightRec.preferredUndertone;
  } else {
    preferredUndertone = null;
  }

  final maxPrice = _budgetMaxPrice[room.budget]!;

  final scored = <RoomPaintRecommendation>[];

  for (final paint in allPaints) {
    // Budget filter: skip paints over budget (if price data exists).
    if (paint.approximatePricePerLitre != null &&
        paint.approximatePricePerLitre! > maxPrice) {
      continue;
    }

    final paintLab = LabColour(paint.labL, paint.labA, paint.labB);
    final dE = deltaE2000(heroLab, paintLab);

    // Skip paints that are too different (delta-E > 30).
    if (dE > 30) continue;

    // Score: lower delta-E = better colour match (0-50 points).
    final colourScore = (30 - dE).clamp(0, 30).toDouble();

    // Score: undertone compatibility (0-15 points).
    double undertoneScore = 0;
    if (preferredUndertone != null) {
      if (paint.undertone == preferredUndertone) {
        undertoneScore = 15;
      } else if (paint.undertone == Undertone.neutral) {
        undertoneScore = 8;
      }
    } else {
      // No direction set — neutral bonus.
      undertoneScore = 5;
    }

    // Score: budget fit bonus (0-5 points) — cheaper within bracket scores
    // slightly higher to surface accessible options.
    double budgetScore = 0;
    if (paint.approximatePricePerLitre != null) {
      budgetScore = 5;
    }

    final totalScore = colourScore + undertoneScore + budgetScore;

    // Build reason string.
    final reason = _buildReason(
      paint: paint,
      deltaE: dE,
      room: room,
      preferredUndertone: preferredUndertone,
    );

    scored.add(
      RoomPaintRecommendation(
        paint: paint,
        score: totalScore,
        deltaE: dE,
        reason: reason,
      ),
    );
  }

  // Sort by score descending.
  scored.sort((a, b) => b.score.compareTo(a.score));

  // Deduplicate by brand: keep at most 2 per brand for variety.
  final result = <RoomPaintRecommendation>[];
  final brandCount = <String, int>{};
  for (final rec in scored) {
    final count = brandCount[rec.paint.brand] ?? 0;
    if (count >= 2) continue;
    brandCount[rec.paint.brand] = count + 1;
    result.add(rec);
    if (result.length >= limit) break;
  }

  return result;
}

String _buildReason({
  required PaintColour paint,
  required double deltaE,
  required Room room,
  required Undertone? preferredUndertone,
}) {
  final parts = <String>[];

  if (deltaE < 5) {
    parts.add('Very close match to your hero colour');
  } else if (deltaE < 15) {
    parts.add('Harmonises with your hero colour');
  } else {
    parts.add('Complementary tone for this room');
  }

  if (room.direction != null &&
      preferredUndertone != null &&
      paint.undertone == preferredUndertone) {
    final dir = room.direction!.displayName.toLowerCase();
    parts.add(
      '${paint.undertone.displayName.toLowerCase()} undertone suits '
      'your $dir-facing light',
    );
  }

  return parts.join('. ');
}
