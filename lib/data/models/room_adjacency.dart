/// Represents an adjacency relationship between two rooms.
class RoomAdjacency {
  const RoomAdjacency({
    required this.id,
    required this.roomIdA,
    required this.roomIdB,
  });

  final String id;
  final String roomIdA;
  final String roomIdB;
}
