import 'dart:math';
import 'package:palette/core/colour/lab_colour.dart';

/// Convert CIE L*a*b* to CIE LCh (cylindrical representation).
///
/// L: Lightness (same as Lab)
/// C: Chroma (saturation)
/// h: Hue angle in degrees (0-360)
({double l, double c, double h}) labToLch(LabColour lab) {
  final c = lab.chroma;
  final h = lab.hueAngle;
  return (l: lab.l, c: c, h: h);
}

/// Convert CIE LCh back to CIE L*a*b*.
LabColour lchToLab(double l, double c, double h) {
  final hRad = h * pi / 180;
  return LabColour(l, c * cos(hRad), c * sin(hRad));
}

/// Normalise a hue angle to the 0-360 range.
double _normaliseHue(double hue) {
  var h = hue % 360;
  if (h < 0) h += 360;
  return h;
}

/// Rotate a Lab colour by the given number of degrees on the hue axis.
/// Preserves lightness and chroma.
LabColour _rotateHue(LabColour lab, double degrees) {
  final lch = labToLch(lab);
  if (lch.c < 1e-10) return lab; // achromatic, rotation is meaningless
  return lchToLab(lch.l, lch.c, _normaliseHue(lch.h + degrees));
}

/// Get the complementary colour (hue + 180 degrees).
/// Creates vibrant contrast.
LabColour complementary(LabColour lab) => _rotateHue(lab, 180);

/// Get analogous colours (hue +/- 30 degrees).
/// Creates a harmonious, cohesive feel.
({LabColour left, LabColour right}) analogous(LabColour lab) => (
      left: _rotateHue(lab, -30),
      right: _rotateHue(lab, 30),
    );

/// Get triadic colours (hue +/- 120 degrees).
/// Creates a balanced, vibrant palette.
({LabColour second, LabColour third}) triadic(LabColour lab) => (
      second: _rotateHue(lab, 120),
      third: _rotateHue(lab, 240),
    );

/// Get split-complementary colours (hue + 150 and + 210 degrees).
/// A softer alternative to complementary.
({LabColour left, LabColour right}) splitComplementary(LabColour lab) => (
      left: _rotateHue(lab, 150),
      right: _rotateHue(lab, 210),
    );
