import 'package:palette/data/database/palette_database.dart';

/// Repository for partner profile data (Phase 3.3).
class PartnerRepository {
  PartnerRepository(this._db);

  final PaletteDatabase _db;

  /// Watch the current partner (only one partner per user in v1).
  Stream<PartnerProfile?> watchPartner() {
    final query = _db.select(_db.partnerProfiles)..limit(1);
    return query.watchSingleOrNull();
  }

  /// Get the current partner, if any.
  Future<PartnerProfile?> getPartner() {
    final query = _db.select(_db.partnerProfiles)..limit(1);
    return query.getSingleOrNull();
  }

  /// Insert or update a partner profile.
  Future<void> upsertPartner(PartnerProfilesCompanion companion) {
    return _db.into(_db.partnerProfiles).insertOnConflictUpdate(companion);
  }

  /// Delete the current partner.
  Future<void> deletePartner(String id) {
    return (_db.delete(_db.partnerProfiles)
      ..where((t) => t.id.equals(id))).go();
  }
}
