import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette/core/analytics/analytics_events.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/core/colour/undertone.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/data/database/palette_database.dart';
import 'package:palette/data/models/moodboard.dart';
import 'package:palette/data/repositories/paint_colour_repository.dart';
import 'package:palette/features/moodboards/providers/moodboard_providers.dart';
import 'package:palette/features/palette/providers/palette_providers.dart';
import 'package:palette/providers/analytics_provider.dart';
import 'package:palette/providers/app_providers.dart';
import 'package:palette/providers/database_providers.dart';
import 'package:uuid/uuid.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  late final _picker = ImagePicker();
  bool _isProcessing = false;
  Color? _capturedColour;
  late String _capturedHex;
  List<PaintColourMatch>? _matches;

  /// Temperature adjustment: -1.0 (cooler) to 1.0 (warmer), default 0.
  double _temperatureShift = 0.0;

  /// Original captured colour before temperature nudge.
  Color? _originalColour;

  Future<void> _captureFromCamera() => _capture(ImageSource.camera);
  Future<void> _captureFromGallery() => _capture(ImageSource.gallery);

  Future<void> _capture(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      final bytes = await picked.readAsBytes();
      final colour = await _extractDominantColour(bytes);
      if (!mounted) return;

      _originalColour = colour;
      _temperatureShift = 0.0;
      await _updateColourAndMatches(colour);

      ref.read(analyticsProvider).track('colour_captured', {
        'source': source == ImageSource.camera ? 'camera' : 'gallery',
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not process image. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _updateColourAndMatches(Color colour) async {
    final r = (colour.r * 255).round();
    final g = (colour.g * 255).round();
    final b = (colour.b * 255).round();
    final hex =
        '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';

    final repo = ref.read(paintColourRepositoryProvider);
    final matches = await repo.findClosestMatches(hex, limit: 3);

    if (!mounted) return;
    setState(() {
      _capturedColour = colour;
      _capturedHex = hex.toUpperCase();
      _matches = matches;
      _isProcessing = false;
    });
  }

  /// K-means clustering to extract dominant colour from image bytes.
  Future<Color> _extractDominantColour(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final width = image.width;
    final height = image.height;
    image.dispose();

    if (byteData == null) return const Color(0xFF808080);

    // Sample pixels uniformly across the image (max ~2000 samples for speed).
    final totalPixels = width * height;
    final step = math.max(1, totalPixels ~/ 2000);
    final samples = <_RGB>[];

    for (var i = 0; i < totalPixels; i += step) {
      final offset = i * 4;
      if (offset + 2 >= byteData.lengthInBytes) break;
      final r = byteData.getUint8(offset);
      final g = byteData.getUint8(offset + 1);
      final b = byteData.getUint8(offset + 2);
      samples.add(_RGB(r.toDouble(), g.toDouble(), b.toDouble()));
    }

    if (samples.isEmpty) return const Color(0xFF808080);

    // K-means with k=3, pick the largest cluster's centroid.
    const k = 3;
    final centroids = _kMeans(samples, k, maxIterations: 10);

    // Pick the centroid with the most assigned samples.
    final counts = List.filled(k, 0);
    for (final sample in samples) {
      var bestIdx = 0;
      var bestDist = double.infinity;
      for (var c = 0; c < centroids.length; c++) {
        final d = centroids[c].distanceTo(sample);
        if (d < bestDist) {
          bestDist = d;
          bestIdx = c;
        }
      }
      counts[bestIdx]++;
    }

    var dominantIdx = 0;
    for (var i = 1; i < k; i++) {
      if (counts[i] > counts[dominantIdx]) dominantIdx = i;
    }

    final dominant = centroids[dominantIdx];
    return Color.fromARGB(
      255,
      dominant.r.round().clamp(0, 255),
      dominant.g.round().clamp(0, 255),
      dominant.b.round().clamp(0, 255),
    );
  }

  /// Simple k-means clustering on RGB values.
  List<_RGB> _kMeans(List<_RGB> points, int k, {int maxIterations = 10}) {
    if (points.length <= k) return List.of(points);

    final rng = math.Random(42);
    // Initialise centroids randomly from samples.
    final indices = <int>{};
    while (indices.length < k) {
      indices.add(rng.nextInt(points.length));
    }
    final centroids = indices.map((i) => _RGB.copy(points[i])).toList();

    for (var iter = 0; iter < maxIterations; iter++) {
      // Assign each point to nearest centroid.
      final sums = List.generate(k, (_) => _RGB(0, 0, 0));
      final counts = List.filled(k, 0);

      for (final p in points) {
        var bestIdx = 0;
        var bestDist = double.infinity;
        for (var c = 0; c < k; c++) {
          final d = centroids[c].distanceTo(p);
          if (d < bestDist) {
            bestDist = d;
            bestIdx = c;
          }
        }
        sums[bestIdx] = _RGB(
          sums[bestIdx].r + p.r,
          sums[bestIdx].g + p.g,
          sums[bestIdx].b + p.b,
        );
        counts[bestIdx]++;
      }

      // Update centroids.
      var converged = true;
      for (var c = 0; c < k; c++) {
        if (counts[c] == 0) continue;
        final newR = sums[c].r / counts[c];
        final newG = sums[c].g / counts[c];
        final newB = sums[c].b / counts[c];
        final moved =
            (centroids[c].r - newR).abs() +
            (centroids[c].g - newG).abs() +
            (centroids[c].b - newB).abs();
        if (moved > 1.0) converged = false;
        centroids[c] = _RGB(newR, newG, newB);
      }
      if (converged) break;
    }

    return centroids;
  }

  /// Apply a temperature shift to the original colour.
  Color _applyTemperatureShift(Color colour, double shift) {
    if (shift == 0) return colour;

    final r = (colour.r * 255).round();
    final g = (colour.g * 255).round();
    final b = (colour.b * 255).round();

    // Warm shift: boost red/yellow, reduce blue.
    // Cool shift: boost blue, reduce red/yellow.
    final amount = (shift.abs() * 30).round();
    int newR, newG, newB;

    if (shift > 0) {
      // Warmer
      newR = (r + amount).clamp(0, 255);
      newG = g;
      newB = (b - amount).clamp(0, 255);
    } else {
      // Cooler
      newR = (r - amount).clamp(0, 255);
      newG = g;
      newB = (b + amount).clamp(0, 255);
    }

    return Color.fromARGB(255, newR, newG, newB);
  }

  void _onTemperatureChanged(double value) {
    if (_originalColour == null) return;
    setState(() {
      _temperatureShift = value;
      _isProcessing = true;
    });

    final adjusted = _applyTemperatureShift(_originalColour!, value);
    _updateColourAndMatches(adjusted);
  }

  Future<void> _saveToMoodboard() async {
    final moodboards = ref.read(allMoodboardsProvider).valueOrNull;
    if (moodboards == null || moodboards.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a moodboard first to save colours.'),
        ),
      );
      return;
    }

    // If only one moodboard, save directly. Otherwise show picker.
    if (moodboards.length == 1) {
      await _addToMoodboard(moodboards.first.id, moodboards.first.name);
    } else {
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        builder:
            (ctx) => _MoodboardPickerSheet(
              moodboards: moodboards,
              onSelected: (id, name) {
                Navigator.pop(ctx);
                _addToMoodboard(id, name);
              },
            ),
      );
    }
  }

  Future<void> _addToMoodboard(String moodboardId, String name) async {
    final repo = ref.read(moodboardRepositoryProvider);
    final hexWithout = _capturedHex.replaceFirst('#', '');

    await repo.addItem(
      MoodboardItemsCompanion.insert(
        id: const Uuid().v4(),
        moodboardId: moodboardId,
        type: 'colour',
        colourHex: Value(hexWithout),
        colourName: Value('Captured colour $hexWithout'),
        sortOrder: 0,
        addedAt: DateTime.now(),
      ),
    );
    await repo.update(
      moodboardId,
      MoodboardsCompanion(updatedAt: Value(DateTime.now())),
    );

    ref.read(analyticsProvider).track(AnalyticsEvents.moodboardItemAdded, {
      'moodboard_id': moodboardId,
      'item_type': 'colour',
      'colour_hex': hexWithout,
      'source': 'colour_capture',
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Saved to $name')));
  }

  Future<void> _saveToPalette() async {
    final tier = ref.read(subscriptionTierProvider);
    if (tier.index < SubscriptionTier.plus.index) {
      // Show paywall prompt.
      if (!mounted) return;
      ref.read(analyticsProvider).track(AnalyticsEvents.paywallViewed, {
        'trigger': 'colour_capture_save_to_palette',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Upgrade to Palette Plus to save captured colours to your '
            'palette with clash warnings.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Premium user: check for clash and save.
    final dna = ref.read(latestColourDnaProvider).valueOrNull;
    if (dna == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete the Colour DNA quiz first.')),
      );
      return;
    }

    final paletteRepo = ref.read(paletteRepositoryProvider);
    final hexWithout = _capturedHex.replaceFirst('#', '');

    final clashWarning = await paletteRepo.checkForClash(dna.id, hexWithout);

    if (!mounted) return;

    if (clashWarning != null) {
      // Show clash warning dialog, let user proceed or cancel.
      final proceed = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Clash Warning'),
              content: Text(clashWarning),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Add Anyway'),
                ),
              ],
            ),
      );
      if (proceed != true || !mounted) return;
    }

    // Get existing palette count for sort order.
    final existing = await paletteRepo.getForResult(dna.id);
    await paletteRepo.insert(
      PaletteColoursCompanion.insert(
        id: const Uuid().v4(),
        colourDnaResultId: dna.id,
        hex: hexWithout,
        sortOrder: existing.length,
        isSurprise: false,
        addedAt: DateTime.now(),
      ),
    );

    ref.read(analyticsProvider).track(AnalyticsEvents.paletteEdited, {
      'action': 'add_colour',
      'source': 'colour_capture',
      'colour_hex': hexWithout,
      'had_clash_warning': clashWarning != null,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Colour added to your palette')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Colour Capture')),
      body:
          _isProcessing
              ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Analysing colour…'),
                  ],
                ),
              )
              : _capturedColour == null
              ? _buildEmptyState()
              : _buildResult(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: PaletteColours.softCream,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 40,
                color: PaletteColours.sageGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Capture a Colour',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Point your camera at any surface — a wall, a cushion, a '
              "favourite mug — and we'll find the closest paint matches.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: PaletteColours.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'For best results, capture in natural daylight.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: PaletteColours.textTertiary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildCaptureButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _captureFromCamera,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take Photo'),
            style: FilledButton.styleFrom(
              backgroundColor: PaletteColours.sageGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _captureFromGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose from Gallery'),
            style: OutlinedButton.styleFrom(
              foregroundColor: PaletteColours.sageGreen,
              side: const BorderSide(color: PaletteColours.sageGreen),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final lab = hexToLab(_capturedHex);
    final undertoneResult = classifyUndertone(lab);

    // Calculate palette fit.
    final dna = ref.watch(latestColourDnaProvider).valueOrNull;
    double? paletteFitDeltaE;
    if (dna != null) {
      final capturedLab = hexToLab(_capturedHex);
      var minDE = double.infinity;
      for (final hex in dna.colourHexes) {
        final palLab = hexToLab(hex);
        final dE = deltaE2000(capturedLab, palLab);
        if (dE < minDE) minDE = dE;
      }
      paletteFitDeltaE = minDE;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Captured colour swatch
        _buildCapturedSwatch(undertoneResult),
        const SizedBox(height: 16),

        // Palette fit indicator
        if (paletteFitDeltaE != null) ...[
          _buildPaletteFitCard(paletteFitDeltaE),
          const SizedBox(height: 16),
        ],

        // Nudge warmer/cooler slider
        _buildTemperatureSlider(),
        const SizedBox(height: 20),

        // Closest paint matches
        Text(
          'Closest Paint Matches',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (_matches != null)
          ...List.generate(_matches!.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMatchCard(_matches![i], i + 1),
            );
          }),
        const SizedBox(height: 16),

        // Save actions
        _buildSaveActions(),
        const SizedBox(height: 20),

        // Capture again buttons
        _buildCaptureButtons(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCapturedSwatch(UndertoneResult undertoneResult) {
    return Container(
      decoration: BoxDecoration(
        color: PaletteColours.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PaletteColours.divider),
      ),
      child: Column(
        children: [
          // Large colour swatch
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _capturedColour,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _capturedHex,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
          // Info row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Captured Colour',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildInfoChip(
                            undertoneResult.classification.displayName,
                            _undertoneIcon(undertoneResult.classification),
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(_capturedHex, Icons.palette_outlined),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _capturedHex));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Colour code copied'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.copy,
                    color: PaletteColours.textSecondary,
                  ),
                  tooltip: 'Copy hex code',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteFitCard(double deltaE) {
    final String label;
    final Color badgeColour;
    if (deltaE < 25) {
      label = 'Fits your palette';
      badgeColour = PaletteColours.statusPositive;
    } else if (deltaE < 40) {
      label = 'Near your palette';
      badgeColour = PaletteColours.statusWarning;
    } else {
      label = 'Outside your palette';
      badgeColour = PaletteColours.textTertiary;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: badgeColour.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: badgeColour.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            deltaE < 25
                ? Icons.check_circle_outline
                : deltaE < 40
                ? Icons.info_outline
                : Icons.warning_amber_outlined,
            color: badgeColour,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: badgeColour,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Palette fit',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PaletteColours.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColour.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${deltaEToMatchPercentage(deltaE).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: badgeColour,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaletteColours.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PaletteColours.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.thermostat_outlined,
                size: 18,
                color: PaletteColours.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Nudge warmer / cooler',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Adjust if the captured colour looks different from the '
            'real thing.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: PaletteColours.textTertiary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.ac_unit,
                size: 16,
                color: PaletteColours.statusPositive,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: PaletteColours.sageGreen,
                    inactiveTrackColor: PaletteColours.warmGrey,
                    thumbColor: PaletteColours.sageGreen,
                    overlayColor: PaletteColours.sageGreen.withValues(
                      alpha: 0.12,
                    ),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _temperatureShift,
                    min: -1.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: _onTemperatureChanged,
                  ),
                ),
              ),
              const Icon(
                Icons.wb_sunny_outlined,
                size: 16,
                color: PaletteColours.softGold,
              ),
            ],
          ),
          if (_temperatureShift != 0)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _onTemperatureChanged(0),
                child: const Text('Reset', style: TextStyle(fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSaveActions() {
    final tier = ref.watch(subscriptionTierProvider);
    final isPremium = tier.index >= SubscriptionTier.plus.index;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Save This Colour',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        // Save to moodboard — free for all users.
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _saveToMoodboard,
            icon: const Icon(Icons.dashboard_outlined, size: 18),
            label: const Text('Save to Moodboard'),
            style: OutlinedButton.styleFrom(
              foregroundColor: PaletteColours.sageGreen,
              side: const BorderSide(color: PaletteColours.sageGreen),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Save to palette — premium only.
        SizedBox(
          width: double.infinity,
          child:
              isPremium
                  ? FilledButton.icon(
                    onPressed: _saveToPalette,
                    icon: const Icon(Icons.palette_outlined, size: 18),
                    label: const Text('Save to Palette'),
                    style: FilledButton.styleFrom(
                      backgroundColor: PaletteColours.sageGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  )
                  : OutlinedButton.icon(
                    onPressed: _saveToPalette,
                    icon: const Icon(Icons.lock_outline, size: 18),
                    label: const Text('Save to Palette (Plus)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PaletteColours.textSecondary,
                      side: const BorderSide(color: PaletteColours.warmGrey),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: PaletteColours.softCream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: PaletteColours.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: PaletteColours.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _undertoneIcon(Undertone undertone) {
    return switch (undertone) {
      Undertone.warm => Icons.wb_sunny_outlined,
      Undertone.cool => Icons.ac_unit,
      Undertone.neutral => Icons.balance,
    };
  }

  Widget _buildMatchCard(PaintColourMatch match, int rank) {
    final paint = match.colour;
    final matchPercent = deltaEToMatchPercentage(match.deltaE);
    final parsedColour = _parseHex(paint.hex);
    final fitLevel = _fitLevel(match.deltaE);

    return Container(
      decoration: BoxDecoration(
        color: PaletteColours.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PaletteColours.divider),
      ),
      child: Row(
        children: [
          // Paint swatch
          Container(
            width: 72,
            height: 96,
            decoration: BoxDecoration(
              color: parsedColour,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
            ),
          ),
          // Paint info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          paint.name,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildFitBadge(matchPercent, fitLevel),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${paint.brand}  ·  ${paint.code}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PaletteColours.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildInfoChip(
                        paint.undertone.displayName,
                        _undertoneIcon(paint.undertone),
                      ),
                      const SizedBox(width: 8),
                      if (paint.approximatePricePerLitre != null)
                        _buildInfoChip(
                          '~£${paint.approximatePricePerLitre!.toStringAsFixed(0)}/L',
                          Icons.payments_outlined,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _FitLevel _fitLevel(double deltaE) {
    if (deltaE < 25) return _FitLevel.good;
    if (deltaE < 40) return _FitLevel.close;
    return _FitLevel.distant;
  }

  Widget _buildFitBadge(double matchPercent, _FitLevel level) {
    final (colour, label) = switch (level) {
      _FitLevel.good => (PaletteColours.statusPositive, 'Close match'),
      _FitLevel.close => (PaletteColours.statusWarning, 'Nearby'),
      _FitLevel.distant => (PaletteColours.textTertiary, 'Distant'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${matchPercent.toStringAsFixed(0)}% · $label',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colour,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _parseHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16) ?? 0x808080;
    return Color(0xFF000000 | value);
  }
}

enum _FitLevel { good, close, distant }

/// Simple RGB container for k-means clustering.
class _RGB {
  _RGB(this.r, this.g, this.b);
  _RGB.copy(_RGB other) : r = other.r, g = other.g, b = other.b;

  double r, g, b;

  double distanceTo(_RGB other) {
    final dr = r - other.r;
    final dg = g - other.g;
    final db = b - other.b;
    return dr * dr + dg * dg + db * db;
  }
}

/// Bottom sheet to pick which moodboard to save to.
class _MoodboardPickerSheet extends StatelessWidget {
  const _MoodboardPickerSheet({
    required this.moodboards,
    required this.onSelected,
  });

  final List<Moodboard> moodboards;
  final void Function(String id, String name) onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Save to Moodboard',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1),
          ...moodboards.map(
            (board) => ListTile(
              leading: const Icon(
                Icons.dashboard_outlined,
                color: PaletteColours.sageGreen,
              ),
              title: Text(board.name),
              onTap: () => onSelected(board.id, board.name),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
