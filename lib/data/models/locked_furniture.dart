import 'package:palette/core/constants/enums.dart';

/// A piece of furniture locked into a room's colour plan.
class LockedFurniture {
  const LockedFurniture({
    required this.id,
    required this.roomId,
    required this.name,
    required this.colourHex,
    required this.role,
    required this.sortOrder,
  });

  final String id;
  final String roomId;
  final String name;
  final String colourHex;
  final FurnitureRole role;
  final int sortOrder;
}
