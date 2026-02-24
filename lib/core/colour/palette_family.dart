import 'package:palette/core/colour/lab_colour.dart';
import 'package:palette/core/constants/enums.dart';

/// Classify a colour into one of the seven palette families.
///
/// Uses heuristic rules based on L* (lightness), chroma (saturation),
/// and a*/b* (colour axis) values.
///
/// Checked in priority order: darks, pastels, brights, jewel tones,
/// earth tones, warm neutrals, cool neutrals (fallback).
PaletteFamily classifyPaletteFamily(LabColour lab) {
  final lightness = lab.l;
  final chroma = lab.chroma;

  // Darks: very low lightness
  if (lightness < 25) {
    return PaletteFamily.darks;
  }

  // Pastels: high lightness, low-to-moderate chroma
  if (lightness > 70 && chroma < 30) {
    return PaletteFamily.pastels;
  }

  // Brights: moderate lightness, high chroma
  if (lightness >= 40 && lightness <= 75 && chroma > 50) {
    return PaletteFamily.brights;
  }

  // Jewel tones: moderate-to-low lightness, moderate-to-high chroma
  if (lightness >= 20 && lightness <= 55 && chroma >= 30 && chroma <= 60) {
    return PaletteFamily.jewelTones;
  }

  // Earth tones: moderate lightness, moderate chroma, warm-leaning
  if (lightness >= 30 &&
      lightness <= 65 &&
      chroma >= 15 &&
      chroma <= 45 &&
      lab.b > 0 &&
      lab.a > -5) {
    return PaletteFamily.earthTones;
  }

  // Warm neutrals: moderate-to-high lightness, low chroma, warm
  if (lightness > 40 && chroma < 15 && lab.b > 0) {
    return PaletteFamily.warmNeutrals;
  }

  // Cool neutrals: everything else (fallback)
  return PaletteFamily.coolNeutrals;
}
