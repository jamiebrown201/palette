import 'package:drift/drift.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/colour_dna_result.dart';

/// Repository for Colour DNA quiz results.
class ColourDnaRepository {
  ColourDnaRepository(this._db);

  final PaletteDatabase _db;

  Future<ColourDnaResult?> getLatest() =>
      (_db.select(_db.colourDnaResults)
            ..orderBy([(t) => OrderingTerm.desc(t.completedAt)])
            ..limit(1))
          .getSingleOrNull();

  Stream<ColourDnaResult?> watchLatest() =>
      (_db.select(_db.colourDnaResults)
            ..orderBy([(t) => OrderingTerm.desc(t.completedAt)])
            ..limit(1))
          .watchSingleOrNull();

  Future<ColourDnaResult?> getById(String id) =>
      (_db.select(_db.colourDnaResults)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> insert(ColourDnaResultsCompanion result) =>
      _db.into(_db.colourDnaResults).insert(result);

  Future<void> update(ColourDnaResultsCompanion result) =>
      (_db.update(_db.colourDnaResults)
            ..where((t) => t.id.equals(result.id.value)))
          .write(result);

  Future<List<ColourDnaResult>> getAll() =>
      (_db.select(_db.colourDnaResults)
            ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
          .get();
}
