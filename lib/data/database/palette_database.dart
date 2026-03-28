import 'package:drift/drift.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/database/converters.dart';
import 'package:palette/data/database/tables.dart';
import 'package:palette/data/models/colour_dna_result.dart';
import 'package:palette/data/models/colour_interaction.dart';
import 'package:palette/data/models/locked_furniture.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/data/models/palette_colour.dart';
import 'package:palette/data/models/product.dart';
import 'package:palette/data/models/red_thread_colour.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/data/models/room_adjacency.dart';
import 'package:palette/data/models/shopping_list_item.dart';
import 'package:palette/data/models/user_profile.dart';

part 'palette_database.g.dart';

@DriftDatabase(
  tables: [
    PaintColours,
    ColourDnaResults,
    PaletteColours,
    Rooms,
    LockedFurnitureItems,
    RedThreadColours,
    RoomAdjacencies,
    UserProfiles,
    ColourInteractions,
    Products,
    ShoppingListItems,
  ],
)
class PaletteDatabase extends _$PaletteDatabase {
  PaletteDatabase(super.e);

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(colourDnaResults, colourDnaResults.dnaConfidence);
        await m.addColumn(colourDnaResults, colourDnaResults.archetype);
      }
      if (from < 3) {
        // PaintColours gets two new non-nullable columns (cabStar,
        // chromaBand). Simplest approach: delete all seed rows so
        // seedIfNeeded() re-seeds with the new columns on next launch.
        await delete(paintColours).go();

        // ColourDnaResults gets two new nullable columns.
        await m.addColumn(
          colourDnaResults,
          colourDnaResults.undertoneTemperature,
        );
        await m.addColumn(colourDnaResults, colourDnaResults.systemPaletteJson);
      }
      if (from < 4) {
        await m.addColumn(
          colourDnaResults,
          colourDnaResults.saturationPreference,
        );
      }
      if (from < 5) {
        await m.createTable(colourInteractions);
        await m.addColumn(userProfiles, userProfiles.driftPromptDismissedAt);
      }
      if (from < 6) {
        await m.addColumn(userProfiles, userProfiles.canPaint);
        await m.addColumn(userProfiles, userProfiles.canDrill);
        await m.addColumn(userProfiles, userProfiles.keepingFlooring);
        await m.addColumn(userProfiles, userProfiles.isTemporaryHome);
        await m.addColumn(userProfiles, userProfiles.reversibleOnly);
      }
      if (from < 7) {
        // Expanded Furniture Lock (2A.1)
        await m.addColumn(lockedFurnitureItems, lockedFurnitureItems.category);
        await m.addColumn(lockedFurnitureItems, lockedFurnitureItems.status);
        await m.addColumn(lockedFurnitureItems, lockedFurnitureItems.material);
        await m.addColumn(lockedFurnitureItems, lockedFurnitureItems.woodTone);
        await m.addColumn(
          lockedFurnitureItems,
          lockedFurnitureItems.metalFinish,
        );
        await m.addColumn(lockedFurnitureItems, lockedFurnitureItems.style);
        await m.addColumn(
          lockedFurnitureItems,
          lockedFurnitureItems.textureFeel,
        );
        await m.addColumn(
          lockedFurnitureItems,
          lockedFurnitureItems.visualWeight,
        );
        await m.addColumn(
          lockedFurnitureItems,
          lockedFurnitureItems.finishSheen,
        );
      }
      if (from < 8) {
        // Product Catalogue (2A.3)
        await m.createTable(products);
      }
      if (from < 9) {
        // Room Dimensions (Phase 1E)
        await m.addColumn(rooms, rooms.roomSize);
        await m.addColumn(rooms, rooms.widthMetres);
        await m.addColumn(rooms, rooms.lengthMetres);
      }
      if (from < 10) {
        // Shopping List (Phase 2B.2)
        await m.createTable(shoppingListItems);
      }
    },
  );
}
