import 'dart:math';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/constants/enums.dart';

/// Convert colour temperature in Kelvin to an RGB tint colour.
///
/// Uses the Tanner Helland algorithm (polynomial approximation).
/// Valid range: 1000K - 40000K.
({int r, int g, int b}) kelvinToRgb(int kelvin) {
  final temp = kelvin.clamp(1000, 40000) / 100.0;

  int red;
  int green;
  int blue;

  // Red
  if (temp <= 66) {
    red = 255;
  } else {
    red = (329.698727446 * pow(temp - 60, -0.1332047592)).round().clamp(0, 255);
  }

  // Green
  if (temp <= 66) {
    green =
        (99.4708025861 * log(temp) - 161.1195681661).round().clamp(0, 255);
  } else {
    green =
        (288.1221695283 * pow(temp - 60, -0.0755148492)).round().clamp(0, 255);
  }

  // Blue
  if (temp >= 66) {
    blue = 255;
  } else if (temp <= 19) {
    blue = 0;
  } else {
    blue = (138.5177312231 * log(temp - 10) - 305.0447927307)
        .round()
        .clamp(0, 255);
  }

  return (r: red, g: green, b: blue);
}

/// Simulate how a colour appears under a given light temperature.
///
/// Blends the Kelvin tint with the base colour at the given opacity.
/// Returns the result as a hex string.
String simulateLightOnColour(
  String hex,
  int kelvin, {
  double opacity = 0.15,
}) {
  final base = hexToRgb(hex);
  final tint = kelvinToRgb(kelvin);

  int blend(int baseVal, int tintVal) {
    return (baseVal * (1 - opacity) + tintVal * opacity).round().clamp(0, 255);
  }

  return rgbToHex(
    blend(base.r, tint.r),
    blend(base.g, tint.g),
    blend(base.b, tint.b),
  );
}

/// Kelvin lookup table for compass direction and time of day.
///
/// Values based on typical UK natural light conditions:
/// - North: cool, blue-toned (7500-9000K)
/// - South: warm, golden (4000-5000K)
/// - East: warm morning, cool afternoon (3500-7500K)
/// - West: cool morning, warm afternoon (7500-3500K)
const Map<CompassDirection, Map<UsageTime, int>> _kelvinTable = {
  CompassDirection.north: {
    UsageTime.morning: 8000,
    UsageTime.afternoon: 7500,
    UsageTime.evening: 9000,
    UsageTime.allDay: 7500,
  },
  CompassDirection.south: {
    UsageTime.morning: 4500,
    UsageTime.afternoon: 5000,
    UsageTime.evening: 4000,
    UsageTime.allDay: 5000,
  },
  CompassDirection.east: {
    UsageTime.morning: 3500,
    UsageTime.afternoon: 5000,
    UsageTime.evening: 7500,
    UsageTime.allDay: 5000,
  },
  CompassDirection.west: {
    UsageTime.morning: 7500,
    UsageTime.afternoon: 5000,
    UsageTime.evening: 3500,
    UsageTime.allDay: 5000,
  },
};

/// Get the approximate colour temperature for a room based on its
/// compass direction and primary usage time.
int getKelvinForRoom(CompassDirection direction, UsageTime timeSlot) {
  return _kelvinTable[direction]![timeSlot]!;
}
