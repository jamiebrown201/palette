import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/providers/applied_state_provider.dart';

void main() {
  group('PaintLibraryFilters', () {
    test('empty filters have no active filters', () {
      const filters = PaintLibraryFilters.empty;
      expect(filters.hasFilters, isFalse);
    });

    test('setting brand makes hasFilters true', () {
      const filters = PaintLibraryFilters(brand: 'Dulux');
      expect(filters.hasFilters, isTrue);
    });

    test('setting family makes hasFilters true', () {
      const filters = PaintLibraryFilters(family: PaletteFamily.pastels);
      expect(filters.hasFilters, isTrue);
    });

    test('setting undertone makes hasFilters true', () {
      const filters = PaintLibraryFilters(undertone: Undertone.warm);
      expect(filters.hasFilters, isTrue);
    });

    test('setting paletteOnly makes hasFilters true', () {
      const filters = PaintLibraryFilters(paletteOnly: true);
      expect(filters.hasFilters, isTrue);
    });

    test('setting searchQuery makes hasFilters true', () {
      const filters = PaintLibraryFilters(searchQuery: 'sage');
      expect(filters.hasFilters, isTrue);
    });

    test('copyWith replaces brand', () {
      const original = PaintLibraryFilters(brand: 'Dulux');
      final updated = original.copyWith(brand: () => 'Crown');
      expect(updated.brand, 'Crown');
    });

    test('copyWith clears brand with null', () {
      const original = PaintLibraryFilters(brand: 'Dulux');
      final updated = original.copyWith(brand: () => null);
      expect(updated.brand, isNull);
    });

    test('copyWith preserves other fields', () {
      const original = PaintLibraryFilters(
        brand: 'Dulux',
        family: PaletteFamily.brights,
        searchQuery: 'test',
      );
      final updated = original.copyWith(brand: () => 'Crown');
      expect(updated.family, PaletteFamily.brights);
      expect(updated.searchQuery, 'test');
    });
  });

  group('PriceBracketFilter', () {
    test('budget matches under 25', () {
      expect(PriceBracketFilter.budget.matches(20), isTrue);
      expect(PriceBracketFilter.budget.matches(25), isFalse);
    });

    test('mid matches 25 to 50', () {
      expect(PriceBracketFilter.mid.matches(25), isTrue);
      expect(PriceBracketFilter.mid.matches(40), isTrue);
      expect(PriceBracketFilter.mid.matches(50), isTrue);
      expect(PriceBracketFilter.mid.matches(51), isFalse);
    });

    test('premium matches over 50', () {
      expect(PriceBracketFilter.premium.matches(51), isTrue);
      expect(PriceBracketFilter.premium.matches(50), isFalse);
    });

    test('labels use pound signs', () {
      expect(PriceBracketFilter.budget.label, '\u00A3');
      expect(PriceBracketFilter.mid.label, '\u00A3\u00A3');
      expect(PriceBracketFilter.premium.label, '\u00A3\u00A3\u00A3');
    });
  });

  group('paintLibraryFiltersProvider', () {
    test('defaults to empty filters for any room key', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final filters = container.read(paintLibraryFiltersProvider('room-1'));
      expect(filters.hasFilters, isFalse);
    });

    test('persists filters per room key independently', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set filter for room-1
      container
          .read(paintLibraryFiltersProvider('room-1').notifier)
          .state = const PaintLibraryFilters(brand: 'Dulux');

      // Set filter for room-2
      container
          .read(paintLibraryFiltersProvider('room-2').notifier)
          .state = const PaintLibraryFilters(brand: 'Crown');

      expect(
        container.read(paintLibraryFiltersProvider('room-1')).brand,
        'Dulux',
      );
      expect(
        container.read(paintLibraryFiltersProvider('room-2')).brand,
        'Crown',
      );
    });

    test('global key (empty string) is independent of room keys', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(paintLibraryFiltersProvider('').notifier)
          .state = const PaintLibraryFilters(family: PaletteFamily.darks);

      container
          .read(paintLibraryFiltersProvider('room-1').notifier)
          .state = const PaintLibraryFilters(family: PaletteFamily.brights);

      expect(
        container.read(paintLibraryFiltersProvider('')).family,
        PaletteFamily.darks,
      );
      expect(
        container.read(paintLibraryFiltersProvider('room-1')).family,
        PaletteFamily.brights,
      );
    });
  });

  group('whiteFinderUndertoneFilterProvider', () {
    test('defaults to null (show all)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final filter = container.read(
        whiteFinderUndertoneFilterProvider('room-1'),
      );
      expect(filter, isNull);
    });

    test('persists selection per room', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(whiteFinderUndertoneFilterProvider('room-1').notifier)
          .state = WhiteUndertone.blue;

      container
          .read(whiteFinderUndertoneFilterProvider('room-2').notifier)
          .state = WhiteUndertone.yellow;

      expect(
        container.read(whiteFinderUndertoneFilterProvider('room-1')),
        WhiteUndertone.blue,
      );
      expect(
        container.read(whiteFinderUndertoneFilterProvider('room-2')),
        WhiteUndertone.yellow,
      );
    });
  });
}
