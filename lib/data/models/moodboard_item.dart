/// An item on a moodboard — colour swatch, image URL, or product reference.
class MoodboardItem {
  const MoodboardItem({
    required this.id,
    required this.moodboardId,
    required this.type,
    required this.sortOrder,
    required this.addedAt,
    this.colourHex,
    this.colourName,
    this.imageUrl,
    this.productId,
    this.label,
  });

  final String id;
  final String moodboardId;

  /// 'colour', 'image', or 'product'.
  final String type;

  /// For colour swatches.
  final String? colourHex;
  final String? colourName;

  /// For web images or camera photos.
  final String? imageUrl;

  /// For products from the catalogue.
  final String? productId;

  /// Optional user label / note.
  final String? label;

  final int sortOrder;
  final DateTime addedAt;
}
