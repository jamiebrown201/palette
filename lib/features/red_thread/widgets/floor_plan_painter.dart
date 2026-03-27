import 'package:flutter/material.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/features/red_thread/logic/floor_plan_template.dart';

/// Paints a floor plan template with rooms filled by their hero colour.
class FloorPlanPainter extends CustomPainter {
  const FloorPlanPainter({
    required this.template,
    required this.roomColours,
    required this.threadHexes,
  });

  final FloorPlanTemplate template;

  /// Map of zone ID to hero colour hex.
  final Map<String, String?> roomColours;

  /// Thread colour hexes to highlight as indicators.
  final List<String> threadHexes;

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = PaletteColours.textSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const textStyle = TextStyle(
      color: PaletteColours.textPrimary,
      fontSize: 10,
    );

    for (final zone in template.zones) {
      final rect = Rect.fromLTWH(
        zone.x * size.width,
        zone.y * size.height,
        zone.width * size.width,
        zone.height * size.height,
      );

      // Fill with room hero colour
      final hex = roomColours[zone.id];
      final fillColour = hex != null
          ? _hexToColor(hex)
          : PaletteColours.warmGrey.withValues(alpha: 0.3);

      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()..color = fillColour,
        )
        // Border
        ..drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          borderPaint,
        );

      // Zone label
      final textPainter = TextPainter(
        text: TextSpan(text: zone.name, style: textStyle),
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
      threadHexes != oldDelegate.threadHexes;

  static Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}
