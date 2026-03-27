import 'package:palette/features/onboarding/models/system_palette.dart';

/// Key anchor colours from the user's DNA system palette, for use in
/// the 70/20/10 picker context.
class DnaAnchors {
  const DnaAnchors({
    this.dominantWall,
    this.deepAnchor,
    this.trimWhite,
    this.accentPop,
  });

  final PaintReference? dominantWall;
  final PaintReference? deepAnchor;
  final PaintReference? trimWhite;
  final PaintReference? accentPop;

  /// Extract key anchors from a system palette.
  factory DnaAnchors.fromSystemPalette(SystemPalette palette) => DnaAnchors(
        dominantWall:
            palette.dominantWalls.isNotEmpty ? palette.dominantWalls.first : null,
        deepAnchor: palette.deepAnchor,
        trimWhite: palette.trimWhite,
        accentPop:
            palette.accentPops.isNotEmpty ? palette.accentPops.first : null,
      );
}
