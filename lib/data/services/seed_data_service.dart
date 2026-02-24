import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/palette_family.dart';
import 'package:palette/core/colour/undertone.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/repositories/paint_colour_repository.dart';

/// Current seed data version. Bump this when paint_colours.json changes
/// to trigger re-seeding on app update.
const int seedDataVersion = 1;

/// Service responsible for loading paint colour seed data from bundled JSON
/// into the local database on first launch (or when data version changes).
class SeedDataService {
  SeedDataService(this._db, this._paintColourRepo);

  final PaletteDatabase _db;
  final PaintColourRepository _paintColourRepo;

  /// Load seed data if needed (first launch or version bump).
  ///
  /// Returns `true` if seed data was loaded, `false` if already present.
  Future<bool> seedIfNeeded() async {
    final currentCount = await _paintColourRepo.count();
    if (currentCount > 0) return false;

    await _loadPaintColours();
    return true;
  }

  /// Force re-seed: clear existing data and reload from JSON.
  Future<void> reseed() async {
    await _db.delete(_db.paintColours).go();
    await _loadPaintColours();
  }

  Future<void> _loadPaintColours() async {
    final jsonString =
        await rootBundle.loadString('assets/data/paint_colours.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final colours = data['colours'] as List<dynamic>;

    final companions = <PaintColoursCompanion>[];

    for (final entry in colours) {
      final map = entry as Map<String, dynamic>;
      final hex = map['hex'] as String;
      final lab = hexToLab(hex);
      final undertoneResult = classifyUndertone(lab);
      final family = classifyPaletteFamily(lab);

      companions.add(
        PaintColoursCompanion.insert(
          id: map['id'] as String,
          brand: map['brand'] as String,
          name: map['name'] as String,
          code: map['code'] as String,
          hex: hex,
          labL: lab.l,
          labA: lab.a,
          labB: lab.b,
          lrv: (map['lrv'] as num).toDouble(),
          undertone: undertoneResult.classification,
          paletteFamily: family,
          collection: Value(map['collection'] as String?),
          approximatePricePerLitre: Value(
            map['approximatePricePerLitre'] != null
                ? (map['approximatePricePerLitre'] as num).toDouble()
                : null,
          ),
          priceLastChecked: Value(
            map['priceLastChecked'] != null
                ? DateTime.parse(map['priceLastChecked'] as String)
                : null,
          ),
        ),
      );
    }

    await _paintColourRepo.insertAll(companions);
  }
}

/// Load retailer configuration from bundled JSON.
Future<Map<String, RetailerConfig>> loadRetailerConfigs() async {
  final jsonString =
      await rootBundle.loadString('assets/data/retailer_configs.json');
  final data = json.decode(jsonString) as Map<String, dynamic>;
  final brands = data['brands'] as Map<String, dynamic>;

  return brands.map((brand, config) {
    final c = config as Map<String, dynamic>;
    return MapEntry(
      brand,
      RetailerConfig(
        productUrlTemplate: c['productUrlTemplate'] as String?,
        searchUrlTemplate: c['searchUrlTemplate'] as String?,
        homepageUrl: c['homepageUrl'] as String,
        affiliatePrefix: c['affiliatePrefix'] as String?,
      ),
    );
  });
}

/// URL configuration for a paint brand retailer.
class RetailerConfig {
  const RetailerConfig({
    required this.homepageUrl,
    this.productUrlTemplate,
    this.searchUrlTemplate,
    this.affiliatePrefix,
  });

  final String? productUrlTemplate;
  final String? searchUrlTemplate;
  final String homepageUrl;
  final String? affiliatePrefix;

  /// Build the best available URL for a paint colour.
  /// Falls back through: product page -> search -> homepage.
  String buildUrl({
    required String colourCode,
    required String colourName,
  }) {
    if (productUrlTemplate != null) {
      return _applyAffiliate(
        productUrlTemplate!
            .replaceAll('{code}', colourCode)
            .replaceAll('{name}', Uri.encodeComponent(colourName)),
      );
    }
    if (searchUrlTemplate != null) {
      return _applyAffiliate(
        searchUrlTemplate!
            .replaceAll('{name}', Uri.encodeComponent(colourName))
            .replaceAll('{code}', colourCode),
      );
    }
    return _applyAffiliate(homepageUrl);
  }

  String _applyAffiliate(String url) {
    if (affiliatePrefix == null) return url;
    final separator = url.contains('?') ? '&' : '?';
    return '$url$separator$affiliatePrefix';
  }
}
