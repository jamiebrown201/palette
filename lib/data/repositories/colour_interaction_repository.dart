import 'package:drift/drift.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/colour_interaction.dart';

/// Repository for logging colour interactions (for DNA drift detection).
class ColourInteractionRepository {
  ColourInteractionRepository(this._db);

  final PaletteDatabase _db;

  Future<void> logInteraction({
    required String id,
    required String interactionType,
    required String hex,
    required String contextScreen,
    String? paintId,
    String? contextRoomId,
    String? previousHex,
  }) =>
      _db.into(_db.colourInteractions).insert(
            ColourInteractionsCompanion.insert(
              id: id,
              interactionType: interactionType,
              hex: hex,
              contextScreen: contextScreen,
              paintId: Value(paintId),
              contextRoomId: Value(contextRoomId),
              previousHex: Value(previousHex),
              createdAt: DateTime.now(),
            ),
          );

  Future<List<ColourInteraction>> getRecentInteractions({int limit = 50}) =>
      (_db.select(_db.colourInteractions)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .get();

  Future<List<ColourInteraction>> getInteractionsSince(DateTime since) =>
      (_db.select(_db.colourInteractions)
            ..where((t) => t.createdAt.isBiggerOrEqualValue(since))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();
}
