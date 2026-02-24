import 'package:palette/core/constants/enums.dart';

/// A room profile in the user's home.
class Room {
  const Room({
    required this.id,
    required this.name,
    required this.usageTime,
    required this.moods,
    required this.budget,
    required this.isRenterMode,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.direction,
    this.heroColourHex,
    this.betaColourHex,
    this.surpriseColourHex,
    this.wallColourHex,
  });

  final String id;
  final String name;
  final CompassDirection? direction;
  final UsageTime usageTime;
  final List<RoomMood> moods;
  final BudgetBracket budget;
  final String? heroColourHex;
  final String? betaColourHex;
  final String? surpriseColourHex;
  final bool isRenterMode;
  final int sortOrder;
  final String? wallColourHex;
  final DateTime createdAt;
  final DateTime updatedAt;

  Room copyWith({
    String? id,
    String? name,
    CompassDirection? direction,
    UsageTime? usageTime,
    List<RoomMood>? moods,
    BudgetBracket? budget,
    String? heroColourHex,
    String? betaColourHex,
    String? surpriseColourHex,
    bool? isRenterMode,
    int? sortOrder,
    String? wallColourHex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      direction: direction ?? this.direction,
      usageTime: usageTime ?? this.usageTime,
      moods: moods ?? this.moods,
      budget: budget ?? this.budget,
      heroColourHex: heroColourHex ?? this.heroColourHex,
      betaColourHex: betaColourHex ?? this.betaColourHex,
      surpriseColourHex: surpriseColourHex ?? this.surpriseColourHex,
      isRenterMode: isRenterMode ?? this.isRenterMode,
      sortOrder: sortOrder ?? this.sortOrder,
      wallColourHex: wallColourHex ?? this.wallColourHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
