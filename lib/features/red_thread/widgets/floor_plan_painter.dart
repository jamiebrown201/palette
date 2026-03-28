import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/features/red_thread/logic/floor_plan_template.dart';

/// Paints a floor plan template with rooms filled by their hero colour,
/// edges connecting adjacent rooms, and warning indicators on disconnected rooms.
class FloorPlanPainter extends CustomPainter {
  const FloorPlanPainter({
    required this.template,
    required this.roomColours,
    required this.threadHexes,
    required this.disconnectedZoneIds,
  });

  final FloorPlanTemplate template;

  /// Map of zone ID to hero colour hex.
  final Map<String, String?> roomColours;

  /// Thread colour hexes to highlight as edge colours.
  final List<String> threadHexes;

  /// Zone IDs that are not connected to any thread colour.
  final Set<String> disconnectedZoneIds;

  @override
  void paint(Canvas canvas, Size size) {
    final zoneRects = <String, Rect>{};

    // Pre-compute zone rects
    for (final zone in template.zones) {
      zoneRects[zone.id] = Rect.fromLTWH(
        zone.x * size.width,
        zone.y * size.height,
        zone.width * size.width,
        zone.height * size.height,
      );
    }

    // Draw edges between adjacent zones
    _drawEdges(canvas, size, zoneRects);

    // Draw room nodes
    _drawNodes(canvas, size, zoneRects);
  }

  void _drawEdges(Canvas canvas, Size size, Map<String, Rect> zoneRects) {
    final threadColour =
        threadHexes.isNotEmpty
            ? hexToColor(threadHexes.first)
            : PaletteColours.sageGreen;

    final edgePaint =
        Paint()
          ..color = threadColour.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;

    for (final (zoneA, zoneB) in template.adjacencies) {
      final rectA = zoneRects[zoneA];
      final rectB = zoneRects[zoneB];
      if (rectA == null || rectB == null) continue;

      final centerA = rectA.center;
      final centerB = rectB.center;

      // Draw a curved edge between zone centres
      final midX = (centerA.dx + centerB.dx) / 2;
      final midY = (centerA.dy + centerB.dy) / 2;

      // Offset the control point perpendicular to the line for a subtle curve
      final dx = centerB.dx - centerA.dx;
      final dy = centerB.dy - centerA.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      final curveOffset = dist * 0.15;
      final controlPoint = Offset(
        midX + (dy / dist) * curveOffset,
        midY - (dx / dist) * curveOffset,
      );

      final path =
          Path()
            ..moveTo(centerA.dx, centerA.dy)
            ..quadraticBezierTo(
              controlPoint.dx,
              controlPoint.dy,
              centerB.dx,
              centerB.dy,
            );

      canvas.drawPath(path, edgePaint);

      // Draw small circle at each end
      final dotPaint =
          Paint()
            ..color = threadColour.withValues(alpha: 0.8)
            ..style = PaintingStyle.fill;
      canvas.drawCircle(centerA, 3, dotPaint);
      canvas.drawCircle(centerB, 3, dotPaint);
    }
  }

  void _drawNodes(Canvas canvas, Size size, Map<String, Rect> zoneRects) {
    final borderPaint =
        Paint()
          ..color = PaletteColours.textSecondary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    final warningBorderPaint =
        Paint()
          ..color = PaletteColours.softGold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;

    const textStyle = TextStyle(
      color: PaletteColours.textPrimary,
      fontSize: 10,
    );

    const warningTextStyle = TextStyle(
      color: PaletteColours.softGoldDark,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    for (final zone in template.zones) {
      final rect = zoneRects[zone.id]!;
      final isDisconnected = disconnectedZoneIds.contains(zone.id);

      // Fill with room hero colour
      final hex = roomColours[zone.id];
      final fillColour =
          hex != null
              ? hexToColor(hex)
              : PaletteColours.warmGrey.withValues(alpha: 0.3);

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

      canvas
        ..drawRRect(rrect, Paint()..color = fillColour)
        ..drawRRect(rrect, isDisconnected ? warningBorderPaint : borderPaint);

      // Warning indicator: small triangle icon in top-right for disconnected rooms
      if (isDisconnected) {
        final warningSize = rect.width.clamp(0, 14).toDouble();
        final iconOffset = Offset(rect.right - warningSize - 4, rect.top + 4);
        final warningPaint =
            Paint()
              ..color = PaletteColours.softGoldDark
              ..style = PaintingStyle.fill;

        // Draw a small warning dot
        canvas.drawCircle(
          Offset(
            iconOffset.dx + warningSize / 2,
            iconOffset.dy + warningSize / 2,
          ),
          warningSize / 2,
          warningPaint,
        );

        // Draw exclamation mark
        final exclamationPainter = TextPainter(
          text: const TextSpan(
            text: '!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        exclamationPainter.paint(
          canvas,
          Offset(
            iconOffset.dx + (warningSize - exclamationPainter.width) / 2,
            iconOffset.dy + (warningSize - exclamationPainter.height) / 2,
          ),
        );
      }

      // Zone label
      final labelStyle = isDisconnected ? warningTextStyle : textStyle;
      final textPainter = TextPainter(
        text: TextSpan(text: zone.name, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rect.width - 8);

      textPainter.paint(
        canvas,
        Offset(
          rect.left + (rect.width - textPainter.width) / 2,
          rect.top + (rect.height - textPainter.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(FloorPlanPainter oldDelegate) =>
      template != oldDelegate.template ||
      roomColours != oldDelegate.roomColours ||
      threadHexes != oldDelegate.threadHexes ||
      disconnectedZoneIds != oldDelegate.disconnectedZoneIds;
}
