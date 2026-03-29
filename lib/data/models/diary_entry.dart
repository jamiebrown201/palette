/// A before-and-after photo entry in the Design Diary.
///
/// Each entry is linked to a room and captures a photo at a point in time.
/// Entries are grouped as "before" or "after" to form a visual journey.
class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.photoPath,
    required this.phase,
    required this.createdAt,
    this.caption,
    this.heroColourHex,
  });

  final String id;
  final String roomId;
  final String roomName;

  /// Local file path to the photo.
  final String photoPath;

  /// 'before' or 'after'.
  final String phase;

  /// Optional user-written caption.
  final String? caption;

  /// Snapshot of the room's hero colour at the time of capture.
  final String? heroColourHex;

  final DateTime createdAt;

  bool get isBefore => phase == 'before';
  bool get isAfter => phase == 'after';
}
