import 'package:palette/core/constants/enums.dart';

/// A paint colour from the database.
class PaintColour {
  const PaintColour({
    required this.id,
    required this.brand,
    required this.name,
    required this.code,
    required this.hex,
    required this.labL,
    required this.labA,
    required this.labB,
    required this.lrv,
    required this.undertone,
    required this.paletteFamily,
    this.collection,
    this.approximatePricePerLitre,
    this.priceLastChecked,
  });

  final String id;
  final String brand;
  final String name;
  final String code;
  final String hex;
  final double labL;
  final double labA;
  final double labB;
  final double lrv;
  final Undertone undertone;
  final PaletteFamily paletteFamily;
  final String? collection;
  final double? approximatePricePerLitre;
  final DateTime? priceLastChecked;

  PaintColour copyWith({
    String? id,
    String? brand,
    String? name,
    String? code,
    String? hex,
    double? labL,
    double? labA,
    double? labB,
    double? lrv,
    Undertone? undertone,
    PaletteFamily? paletteFamily,
    String? collection,
    double? approximatePricePerLitre,
    DateTime? priceLastChecked,
  }) {
    return PaintColour(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      name: name ?? this.name,
      code: code ?? this.code,
      hex: hex ?? this.hex,
      labL: labL ?? this.labL,
      labA: labA ?? this.labA,
      labB: labB ?? this.labB,
      lrv: lrv ?? this.lrv,
      undertone: undertone ?? this.undertone,
      paletteFamily: paletteFamily ?? this.paletteFamily,
      collection: collection ?? this.collection,
      approximatePricePerLitre:
          approximatePricePerLitre ?? this.approximatePricePerLitre,
      priceLastChecked: priceLastChecked ?? this.priceLastChecked,
    );
  }
}
