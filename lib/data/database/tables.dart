import 'package:drift/drift.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/database/converters.dart';
import 'package:palette/data/models/colour_dna_result.dart';
import 'package:palette/data/models/locked_furniture.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/data/models/palette_colour.dart';
import 'package:palette/data/models/red_thread_colour.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/data/models/room_adjacency.dart';
import 'package:palette/data/models/user_profile.dart';

// ---------------------------------------------------------------------------
// Paint colours (seed data from JSON)
// ---------------------------------------------------------------------------

@UseRowClass(PaintColour)
class PaintColours extends Table {
  TextColumn get id => text()();
  TextColumn get brand => text()();
  TextColumn get name => text()();
  TextColumn get code => text()();
  TextColumn get hex => text()();
  RealColumn get labL => real()();
  RealColumn get labA => real()();
  RealColumn get labB => real()();
  RealColumn get lrv => real()();
  TextColumn get undertone =>
      text().map(const EnumNameConverter<Undertone>(Undertone.values))();
  TextColumn get paletteFamily => text()
      .map(const EnumNameConverter<PaletteFamily>(PaletteFamily.values))();
  TextColumn get collection => text().nullable()();
  RealColumn get approximatePricePerLitre => real().nullable()();
  DateTimeColumn get priceLastChecked => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Colour DNA quiz results
// ---------------------------------------------------------------------------

@UseRowClass(ColourDnaResult)
class ColourDnaResults extends Table {
  TextColumn get id => text()();
  TextColumn get primaryFamily => text()
      .map(const EnumNameConverter<PaletteFamily>(PaletteFamily.values))();
  TextColumn get secondaryFamily => text()
      .nullable()
      .map(const EnumNameConverter<PaletteFamily>(PaletteFamily.values))();
  TextColumn get colourHexes =>
      text().map(const StringListConverter())();
  TextColumn get propertyType => text()
      .nullable()
      .map(const EnumNameConverter<PropertyType>(PropertyType.values))();
  TextColumn get propertyEra => text()
      .nullable()
      .map(const EnumNameConverter<PropertyEra>(PropertyEra.values))();
  TextColumn get projectStage => text()
      .nullable()
      .map(const EnumNameConverter<ProjectStage>(ProjectStage.values))();
  TextColumn get tenure => text()
      .nullable()
      .map(const EnumNameConverter<Tenure>(Tenure.values))();
  DateTimeColumn get completedAt => dateTime()();
  BoolColumn get isComplete => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// User's personal palette colours
// ---------------------------------------------------------------------------

@UseRowClass(PaletteColour)
class PaletteColours extends Table {
  TextColumn get id => text()();
  TextColumn get colourDnaResultId =>
      text().references(ColourDnaResults, #id)();
  TextColumn get paintColourId =>
      text().nullable().references(PaintColours, #id)();
  TextColumn get hex => text()();
  IntColumn get sortOrder => integer()();
  BoolColumn get isSurprise => boolean()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Rooms
// ---------------------------------------------------------------------------

@UseRowClass(Room)
class Rooms extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get direction => text()
      .nullable()
      .map(
        const EnumNameConverter<CompassDirection>(CompassDirection.values),
      )();
  TextColumn get usageTime =>
      text().map(const EnumNameConverter<UsageTime>(UsageTime.values))();
  TextColumn get moods => text().map(const RoomMoodListConverter())();
  TextColumn get budget => text()
      .map(const EnumNameConverter<BudgetBracket>(BudgetBracket.values))();
  TextColumn get heroColourHex => text().nullable()();
  TextColumn get betaColourHex => text().nullable()();
  TextColumn get surpriseColourHex => text().nullable()();
  BoolColumn get isRenterMode => boolean()();
  IntColumn get sortOrder => integer()();
  TextColumn get wallColourHex => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Locked furniture items within a room
// ---------------------------------------------------------------------------

@UseRowClass(LockedFurniture)
class LockedFurnitureItems extends Table {
  TextColumn get id => text()();
  TextColumn get roomId => text().references(Rooms, #id)();
  TextColumn get name => text()();
  TextColumn get colourHex => text()();
  TextColumn get role => text()
      .map(const EnumNameConverter<FurnitureRole>(FurnitureRole.values))();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'locked_furniture';
}

// ---------------------------------------------------------------------------
// Red Thread colours (whole-house unifying colours)
// ---------------------------------------------------------------------------

@UseRowClass(RedThreadColour)
class RedThreadColours extends Table {
  TextColumn get id => text()();
  TextColumn get hex => text()();
  TextColumn get paintColourId =>
      text().nullable().references(PaintColours, #id)();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Room adjacencies (which rooms connect to each other)
// ---------------------------------------------------------------------------

@UseRowClass(RoomAdjacency)
class RoomAdjacencies extends Table {
  TextColumn get id => text()();
  TextColumn get roomIdA => text().references(Rooms, #id)();
  TextColumn get roomIdB => text().references(Rooms, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// User profile (single-row table for local preferences)
// ---------------------------------------------------------------------------

@UseRowClass(UserProfile)
class UserProfiles extends Table {
  TextColumn get id => text()();
  BoolColumn get hasCompletedOnboarding => boolean()();
  TextColumn get subscriptionTier => text().map(
        const EnumNameConverter<SubscriptionTier>(SubscriptionTier.values),
      )();
  BoolColumn get colourBlindMode => boolean()();
  TextColumn get colourDnaResultId =>
      text().nullable().references(ColourDnaResults, #id)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
