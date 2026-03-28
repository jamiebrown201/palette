import 'package:drift/drift.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/product.dart';
import 'package:palette/features/rooms/logic/room_gap_engine.dart';

/// Repository for the curated product catalogue.
class ProductRepository {
  ProductRepository(this._db);

  final PaletteDatabase _db;

  /// All available products.
  Future<List<Product>> getAllProducts() =>
      (_db.select(_db.products)..where((t) => t.available.equals(true))).get();

  /// Products filtered by category.
  Future<List<Product>> getByCategory(ProductCategory category) =>
      (_db.select(_db.products)..where(
        (t) => t.category.equals(category.name) & t.available.equals(true),
      )).get();

  /// Products for a specific gap type (maps gap → relevant categories).
  Future<List<Product>> getForGapType(
    GapType gapType, {
    bool renterSafeOnly = false,
  }) async {
    final categories = _gapToCategories(gapType);
    if (categories.isEmpty) return [];

    final query = _db.select(_db.products)..where(
      (t) =>
          t.category.isIn(categories.map((c) => c.name).toList()) &
          t.available.equals(true),
    );

    if (renterSafeOnly) {
      query.where((t) => t.renterSafe.equals(true));
    }

    return query.get();
  }

  /// Insert a product (used by seeding).
  Future<void> insertProduct(ProductsCompanion product) =>
      _db.into(_db.products).insert(product);

  /// Batch insert products.
  Future<void> insertAll(List<ProductsCompanion> products) => _db.batch((
    batch,
  ) {
    batch.insertAll(_db.products, products, mode: InsertMode.insertOrReplace);
  });

  /// Count of available products.
  Future<int> productCount() async {
    final countExp = _db.products.id.count();
    final query =
        _db.selectOnly(_db.products)
          ..addColumns([countExp])
          ..where(_db.products.available.equals(true));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  /// Map gap types to product categories the engine should consider.
  static List<ProductCategory> _gapToCategories(GapType gapType) =>
      switch (gapType) {
        GapType.rug => [ProductCategory.rug],
        GapType.ambientLighting => [ProductCategory.pendantLight],
        GapType.taskLighting => [ProductCategory.floorLamp],
        GapType.accentLighting => [ProductCategory.tableLamp],
        GapType.textureContrast => [
          ProductCategory.throwBlanket,
          ProductCategory.cushion,
          ProductCategory.rug,
        ],
        GapType.accentColour => [
          ProductCategory.cushion,
          ProductCategory.throwBlanket,
        ],
        GapType.warmMaterial => [
          ProductCategory.throwBlanket,
          ProductCategory.cushion,
          ProductCategory.rug,
        ],
        GapType.coolMaterial => [
          ProductCategory.tableLamp,
          ProductCategory.floorLamp,
        ],
        _ => [],
      };
}
