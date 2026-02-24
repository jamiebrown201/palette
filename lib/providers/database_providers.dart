import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/repositories/colour_dna_repository.dart';
import 'package:palette/data/repositories/paint_colour_repository.dart';
import 'package:palette/data/repositories/palette_repository.dart';
import 'package:palette/data/repositories/red_thread_repository.dart';
import 'package:palette/data/repositories/room_repository.dart';
import 'package:palette/data/repositories/user_profile_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_providers.g.dart';

/// The Drift database instance. Must be overridden in ProviderScope at startup.
@Riverpod(keepAlive: true)
PaletteDatabase paletteDatabase(Ref ref) {
  throw UnimplementedError(
    'paletteDatabaseProvider must be overridden with the actual database.',
  );
}

@Riverpod(keepAlive: true)
PaintColourRepository paintColourRepository(Ref ref) =>
    PaintColourRepository(ref.watch(paletteDatabaseProvider));

@Riverpod(keepAlive: true)
RoomRepository roomRepository(Ref ref) =>
    RoomRepository(ref.watch(paletteDatabaseProvider));

@Riverpod(keepAlive: true)
PaletteRepository paletteRepository(Ref ref) =>
    PaletteRepository(ref.watch(paletteDatabaseProvider));

@Riverpod(keepAlive: true)
ColourDnaRepository colourDnaRepository(Ref ref) =>
    ColourDnaRepository(ref.watch(paletteDatabaseProvider));

@Riverpod(keepAlive: true)
RedThreadRepository redThreadRepository(Ref ref) =>
    RedThreadRepository(ref.watch(paletteDatabaseProvider));

@Riverpod(keepAlive: true)
UserProfileRepository userProfileRepository(Ref ref) =>
    UserProfileRepository(ref.watch(paletteDatabaseProvider));
