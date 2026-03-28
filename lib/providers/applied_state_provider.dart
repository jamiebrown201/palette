import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/constants/enums.dart';

/// Filter state for a room session in the Paint Library.
class PaintLibraryFilters {
  const PaintLibraryFilters({
    this.brand,
    this.family,
    this.undertone,
    this.priceBracket,
    this.paletteOnly = false,
    this.searchQuery = '',
  });

  final String? brand;
  final PaletteFamily? family;
  final Undertone? undertone;
  final PriceBracketFilter? priceBracket;
  final bool paletteOnly;
  final String searchQuery;

  bool get hasFilters =>
      brand != null ||
      family != null ||
      undertone != null ||
      priceBracket != null ||
      paletteOnly ||
      searchQuery.isNotEmpty;

  PaintLibraryFilters copyWith({
    String? Function()? brand,
    PaletteFamily? Function()? family,
    Undertone? Function()? undertone,
    PriceBracketFilter? Function()? priceBracket,
    bool? paletteOnly,
    String? searchQuery,
  }) {
    return PaintLibraryFilters(
      brand: brand != null ? brand() : this.brand,
      family: family != null ? family() : this.family,
      undertone: undertone != null ? undertone() : this.undertone,
      priceBracket: priceBracket != null ? priceBracket() : this.priceBracket,
      paletteOnly: paletteOnly ?? this.paletteOnly,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  static const empty = PaintLibraryFilters();
}

/// Price bracket filter for paint library.
enum PriceBracketFilter {
  budget,
  mid,
  premium;

  String get label => switch (this) {
    PriceBracketFilter.budget => '\u00A3',
    PriceBracketFilter.mid => '\u00A3\u00A3',
    PriceBracketFilter.premium => '\u00A3\u00A3\u00A3',
  };

  bool matches(double pricePerLitre) => switch (this) {
    PriceBracketFilter.budget => pricePerLitre < 25,
    PriceBracketFilter.mid => pricePerLitre >= 25 && pricePerLitre <= 50,
    PriceBracketFilter.premium => pricePerLitre > 50,
  };
}

/// Persists paint library filters per room session.
/// Key: roomId (or empty string for global/non-room context).
final paintLibraryFiltersProvider =
    StateProvider.family<PaintLibraryFilters, String>(
      (_, __) => PaintLibraryFilters.empty,
    );

/// Persists White Finder undertone filter per room session.
/// Key: roomId (or empty string for global/non-room context).
/// Value: the selected WhiteUndertone to filter by, or null for "show all".
final whiteFinderUndertoneFilterProvider =
    StateProvider.family<WhiteUndertone?, String>((_, __) => null);
