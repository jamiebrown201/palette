import 'package:drift/drift.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/core/constants/app_constants.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/palette_colour.dart';

/// Repository for the user's personal colour palette.
class PaletteRepository {
  PaletteRepository(this._db);

  final PaletteDatabase _db;

  Future<List<PaletteColour>> getForResult(String colourDnaResultId) =>
      (_db.select(_db.paletteColours)
            ..where((t) => t.colourDnaResultId.equals(colourDnaResultId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Stream<List<PaletteColour>> watchForResult(String colourDnaResultId) =>
      (_db.select(_db.paletteColours)
            ..where((t) => t.colourDnaResultId.equals(colourDnaResultId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<void> insert(PaletteColoursCompanion colour) =>
      _db.into(_db.paletteColours).insert(colour);

  Future<void> insertAll(List<PaletteColoursCompanion> colours) =>
      _db.batch((b) => b.insertAll(_db.paletteColours, colours));

  Future<void> delete(String id) =>
      (_db.delete(_db.paletteColours)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAllForResult(String colourDnaResultId) =>
      (_db.delete(_db.paletteColours)
            ..where((t) => t.colourDnaResultId.equals(colourDnaResultId)))
          .go();

  /// Check if adding a colour would clash with existing palette colours.
  ///
  /// A clash is defined as having a delta-E > [AppConstants.deltaEModerateMatchThreshold]
  /// with ALL existing colours (i.e., the new colour is too different from everything).
  /// Returns a human-readable warning if a clash is detected, or null if OK.
  Future<String?> checkForClash(
    String colourDnaResultId,
    String candidateHex,
  ) async {
    final existing = await getForResult(colourDnaResultId);
    if (existing.isEmpty) return null;

    final candidateLab = hexToLab(candidateHex);

    var minDeltaE = double.infinity;
    for (final pc in existing) {
      final lab = hexToLab(pc.hex);
      final dE = deltaE2000(candidateLab, lab);
      if (dE < minDeltaE) minDeltaE = dE;
    }

    if (minDeltaE > AppConstants.deltaEModerateMatchThreshold) {
      return 'This colour is quite different from your existing palette. '
          'It may feel disconnected — consider a bridging tone.';
    }

    return null;
  }
}
