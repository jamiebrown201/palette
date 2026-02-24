/// App-wide constants for the Palette application.
abstract final class AppConstants {
  static const String appName = 'Palette';

  static const int minPaletteColours = 8;
  static const int maxPaletteColours = 12;

  static const int minRedThreadColours = 2;
  static const int maxRedThreadColours = 4;

  static const int maxFreeMoodboards = 1;

  static const double deltaECloseMatchThreshold = 25.0;
  static const double deltaEModerateMatchThreshold = 40.0;
  static const double deltaECrossBrandThreshold = 5.0;

  static const double compassBucketSizeDegrees = 90.0;

  static const int maxPaintMatchResults = 5;
  static const int minQuizPromptsForResult = 1;

  static const double kelvinOverlayOpacity = 0.15;
}
