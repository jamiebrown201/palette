import 'dart:math';
import 'package:palette/core/colour/lab_colour.dart';

/// Colour space conversions using sRGB colour space with D65 illuminant.
///
/// Standards:
/// - sRGB: IEC 61966-2-1:1999
/// - D65 reference white: X=95.047, Y=100.000, Z=108.883
/// - CIE L*a*b*: CIELAB 1976

// D65 reference white point
const double _xn = 95.047;
const double _yn = 100.0;
const double _zn = 108.883;

/// Parse a hex colour string to RGB components.
/// Accepts formats: '#RRGGBB', 'RRGGBB', '#rrggbb'.
({int r, int g, int b}) hexToRgb(String hex) {
  final cleaned = hex.replaceAll('#', '').toUpperCase();
  assert(cleaned.length == 6, 'Hex string must be 6 characters: $hex');
  final value = int.parse(cleaned, radix: 16);
  return (
    r: (value >> 16) & 0xFF,
    g: (value >> 8) & 0xFF,
    b: value & 0xFF,
  );
}

/// Convert RGB components to a hex colour string with # prefix.
String rgbToHex(int r, int g, int b) {
  String toHex(int v) => v.clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '#${toHex(r)}${toHex(g)}${toHex(b)}'.toUpperCase();
}

/// Convert sRGB (0-255) to linear RGB (0.0-1.0).
/// Applies inverse sRGB companding (gamma correction).
({double r, double g, double b}) _srgbToLinear(int sr, int sg, int sb) {
  double linearise(int value) {
    final v = value / 255.0;
    return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  return (r: linearise(sr), g: linearise(sg), b: linearise(sb));
}

/// Convert linear RGB (0.0-1.0) to sRGB (0-255).
/// Applies sRGB forward companding.
({int r, int g, int b}) _linearToSrgb(double lr, double lg, double lb) {
  int compand(double v) {
    final clamped = v.clamp(0.0, 1.0);
    final srgb =
        clamped <= 0.0031308 ? 12.92 * clamped : 1.055 * pow(clamped, 1 / 2.4) - 0.055;
    return (srgb * 255).round().clamp(0, 255);
  }

  return (r: compand(lr), g: compand(lg), b: compand(lb));
}

/// Convert linear RGB to CIE XYZ using the sRGB/D65 matrix.
({double x, double y, double z}) _linearRgbToXyz(
  double r,
  double g,
  double b,
) {
  return (
    x: r * 0.4124564 + g * 0.3575761 + b * 0.1804375,
    y: r * 0.2126729 + g * 0.7151522 + b * 0.0721750,
    z: r * 0.0193339 + g * 0.1191920 + b * 0.9503041,
  );
}

/// Convert CIE XYZ to linear RGB using the inverse sRGB/D65 matrix.
({double r, double g, double b}) _xyzToLinearRgb(
  double x,
  double y,
  double z,
) {
  return (
    r: x * 3.2404542 + y * -1.5371385 + z * -0.4985314,
    g: x * -0.9692660 + y * 1.8760108 + z * 0.0415560,
    b: x * 0.0556434 + y * -0.2040259 + z * 1.0572252,
  );
}

/// CIE Lab forward transform helper function.
double _labF(double t) {
  const delta = 6.0 / 29.0;
  const delta3 = delta * delta * delta;
  return t > delta3 ? pow(t, 1.0 / 3.0).toDouble() : t / (3 * delta * delta) + 4.0 / 29.0;
}

/// CIE Lab inverse transform helper function.
double _labFInverse(double t) {
  const delta = 6.0 / 29.0;
  return t > delta ? t * t * t : 3 * delta * delta * (t - 4.0 / 29.0);
}

/// Convert CIE XYZ to CIE L*a*b* using D65 reference white.
LabColour _xyzToLab(double x, double y, double z) {
  final fx = _labF(x / _xn);
  final fy = _labF(y / _yn);
  final fz = _labF(z / _zn);
  return LabColour(
    116 * fy - 16,
    500 * (fx - fy),
    200 * (fy - fz),
  );
}

/// Convert CIE L*a*b* to CIE XYZ using D65 reference white.
({double x, double y, double z}) _labToXyz(LabColour lab) {
  final fy = (lab.l + 16) / 116;
  final fx = lab.a / 500 + fy;
  final fz = fy - lab.b / 200;
  return (
    x: _xn * _labFInverse(fx),
    y: _yn * _labFInverse(fy),
    z: _zn * _labFInverse(fz),
  );
}

/// Convert sRGB (0-255) to CIE L*a*b*.
/// Full pipeline: sRGB -> linear RGB -> XYZ (D65) -> Lab.
LabColour rgbToLab(int r, int g, int b) {
  final linear = _srgbToLinear(r, g, b);
  final xyz = _linearRgbToXyz(linear.r, linear.g, linear.b);
  // Scale XYZ to 0-100 range
  return _xyzToLab(xyz.x * 100, xyz.y * 100, xyz.z * 100);
}

/// Convert CIE L*a*b* to sRGB (0-255).
/// Full pipeline: Lab -> XYZ (D65) -> linear RGB -> sRGB.
/// Values are clamped to the 0-255 range.
({int r, int g, int b}) labToRgb(LabColour lab) {
  final xyz = _labToXyz(lab);
  // Scale XYZ from 0-100 back to 0-1 range
  final linear = _xyzToLinearRgb(xyz.x / 100, xyz.y / 100, xyz.z / 100);
  return _linearToSrgb(linear.r, linear.g, linear.b);
}

/// Convert a hex colour string to CIE L*a*b*.
LabColour hexToLab(String hex) {
  final rgb = hexToRgb(hex);
  return rgbToLab(rgb.r, rgb.g, rgb.b);
}

/// Convert CIE L*a*b* to a hex colour string.
String labToHex(LabColour lab) {
  final rgb = labToRgb(lab);
  return rgbToHex(rgb.r, rgb.g, rgb.b);
}
