import 'package:palette/core/constants/enums.dart';

/// Light direction recommendations based on Sowerby's colour matrix.
///
/// - North-facing: cooler light, recommend warm tones to compensate
/// - South-facing: warm light, can handle cooler tones
/// - East-facing: warm morning, cool afternoon
/// - West-facing: cool morning, warm evening
class LightRecommendation {
  const LightRecommendation({
    required this.direction,
    required this.usageTime,
    required this.summary,
    required this.recommendation,
    required this.preferredUndertone,
    required this.avoidUndertone,
  });

  final CompassDirection direction;
  final UsageTime usageTime;
  final String summary;
  final String recommendation;
  final Undertone preferredUndertone;
  final Undertone? avoidUndertone;
}

/// Get light recommendation for a room based on direction and usage time.
LightRecommendation getLightRecommendation({
  required CompassDirection direction,
  required UsageTime usageTime,
}) {
  return switch ((direction, usageTime)) {
    // North-facing
    (CompassDirection.north, UsageTime.morning) => const LightRecommendation(
        direction: CompassDirection.north,
        usageTime: UsageTime.morning,
        summary: 'Cool, diffused light',
        recommendation:
            'North-facing rooms receive cool, even light throughout the day. '
            'Warm undertones in paint colours will counterbalance the '
            'blue-ish quality of the light, creating a cosy atmosphere.',
        preferredUndertone: Undertone.warm,
        avoidUndertone: Undertone.cool,
      ),
    (CompassDirection.north, _) => const LightRecommendation(
        direction: CompassDirection.north,
        usageTime: UsageTime.allDay,
        summary: 'Cool, consistent light',
        recommendation:
            'This north-facing room gets steady, cool light. Embrace it with '
            'warm whites (yellow or pink undertone) and earthy neutrals. '
            'Avoid blue-based whites, which will feel cold.',
        preferredUndertone: Undertone.warm,
        avoidUndertone: Undertone.cool,
      ),
    // South-facing
    (CompassDirection.south, UsageTime.morning) => const LightRecommendation(
        direction: CompassDirection.south,
        usageTime: UsageTime.morning,
        summary: 'Warm, bright morning light',
        recommendation:
            'South-facing rooms are flooded with warm sunlight. '
            'You have the most flexibility here — both warm and cool '
            'tones work beautifully. Cool whites and blues will feel fresh.',
        preferredUndertone: Undertone.cool,
        avoidUndertone: null,
      ),
    (CompassDirection.south, _) => const LightRecommendation(
        direction: CompassDirection.south,
        usageTime: UsageTime.allDay,
        summary: 'Warm, generous light',
        recommendation:
            'Lucky you — south-facing rooms are the most forgiving. '
            'Cool colours will be warmed by the sun, and warm colours '
            'will glow. This room can handle bold, saturated shades.',
        preferredUndertone: Undertone.neutral,
        avoidUndertone: null,
      ),
    // East-facing
    (CompassDirection.east, UsageTime.morning) => const LightRecommendation(
        direction: CompassDirection.east,
        usageTime: UsageTime.morning,
        summary: 'Warm, golden morning light',
        recommendation:
            'East-facing rooms are at their best in the morning with '
            'warm, golden light. Warm neutrals and yellows will amplify '
            'this beautiful quality.',
        preferredUndertone: Undertone.warm,
        avoidUndertone: null,
      ),
    (CompassDirection.east, UsageTime.evening) => const LightRecommendation(
        direction: CompassDirection.east,
        usageTime: UsageTime.evening,
        summary: 'Cooler evening shadows',
        recommendation:
            'By evening, east-facing rooms lose their warm light and '
            'shift cooler. If this room is mainly used in the evenings, '
            'choose warm, enveloping tones to compensate.',
        preferredUndertone: Undertone.warm,
        avoidUndertone: Undertone.cool,
      ),
    (CompassDirection.east, _) => const LightRecommendation(
        direction: CompassDirection.east,
        usageTime: UsageTime.allDay,
        summary: 'Warm mornings, cool evenings',
        recommendation:
            'East-facing rooms transition from warm morning light to '
            'cooler afternoons. A warm neutral palette works well across '
            'the whole day.',
        preferredUndertone: Undertone.warm,
        avoidUndertone: null,
      ),
    // West-facing
    (CompassDirection.west, UsageTime.morning) => const LightRecommendation(
        direction: CompassDirection.west,
        usageTime: UsageTime.morning,
        summary: 'Cool, subdued morning light',
        recommendation:
            'West-facing rooms have cool mornings. If you mainly use '
            'this room in the morning, warm undertones will brighten things up.',
        preferredUndertone: Undertone.warm,
        avoidUndertone: Undertone.cool,
      ),
    (CompassDirection.west, UsageTime.evening) => const LightRecommendation(
        direction: CompassDirection.west,
        usageTime: UsageTime.evening,
        summary: 'Warm, dramatic evening light',
        recommendation:
            'West-facing rooms come alive in the evening with warm, '
            'golden sunset light. Cooler tones will be beautifully '
            'balanced, and warm tones will glow dramatically.',
        preferredUndertone: Undertone.neutral,
        avoidUndertone: null,
      ),
    (CompassDirection.west, _) => const LightRecommendation(
        direction: CompassDirection.west,
        usageTime: UsageTime.allDay,
        summary: 'Cool mornings, warm evenings',
        recommendation:
            'West-facing rooms mirror east-facing ones in reverse. '
            'Neutral tones with a slight warm lean work well throughout '
            'the day.',
        preferredUndertone: Undertone.warm,
        avoidUndertone: null,
      ),
  };
}

/// Get a short educational message about a compass direction (free tier).
String getLightDirectionSummary(CompassDirection direction) {
  return switch (direction) {
    CompassDirection.north =>
      'North-facing rooms receive cool, diffused light throughout the day.',
    CompassDirection.south =>
      'South-facing rooms are flooded with warm, generous sunlight.',
    CompassDirection.east =>
      'East-facing rooms enjoy warm morning light that cools in the afternoon.',
    CompassDirection.west =>
      'West-facing rooms get cool mornings and warm, golden evening light.',
  };
}
