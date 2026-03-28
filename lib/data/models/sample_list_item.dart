/// A paint sample the user wants to order.
///
/// Items are added from paint swatches throughout the app and grouped by brand
/// on the Sample List screen.
class SampleListItem {
  const SampleListItem({
    required this.id,
    required this.paintColourId,
    required this.colourName,
    required this.colourCode,
    required this.brand,
    required this.hex,
    required this.addedAt,
    this.roomId,
    this.roomName,
    this.orderedAt,
    this.arrivedAt,
  });

  final String id;
  final String paintColourId;
  final String colourName;
  final String colourCode;
  final String brand;
  final String hex;

  /// Optional room context — which room this sample is for.
  final String? roomId;
  final String? roomName;

  final DateTime addedAt;

  /// When the user marked the sample as ordered.
  final DateTime? orderedAt;

  /// When the user confirmed samples arrived.
  final DateTime? arrivedAt;

  bool get isOrdered => orderedAt != null;
  bool get hasArrived => arrivedAt != null;
}
