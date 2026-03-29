import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/data/models/locked_furniture.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/palette/providers/palette_providers.dart';
import 'package:palette/features/red_thread/providers/red_thread_providers.dart';
import 'package:palette/features/rooms/logic/lighting_planner.dart';
import 'package:palette/features/rooms/logic/product_scoring.dart';
import 'package:palette/features/rooms/logic/renovation_sequencing.dart';
import 'package:palette/features/rooms/logic/room_audit.dart';
import 'package:palette/features/rooms/logic/room_gap_engine.dart';
import 'package:palette/features/rooms/logic/room_paint_recommendations.dart';
import 'package:palette/features/rooms/logic/seasonal_refresh.dart';
import 'package:palette/features/rooms/logic/whole_home_bundles.dart';
import 'package:palette/features/rooms/providers/feedback_providers.dart';
import 'package:palette/providers/database_providers.dart';

/// Stream of all rooms, ordered by sort order.
final allRoomsProvider = StreamProvider<List<Room>>((ref) {
  return ref.watch(roomRepositoryProvider).watchAllRooms();
});

/// Reactive stream of a single room by ID.
final roomByIdProvider = StreamProvider.family<Room?, String>((ref, roomId) {
  return ref.watch(roomRepositoryProvider).watchRoomById(roomId);
});

/// Reactive stream of furniture items for a room.
final furnitureForRoomProvider =
    StreamProvider.family<List<LockedFurniture>, String>((ref, roomId) {
      return ref.watch(roomRepositoryProvider).watchFurnitureForRoom(roomId);
    });

/// Paint recommendations for a specific room, based on hero colour,
/// direction, and budget bracket.
final roomPaintRecommendationsProvider =
    FutureProvider.family<List<RoomPaintRecommendation>, Room>((
      ref,
      room,
    ) async {
      if (room.heroColourHex == null) return [];
      final paintRepo = ref.watch(paintColourRepositoryProvider);
      final allPaints = await paintRepo.getAll();
      return computeRoomPaintRecommendations(allPaints: allPaints, room: room);
    });

/// Room gap analysis for a specific room.
///
/// Requires a 70/20/10 plan to be present. Returns an empty report otherwise.
final roomGapReportProvider = FutureProvider.family<RoomGapReport, String>((
  ref,
  roomId,
) async {
  final room = await ref.watch(roomByIdProvider(roomId).future);
  if (room == null) {
    return const RoomGapReport(gaps: [], dataQuality: DataQuality.none);
  }
  final furniture = await ref.watch(furnitureForRoomProvider(roomId).future);
  final threadColours = await ref.watch(threadColoursProvider.future);
  return analyseRoomGaps(
    room: room,
    furniture: furniture,
    threadColours: threadColours,
  );
});

/// Product recommendations for the primary gap in a room.
///
/// Scores products from the catalogue against the room's context, locked
/// furniture, colour plan, and user's archetype. Returns diverse slots
/// (recommended, best value, something different, safe choice).
final roomProductRecsProvider = FutureProvider.family<
  List<(RecommendationSlot, ScoredProduct)>,
  String
>((ref, roomId) async {
  final report = await ref.watch(roomGapReportProvider(roomId).future);
  if (!report.hasGaps || report.primaryGap == null) return [];

  final room = await ref.watch(roomByIdProvider(roomId).future);
  if (room == null) return [];

  final furniture = await ref.watch(furnitureForRoomProvider(roomId).future);
  final productRepo = ref.watch(productRepositoryProvider);
  final dna = await ref.watch(latestColourDnaProvider.future);

  final weightsConfig = await ref.watch(scoringWeightsConfigProvider.future);

  final candidates = await productRepo.getForGapType(
    report.primaryGap!.gapType,
    renterSafeOnly: room.isRenterMode,
  );

  if (candidates.isEmpty) return [];

  final weights = weightsConfig.forCategory(report.primaryGap!.gapType.name);

  final scored = scoreProducts(
    candidates: candidates,
    room: room,
    lockedFurniture: furniture,
    archetype: dna?.archetype,
    weights: weights,
    limit: 10,
  );

  return diverseRecommendations(scored: scored);
});

/// Seasonal refresh suggestions for all rooms.
///
/// Generates one suggestion per room with a 70/20/10 plan,
/// using the current season and matching products from the catalogue.
final seasonalSuggestionsProvider = FutureProvider<List<SeasonalSuggestion>>((
  ref,
) async {
  final rooms = await ref.watch(allRoomsProvider.future);
  final productRepo = ref.watch(productRepositoryProvider);
  final catalogue = await productRepo.getAllProducts();
  final threadColours = await ref.watch(threadColoursProvider.future);

  final now = DateTime.now();
  final season = seasonFromDate(now);

  return generateSeasonalSuggestions(
    rooms: rooms,
    catalogue: catalogue,
    season: season,
    threadColourHexes: threadColours.map((t) => t.hex).toList(),
  );
});

/// Room audit: evaluates a room against Watson-Smyth's design rules.
///
/// Scores texture layering, material balance, lighting layers, colour plan,
/// metal consistency, wood tone harmony, visual weight, and more.
final roomAuditProvider = FutureProvider.family<RoomAuditReport, String>((
  ref,
  roomId,
) async {
  final room = await ref.watch(roomByIdProvider(roomId).future);
  if (room == null) {
    return const RoomAuditReport(
      roomName: '',
      rules: [],
      score: 0,
      totalPossible: 0,
      summary: 'Room not found',
    );
  }
  final furniture = await ref.watch(furnitureForRoomProvider(roomId).future);
  return auditRoom(room: room, furniture: furniture);
});

/// Lighting plan for a specific room.
///
/// Analyses locked furniture to determine which of the three lighting
/// layers (ambient, task, accent) are covered, and recommends products
/// from the catalogue for any missing layers.
final lightingPlanProvider = FutureProvider.family<LightingPlan, String>((
  ref,
  roomId,
) async {
  final room = await ref.watch(roomByIdProvider(roomId).future);
  if (room == null) {
    return const LightingPlan(
      roomName: '',
      layers: [],
      summary: 'Room not found',
      layersCovered: 0,
      layersTotal: 3,
    );
  }
  final furniture = await ref.watch(furnitureForRoomProvider(roomId).future);
  final productRepo = ref.watch(productRepositoryProvider);
  final catalogue = await productRepo.getAllProducts();

  return generateLightingPlan(
    room: room,
    furniture: furniture,
    catalogue: catalogue,
  );
});

/// Renovation guide for a specific room.
///
/// Generates a step-by-step sequence adapted to the room's property
/// type, era, tenure, and existing furniture. Follows the professional
/// decorator's rule: top-down, big-to-small, structural-to-decorative.
final renovationGuideProvider = FutureProvider.family<RenovationGuide, String>((
  ref,
  roomId,
) async {
  final room = await ref.watch(roomByIdProvider(roomId).future);
  if (room == null) {
    return const RenovationGuide(
      roomName: '',
      steps: [],
      summary: 'Room not found',
      completedCount: 0,
      totalCount: 0,
    );
  }
  final furniture = await ref.watch(furnitureForRoomProvider(roomId).future);
  final dna = await ref.watch(latestColourDnaProvider.future);

  return generateRenovationGuide(
    room: room,
    furniture: furniture,
    propertyType: dna?.propertyType,
    propertyEra: dna?.propertyEra,
    tenure: dna?.tenure,
  );
});

/// Whole-home bundles: cross-room product recommendations that
/// strengthen the Red Thread between adjacent rooms.
final wholeHomeBundlesProvider = FutureProvider<List<WholeHomeBundle>>((
  ref,
) async {
  final rooms = await ref.watch(allRoomsProvider.future);
  if (rooms.length < 2) return [];

  final threadRepo = ref.watch(redThreadRepositoryProvider);
  final threadColours = await threadRepo.getThreadColours();
  if (threadColours.isEmpty) return [];

  final adjacencies = await threadRepo.getAdjacencies();
  if (adjacencies.isEmpty) return [];

  final productRepo = ref.watch(productRepositoryProvider);
  final catalogue = await productRepo.getAllProducts();

  final dna = await ref.watch(latestColourDnaProvider.future);

  // Build furniture map for all rooms
  final roomRepo = ref.watch(roomRepositoryProvider);
  final furnitureByRoom = <String, List<LockedFurniture>>{};
  for (final room in rooms) {
    furnitureByRoom[room.id] = await roomRepo.getFurnitureForRoom(room.id);
  }

  final weightsConfig = await ref.watch(scoringWeightsConfigProvider.future);

  return generateWholeHomeBundles(
    rooms: rooms,
    adjacencies: adjacencies,
    threadHexes: threadColours.map((t) => t.hex).toList(),
    catalogue: catalogue,
    furnitureByRoom: furnitureByRoom,
    archetype: dna?.archetype,
    weights: weightsConfig.forCategory('bundle'),
  );
});
