import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/core/colour/lab_colour.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/data/models/locked_furniture.dart';
import 'package:palette/data/models/product.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/data/models/room_adjacency.dart';
import 'package:palette/features/rooms/logic/product_scoring.dart';

/// A cross-room product bundle that strengthens the Red Thread.
///
/// Each bundle connects two adjacent rooms by recommending products whose
/// colours harmonise with the thread colours shared between them.
class WholeHomeBundle {
  const WholeHomeBundle({
    required this.roomA,
    required this.roomB,
    required this.sharedThreadHex,
    required this.headline,
    required this.description,
    required this.recommendations,
  });

  /// First room in the pair.
  final Room roomA;

  /// Second room in the pair.
  final Room roomB;

  /// The Red Thread colour hex that connects these rooms.
  final String sharedThreadHex;

  /// Short headline, e.g. "Connect your Living Room and Hallway".
  final String headline;

  /// Longer explanation of why this bundle works.
  final String description;

  /// Product recommendations that work across both rooms.
  /// Each entry: (room the product is for, scored product).
  final List<BundleRecommendation> recommendations;
}

/// A single product recommendation within a bundle.
class BundleRecommendation {
  const BundleRecommendation({
    required this.room,
    required this.product,
    required this.reason,
  });

  /// The room this product is recommended for.
  final Room room;

  /// The scored product.
  final Product product;

  /// Why this product connects the rooms.
  final String reason;
}

/// Generate whole-home bundles from adjacent room pairs and thread colours.
///
/// For each pair of adjacent rooms that share a Red Thread colour, finds
/// products from the catalogue that would strengthen the visual connection
/// between those rooms.
List<WholeHomeBundle> generateWholeHomeBundles({
  required List<Room> rooms,
  required List<RoomAdjacency> adjacencies,
  required List<String> threadHexes,
  required List<Product> catalogue,
  required Map<String, List<LockedFurniture>> furnitureByRoom,
  ColourArchetype? archetype,
  ScoringWeights weights = kDefaultWeights,
}) {
  if (threadHexes.isEmpty || adjacencies.isEmpty || rooms.length < 2) {
    return [];
  }

  final roomMap = {for (final r in rooms) r.id: r};
  final bundles = <WholeHomeBundle>[];

  for (final adj in adjacencies) {
    final roomA = roomMap[adj.roomIdA];
    final roomB = roomMap[adj.roomIdB];
    if (roomA == null || roomB == null) continue;
    if (roomA.heroColourHex == null && roomB.heroColourHex == null) continue;

    // Find shared thread colours between these two rooms
    final sharedThread = _findSharedThread(
      roomA: roomA,
      roomB: roomB,
      threadHexes: threadHexes,
    );
    if (sharedThread == null) continue;

    final bundle = _buildBundle(
      roomA: roomA,
      roomB: roomB,
      sharedThreadHex: sharedThread,
      catalogue: catalogue,
      furnitureByRoom: furnitureByRoom,
      archetype: archetype,
      weights: weights,
    );
    if (bundle != null) {
      bundles.add(bundle);
    }
  }

  return bundles;
}

/// Find the strongest shared Red Thread colour between two rooms.
///
/// A thread colour is "shared" if it appears within delta-E 25 of at least
/// one colour in each room's palette (hero, beta, or surprise).
String? _findSharedThread({
  required Room roomA,
  required Room roomB,
  required List<String> threadHexes,
}) {
  for (final threadHex in threadHexes) {
    final threadLab = hexToLab(threadHex);
    final closeToA = _isCloseToRoom(threadLab, roomA);
    final closeToB = _isCloseToRoom(threadLab, roomB);
    if (closeToA && closeToB) return threadHex;
  }

  // Fallback: find thread colour close to at least one room
  for (final threadHex in threadHexes) {
    final threadLab = hexToLab(threadHex);
    if (_isCloseToRoom(threadLab, roomA) || _isCloseToRoom(threadLab, roomB)) {
      return threadHex;
    }
  }

  return threadHexes.isNotEmpty ? threadHexes.first : null;
}

bool _isCloseToRoom(LabColour threadLab, Room room) {
  const threshold = 25.0;
  final hexes =
      [
        room.heroColourHex,
        room.betaColourHex,
        room.surpriseColourHex,
      ].whereType<String>();
  for (final hex in hexes) {
    if (deltaE2000(threadLab, hexToLab(hex)) < threshold) return true;
  }
  return false;
}

WholeHomeBundle? _buildBundle({
  required Room roomA,
  required Room roomB,
  required String sharedThreadHex,
  required List<Product> catalogue,
  required Map<String, List<LockedFurniture>> furnitureByRoom,
  required ColourArchetype? archetype,
  required ScoringWeights weights,
}) {
  final furnitureA = furnitureByRoom[roomA.id] ?? [];
  final furnitureB = furnitureByRoom[roomB.id] ?? [];

  // Find products that harmonise with the shared thread colour
  final threadLab = hexToLab(sharedThreadHex);
  final candidates =
      catalogue.where((p) {
        if (!p.available) return false;
        // Product's primary colour should be close to the thread
        final pLab = hexToLab(p.primaryColourHex);
        return deltaE2000(threadLab, pLab) < 35.0;
      }).toList();

  if (candidates.isEmpty) return null;

  // Score for each room and pick the best per room
  final recsA = _bestForRoom(
    room: roomA,
    furniture: furnitureA,
    candidates: candidates,
    archetype: archetype,
    weights: weights,
  );
  final recsB = _bestForRoom(
    room: roomB,
    furniture: furnitureB,
    candidates: candidates,
    archetype: archetype,
    weights: weights,
  );

  final recommendations = <BundleRecommendation>[];

  if (recsA != null) {
    recommendations.add(
      BundleRecommendation(
        room: roomA,
        product: recsA.product,
        reason: _bundleReason(recsA, roomA, roomB, sharedThreadHex),
      ),
    );
  }
  if (recsB != null && recsB.product.id != recsA?.product.id) {
    recommendations.add(
      BundleRecommendation(
        room: roomB,
        product: recsB.product,
        reason: _bundleReason(recsB, roomB, roomA, sharedThreadHex),
      ),
    );
  }

  if (recommendations.isEmpty) return null;

  final headline = 'Connect your ${roomA.name} and ${roomB.name}';
  final description = _bundleDescription(
    roomA: roomA,
    roomB: roomB,
    sharedThreadHex: sharedThreadHex,
    recommendations: recommendations,
  );

  return WholeHomeBundle(
    roomA: roomA,
    roomB: roomB,
    sharedThreadHex: sharedThreadHex,
    headline: headline,
    description: description,
    recommendations: recommendations,
  );
}

ScoredProduct? _bestForRoom({
  required Room room,
  required List<LockedFurniture> furniture,
  required List<Product> candidates,
  required ColourArchetype? archetype,
  required ScoringWeights weights,
}) {
  if (room.heroColourHex == null) return null;

  final scored = scoreProducts(
    candidates: candidates,
    room: room,
    lockedFurniture: furniture,
    archetype: archetype,
    weights: weights,
    limit: 1,
  );
  return scored.isNotEmpty ? scored.first : null;
}

String _bundleReason(
  ScoredProduct scored,
  Room targetRoom,
  Room linkedRoom,
  String threadHex,
) {
  final category = scored.product.category.displayName.toLowerCase();
  return 'This $category echoes your Red Thread colour, '
      'linking ${targetRoom.name} to ${linkedRoom.name}';
}

String _bundleDescription({
  required Room roomA,
  required Room roomB,
  required String sharedThreadHex,
  required List<BundleRecommendation> recommendations,
}) {
  final categories = recommendations
      .map((r) => r.product.category.displayName.toLowerCase())
      .toSet()
      .join(' and ');

  final dirA = roomA.direction?.displayName ?? '';
  final dirB = roomB.direction?.displayName ?? '';

  final dirNote =
      dirA.isNotEmpty && dirB.isNotEmpty
          ? ' Your $dirA-facing ${roomA.name} and $dirB-facing ${roomB.name}'
              ' share a warm connection through this thread colour.'
          : ' These rooms share a colour thread that creates'
              ' subconscious harmony as you move between them.';

  return 'A $categories combination that strengthens your'
      ' Red Thread.$dirNote';
}
