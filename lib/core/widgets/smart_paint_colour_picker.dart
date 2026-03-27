import 'package:flutter/material.dart';
import 'package:palette/core/colour/colour_suggestions.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/data/models/paint_colour.dart';

/// A paint colour picker bottom sheet with optional smart suggestions.
///
/// When [suggestions] are provided and the search query is empty,
/// a "Suggested for you" section appears above the full paint list.
/// When the user types, suggestions collapse and only search results show.
class SmartPaintColourPicker extends StatefulWidget {
  const SmartPaintColourPicker({
    required this.title,
    required this.paintColours,
    this.suggestions = const [],
    this.contextBanner,
    super.key,
  });

  final String title;
  final List<PaintColour> paintColours;
  final List<ColourSuggestion> suggestions;

  /// Optional context banner shown between the search field and suggestions.
  final String? contextBanner;

  @override
  State<SmartPaintColourPicker> createState() => _SmartPaintColourPickerState();
}

class _SmartPaintColourPickerState extends State<SmartPaintColourPicker> {
  String _query = '';

  List<PaintColour> get _filtered {
    if (_query.isEmpty) return widget.paintColours;
    final q = _query.toLowerCase();
    return widget.paintColours
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q) ||
            p.hex.toLowerCase().contains(q))
        .toList();
  }

  bool get _showSuggestions =>
      _query.isEmpty && widget.suggestions.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            // Header + search
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: PaletteColours.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by name, brand, or hex',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  if (widget.contextBanner != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: PaletteColours.softCream,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: PaletteColours.sageGreenDark,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.contextBanner!,
                              style: Theme.of(ctx)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: PaletteColours.sageGreenDark,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _itemCount,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemBuilder: _buildItem,
              ),
            ),
          ],
        );
      },
    );
  }

  int get _itemCount {
    if (!_showSuggestions) return _filtered.length;
    // suggestions header + suggestions + divider + all paints
    return 1 + widget.suggestions.length + 1 + widget.paintColours.length;
  }

  Widget _buildItem(BuildContext ctx, int index) {
    if (!_showSuggestions) {
      return _paintTile(ctx, _filtered[index]);
    }

    // Suggestions header
    if (index == 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome,
                size: 16, color: PaletteColours.sageGreen),
            const SizedBox(width: 6),
            Text(
              'Suggested for you',
              style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: PaletteColours.sageGreenDark,
                  ),
            ),
          ],
        ),
      );
    }

    // Suggestion tiles
    final suggestionIndex = index - 1;
    if (suggestionIndex < widget.suggestions.length) {
      return _suggestionTile(ctx, widget.suggestions[suggestionIndex]);
    }

    // Divider between suggestions and full list
    final dividerIndex = 1 + widget.suggestions.length;
    if (index == dividerIndex) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'All paints',
                style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                      color: PaletteColours.textTertiary,
                    ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
      );
    }

    // Regular paint list
    final paintIndex = index - dividerIndex - 1;
    if (paintIndex >= 0 && paintIndex < widget.paintColours.length) {
      return _paintTile(ctx, widget.paintColours[paintIndex]);
    }

    return const SizedBox.shrink();
  }

  Widget _suggestionTile(BuildContext ctx, ColourSuggestion suggestion) {
    final pc = suggestion.paint;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: PaletteColours.softCream,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _hexToColor(pc.hex),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: PaletteColours.divider),
          ),
        ),
        title: Text(
          pc.name,
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        subtitle: Text(
          suggestion.reason,
          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                color: PaletteColours.sageGreenDark,
              ),
        ),
        trailing: Text(
          pc.brand,
          style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                color: PaletteColours.textTertiary,
              ),
        ),
        onTap: () => Navigator.pop(ctx, pc),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        dense: true,
      ),
    );
  }

  Widget _paintTile(BuildContext ctx, PaintColour pc) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _hexToColor(pc.hex),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: PaletteColours.divider),
        ),
      ),
      title: Text(pc.name),
      subtitle: Text(pc.brand),
      trailing: Text(
        pc.hex.toUpperCase(),
        style: Theme.of(ctx).textTheme.labelSmall,
      ),
      onTap: () => Navigator.pop(ctx, pc),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
