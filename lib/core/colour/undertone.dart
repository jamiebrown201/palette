import 'dart:math';
import 'package:palette/core/colour/lab_colour.dart';
import 'package:palette/core/constants/enums.dart';

/// Result of undertone classification with confidence score.
class UndertoneResult {
  const UndertoneResult(this.classification, this.confidence);

  final Undertone classification;

  /// Confidence from 0.0 (barely classified) to 1.0 (strong signal).
  final double confidence;

  @override
  String toString() =>
      'UndertoneResult(${classification.displayName}, '
      'confidence: ${confidence.toStringAsFixed(2)})';
}

/// Classify the undertone of a colour from its Lab values.
///
/// Primary signal: b* channel (positive = warm/yellow, negative = cool/blue).
/// Secondary signal: a* channel (positive = red warmth, negative = green cool).
///
/// Weighted score: warmth = b* * 0.7 + a* * 0.3
/// Thresholds calibrated for paint colour classification.
UndertoneResult classifyUndertone(LabColour lab) {
  const threshold = 5.0;
  const maxDistance = 20.0;

  final warmth = lab.b * 0.7 + lab.a * 0.3;

  if (warmth > threshold) {
    final confidence = min(1.0, (warmth - threshold) / maxDistance);
    return UndertoneResult(Undertone.warm, confidence);
  } else if (warmth < -threshold) {
    final confidence = min(1.0, (-warmth - threshold) / maxDistance);
    return UndertoneResult(Undertone.cool, confidence);
  } else {
    // Neutral zone: confidence is higher when closer to zero
    final confidence = 1.0 - (warmth.abs() / threshold);
    return UndertoneResult(Undertone.neutral, confidence);
  }
}
