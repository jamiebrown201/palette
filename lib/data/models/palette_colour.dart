/// A colour in the user's personal palette.
class PaletteColour {
  const PaletteColour({
    required this.id,
    required this.colourDnaResultId,
    required this.hex,
    required this.sortOrder,
    required this.isSurprise,
    required this.addedAt,
    this.paintColourId,
  });

  final String id;
  final String colourDnaResultId;
  final String? paintColourId;
  final String hex;
  final int sortOrder;
  final bool isSurprise;
  final DateTime addedAt;
}
