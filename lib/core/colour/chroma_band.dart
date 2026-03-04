import 'package:palette/core/constants/enums.dart';

/// Classify a paint's chroma (Cab*) into a perceptual band.
///
/// Thresholds from SPEC_DNA.md Section 5.3:
/// - muted: Cab* < 25 (low saturation, greyed-out)
/// - mid: 25 ≤ Cab* ≤ 50 (moderate saturation)
/// - bold: Cab* > 50 (high saturation, vivid)
ChromaBand classifyChromaBand(double cabStar) {
  if (cabStar < 25) return ChromaBand.muted;
  if (cabStar <= 50) return ChromaBand.mid;
  return ChromaBand.bold;
}
