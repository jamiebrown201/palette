import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/features/colour_wheel/providers/colour_wheel_providers.dart';
import 'package:palette/features/palette/widgets/colour_detail_sheet.dart';

class PaintLibraryScreen extends ConsumerStatefulWidget {
  const PaintLibraryScreen({super.key});

  @override
  ConsumerState<PaintLibraryScreen> createState() =>
      _PaintLibraryScreenState();
}

class _PaintLibraryScreenState extends ConsumerState<PaintLibraryScreen> {
  String _searchQuery = '';
  String? _brandFilter;
  PaletteFamily? _familyFilter;
  Undertone? _undertoneFilter;

  @override
  Widget build(BuildContext context) {
    final allColoursAsync = ref.watch(allPaintColoursProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paint Library')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
          ),
          const SizedBox(height: 8),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterDropdown<String>(
                  label: 'Brand',
                  value: _brandFilter,
                  items: const [
                    'Farrow & Ball',
                    'Dulux',
                    'Little Greene',
                    'Benjamin Moore',
                    'Crown',
                  ],
                  onChanged: (v) => setState(() => _brandFilter = v),
                ),
                const SizedBox(width: 8),
                _FilterDropdown<PaletteFamily>(
                  label: 'Family',
                  value: _familyFilter,
                  items: PaletteFamily.values,
                  labelBuilder: (f) => f.displayName,
                  onChanged: (v) => setState(() => _familyFilter = v),
                ),
                const SizedBox(width: 8),
                _FilterDropdown<Undertone>(
                  label: 'Undertone',
                  value: _undertoneFilter,
                  items: Undertone.values,
                  labelBuilder: (u) => u.displayName,
                  onChanged: (v) => setState(() => _undertoneFilter = v),
                ),
                if (_hasFilters) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('Clear'),
                    onPressed: () => setState(() {
                      _brandFilter = null;
                      _familyFilter = null;
                      _undertoneFilter = null;
                      _searchQuery = '';
                    }),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Results
          Expanded(
            child: allColoursAsync.when(
              data: (allColours) {
                final filtered = _applyFilters(allColours);
                if (filtered.isEmpty) {
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
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _PaintColourTile(colour: filtered[index]),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasFilters =>
      _brandFilter != null ||
      _familyFilter != null ||
      _undertoneFilter != null ||
      _searchQuery.isNotEmpty;

  List<PaintColour> _applyFilters(List<PaintColour> colours) {
    var result = colours;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where((c) => c.name.toLowerCase().contains(query))
          .toList();
    }

    if (_brandFilter != null) {
      result = result.where((c) => c.brand == _brandFilter).toList();
    }

    if (_familyFilter != null) {
      result =
          result.where((c) => c.paletteFamily == _familyFilter).toList();
    }

    if (_undertoneFilter != null) {
      result =
          result.where((c) => c.undertone == _undertoneFilter).toList();
    }

    return result;
  }
}

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
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: items.map((item) {
            final itemLabel = labelBuilder?.call(item) ?? item.toString();
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

class _PaintColourTile extends StatelessWidget {
  const _PaintColourTile({required this.colour});

  final PaintColour colour;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _hexToColor(colour.hex),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PaletteColours.divider),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
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

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
