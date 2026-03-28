import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/product.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/rooms/logic/seasonal_refresh.dart';

Room _room({
  String id = 'r1',
  String name = 'Living Room',
  String? heroColourHex = '#C4A882',
  String? betaColourHex = '#8FAE8B',
  String? surpriseColourHex = '#C9A96E',
  CompassDirection? direction = CompassDirection.south,
  bool isRenterMode = false,
}) {
  return Room(
    id: id,
    name: name,
    usageTime: UsageTime.evening,
    moods: [RoomMood.cocooning],
    budget: BudgetBracket.midRange,
    isRenterMode: isRenterMode,
    sortOrder: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    direction: direction,
    heroColourHex: heroColourHex,
    betaColourHex: betaColourHex,
    surpriseColourHex: surpriseColourHex,
  );
}

Product _product({
  String id = 'p1',
  ProductCategory category = ProductCategory.cushion,
  TextureFeel textureFeel = TextureFeel.smooth,
  bool renterSafe = true,
  bool available = true,
}) {
  return Product(
    id: id,
    category: category,
    name: 'Test Product',
    brand: 'Test Brand',
    retailer: 'TestShop',
    priceGbp: 25.0,
    affiliateUrl: 'https://example.com',
    imageUrl: 'https://example.com/img.jpg',
    primaryColourHex: '#C4A882',
    undertone: Undertone.warm,
    materials: [ProductMaterial.fabricCotton],
    styles: [ProductStyle.modern],
    textureFeel: textureFeel,
    visualWeight: VisualWeight.light,
    finishSheen: FinishSheen.matte,
    renterSafe: renterSafe,
    available: available,
  );
}

void main() {
  group('seasonFromDate', () {
    test('returns spring for March', () {
      expect(seasonFromDate(DateTime(2026, 3, 15)), Season.spring);
    });

    test('returns summer for July', () {
      expect(seasonFromDate(DateTime(2026, 7, 1)), Season.summer);
    });

    test('returns autumn for October', () {
      expect(seasonFromDate(DateTime(2026, 10, 20)), Season.autumn);
    });

    test('returns winter for January', () {
      expect(seasonFromDate(DateTime(2026, 1, 5)), Season.winter);
    });

    test('returns winter for December', () {
      expect(seasonFromDate(DateTime(2026, 12, 25)), Season.winter);
    });

    test('returns spring for May', () {
      expect(seasonFromDate(DateTime(2026, 5, 31)), Season.spring);
    });
  });

  group('generateSeasonalSuggestions', () {
    test('returns empty list when no rooms have hero colour', () {
      final rooms = [_room(heroColourHex: null)];
      final result = generateSeasonalSuggestions(
        rooms: rooms,
        catalogue: [],
        season: Season.spring,
      );
      expect(result, isEmpty);
    });

    test('generates one suggestion per room with hero colour', () {
      final rooms = [
        _room(id: 'r1', name: 'Living Room'),
        _room(id: 'r2', name: 'Bedroom'),
      ];
      final result = generateSeasonalSuggestions(
        rooms: rooms,
        catalogue: [],
        season: Season.autumn,
      );
      expect(result.length, 2);
      expect(result[0].room.id, 'r1');
      expect(result[1].room.id, 'r2');
    });

    test('spring suggestions reference cushions', () {
      final rooms = [_room()];
      final result = generateSeasonalSuggestions(
        rooms: rooms,
        catalogue: [],
        season: Season.spring,
      );
      expect(result.first.productType, ProductCategory.cushion);
      expect(result.first.headline.toLowerCase(), contains('cushion'));
    });

    test('autumn suggestions reference throws', () {
      final rooms = [_room()];
      final result = generateSeasonalSuggestions(
        rooms: rooms,
        catalogue: [],
        season: Season.autumn,
      );
      expect(result.first.productType, ProductCategory.throwBlanket);
      expect(result.first.headline.toLowerCase(), contains('throw'));
    });

    test('winter suggestions reference lighting', () {
      final rooms = [_room()];
      final result = generateSeasonalSuggestions(
        rooms: rooms,
        catalogue: [],
        season: Season.winter,
      );
      expect(result.first.productType, ProductCategory.floorLamp);
      expect(result.first.headline.toLowerCase(), contains('lighting'));
    });

    test('matches products from catalogue for the season', () {
      final rooms = [_room()];
      final catalogue = [
        _product(id: 'autumn-throw', category: ProductCategory.throwBlanket),
        _product(id: 'rug', category: ProductCategory.rug),
      ];
      final result = generateSeasonalSuggestions(
        rooms: rooms,
        catalogue: catalogue,
        season: Season.autumn,
      );
      expect(result.first.matchedProduct, isNotNull);
      expect(result.first.matchedProduct!.id, 'autumn-throw');
    });

    test('prefers chunky textures in autumn', () {
      final rooms = [_room()];
      final catalogue = [
        _product(
          id: 'smooth-throw',
          category: ProductCategory.throwBlanket,
          textureFeel: TextureFeel.smooth,
        ),
        _product(
          id: 'chunky-throw',
          category: ProductCategory.throwBlanket,
          textureFeel: TextureFeel.chunky,
        ),
      ];
      final result = generateSeasonalSuggestions(
        rooms: rooms,
        catalogue: catalogue,
        season: Season.autumn,
      );
      expect(result.first.matchedProduct!.id, 'chunky-throw');
    });

    test('filters to renter-safe products for renter rooms', () {
      final rooms = [_room(isRenterMode: true)];
      final catalogue = [
        _product(
          id: 'hardwired',
          category: ProductCategory.cushion,
          renterSafe: false,
        ),
        _product(
          id: 'safe-cushion',
          category: ProductCategory.cushion,
          renterSafe: true,
        ),
      ];
      final result = generateSeasonalSuggestions(
        rooms: rooms,
        catalogue: catalogue,
        season: Season.spring,
      );
      expect(result.first.matchedProduct!.id, 'safe-cushion');
    });

    test('excludes unavailable products', () {
      final rooms = [_room()];
      final catalogue = [
        _product(
          id: 'unavailable',
          category: ProductCategory.cushion,
          available: false,
        ),
      ];
      final result = generateSeasonalSuggestions(
        rooms: rooms,
        catalogue: catalogue,
        season: Season.spring,
      );
      expect(result.first.matchedProduct, isNull);
    });

    test('description mentions room name', () {
      final rooms = [_room(name: 'Kitchen')];
      final result = generateSeasonalSuggestions(
        rooms: rooms,
        catalogue: [],
        season: Season.spring,
      );
      expect(result.first.description, contains('Kitchen'));
    });

    test('description references light direction for east room in spring', () {
      final rooms = [_room(direction: CompassDirection.east)];
      final result = generateSeasonalSuggestions(
        rooms: rooms,
        catalogue: [],
        season: Season.spring,
      );
      expect(result.first.description.toLowerCase(), contains('morning light'));
    });
  });

  group('Season extension', () {
    test('focus categories differ per season', () {
      expect(Season.spring.focusCategories, isNotEmpty);
      expect(
        Season.winter.focusCategories,
        contains(ProductCategory.throwBlanket),
      );
    });

    test('preferred textures differ per season', () {
      expect(Season.autumn.preferredTextures, contains(TextureFeel.chunky));
      expect(Season.spring.preferredTextures, contains(TextureFeel.smooth));
    });
  });
}
