import 'package:palette/core/constants/enums.dart';

/// A piece of furniture locked into a room's colour plan.
///
/// Progressive data capture:
/// - Minimum viable (3 taps): name, category, status
/// - Enhanced: colourHex, material, woodTone, metalFinish, style, role
/// - Advanced: visualWeight, finishSheen, textureFeel
class LockedFurniture {
  const LockedFurniture({
    required this.id,
    required this.roomId,
    required this.name,
    required this.colourHex,
    required this.role,
    required this.sortOrder,
    this.category,
    this.status,
    this.material,
    this.woodTone,
    this.metalFinish,
    this.style,
    this.textureFeel,
    this.visualWeight,
    this.finishSheen,
  });

  final String id;
  final String roomId;
  final String name;
  final String colourHex;
  final FurnitureRole role;
  final int sortOrder;

  // Progressive capture fields
  final FurnitureCategory? category;
  final FurnitureStatus? status;
  final FurnitureMaterial? material;
  final WoodTone? woodTone;
  final MetalFinish? metalFinish;
  final FurnitureStyle? style;
  final TextureFeel? textureFeel;
  final VisualWeight? visualWeight;
  final FinishSheen? finishSheen;

  /// Whether this item has enhanced data beyond the minimum.
  bool get hasEnhancedData =>
      material != null || woodTone != null || metalFinish != null;

  /// Whether this item is something the user wants to keep or work around.
  bool get isKeeping =>
      status == null ||
      status == FurnitureStatus.keeping ||
      status == FurnitureStatus.mightReplace;

  /// A short summary line for display.
  String get summaryLine {
    final parts = <String>[];
    if (category != null) parts.add(category!.displayName);
    if (material != null) parts.add(material!.displayName);
    if (status != null && status != FurnitureStatus.keeping) {
      parts.add(status!.displayName);
    }
    return parts.isEmpty ? role.displayName : parts.join(' · ');
  }
}
