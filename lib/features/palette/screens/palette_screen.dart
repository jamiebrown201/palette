import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/widgets/colour_disclaimer.dart';
import 'package:palette/core/widgets/palette_bottom_sheet.dart';
import 'package:palette/core/widgets/premium_gate.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/colour_dna_result.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/features/colour_wheel/providers/colour_wheel_providers.dart';
import 'package:palette/features/palette/providers/palette_providers.dart';
import 'package:palette/features/palette/widgets/colour_detail_sheet.dart';
import 'package:palette/features/palette/widgets/palette_grid.dart';
import 'package:palette/providers/database_providers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

enum _EditMode { none, swap, remove }

class PaletteScreen extends ConsumerStatefulWidget {
  const PaletteScreen({super.key});

  @override
  ConsumerState<PaletteScreen> createState() => _PaletteScreenState();
}

class _PaletteScreenState extends ConsumerState<PaletteScreen> {
  final _repaintKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareColourDna() async {
    setState(() => _isSharing = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      await Share.shareXFiles(
        [
          XFile.fromData(bytes,
              mimeType: 'image/png', name: 'colour-dna.png'),
        ],
        text:
            'I just discovered my Colour DNA! Take the quiz to find yours.',
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dnaResult = ref.watch(latestColourDnaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Palette'),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              )
            : null,
        actions: [
          if (dnaResult.valueOrNull != null)
            IconButton(
              onPressed: _isSharing ? null : _shareColourDna,
              tooltip: 'Share My Colour DNA',
              icon: _isSharing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share_outlined),
            ),
        ],
      ),
      body: dnaResult.when(
        data: (result) {
          if (result == null) {
            return _NoPaletteView(
              onTakeQuiz: () => context.go('/onboarding'),
            );
          }
          return _PaletteContent(
            result: result,
            repaintKey: _repaintKey,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _NoPaletteView extends StatelessWidget {
  const _NoPaletteView({required this.onTakeQuiz});

  final VoidCallback onTakeQuiz;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.palette_outlined,
              size: 64,
              color: PaletteColours.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Discover your colours',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Take the Colour DNA quiz to generate your personalised palette',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: PaletteColours.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onTakeQuiz,
              child: const Text('Take the Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteContent extends ConsumerStatefulWidget {
  const _PaletteContent({required this.result, this.repaintKey});

  final ColourDnaResult result;
  final GlobalKey? repaintKey;

  @override
  ConsumerState<_PaletteContent> createState() => _PaletteContentState();
}

class _PaletteContentState extends ConsumerState<_PaletteContent> {
  _EditMode _editMode = _EditMode.none;

  void _setEditMode(_EditMode mode) {
    setState(() => _editMode = _editMode == mode ? _EditMode.none : mode);
  }

  Future<void> _handleColourTap(String hex) async {
    switch (_editMode) {
      case _EditMode.none:
        await _showColourDetail(hex);
      case _EditMode.swap:
        await _swapColour(hex);
      case _EditMode.remove:
        await _removeColour(hex);
    }
  }

  Future<void> _addColour() async {
    final allPaints = await ref.read(allPaintColoursProvider.future);
    if (!mounted) return;

    final selected = await PaletteBottomSheet.show<PaintColour>(
      context: context,
      builder: (_) => _PaintColourPicker(
        title: 'Add a colour',
        paintColours: allPaints,
      ),
    );
    if (selected == null || !mounted) return;

    final result = widget.result;
    final paletteRepo = ref.read(paletteRepositoryProvider);
    final dnaRepo = ref.read(colourDnaRepositoryProvider);

    // Check for clash
    final warning = await paletteRepo.checkForClash(result.id, selected.hex);
    if (warning != null && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Heads up'),
          content: Text(warning),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    final hexes = [...result.colourHexes, selected.hex];
    await paletteRepo.insert(PaletteColoursCompanion.insert(
      id: const Uuid().v4(),
      colourDnaResultId: result.id,
      hex: selected.hex,
      sortOrder: result.colourHexes.length,
      isSurprise: false,
      addedAt: DateTime.now(),
      paintColourId: Value(selected.id),
    ));
    await dnaRepo.update(ColourDnaResultsCompanion(
      id: Value(result.id),
      colourHexes: Value(hexes),
    ));
    ref.invalidate(latestColourDnaProvider);
  }

  Future<void> _swapColour(String oldHex) async {
    final allPaints = await ref.read(allPaintColoursProvider.future);
    if (!mounted) return;

    final selected = await PaletteBottomSheet.show<PaintColour>(
      context: context,
      builder: (_) => _PaintColourPicker(
        title: 'Replace ${oldHex.toUpperCase()}',
        paintColours: allPaints,
      ),
    );
    if (selected == null || !mounted) return;

    final result = widget.result;
    final paletteRepo = ref.read(paletteRepositoryProvider);
    final dnaRepo = ref.read(colourDnaRepositoryProvider);

    // Get existing palette colours to find the one being swapped
    final existing = await paletteRepo.getForResult(result.id);
    final target = existing.where((e) => e.hex == oldHex).firstOrNull;

    if (target != null) {
      await paletteRepo.delete(target.id);
      await paletteRepo.insert(PaletteColoursCompanion.insert(
        id: const Uuid().v4(),
        colourDnaResultId: result.id,
        hex: selected.hex,
        sortOrder: target.sortOrder,
        isSurprise: false,
        addedAt: DateTime.now(),
        paintColourId: Value(selected.id),
      ));
    }

    final hexes = result.colourHexes
        .map((h) => h == oldHex ? selected.hex : h)
        .toList();
    await dnaRepo.update(ColourDnaResultsCompanion(
      id: Value(result.id),
      colourHexes: Value(hexes),
    ));
    ref.invalidate(latestColourDnaProvider);
    setState(() => _editMode = _EditMode.none);
  }

  Future<void> _removeColour(String hex) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove colour?'),
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _hexToColor(hex),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: PaletteColours.divider),
              ),
            ),
            const SizedBox(width: 12),
            Text(hex.toUpperCase()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = widget.result;
    final paletteRepo = ref.read(paletteRepositoryProvider);
    final dnaRepo = ref.read(colourDnaRepositoryProvider);

    final existing = await paletteRepo.getForResult(result.id);
    final target = existing.where((e) => e.hex == hex).firstOrNull;
    if (target != null) {
      await paletteRepo.delete(target.id);
    }

    final hexes = result.colourHexes.where((h) => h != hex).toList();
    await dnaRepo.update(ColourDnaResultsCompanion(
      id: Value(result.id),
      colourHexes: Value(hexes),
    ));
    ref.invalidate(latestColourDnaProvider);
    setState(() => _editMode = _EditMode.none);
  }

  Future<void> _showColourDetail(String hex) async {
    final paintRepo = ref.read(paintColourRepositoryProvider);
    final matches = await paintRepo.findClosestMatches(hex, limit: 5);
    if (!mounted) return;

    await PaletteBottomSheet.show<void>(
      context: context,
      builder: (context) => ColourDetailSheet(
        hex: hex,
        matches: matches,
        paintColourRepo: paintRepo,
        paletteHexes: widget.result.colourHexes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final colourHexes = result.colourHexes;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap shareable content in RepaintBoundary
          RepaintBoundary(
            key: widget.repaintKey,
            child: Container(
              color: PaletteColours.warmWhite,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Family badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: PaletteColours.sageGreenLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        result.primaryFamily.displayName,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: PaletteColours.sageGreenDark,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                  ),
                  if (result.secondaryFamily != null) ...[
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        'with ${result.secondaryFamily!.displayName} accents',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: PaletteColours.textSecondary,
                                ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Colour mosaic grid
                  PaletteGrid(
                    hexColours: colourHexes,
                    onColourTap: _handleColourTap,
                  ),
                ],
              ),
            ),
          ),

          // Edit mode instruction
          if (_editMode != _EditMode.none) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: PaletteColours.sageGreenLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _editMode == _EditMode.swap
                        ? Icons.swap_horiz
                        : Icons.remove_circle_outline,
                    size: 18,
                    color: PaletteColours.sageGreenDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _editMode == _EditMode.swap
                          ? 'Tap a colour to swap it'
                          : 'Tap a colour to remove it',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: PaletteColours.sageGreenDark,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _editMode = _EditMode.none),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Premium editing section
          PremiumGate(
            requiredTier: SubscriptionTier.plus,
            upgradeMessage: 'Upgrade to edit your palette',
            child: _PaletteEditActions(
              editMode: _editMode,
              onAdd: _addColour,
              onSwap: () => _setEditMode(_EditMode.swap),
              onRemove: () => _setEditMode(_EditMode.remove),
            ),
          ),
          const SizedBox(height: 24),
          const ColourDisclaimer(),
        ],
      ),
    );
  }
}

class _PaletteEditActions extends StatelessWidget {
  const _PaletteEditActions({
    required this.editMode,
    required this.onAdd,
    required this.onSwap,
    required this.onRemove,
  });

  final _EditMode editMode;
  final VoidCallback onAdd;
  final VoidCallback onSwap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: Icons.add_circle_outline,
          label: 'Add',
          isActive: false,
          onTap: onAdd,
        ),
        _ActionButton(
          icon: Icons.swap_horiz,
          label: 'Swap',
          isActive: editMode == _EditMode.swap,
          onTap: onSwap,
        ),
        _ActionButton(
          icon: Icons.remove_circle_outline,
          label: 'Remove',
          isActive: editMode == _EditMode.remove,
          onTap: onRemove,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label palette colour',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: isActive
              ? BoxDecoration(
                  color: PaletteColours.sageGreenLight,
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive
                    ? PaletteColours.sageGreenDark
                    : PaletteColours.sageGreen,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isActive ? PaletteColours.sageGreenDark : null,
                      fontWeight: isActive ? FontWeight.w600 : null,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaintColourPicker extends StatefulWidget {
  const _PaintColourPicker({
    required this.title,
    required this.paintColours,
  });

  final String title;
  final List<PaintColour> paintColours;

  @override
  State<_PaintColourPicker> createState() => _PaintColourPickerState();
}

class _PaintColourPickerState extends State<_PaintColourPicker> {
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
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filtered.length,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemBuilder: (ctx, i) {
                  final pc = _filtered[i];
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
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
