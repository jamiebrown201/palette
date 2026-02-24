import 'package:drift/drift.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/database/converters.dart';
import 'package:palette/data/database/tables.dart';
import 'package:palette/data/models/colour_dna_result.dart';
import 'package:palette/data/models/locked_furniture.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/data/models/palette_colour.dart';
import 'package:palette/data/models/red_thread_colour.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/data/models/room_adjacency.dart';
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
  ],
)
class PaletteDatabase extends _$PaletteDatabase {
  PaletteDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
