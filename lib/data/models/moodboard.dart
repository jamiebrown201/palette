/// A room-specific digital moodboard.
///
/// Free users get 1 moodboard; premium users get unlimited.
class Moodboard {
  const Moodboard({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.roomId,
    this.roomName,
  });

  final String id;
  final String name;
  final String? roomId;
  final String? roomName;
  final DateTime createdAt;
  final DateTime updatedAt;
}
