import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/widgets/premium_gate.dart';
import 'package:palette/core/widgets/section_header.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/red_thread/logic/floor_plan_template.dart';
import 'package:palette/features/red_thread/providers/red_thread_providers.dart';
import 'package:palette/features/red_thread/widgets/floor_plan_painter.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';
import 'package:palette/providers/database_providers.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

class RedThreadScreen extends ConsumerStatefulWidget {
  const RedThreadScreen({super.key});

  @override
  ConsumerState<RedThreadScreen> createState() => _RedThreadScreenState();
}

class _RedThreadScreenState extends ConsumerState<RedThreadScreen> {
  FloorPlanTemplate? _selectedTemplate;
  final _repaintKey = GlobalKey();
  bool _isExporting = false;

  Future<void> _exportAsImage() async {
    setState(() => _isExporting = true);
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
          XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: 'red-thread.png',
          ),
        ],
        text: 'My Red Thread whole-house colour plan.',
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportAsPdf() async {
    setState(() => _isExporting = true);
    try {
      final rooms = ref.read(allRoomsProvider).valueOrNull ?? [];
      final threads =
          ref.read(threadColoursProvider).valueOrNull ?? [];

      final pdf = pw.Document()
        ..addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Red Thread — Whole-House Colour Plan',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),

                // Thread colours
                if (threads.isNotEmpty) ...[
                  pw.Text(
                    'Thread Colours',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: threads.map((t) {
                      final c = _pdfColourFromHex(t.hex);
                      return pw.Container(
                        width: 40,
                        height: 40,
                        margin: const pw.EdgeInsets.only(right: 8),
                        decoration: pw.BoxDecoration(
                          color: c,
                          border: pw.Border.all(
                            color: PdfColors.grey400,
                          ),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            t.hex.toUpperCase().replaceAll('#', ''),
                            style: pw.TextStyle(
                              fontSize: 6,
                              color: _isLightColour(t.hex)
                                  ? PdfColors.black
                                  : PdfColors.white,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  pw.SizedBox(height: 20),
                ],

                // Room breakdown
                pw.Text(
                  'Room Colour Plans',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                ...rooms.map((room) {
                  final hexes = [
                    if (room.heroColourHex != null)
                      ('Hero 70%', room.heroColourHex!),
                    if (room.betaColourHex != null)
                      ('Beta 20%', room.betaColourHex!),
                    if (room.surpriseColourHex != null)
                      ('Surprise 10%', room.surpriseColourHex!),
                  ];

                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 12),
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                room.name,
                                style: pw.TextStyle(
                                  fontSize: 13,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            if (room.direction != null)
                              pw.Text(
                                '${room.direction!.displayName}-facing',
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey600,
                                ),
                              ),
                          ],
                        ),
                        if (hexes.isNotEmpty) ...[
                          pw.SizedBox(height: 8),
                          pw.Row(
                            children: hexes.map((entry) {
                              final c = _pdfColourFromHex(entry.$2);
                              return pw.Expanded(
                                child: pw.Column(
                                  children: [
                                    pw.Container(
                                      height: 30,
                                      margin: const pw.EdgeInsets.symmetric(
                                          horizontal: 2),
                                      decoration: pw.BoxDecoration(
                                        color: c,
                                        border: pw.Border.all(
                                          color: PdfColors.grey300,
                                        ),
                                        borderRadius:
                                            pw.BorderRadius.circular(4),
                                      ),
                                    ),
                                    pw.SizedBox(height: 2),
                                    pw.Text(
                                      entry.$1,
                                      style: const pw.TextStyle(fontSize: 7),
                                    ),
                                    pw.Text(
                                      entry.$2.toUpperCase(),
                                      style: const pw.TextStyle(
                                        fontSize: 7,
                                        color: PdfColors.grey500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ] else
                          pw.Text(
                            'No colour plan assigned yet',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey500,
                            ),
                          ),
                      ],
                    ),
                  );
                }),

                pw.Spacer(),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Generated by Palette',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey400,
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'red-thread.pdf',
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(allRoomsProvider);
    final threadsAsync = ref.watch(threadColoursProvider);
    final templatesAsync = ref.watch(floorPlanTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Red Thread'),
        actions: [
          PremiumGate(
            requiredTier: SubscriptionTier.plus,
            upgradeMessage: 'Upgrade to export your Red Thread',
            child: _isExporting
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : PopupMenuButton<String>(
                    icon: const Icon(Icons.ios_share),
                    tooltip: 'Export',
                    onSelected: (value) {
                      if (value == 'image') {
                        _exportAsImage();
                      } else if (value == 'pdf') {
                        _exportAsPdf();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'image',
                        child: ListTile(
                          leading: Icon(Icons.image_outlined),
                          title: Text('Export as image'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'pdf',
                        child: ListTile(
                          leading: Icon(Icons.picture_as_pdf_outlined),
                          title: Text('Export as PDF'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      body: roomsAsync.when(
        data: (rooms) {
          // Show blurred preview for free users with 3+ rooms,
          // lock icon for free users with fewer rooms.
          return PremiumGate(
            requiredTier: SubscriptionTier.plus,
            upgradeMessage: rooms.length >= 3
                ? 'Unlock whole-house colour coherence'
                : 'Create 3+ rooms, then upgrade to see your Red Thread',
            child: threadsAsync.when(
              data: (threads) => templatesAsync.when(
                data: (templates) => RepaintBoundary(
                  key: _repaintKey,
                  child: _RedThreadContent(
                    rooms: rooms,
                    threadHexes: threads.map((t) => t.hex).toList(),
                    templates: templates,
                    selectedTemplate: _selectedTemplate,
                    onTemplateChanged: (t) =>
                        setState(() => _selectedTemplate = t),
                  ),
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _RedThreadContent extends ConsumerWidget {
  const _RedThreadContent({
    required this.rooms,
    required this.threadHexes,
    required this.templates,
    required this.selectedTemplate,
    required this.onTemplateChanged,
  });

  final List<Room> rooms;
  final List<String> threadHexes;
  final List<FloorPlanTemplate> templates;
  final FloorPlanTemplate? selectedTemplate;
  final ValueChanged<FloorPlanTemplate?> onTemplateChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rooms.length < 3) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.linear_scale,
                size: 64,
                color: PaletteColours.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'Add at least 3 rooms',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'The Red Thread works best when you have 3 or more rooms '
                'with colour plans assigned.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: PaletteColours.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thread colour selection
          const SectionHeader(title: 'Thread Colours'),
          const SizedBox(height: 4),
          Text(
            'Choose 2-4 unifying colours that will tie your rooms together.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PaletteColours.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          _ThreadColourRow(threadHexes: threadHexes),
          const SizedBox(height: 24),

          // Floor plan template
          const SectionHeader(title: 'Floor Plan'),
          const SizedBox(height: 8),
          _TemplatePicker(
            templates: templates,
            selected: selectedTemplate,
            onChanged: onTemplateChanged,
          ),
          if (selectedTemplate != null) ...[
            const SizedBox(height: 16),
            _FloorPlanView(
              template: selectedTemplate!,
              rooms: rooms,
              threadHexes: threadHexes,
            ),
          ],
          const SizedBox(height: 24),

          // Coherence check
          if (threadHexes.isNotEmpty) ...[
            const SectionHeader(title: 'Coherence Check'),
            const SizedBox(height: 8),
            _CoherenceSection(rooms: rooms),
          ],

          // Adjacent comparison
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Room Transitions',
            actionLabel: 'Define connections',
            onAction: () => _showAdjacencySheet(context, ref, rooms),
          ),
          const SizedBox(height: 8),
          _AdjacentRoomComparison(rooms: rooms, threadHexes: threadHexes),
        ],
      ),
    );
  }

  void _showAdjacencySheet(
    BuildContext context,
    WidgetRef ref,
    List<Room> rooms,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => _AdjacencySheet(
          rooms: rooms,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Adjacency sheet – lets users define which rooms connect to each other.
// ---------------------------------------------------------------------------

class _AdjacencySheet extends ConsumerWidget {
  const _AdjacencySheet({
    required this.rooms,
    required this.scrollController,
  });

  final List<Room> rooms;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairsAsync = ref.watch(adjacentRoomPairsProvider);
    final repo = ref.read(redThreadRepositoryProvider);

    return Column(
      children: [
        // Drag handle
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: PaletteColours.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Room Connections',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddConnectionDialog(
                  context,
                  ref,
                  rooms,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Define which rooms connect to each other so transitions '
            'can be checked.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PaletteColours.textSecondary,
                ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: pairsAsync.when(
            data: (pairs) {
              if (pairs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.swap_horiz,
                        size: 48,
                        color: PaletteColours.textTertiary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No connections defined yet',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: PaletteColours.textSecondary,
                                ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () => _showAddConnectionDialog(
                          context,
                          ref,
                          rooms,
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add connection'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: pairs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final pair = pairs[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.compare_arrows,
                      color: PaletteColours.sageGreen,
                    ),
                    title: Text(
                      '${pair.$1.name}  \u2194  ${pair.$2.name}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () async {
                        final adjacencies = await repo.getAdjacencies();
                        final match = adjacencies.where((a) {
                          return (a.roomIdA == pair.$1.id &&
                                  a.roomIdB == pair.$2.id) ||
                              (a.roomIdA == pair.$2.id &&
                                  a.roomIdB == pair.$1.id);
                        }).firstOrNull;
                        if (match != null) {
                          await repo.deleteAdjacency(match.id);
                          ref.invalidate(adjacentRoomPairsProvider);
                        }
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  void _showAddConnectionDialog(
    BuildContext context,
    WidgetRef ref,
    List<Room> rooms,
  ) {
    if (rooms.length < 2) return;

    Room? roomA;
    Room? roomB;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Connection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Room A',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Room>(
                    isExpanded: true,
                    isDense: true,
                    hint: const Text('Select room'),
                    items: rooms
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.name),
                            ))
                        .toList(),
                    value: roomA,
                    onChanged: (v) => setDialogState(() {
                      roomA = v;
                      // Reset Room B if it conflicts
                      if (roomB?.id == v?.id) roomB = null;
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Room B',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Room>(
                    isExpanded: true,
                    isDense: true,
                    hint: const Text('Select room'),
                    items: rooms
                        .where((r) => r.id != roomA?.id)
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.name),
                            ))
                        .toList(),
                    value: roomB,
                    onChanged: (v) => setDialogState(() => roomB = v),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: (roomA != null && roomB != null)
                  ? () async {
                      final repo = ref.read(redThreadRepositoryProvider);
                      await repo.insertAdjacency(
                        RoomAdjacenciesCompanion.insert(
                          id: const Uuid().v4(),
                          roomIdA: roomA!.id,
                          roomIdB: roomB!.id,
                        ),
                      );
                      ref.invalidate(adjacentRoomPairsProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  : null,
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Thread colour row
// ---------------------------------------------------------------------------

class _ThreadColourRow extends ConsumerWidget {
  const _ThreadColourRow({required this.threadHexes});

  final List<String> threadHexes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ...threadHexes.map((hex) => _ThreadSwatch(
              hex: hex,
              onDelete: () async {
                final repo = ref.read(redThreadRepositoryProvider);
                final threads = await repo.getThreadColours();
                final match = threads.where((t) => t.hex == hex).firstOrNull;
                if (match != null) {
                  await repo.deleteThreadColour(match.id);
                }
              },
            )),
        if (threadHexes.length < 4)
          _AddThreadButton(
            onAdd: () => _showColourPicker(context, ref),
          ),
      ],
    );
  }

  void _showColourPicker(BuildContext context, WidgetRef ref) {
    // Simple hex input dialog
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Thread Colour'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '#AABBCC',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final hex = controller.text.trim();
              if (hex.length >= 6) {
                final normalised =
                    hex.startsWith('#') ? hex : '#$hex';
                final repo = ref.read(redThreadRepositoryProvider);
                final threads = await repo.getThreadColours();
                await repo.insertThreadColour(
                  RedThreadColoursCompanion.insert(
                    id: const Uuid().v4(),
                    hex: normalised,
                    sortOrder: threads.length,
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _ThreadSwatch extends StatelessWidget {
  const _ThreadSwatch({
    required this.hex,
    required this.onDelete,
  });

  final String hex;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onDelete,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _hexToColor(hex),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: PaletteColours.divider, width: 2),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(6)),
            ),
            child: Text(
              hex.toUpperCase().replaceAll('#', ''),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddThreadButton extends StatelessWidget {
  const _AddThreadButton({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: PaletteColours.warmGrey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: PaletteColours.divider,
            width: 2,
          ),
        ),
        child: const Icon(Icons.add, color: PaletteColours.textTertiary),
      ),
    );
  }
}

class _TemplatePicker extends StatelessWidget {
  const _TemplatePicker({
    required this.templates,
    required this.selected,
    required this.onChanged,
  });

  final List<FloorPlanTemplate> templates;
  final FloorPlanTemplate? selected;
  final ValueChanged<FloorPlanTemplate?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: templates.map((t) {
        final isSelected = selected?.id == t.id;
        return ChoiceChip(
          label: Text(t.name),
          selected: isSelected,
          onSelected: (_) => onChanged(isSelected ? null : t),
          selectedColor: PaletteColours.sageGreenLight,
        );
      }).toList(),
    );
  }
}

class _FloorPlanView extends StatelessWidget {
  const _FloorPlanView({
    required this.template,
    required this.rooms,
    required this.threadHexes,
  });

  final FloorPlanTemplate template;
  final List<Room> rooms;
  final List<String> threadHexes;

  @override
  Widget build(BuildContext context) {
    // Map template zones to room hero colours by matching names
    final roomByName = <String, Room>{};
    for (final room in rooms) {
      roomByName[room.name.toLowerCase()] = room;
    }

    final colourMap = <String, String?>{};
    for (final zone in template.zones) {
      final matchedRoom = roomByName[zone.name.toLowerCase()];
      colourMap[zone.id] = matchedRoom?.heroColourHex;
    }

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: PaletteColours.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PaletteColours.divider),
      ),
      padding: const EdgeInsets.all(16),
      child: CustomPaint(
        painter: FloorPlanPainter(
          template: template,
          roomColours: colourMap,
          threadHexes: threadHexes,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _CoherenceSection extends ConsumerWidget {
  const _CoherenceSection({required this.rooms});

  final List<Room> rooms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(coherenceReportProvider);

    return reportAsync.when(
      data: (report) {
        if (report.results.isEmpty) {
          return Text(
            'Add thread colours and assign room palettes to check coherence.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PaletteColours.textSecondary,
                ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: report.overallCoherent
                    ? PaletteColours.sageGreenLight
                    : PaletteColours.softGoldLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    report.overallCoherent
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_outlined,
                    color: report.overallCoherent
                        ? PaletteColours.sageGreenDark
                        : PaletteColours.softGoldDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      report.overallCoherent
                          ? 'All rooms are connected by your thread colours!'
                          : '${report.disconnectedCount} room${report.disconnectedCount == 1 ? '' : 's'} '
                              'not yet connected to the thread.',
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Per-room results
            ...report.results.map((result) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        result.isConnected
                            ? Icons.link
                            : Icons.link_off,
                        size: 16,
                        color: result.isConnected
                            ? PaletteColours.sageGreen
                            : PaletteColours.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.roomName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      if (result.matchingThreadHex != null)
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _hexToColor(result.matchingThreadHex!),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: PaletteColours.divider),
                          ),
                        ),
                    ],
                  ),
                )),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }
}

// ---------------------------------------------------------------------------
// Adjacent room comparison – now backed by real adjacency data.
// ---------------------------------------------------------------------------

class _AdjacentRoomComparison extends ConsumerWidget {
  const _AdjacentRoomComparison({
    required this.rooms,
    required this.threadHexes,
  });

  final List<Room> rooms;
  final List<String> threadHexes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rooms.length < 2) {
      return Text(
        'Add more rooms to see how adjacent spaces relate.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PaletteColours.textSecondary,
            ),
      );
    }

    final pairsAsync = ref.watch(adjacentRoomPairsProvider);

    return pairsAsync.when(
      data: (pairs) {
        if (pairs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PaletteColours.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PaletteColours.divider),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.swap_horiz,
                  size: 32,
                  color: PaletteColours.textTertiary,
                ),
                const SizedBox(height: 8),
                Text(
                  'No room connections defined yet.\n'
                  'Tap "Define connections" above to get started.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PaletteColours.textSecondary,
                      ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: pairs.map((pair) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RoomPairCard(
                roomA: pair.$1,
                roomB: pair.$2,
                threadHexes: threadHexes,
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }
}

class _RoomPairCard extends StatelessWidget {
  const _RoomPairCard({
    required this.roomA,
    required this.roomB,
    required this.threadHexes,
  });

  final Room roomA;
  final Room roomB;
  final List<String> threadHexes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PaletteColours.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PaletteColours.divider),
      ),
      child: Row(
        children: [
          Expanded(child: _MiniRoomPalette(room: roomA)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.compare_arrows,
              size: 20,
              color: PaletteColours.textTertiary,
            ),
          ),
          Expanded(child: _MiniRoomPalette(room: roomB)),
        ],
      ),
    );
  }
}

class _MiniRoomPalette extends StatelessWidget {
  const _MiniRoomPalette({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    final hexes = [
      room.heroColourHex,
      room.betaColourHex,
      room.surpriseColourHex,
    ].whereType<String>().toList();

    return Column(
      children: [
        Text(
          room.name,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: hexes.isEmpty
              ? [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: PaletteColours.warmGrey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ]
              : hexes
                  .map((hex) => Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: _hexToColor(hex),
                          borderRadius: BorderRadius.circular(4),
                          border:
                              Border.all(color: PaletteColours.divider),
                        ),
                      ))
                  .toList(),
        ),
      ],
    );
  }
}

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}

PdfColor _pdfColourFromHex(String hex) {
  final cleaned = hex.replaceAll('#', '');
  final value = int.parse(cleaned, radix: 16);
  return PdfColor(
    ((value >> 16) & 0xFF) / 255.0,
    ((value >> 8) & 0xFF) / 255.0,
    (value & 0xFF) / 255.0,
  );
}

bool _isLightColour(String hex) {
  final cleaned = hex.replaceAll('#', '');
  final value = int.parse(cleaned, radix: 16);
  final r = (value >> 16) & 0xFF;
  final g = (value >> 8) & 0xFF;
  final b = value & 0xFF;
  // Relative luminance approximation
  return (0.299 * r + 0.587 * g + 0.114 * b) > 186;
}
