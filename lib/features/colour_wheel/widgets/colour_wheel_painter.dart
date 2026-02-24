import 'dart:math';
import 'package:flutter/material.dart';

/// Custom painter that renders an HSL colour wheel.
///
/// The wheel is drawn as a series of arcs in a ring shape.
/// Hue varies around the circumference, saturation is constant (high),
/// and lightness is mapped from outer (light) to inner (dark).
class ColourWheelPainter extends CustomPainter {
  const ColourWheelPainter({this.selectedHue, this.selectedRadial});

  /// If non-null, draws a marker at this hue angle (0-360).
  final double? selectedHue;

  /// Position within the ring as a fraction (0 = outer edge, 1 = inner edge).
  final double? selectedRadial;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final outerRadius = min(size.width, size.height) / 2;
    final innerRadius = outerRadius * 0.35;
    final ringWidth = outerRadius - innerRadius;

    const hueSteps = 360;
    const lightnessSteps = 8;

    for (var h = 0; h < hueSteps; h++) {
      final hue = h.toDouble();
      final startAngle = (hue - 90) * pi / 180; // Start from top
      const sweepAngle = 1.5 * pi / 180; // Slightly wider to avoid gaps

      for (var lIdx = 0; lIdx < lightnessSteps; lIdx++) {
        // Lightness from 0.75 (outer, lighter) to 0.3 (inner, darker)
        final lightness = 0.75 - (lIdx / lightnessSteps) * 0.45;
        final color = HSLColor.fromAHSL(1.0, hue, 0.7, lightness).toColor();

        final segmentOuter = innerRadius + ringWidth * (1 - lIdx / lightnessSteps);
        final segmentInner =
            innerRadius + ringWidth * (1 - (lIdx + 1) / lightnessSteps);

        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = segmentOuter - segmentInner;

        final radius = (segmentOuter + segmentInner) / 2;

        canvas.drawArc(
          Rect.fromCircle(center: centre, radius: radius),
          startAngle,
          sweepAngle,
          false,
          paint,
        );
      }
    }

    // Draw selection indicator
    if (selectedHue != null) {
      final angle = (selectedHue! - 90) * pi / 180;
      final radial = (selectedRadial ?? 0.5).clamp(0.0, 1.0);
      // Map radial 0 (outer) to 1 (inner) onto the ring
      final markerRadius = outerRadius - radial * ringWidth;
      final markerPos = Offset(
        centre.dx + markerRadius * cos(angle),
        centre.dy + markerRadius * sin(angle),
      );

      canvas
        ..drawCircle(
          markerPos,
          8,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill,
        )
        ..drawCircle(
          markerPos,
          8,
          Paint()
            ..color = Colors.black54
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
    }
  }

  @override
  bool shouldRepaint(ColourWheelPainter oldDelegate) =>
      selectedHue != oldDelegate.selectedHue ||
      selectedRadial != oldDelegate.selectedRadial;
}
