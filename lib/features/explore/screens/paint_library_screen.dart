import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/widgets/error_card.dart';
import 'package:palette/core/widgets/room_context_badge.dart';
import 'package:palette/data/models/colour_dna_result.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/colour_wheel/providers/colour_wheel_providers.dart';
import 'package:palette/features/explore/logic/paint_match.dart';
import 'package:palette/features/onboarding/data/archetype_definitions.dart';
import 'package:palette/features/palette/providers/palette_providers.dart';
import 'package:palette/features/palette/widgets/colour_detail_sheet.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';
import 'package:palette/providers/applied_state_provider.dart';

class PaintLibraryScreen extends ConsumerStatefulWidget {
  const PaintLibraryScreen({this.roomId, super.key});

  final String? roomId;

  @override
  ConsumerState<PaintLibraryScreen> createState() => _PaintLibraryScreenState();
}

class _PaintLibraryScreenState extends ConsumerState<PaintLibraryScreen> {
  late final TextEditingController _searchController;

  /// The key for the per-room filter provider (empty string = global).
  String get _filterKey => widget.roomId ?? '';

  @override
  void initState() {
    super.initState();
    final initial = ref.read(paintLibraryFiltersProvider(_filterKey));
    _searchController = TextEditingController(text: initial.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(paintLibraryFiltersProvider(_filterKey));
    final allColoursAsync = ref.watch(allPaintColoursProvider);
    final dnaAsync = ref.watch(latestColourDnaProvider);
    final roomsAsync = ref.watch(allRoomsProvider);

    final hasDna = dnaAsync.valueOrNull != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Paint Library')),
      body: Column(
        children: [
          // Room context badge (when accessed from a room)
          if (widget.roomId != null) RoomContextBadge(roomId: widget.roomId!),

          // Active filter summary chips
          if (filters.hasFilters)
            _AppliedFiltersSummary(
              filters: filters,
              onReset: () {
                ref
                    .read(paintLibraryFiltersProvider(_filterKey).notifier)
                    .state = PaintLibraryFilters.empty;
                _searchController.clear();
              },
            ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                ref
                    .read(paintLibraryFiltersProvider(_filterKey).notifier)
                    .state = filters.copyWith(searchQuery: v.trim());
              },
            ),
          ),
          const SizedBox(height: 8),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (hasDna) ...[
                  FilterChip(
                    avatar: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('My palette'),
                    selected: filters.paletteOnly,
                    onSelected: (v) {
                      ref
                          .read(
                            paintLibraryFiltersProvider(_filterKey).notifier,
                          )
                          .state = filters.copyWith(paletteOnly: v);
                    },
                    selectedColor: PaletteColours.sageGreenLight,
                  ),
                  const SizedBox(width: 8),
                ],
                _FilterDropdown<String>(
                  label: 'Brand',
                  value: filters.brand,
                  items: const [
                    'Farrow & Ball',
                    'Dulux',
                    'Little Greene',
                    'Benjamin Moore',
                    'Crown',
                  ],
                  onChanged: (v) {
                    ref
                        .read(paintLibraryFiltersProvider(_filterKey).notifier)
                        .state = filters.copyWith(brand: () => v);
                  },
                ),
                const SizedBox(width: 8),
                _FilterDropdown<PaletteFamily>(
                  label: 'Family',
                  value: filters.family,
                  items: PaletteFamily.values,
                  labelBuilder: (f) => f.displayName,
                  onChanged: (v) {
                    ref
                        .read(paintLibraryFiltersProvider(_filterKey).notifier)
                        .state = filters.copyWith(family: () => v);
                  },
                ),
                const SizedBox(width: 8),
                _FilterDropdown<Undertone>(
                  label: 'Undertone',
                  value: filters.undertone,
                  items: Undertone.values,
                  labelBuilder: (u) => u.displayName,
                  onChanged: (v) {
                    ref
                        .read(paintLibraryFiltersProvider(_filterKey).notifier)
                        .state = filters.copyWith(undertone: () => v);
                  },
                ),
                const SizedBox(width: 8),
                _FilterDropdown<PriceBracketFilter>(
                  label: 'Price',
                  value: filters.priceBracket,
                  items: PriceBracketFilter.values,
                  labelBuilder: (p) => p.label,
                  onChanged: (v) {
                    ref
                        .read(paintLibraryFiltersProvider(_filterKey).notifier)
                        .state = filters.copyWith(priceBracket: () => v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Results
          Expanded(
            child: allColoursAsync.when(
              data: (allColours) {
                final dna = dnaAsync.valueOrNull;
                final rooms = roomsAsync.valueOrNull ?? <Room>[];
                final results = _applyFiltersAndSort(
                  allColours,
                  filters: filters,
                  dna: dna,
                  rooms: rooms,
                );
                if (results.isEmpty) {
                  return Center(
                    child: Text(
                      'No colours match your filters',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: PaletteColours.textSecondary,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: results.length,
                  itemBuilder:
                      (context, index) =>
                          _PaintColourTile(result: results[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const ErrorCard(),
            ),
          ),
        ],
      ),
    );
  }

  List<PaintMatchResult> _applyFiltersAndSort(
    List<PaintColour> colours, {
    required PaintLibraryFilters filters,
    required ColourDnaResult? dna,
    required List<Room> rooms,
  }) {
    var filtered = colours;

    if (filters.searchQuery.isNotEmpty) {
      final query = filters.searchQuery.toLowerCase();
      filtered =
          filtered.where((c) => c.name.toLowerCase().contains(query)).toList();
    }

    if (filters.brand != null) {
      filtered = filtered.where((c) => c.brand == filters.brand).toList();
    }

    if (filters.family != null) {
      filtered =
          filtered.where((c) => c.paletteFamily == filters.family).toList();
    }

    if (filters.undertone != null) {
      filtered =
          filtered.where((c) => c.undertone == filters.undertone).toList();
    }

    if (filters.priceBracket != null) {
      filtered =
          filtered.where((c) {
            final price = c.approximatePricePerLitre;
            if (price == null) return false;
            return filters.priceBracket!.matches(price);
          }).toList();
    }

    // Compute match data.
    final paletteHexes = dna?.colourHexes ?? <String>[];
    final archetypeName =
        dna?.archetype != null
            ? archetypeDefinitions[dna!.archetype]?.name
            : null;
    final dnaUndertone = dna?.undertoneTemperature;

    var results = computePaintMatches(
      paints: filtered,
      paletteHexes: paletteHexes,
      dnaUndertone: dnaUndertone,
      archetypeName: archetypeName,
      rooms: rooms,
    );

    // Apply palette filter.
    if (filters.paletteOnly) {
      results = results.where((r) => r.isPaletteMatch).toList();
    }

    // Sort: palette matches first (by delta-E), then the rest.
    if (paletteHexes.isNotEmpty && filters.searchQuery.isEmpty) {
      results.sort((a, b) {
        if (a.isPaletteMatch && !b.isPaletteMatch) return -1;
        if (!a.isPaletteMatch && b.isPaletteMatch) return 1;
        if (a.bestDeltaE != null && b.bestDeltaE != null) {
          return a.bestDeltaE!.compareTo(b.bestDeltaE!);
        }
        return 0;
      });
    }

    return results;
  }
}

// ---------------------------------------------------------------------------
// Applied Filters Summary (persistent chips above results)
// ---------------------------------------------------------------------------

class _AppliedFiltersSummary extends StatelessWidget {
  const _AppliedFiltersSummary({required this.filters, required this.onReset});

  final PaintLibraryFilters filters;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (filters.searchQuery.isNotEmpty) {
      chips.add(_chip(context, '"${filters.searchQuery}"', Icons.search));
    }
    if (filters.brand != null) {
      chips.add(_chip(context, filters.brand!, Icons.palette_outlined));
    }
    if (filters.family != null) {
      chips.add(_chip(context, filters.family!.displayName, Icons.color_lens));
    }
    if (filters.undertone != null) {
      chips.add(
        _chip(context, filters.undertone!.displayName, Icons.thermostat),
      );
    }
    if (filters.priceBracket != null) {
      chips.add(
        _chip(context, filters.priceBracket!.label, Icons.attach_money),
      );
    }
    if (filters.paletteOnly) {
      chips.add(_chip(context, 'My palette', Icons.auto_awesome));
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          const Icon(
            Icons.filter_list,
            size: 16,
            color: PaletteColours.sageGreenDark,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final chip in chips) ...[chip, const SizedBox(width: 6)],
                ],
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Reset'),
            style: TextButton.styleFrom(
              foregroundColor: PaletteColours.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: PaletteColours.sageGreenLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: PaletteColours.sageGreenDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: PaletteColours.sageGreenDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter dropdown (unchanged)
// ---------------------------------------------------------------------------

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelBuilder,
  });

  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    final isActive = value != null;
    return FilterChip(
      label: Text(
        isActive ? (labelBuilder?.call(value as T) ?? value.toString()) : label,
      ),
      selected: isActive,
      onSelected: (_) {
        if (isActive) {
          onChanged(null);
        } else {
          _showPicker(context);
        }
      },
      selectedColor: PaletteColours.sageGreenLight,
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  items.map((item) {
                    final itemLabel =
                        labelBuilder?.call(item) ?? item.toString();
                    return ListTile(
                      title: Text(itemLabel),
                      onTap: () {
                        onChanged(item);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
            ),
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// Paint colour tile (unchanged)
// ---------------------------------------------------------------------------

class _PaintColourTile extends StatelessWidget {
  const _PaintColourTile({required this.result});

  final PaintMatchResult result;

  @override
  Widget build(BuildContext context) {
    final colour = result.paint;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hexToColor(colour.hex),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PaletteColours.divider),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      colour.undertone.badge,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      colour.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${colour.brand} \u2022 ${colour.paletteFamily.displayName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PaletteColours.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    colour.hex.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: PaletteColours.textTertiary,
                    ),
                  ),
                  if (colour.approximatePricePerLitre != null)
                    Text(
                      '\u00A3${colour.approximatePricePerLitre!.toStringAsFixed(0)}/L',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: PaletteColours.textTertiary,
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Match badge
          if (result.matchReason != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 60),
              child: _Badge(
                icon: Icons.auto_awesome,
                label: result.matchReason!,
                color: PaletteColours.sageGreenDark,
                bg: PaletteColours.sageGreenLight,
              ),
            ),
          // Room badges (max 2)
          for (final badge in result.roomBadges)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 60),
              child: _Badge(
                icon: Icons.meeting_room_outlined,
                label: badge,
                color: PaletteColours.softGoldDark,
                bg: PaletteColours.softGoldLight,
              ),
            ),
          if (colour.approximatePricePerLitre != null &&
              colour.priceLastChecked != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Prices approximate, last checked ${DateFormat.yMMMd().format(colour.priceLastChecked!)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: PaletteColours.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: BuyThisPaintButton(
              brand: colour.brand,
              colourCode: colour.code,
              colourName: colour.name,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
