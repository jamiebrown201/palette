/// A logged colour interaction for DNA drift detection.
class ColourInteraction {
  const ColourInteraction({
    required this.id,
    required this.interactionType,
    required this.hex,
    required this.contextScreen,
    required this.createdAt,
    this.paintId,
    this.contextRoomId,
    this.previousHex,
  });

  final String id;
  final String interactionType;
  final String? paintId;
  final String hex;
  final String? contextRoomId;
  final String contextScreen;
  final String? previousHex;
  final DateTime createdAt;
}
