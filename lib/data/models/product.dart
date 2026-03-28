import 'package:palette/core/constants/enums.dart';

/// A curated product in the recommendation catalogue.
///
/// Products are scored against the user's room context, locked furniture,
/// colour plan, and design identity to power "Complete the Room" recs.
class Product {
  const Product({
    required this.id,
    required this.category,
    required this.name,
    required this.brand,
    required this.retailer,
    required this.priceGbp,
    required this.affiliateUrl,
    required this.imageUrl,
    required this.primaryColourHex,
    required this.undertone,
    required this.materials,
    required this.styles,
    required this.textureFeel,
    required this.visualWeight,
    required this.finishSheen,
    required this.renterSafe,
    required this.available,
    this.secondaryColourHex,
    this.woodTone,
    this.metalFinish,
    this.rugSize,
    this.widthCm,
    this.heightCm,
    this.depthCm,
    this.lastVerified,
  });

  final String id;
  final ProductCategory category;
  final String name;
  final String brand;
  final String retailer;
  final double priceGbp;
  final String affiliateUrl;
  final String imageUrl;
  final String primaryColourHex;
  final String? secondaryColourHex;
  final Undertone undertone;
  final List<ProductMaterial> materials;
  final List<ProductStyle> styles;
  final TextureFeel textureFeel;
  final VisualWeight visualWeight;
  final FinishSheen finishSheen;
  final WoodTone? woodTone;
  final MetalFinish? metalFinish;
  final RugSize? rugSize;
  final double? widthCm;
  final double? heightCm;
  final double? depthCm;
  final bool renterSafe;
  final bool available;
  final DateTime? lastVerified;

  /// Whether this is a lighting product.
  bool get isLighting =>
      category == ProductCategory.pendantLight ||
      category == ProductCategory.floorLamp ||
      category == ProductCategory.tableLamp;

  /// The budget bracket this product falls into based on category + price.
  PriceTier get priceTier {
    // Rugs: affordable < £150, mid £150-400, investment > £400
    if (category == ProductCategory.rug) {
      if (priceGbp < 150) return PriceTier.affordable;
      if (priceGbp < 400) return PriceTier.midRange;
      return PriceTier.investment;
    }
    // Lighting: affordable < £60, mid £60-200, investment > £200
    if (isLighting) {
      if (priceGbp < 60) return PriceTier.affordable;
      if (priceGbp < 200) return PriceTier.midRange;
      return PriceTier.investment;
    }
    // Soft furnishings: affordable < £30, mid £30-80, investment > £80
    if (priceGbp < 30) return PriceTier.affordable;
    if (priceGbp < 80) return PriceTier.midRange;
    return PriceTier.investment;
  }
}
