import 'dart:math';
import 'package:flutter/material.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/theme/palette_colours.dart';

/// Custom painter that renders an HSL colour wheel.
///
/// The wheel is drawn as a series of arcs in a ring shape.
/// Hue varies around the circumference, saturation is constant (high),
/// and lightness is mapped from outer (light) to inner (dark).
class ColourWheelPainter extends CustomPainter {
  const ColourWheelPainter({
    this.selectedHue,
    this.selectedRadial,
    this.dnaHexes,
    this.showDnaPalette = false,
  });

  /// If non-null, draws a marker at this hue angle (0-360).
  final double? selectedHue;

  /// Position within the ring as a fraction (0 = outer edge, 1 = inner edge).
  final double? selectedRadial;

  /// DNA palette hex colours to show as markers on the wheel.
  final List<String>? dnaHexes;

  /// Whether to show DNA markers prominently (filled) vs subtly (outline only).
  final bool showDnaPalette;

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

        final segmentOuter =
            innerRadius + ringWidth * (1 - lIdx / lightnessSteps);
        final segmentInner =
            innerRadius + ringWidth * (1 - (lIdx + 1) / lightnessSteps);

        final paint =
            Paint()
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

    // Draw DNA palette markers
    if (dnaHexes != null && dnaHexes!.isNotEmpty) {
      for (final hex in dnaHexes!) {
        final pos = _hexToWheelPosition(hex, centre, outerRadius, innerRadius);
        if (pos == null) continue;

        if (showDnaPalette) {
          // Prominent filled diamond
          _drawDiamond(
            canvas,
            pos,
            7,
            Paint()
              ..color = _parseHex(hex)
              ..style = PaintingStyle.fill,
          );
          _drawDiamond(
            canvas,
            pos,
            7,
            Paint()
              ..color = PaletteColours.textOnAccent
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        } else {
          // Subtle outline diamond
          _drawDiamond(
            canvas,
            pos,
            5,
            Paint()
              ..color = PaletteColours.textOnAccent.withValues(alpha: 0.8)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
      }
    }

    // Draw selection indicator (on top of DNA markers)
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
            ..color = PaletteColours.textOnAccent
            ..style = PaintingStyle.fill,
        )
        ..drawCircle(
          markerPos,
          8,
          Paint()
            ..color = PaletteColours.overlay
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
    }
  }

  void _drawDiamond(Canvas canvas, Offset center, double size, Paint paint) {
    final path =
        Path()
          ..moveTo(center.dx, center.dy - size) // top
          ..lineTo(center.dx + size, center.dy) // right
          ..lineTo(center.dx, center.dy + size) // bottom
          ..lineTo(center.dx - size, center.dy) // left
          ..close();
    canvas.drawPath(path, paint);
  }

  /// Convert a hex colour to its position on the wheel.
  Offset? _hexToWheelPosition(
    String hex,
    Offset centre,
    double outerRadius,
    double innerRadius,
  ) {
    final color = _parseHex(hex);
    final hsl = HSLColor.fromColor(color);
    final ringWidth = outerRadius - innerRadius;

    // Map lightness back to radial: 0.75 = outer (radial 0), 0.3 = inner (radial 1)
    final radial = ((0.75 - hsl.lightness) / 0.45).clamp(0.0, 1.0);
    final markerRadius = outerRadius - radial * ringWidth;

    // Skip colours outside the wheel's lightness range
    if (hsl.lightness < 0.25 || hsl.lightness > 0.80) return null;
    // Skip very desaturated colours (they don't map well to the wheel)
    if (hsl.saturation < 0.05) return null;

    final angle = (hsl.hue - 90) * pi / 180;
    return Offset(
      centre.dx + markerRadius * cos(angle),
      centre.dy + markerRadius * sin(angle),
    );
  }

  static Color _parseHex(String hex) {
    return hexToColor(hex);
  }

  @override
  bool shouldRepaint(ColourWheelPainter oldDelegate) =>
      selectedHue != oldDelegate.selectedHue ||
      selectedRadial != oldDelegate.selectedRadial ||
      dnaHexes != oldDelegate.dnaHexes ||
      showDnaPalette != oldDelegate.showDnaPalette;
}
