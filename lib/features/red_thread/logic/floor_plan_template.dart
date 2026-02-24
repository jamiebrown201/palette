import 'dart:convert';

import 'package:flutter/services.dart';

/// A floor plan template for UK property types.
class FloorPlanTemplate {
  const FloorPlanTemplate({
    required this.id,
    required this.name,
    required this.propertyType,
    required this.propertyEra,
    required this.zones,
    required this.adjacencies,
  });

  factory FloorPlanTemplate.fromJson(Map<String, dynamic> json) {
    return FloorPlanTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      propertyType: json['propertyType'] as String,
      propertyEra: json['propertyEra'] as String,
      zones: (json['zones'] as List<dynamic>)
          .map((z) => FloorPlanZone.fromJson(z as Map<String, dynamic>))
          .toList(),
      adjacencies: (json['adjacencies'] as List<dynamic>)
          .map((a) => (a as List<dynamic>).cast<String>())
          .map((pair) => (pair[0], pair[1]))
          .toList(),
    );
  }

  final String id;
  final String name;
  final String propertyType;
  final String propertyEra;
  final List<FloorPlanZone> zones;
  final List<(String, String)> adjacencies;
}

/// A zone (room) within a floor plan template.
class FloorPlanZone {
  const FloorPlanZone({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory FloorPlanZone.fromJson(Map<String, dynamic> json) {
    return FloorPlanZone(
      id: json['id'] as String,
      name: json['name'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  final String id;
  final String name;
  final double x;
  final double y;
  final double width;
  final double height;
}

/// Load floor plan templates from the bundled asset.
Future<List<FloorPlanTemplate>> loadFloorPlanTemplates() async {
  final jsonString =
      await rootBundle.loadString('assets/data/floor_plan_templates.json');
  final data = json.decode(jsonString) as Map<String, dynamic>;
  final templates = data['templates'] as List<dynamic>;
  return templates
      .map((t) => FloorPlanTemplate.fromJson(t as Map<String, dynamic>))
      .toList();
}
