import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/repositories/colour_dna_repository.dart';
import 'package:palette/data/repositories/colour_interaction_repository.dart';
import 'package:palette/data/repositories/feedback_repository.dart';
import 'package:palette/data/repositories/moodboard_repository.dart';
import 'package:palette/data/repositories/paint_colour_repository.dart';
import 'package:palette/data/repositories/palette_repository.dart';
import 'package:palette/data/repositories/product_repository.dart';
import 'package:palette/data/repositories/red_thread_repository.dart';
import 'package:palette/data/repositories/room_repository.dart';
import 'package:palette/data/repositories/sample_list_repository.dart';
import 'package:palette/data/repositories/shopping_list_repository.dart';
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

@Riverpod(keepAlive: true)
ColourInteractionRepository colourInteractionRepository(Ref ref) =>
    ColourInteractionRepository(ref.watch(paletteDatabaseProvider));

@Riverpod(keepAlive: true)
ProductRepository productRepository(Ref ref) =>
    ProductRepository(ref.watch(paletteDatabaseProvider));

@Riverpod(keepAlive: true)
ShoppingListRepository shoppingListRepository(Ref ref) =>
    ShoppingListRepository(ref.watch(paletteDatabaseProvider));

@Riverpod(keepAlive: true)
FeedbackRepository feedbackRepository(Ref ref) =>
    FeedbackRepository(ref.watch(paletteDatabaseProvider));

@Riverpod(keepAlive: true)
MoodboardRepository moodboardRepository(Ref ref) =>
    MoodboardRepository(ref.watch(paletteDatabaseProvider));

@Riverpod(keepAlive: true)
SampleListRepository sampleListRepository(Ref ref) =>
    SampleListRepository(ref.watch(paletteDatabaseProvider));
