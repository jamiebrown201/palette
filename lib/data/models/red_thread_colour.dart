/// A unifying colour in the whole-house Red Thread.
class RedThreadColour {
  const RedThreadColour({
    required this.id,
    required this.hex,
    required this.sortOrder,
    this.paintColourId,
  });

  final String id;
  final String hex;
  final String? paintColourId;
  final int sortOrder;
}
