import 'dart:convert';

/// A reference to a specific paint colour within the system palette.
class PaintReference {
  const PaintReference({
    required this.paintId,
    required this.hex,
    required this.name,
    required this.brand,
    required this.role,
    this.roleLabel,
  });

  final String paintId;
  final String hex;
  final String name;
  final String brand;
  final String role;
  final String? roleLabel;

  Map<String, dynamic> toMap() => {
    'paintId': paintId,
    'hex': hex,
    'name': name,
    'brand': brand,
    'role': role,
    if (roleLabel != null) 'roleLabel': roleLabel,
  };

  factory PaintReference.fromMap(Map<String, dynamic> map) => PaintReference(
    paintId: map['paintId'] as String,
    hex: map['hex'] as String,
    name: map['name'] as String,
    brand: map['brand'] as String,
    role: map['role'] as String,
    roleLabel: map['roleLabel'] as String?,
  );
}

/// A structured role-based palette generated from Colour DNA quiz results.
///
/// Roles:
/// - **trimWhite**: The white/off-white for ceilings and trim
/// - **dominantWalls**: 1-2 colours for primary wall colour
/// - **supportingWalls**: 2-3 colours for adjacent/secondary rooms
/// - **deepAnchor**: 1 darker colour for grounding (feature walls, furniture)
/// - **accentPops**: 0-2 vivid accent colours
/// - **spineColour**: 1 neutral connector that ties rooms together
class SystemPalette {
  const SystemPalette({
    required this.trimWhite,
    required this.dominantWalls,
    required this.supportingWalls,
    required this.deepAnchor,
    required this.accentPops,
    required this.spineColour,
  });

  final PaintReference trimWhite;
  final List<PaintReference> dominantWalls;
  final List<PaintReference> supportingWalls;
  final PaintReference deepAnchor;
  final List<PaintReference> accentPops;
  final PaintReference spineColour;

  /// Convert to a flat list of hex colours for backward compatibility.
  List<String> toColourHexes() {
    final hexes = <String>[
      trimWhite.hex,
      ...dominantWalls.map((r) => r.hex),
      ...supportingWalls.map((r) => r.hex),
      deepAnchor.hex,
      ...accentPops.map((r) => r.hex),
      spineColour.hex,
    ];
    // Deduplicate preserving order
    final seen = <String>{};
    return hexes.where((h) => seen.add(h)).toList();
  }

  /// Serialize to JSON string for database storage.
  String toJson() => jsonEncode(toMap());

  Map<String, dynamic> toMap() => {
    'trimWhite': trimWhite.toMap(),
    'dominantWalls': dominantWalls.map((r) => r.toMap()).toList(),
    'supportingWalls': supportingWalls.map((r) => r.toMap()).toList(),
    'deepAnchor': deepAnchor.toMap(),
    'accentPops': accentPops.map((r) => r.toMap()).toList(),
    'spineColour': spineColour.toMap(),
  };

  /// Deserialize from JSON string.
  factory SystemPalette.fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return SystemPalette.fromMap(map);
  }

  factory SystemPalette.fromMap(Map<String, dynamic> map) => SystemPalette(
    trimWhite: PaintReference.fromMap(map['trimWhite'] as Map<String, dynamic>),
    dominantWalls:
        (map['dominantWalls'] as List<dynamic>)
            .map((e) => PaintReference.fromMap(e as Map<String, dynamic>))
            .toList(),
    supportingWalls:
        (map['supportingWalls'] as List<dynamic>)
            .map((e) => PaintReference.fromMap(e as Map<String, dynamic>))
            .toList(),
    deepAnchor: PaintReference.fromMap(
      map['deepAnchor'] as Map<String, dynamic>,
    ),
    accentPops:
        (map['accentPops'] as List<dynamic>)
            .map((e) => PaintReference.fromMap(e as Map<String, dynamic>))
            .toList(),
    spineColour: PaintReference.fromMap(
      map['spineColour'] as Map<String, dynamic>,
    ),
  );
}
