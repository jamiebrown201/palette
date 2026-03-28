import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/product.dart';
import 'package:palette/data/models/room.dart';

/// The four UK seasons used for refresh suggestions.
enum Season { spring, summer, autumn, winter }

extension SeasonX on Season {
  String get displayName => switch (this) {
    Season.spring => 'Spring',
    Season.summer => 'Summer',
    Season.autumn => 'Autumn',
    Season.winter => 'Winter',
  };

  String get emoji => switch (this) {
    Season.spring => '🌷',
    Season.summer => '☀️',
    Season.autumn => '🍂',
    Season.winter => '❄️',
  };

  /// Product categories that work best this season.
  List<ProductCategory> get focusCategories => switch (this) {
    Season.spring => [
      ProductCategory.cushion,
      ProductCategory.artwork,
      ProductCategory.tableLamp,
    ],
    Season.summer => [
      ProductCategory.curtain,
      ProductCategory.cushion,
      ProductCategory.mirror,
    ],
    Season.autumn => [
      ProductCategory.throwBlanket,
      ProductCategory.cushion,
      ProductCategory.rug,
      ProductCategory.tableLamp,
    ],
    Season.winter => [
      ProductCategory.throwBlanket,
      ProductCategory.rug,
      ProductCategory.cushion,
      ProductCategory.floorLamp,
    ],
  };

  /// Texture feels that suit this season.
  List<TextureFeel> get preferredTextures => switch (this) {
    Season.spring => [TextureFeel.smooth, TextureFeel.lowTexture],
    Season.summer => [TextureFeel.smooth, TextureFeel.lowTexture],
    Season.autumn => [TextureFeel.highTexture, TextureFeel.chunky],
    Season.winter => [TextureFeel.chunky, TextureFeel.highTexture],
  };
}

/// Determine the current UK season from a date.
Season seasonFromDate(DateTime date) {
  final month = date.month;
  if (month >= 3 && month <= 5) return Season.spring;
  if (month >= 6 && month <= 8) return Season.summer;
  if (month >= 9 && month <= 11) return Season.autumn;
  return Season.winter;
}

/// A single seasonal refresh suggestion for a room.
class SeasonalSuggestion {
  const SeasonalSuggestion({
    required this.room,
    required this.season,
    required this.headline,
    required this.description,
    required this.productType,
    required this.colourHint,
    this.matchedProduct,
  });

  final Room room;
  final Season season;
  final String headline;
  final String description;
  final ProductCategory productType;

  /// A hex colour that the suggestion references (e.g. the accent or thread).
  final String colourHint;

  /// An optional matched product from the catalogue.
  final Product? matchedProduct;
}

/// Generate seasonal refresh suggestions for the user's rooms.
///
/// Each room with a 70/20/10 plan gets up to one suggestion per season.
/// Suggestions are algorithmically generated from the room's palette,
/// direction, and the season's characteristics.
List<SeasonalSuggestion> generateSeasonalSuggestions({
  required List<Room> rooms,
  required List<Product> catalogue,
  required Season season,
  List<String> threadColourHexes = const [],
}) {
  final suggestions = <SeasonalSuggestion>[];

  for (final room in rooms) {
    if (room.heroColourHex == null) continue;

    final suggestion = _buildSuggestion(
      room: room,
      season: season,
      catalogue: catalogue,
      threadColourHexes: threadColourHexes,
    );
    if (suggestion != null) {
      suggestions.add(suggestion);
    }
  }

  return suggestions;
}

SeasonalSuggestion? _buildSuggestion({
  required Room room,
  required Season season,
  required List<Product> catalogue,
  required List<String> threadColourHexes,
}) {
  final template = _pickTemplate(room: room, season: season);
  if (template == null) return null;

  // Find a matching product from the catalogue for this suggestion
  final candidates =
      catalogue.where((p) {
        if (!p.available) return false;
        if (!season.focusCategories.contains(p.category)) return false;
        if (room.isRenterMode && !p.renterSafe) return false;
        return true;
      }).toList();

  // Prefer products with matching texture for the season
  candidates.sort((a, b) {
    final aTexture = season.preferredTextures.contains(a.textureFeel) ? 0 : 1;
    final bTexture = season.preferredTextures.contains(b.textureFeel) ? 0 : 1;
    return aTexture.compareTo(bTexture);
  });

  final matched = candidates.isNotEmpty ? candidates.first : null;

  return SeasonalSuggestion(
    room: room,
    season: season,
    headline: template.headline,
    description: template.description,
    productType: template.productType,
    colourHint: template.colourHint,
    matchedProduct: matched,
  );
}

/// Pick the best template for this room + season combination.
_SuggestionTemplate? _pickTemplate({
  required Room room,
  required Season season,
}) {
  final directionLabel = room.direction?.displayName.toLowerCase() ?? '';
  final roomName = room.name;
  final heroHex = room.heroColourHex ?? '';
  final accentHex = room.surpriseColourHex ?? room.betaColourHex ?? heroHex;

  return switch (season) {
    Season.spring => _springTemplate(
      roomName: roomName,
      directionLabel: directionLabel,
      accentHex: accentHex,
      room: room,
    ),
    Season.summer => _summerTemplate(
      roomName: roomName,
      directionLabel: directionLabel,
      accentHex: accentHex,
      room: room,
    ),
    Season.autumn => _autumnTemplate(
      roomName: roomName,
      directionLabel: directionLabel,
      heroHex: heroHex,
      room: room,
    ),
    Season.winter => _winterTemplate(
      roomName: roomName,
      directionLabel: directionLabel,
      heroHex: heroHex,
      room: room,
    ),
  };
}

_SuggestionTemplate _springTemplate({
  required String roomName,
  required String directionLabel,
  required String accentHex,
  required Room room,
}) {
  final lightNote =
      room.direction == CompassDirection.east
          ? 'Your morning light will make these colours sing'
          : 'Fresh colours lift the room as the days get longer';

  return _SuggestionTemplate(
    headline: 'Spring refresh: swap your accent cushions',
    description:
        'Lighter, brighter accents breathe new life into your $roomName. '
        '$lightNote.',
    productType: ProductCategory.cushion,
    colourHint: accentHex,
  );
}

_SuggestionTemplate _summerTemplate({
  required String roomName,
  required String directionLabel,
  required String accentHex,
  required Room room,
}) {
  final lightNote =
      room.direction == CompassDirection.south
          ? 'Your generous southern light means lighter fabrics will glow beautifully'
          : 'Lighter curtains let more of the summer light flood in';

  return _SuggestionTemplate(
    headline: 'Summer: lighten your textiles',
    description:
        'Swap heavier curtains or throws for lighter linen in your $roomName. '
        '$lightNote.',
    productType: ProductCategory.curtain,
    colourHint: accentHex,
  );
}

_SuggestionTemplate _autumnTemplate({
  required String roomName,
  required String directionLabel,
  required String heroHex,
  required Room room,
}) {
  final lightNote =
      room.direction == CompassDirection.west
          ? 'As the clocks go back, your west-facing evening light shifts warmer'
          : 'As the clocks go back, a chunky throw adds warmth to shorter evenings';

  return _SuggestionTemplate(
    headline: 'Autumn: add a chunky throw',
    description:
        'Layer a textured throw in a deeper tone to cosy up your $roomName. '
        '$lightNote.',
    productType: ProductCategory.throwBlanket,
    colourHint: heroHex,
  );
}

_SuggestionTemplate _winterTemplate({
  required String roomName,
  required String directionLabel,
  required String heroHex,
  required Room room,
}) {
  final lightNote =
      room.direction == CompassDirection.north
          ? 'A warm lamp counteracts the limited northern winter light'
          : 'Warm lighting makes your room feel intimate on dark evenings';

  return _SuggestionTemplate(
    headline: 'Winter: warm up your lighting',
    description:
        'Add a warm-toned table lamp or floor lamp to your $roomName. '
        '$lightNote.',
    productType: ProductCategory.floorLamp,
    colourHint: heroHex,
  );
}

class _SuggestionTemplate {
  const _SuggestionTemplate({
    required this.headline,
    required this.description,
    required this.productType,
    required this.colourHint,
  });

  final String headline;
  final String description;
  final ProductCategory productType;
  final String colourHint;
}
