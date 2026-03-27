import 'dart:math';

import 'package:flutter/foundation.dart';

/// Represents a colour in the CIE L*a*b* colour space.
///
/// L*: Lightness (0 = black, 100 = white)
/// a*: Green (-) to Red (+) axis
/// b*: Blue (-) to Yellow (+) axis
@immutable
class LabColour {
  const LabColour(this.l, this.a, this.b);

  final double l;
  final double a;
  final double b;

  /// Chroma: distance from the neutral axis.
  double get chroma => sqrt(a * a + b * b);

  /// Hue angle in degrees (0-360).
  /// Returns 0 for achromatic colours (chroma near zero).
  double get hueAngle {
    if (chroma < 1e-10) return 0;
    final angle = atan2(b, a) * 180 / pi;
    return angle < 0 ? angle + 360 : angle;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LabColour &&
          (l - other.l).abs() < 1e-10 &&
          (a - other.a).abs() < 1e-10 &&
          (b - other.b).abs() < 1e-10;

  @override
  int get hashCode => Object.hash(
        l.roundToDouble(),
        a.roundToDouble(),
        b.roundToDouble(),
      );

  @override
  String toString() =>
      'Lab(${l.toStringAsFixed(2)}, ${a.toStringAsFixed(2)}, '
      '${b.toStringAsFixed(2)})';
}
