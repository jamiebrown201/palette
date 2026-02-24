import 'package:drift/drift.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/core/colour/lab_colour.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/paint_colour.dart';

/// A scored paint colour match with delta-E distance.
typedef PaintColourMatch = ({PaintColour colour, double deltaE});

/// A cross-brand match with delta-E and match percentage.
typedef CrossBrandMatch = ({
  PaintColour colour,
  double deltaE,
  double matchPercent,
});

/// Repository for paint colour data with delta-E matching.
class PaintColourRepository {
  PaintColourRepository(this._db);

  final PaletteDatabase _db;

  Future<List<PaintColour>> getAll() => _db.select(_db.paintColours).get();

  Future<PaintColour?> getById(String id) =>
      (_db.select(_db.paintColours)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<List<PaintColour>> getByBrand(String brand) =>
      (_db.select(_db.paintColours)..where((t) => t.brand.equals(brand)))
          .get();

  Future<List<PaintColour>> getByFamily(PaletteFamily family) =>
      (_db.select(_db.paintColours)
            ..where((t) => t.paletteFamily.equalsValue(family)))
          .get();

  Future<List<PaintColour>> getByUndertone(Undertone undertone) =>
      (_db.select(_db.paintColours)
            ..where((t) => t.undertone.equalsValue(undertone)))
          .get();

  /// Search paint colours by name (case-insensitive partial match).
  /// SQLite LIKE is case-insensitive for ASCII by default.
  Future<List<PaintColour>> search(String query) =>
      (_db.select(_db.paintColours)
            ..where((t) => t.name.like('%${query.toLowerCase()}%')))
          .get();

  /// Find the closest paint colours to a given hex colour using CIEDE2000.
  Future<List<PaintColourMatch>> findClosestMatches(
    String hexColour, {
    int limit = 5,
    String? brandFilter,
  }) async {
    final targetLab = hexToLab(hexColour);

    final List<PaintColour> candidates;
    if (brandFilter != null) {
      candidates = await (_db.select(_db.paintColours)
            ..where((t) => t.brand.equals(brandFilter)))
          .get();
    } else {
      candidates = await _db.select(_db.paintColours).get();
    }

    final scored = <PaintColourMatch>[];
    for (final pc in candidates) {
      final lab = LabColour(pc.labL, pc.labA, pc.labB);
      scored.add((colour: pc, deltaE: deltaE2000(targetLab, lab)));
    }
    scored.sort((a, b) => a.deltaE.compareTo(b.deltaE));

    return scored.take(limit).toList();
  }

  /// Find cross-brand equivalents (delta-E < threshold, default 5.0).
  Future<List<CrossBrandMatch>> findCrossBrandMatches(
    PaintColour source, {
    double threshold = 5.0,
  }) async {
    final sourceLab = LabColour(source.labL, source.labA, source.labB);

    final allColours = await _db.select(_db.paintColours).get();

    final matches = <CrossBrandMatch>[];
    for (final pc in allColours) {
      if (pc.brand == source.brand) continue;
      final lab = LabColour(pc.labL, pc.labA, pc.labB);
      final dE = deltaE2000(sourceLab, lab);
      if (dE <= threshold) {
        matches.add((
          colour: pc,
          deltaE: dE,
          matchPercent: deltaEToMatchPercentage(dE),
        ));
      }
    }
    matches.sort((a, b) => a.deltaE.compareTo(b.deltaE));

    return matches;
  }

  /// Batch-insert paint colours (used for seed data loading).
  Future<void> insertAll(List<PaintColoursCompanion> entries) =>
      _db.batch((b) => b.insertAll(_db.paintColours, entries));

  /// Get the total count of paint colours in the database.
  Future<int> count() async {
    final countExpr = countAll();
    final query = _db.selectOnly(_db.paintColours)
      ..addColumns([countExpr]);
    final row = await query.getSingle();
    return row.read(countExpr)!;
  }
}
