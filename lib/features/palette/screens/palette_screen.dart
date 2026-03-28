import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/colour_suggestions.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/core/colour/lab_colour.dart';
import 'package:palette/core/colour/palette_feedback.dart';
import 'package:palette/core/constants/branded_terms.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/widgets/colour_disclaimer.dart';
import 'package:palette/core/widgets/palette_bottom_sheet.dart';
import 'package:palette/core/widgets/premium_gate.dart';
import 'package:palette/core/widgets/smart_paint_colour_picker.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/colour_dna_result.dart';
import 'package:palette/data/models/paint_colour.dart';
import 'package:palette/features/colour_wheel/providers/colour_wheel_providers.dart';
import 'package:palette/features/onboarding/data/archetype_definitions.dart';
import 'package:palette/features/palette/providers/palette_providers.dart';
import 'package:palette/features/palette/widgets/colour_detail_sheet.dart';
import 'package:palette/features/palette/widgets/colour_review_sheet.dart';
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
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'image/png', name: 'colour-dna.png')],
        // ignore: require_trailing_commas
        text:
            'I just discovered my ${BrandedTerms.colourDna}! Take the quiz to find yours.',
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
        leading:
            Navigator.of(context).canPop()
                ? IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                )
                : null,
        actions: [
          if (dnaResult.valueOrNull != null)
            IconButton(
              onPressed: _isSharing ? null : _shareColourDna,
              tooltip: 'Share My ${BrandedTerms.colourDna}',
              icon:
                  _isSharing
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
            return _NoPaletteView(onTakeQuiz: () => context.go('/onboarding'));
          }
          return _PaletteContent(result: result, repaintKey: _repaintKey);
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
              'Take the ${BrandedTerms.colourDna} quiz to discover ${BrandedTerms.colourDnaSubtitle.toLowerCase()}',
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

    final suggestions = generateSuggestions(
      context: PickerContext(
        pickerRole: PickerRole.paletteAdd,
        existingPaletteHexes: widget.result.colourHexes,
        dnaHexes: widget.result.colourHexes,
      ),
      allPaints: allPaints,
    );

    final selected = await PaletteBottomSheet.show<PaintColour>(
      context: context,
      builder:
          (_) => SmartPaintColourPicker(
            title: 'Add a colour',
            paintColours: allPaints,
            suggestions: suggestions,
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
        builder:
            (ctx) => AlertDialog(
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
    await paletteRepo.insert(
      PaletteColoursCompanion.insert(
        id: const Uuid().v4(),
        colourDnaResultId: result.id,
        hex: selected.hex,
        sortOrder: result.colourHexes.length,
        isSurprise: false,
        addedAt: DateTime.now(),
        paintColourId: Value(selected.id),
      ),
    );
    await dnaRepo.update(
      ColourDnaResultsCompanion(
        id: Value(result.id),
        colourHexes: Value(hexes),
      ),
    );
    ref.invalidate(latestColourDnaProvider);

    // Show feedback about how the new colour relates to the palette.
    if (mounted) {
      final nameMap = _buildNameMap(allPaints, result.colourHexes);
      final feedback = describePaletteImpact(
        newHex: selected.hex,
        existingHexes: result.colourHexes,
        nameMap: nameMap,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(feedback), duration: const Duration(seconds: 3)),
      );
    }

    // Log interaction: palette colour added
    ref
        .read(colourInteractionRepositoryProvider)
        .logInteraction(
          id: const Uuid().v4(),
          interactionType: 'colourFavourited',
          hex: selected.hex,
          contextScreen: 'palette',
          paintId: selected.id,
        );
  }

  Future<void> _swapColour(String oldHex) async {
    final allPaints = await ref.read(allPaintColoursProvider.future);
    if (!mounted) return;

    final otherHexes =
        widget.result.colourHexes
            .where((h) => h.toLowerCase() != oldHex.toLowerCase())
            .toList();
    final suggestions = generateSuggestions(
      context: PickerContext(
        pickerRole: PickerRole.paletteAdd,
        existingPaletteHexes: otherHexes,
        dnaHexes: widget.result.colourHexes,
      ),
      allPaints: allPaints,
    );

    final selected = await PaletteBottomSheet.show<PaintColour>(
      context: context,
      builder:
          (_) => SmartPaintColourPicker(
            title:
                'Replace ${_buildNameMap(allPaints, [oldHex])[oldHex.toLowerCase()] ?? oldHex.toUpperCase()}',
            paintColours: allPaints,
            suggestions: suggestions,
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
      await paletteRepo.insert(
        PaletteColoursCompanion.insert(
          id: const Uuid().v4(),
          colourDnaResultId: result.id,
          hex: selected.hex,
          sortOrder: target.sortOrder,
          isSurprise: false,
          addedAt: DateTime.now(),
          paintColourId: Value(selected.id),
        ),
      );
    }

    final hexes =
        result.colourHexes.map((h) => h == oldHex ? selected.hex : h).toList();
    await dnaRepo.update(
      ColourDnaResultsCompanion(
        id: Value(result.id),
        colourHexes: Value(hexes),
      ),
    );
    ref.invalidate(latestColourDnaProvider);
    setState(() => _editMode = _EditMode.none);

    // Show feedback about how the new colour relates to the palette.
    if (mounted) {
      final otherHexesAfterSwap =
          result.colourHexes
              .where((h) => h.toLowerCase() != oldHex.toLowerCase())
              .toList();
      final nameMap = _buildNameMap(allPaints, otherHexesAfterSwap);
      final feedback = describePaletteImpact(
        newHex: selected.hex,
        existingHexes: otherHexesAfterSwap,
        nameMap: nameMap,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(feedback), duration: const Duration(seconds: 3)),
      );
    }

    // Log interaction: palette colour swapped
    ref
        .read(colourInteractionRepositoryProvider)
        .logInteraction(
          id: const Uuid().v4(),
          interactionType: 'colourSwapped',
          hex: selected.hex,
          contextScreen: 'palette',
          paintId: selected.id,
          previousHex: oldHex,
        );
  }

  Future<void> _removeColour(String hex) async {
    final roleInfo = describeColourRole(
      hex: hex,
      paletteHexes: widget.result.colourHexes,
    );

    // Look up paint name for display.
    final allPaints = await ref.read(allPaintColoursProvider.future);
    final displayName =
        _buildNameMap(allPaints, [hex])[hex.toLowerCase()] ?? hex.toUpperCase();
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Remove colour?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: hexToColor(hex),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: PaletteColours.divider),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(displayName),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
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
                          roleInfo.role,
                          style: Theme.of(ctx).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                if (roleInfo.warning != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    roleInfo.warning!,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: PaletteColours.softGoldDark,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
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
    await dnaRepo.update(
      ColourDnaResultsCompanion(
        id: Value(result.id),
        colourHexes: Value(hexes),
      ),
    );
    ref.invalidate(latestColourDnaProvider);
    setState(() => _editMode = _EditMode.none);

    // Log interaction: palette colour removed
    ref
        .read(colourInteractionRepositoryProvider)
        .logInteraction(
          id: const Uuid().v4(),
          interactionType: 'colourRemoved',
          hex: hex,
          contextScreen: 'palette',
        );
  }

  /// Build a lowercase-hex → paint-name map for user-friendly feedback.
  /// Uses exact match first, then closest delta-E match within threshold.
  static Map<String, String> _buildNameMap(
    List<PaintColour> allPaints,
    List<String> hexes,
  ) {
    final map = <String, String>{};
    final usedNames = <String>{};
    for (final hex in hexes) {
      // Try exact match first.
      final exact =
          allPaints
              .where((p) => p.hex.toLowerCase() == hex.toLowerCase())
              .firstOrNull;
      if (exact != null) {
        var name = exact.name;
        if (usedNames.contains(name)) {
          name = '${exact.name} (${exact.brand})';
        }
        map[hex.toLowerCase()] = name;
        usedNames.add(name);
        continue;
      }
      // Closest match within dE < 10 (using pre-computed Lab values).
      // Skip paints whose name is already taken by another hex.
      final lab = hexToLab(hex);
      final candidates = <(PaintColour, double)>[];
      for (final paint in allPaints) {
        final paintLab = LabColour(paint.labL, paint.labA, paint.labB);
        final dE = deltaE2000(lab, paintLab);
        if (dE < 10) {
          candidates.add((paint, dE));
        }
      }
      candidates.sort((a, b) => a.$2.compareTo(b.$2));
      for (final (paint, _) in candidates) {
        if (!usedNames.contains(paint.name)) {
          map[hex.toLowerCase()] = paint.name;
          usedNames.add(paint.name);
          break;
        }
      }
    }
    return map;
  }

  Future<void> _showColourDetail(String hex) async {
    final paintRepo = ref.read(paintColourRepositoryProvider);
    final matches = await paintRepo.findClosestMatches(hex, limit: 5);
    if (!mounted) return;

    await PaletteBottomSheet.show<void>(
      context: context,
      builder:
          (context) => ColourDetailSheet(
            hex: hex,
            matches: matches,
            paintColourRepo: paintRepo,
            paletteHexes: widget.result.colourHexes,
          ),
    );
  }

  Future<void> _openColourReview() async {
    final allPaints = await ref.read(allPaintColoursProvider.future);
    if (!mounted) return;

    final hexes = widget.result.colourHexes;
    final nameMap = _buildNameMap(allPaints, hexes);
    final health = analysePaletteHealth(hexes, nameMap: nameMap);
    final findings = deriveStructuredFindings(hexes, nameMap: nameMap);

    if (!mounted) return;

    await PaletteBottomSheet.show<void>(
      context: context,
      builder:
          (_) => ColourReviewSheet(
            hexes: hexes,
            nameMap: nameMap,
            health: health,
            findings: findings,
            onSwapColour: _swapColour,
            onAddColour: _addColour,
            onColourTap: _showColourDetail,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final colourHexes = result.colourHexes;
    final archetypeDef =
        result.archetype != null
            ? archetypeDefinitions[result.archetype]
            : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
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
                  // Archetype name or family badge
                  if (archetypeDef != null) ...[
                    Center(
                      child: Text(
                        archetypeDef.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        archetypeDef.headline,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: PaletteColours.sageGreenDark,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ] else ...[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: PaletteColours.sageGreenLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          result.primaryFamily.displayName,
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            color: PaletteColours.sageGreenDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (result.secondaryFamily != null) ...[
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        'with ${result.secondaryFamily!.displayName} accents',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

          // Archetype description
          if (archetypeDef != null) ...[
            const SizedBox(height: 16),
            Text(
              archetypeDef.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: PaletteColours.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PaletteColours.softCream,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why these colours work',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    archetypeDef.whyItWorks,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PaletteColours.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _DesignIdentityCard(archetypeDef: archetypeDef),
          ],

          // Palette story entry point
          if (colourHexes.length >= 2) ...[
            const SizedBox(height: 12),
            _PaletteStoryCard(hexes: colourHexes, onTap: _openColourReview),
          ],

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
                    onPressed: () => setState(() => _editMode = _EditMode.none),
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
            upgradeMessage:
                'Customise your palette to match your evolving taste',
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
          decoration:
              isActive
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
                color:
                    isActive
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

class _PaletteStoryCard extends ConsumerWidget {
  const _PaletteStoryCard({required this.hexes, required this.onTap});

  final List<String> hexes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPaintsAsync = ref.watch(allPaintColoursProvider);
    final nameMap = allPaintsAsync.when(
      data: (paints) => _PaletteContentState._buildNameMap(paints, hexes),
      loading: () => <String, String>{},
      error: (_, __) => <String, String>{},
    );

    final health = analysePaletteHealth(hexes, nameMap: nameMap);
    final hasIssues = health.hasIssues;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              hasIssues
                  ? PaletteColours.softGoldLight.withValues(alpha: 0.3)
                  : PaletteColours.sageGreenLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Mini swatches
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    children: [
                      for (final hex in hexes.take(6))
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: hexToColor(hex),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: PaletteColours.divider),
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: PaletteColours.textTertiary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              health.verdict,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              health.explanation,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PaletteColours.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DesignIdentityCard extends StatelessWidget {
  const _DesignIdentityCard({required this.archetypeDef});

  final ArchetypeDefinition archetypeDef;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PaletteColours.softCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 16,
                color: PaletteColours.softGoldDark,
              ),
              const SizedBox(width: 6),
              Text(
                'Your Design Identity',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Moods
          _GuidanceRow(
            icon: Icons.self_improvement,
            iconColor: PaletteColours.sageGreenDark,
            label: 'Your rooms should feel',
            value: archetypeDef.bestMoods.join(', '),
          ),
          const SizedBox(height: 10),

          // Surfaces & finishes group
          Text(
            'Surfaces & finishes',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: PaletteColours.textTertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          _GuidanceRow(
            icon: Icons.build_outlined,
            iconColor: PaletteColours.softGoldDark,
            label: 'Materials',
            value: archetypeDef.bestMaterials.join(', '),
          ),
          const SizedBox(height: 6),
          _GuidanceRow(
            icon: Icons.park_outlined,
            iconColor: PaletteColours.softGoldDark,
            label: 'Wood tones',
            value: archetypeDef.bestWoodTones.join(', '),
          ),
          const SizedBox(height: 6),
          _GuidanceRow(
            icon: Icons.hardware_outlined,
            iconColor: PaletteColours.softGoldDark,
            label: 'Metals',
            value: archetypeDef.bestMetalFinishes.join(', '),
          ),
          const SizedBox(height: 6),
          _GuidanceRow(
            icon: Icons.texture,
            iconColor: PaletteColours.softGoldDark,
            label: 'Fabrics',
            value: archetypeDef.bestFabrics.join(', '),
          ),
          const SizedBox(height: 12),

          // What to avoid — distinct styling
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: PaletteColours.warmGrey.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.visibility_off_outlined,
                  size: 15,
                  color: PaletteColours.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What to avoid',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: PaletteColours.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        archetypeDef.whatToAvoid,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PaletteColours.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidanceRow extends StatelessWidget {
  const _GuidanceRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PaletteColours.textSecondary,
              ),
              children: [
                TextSpan(
                  text: '$label  ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: PaletteColours.textPrimary,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
