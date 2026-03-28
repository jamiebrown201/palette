import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/colour/delta_e.dart';
import 'package:palette/core/colour/undertone.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/data/repositories/paint_colour_repository.dart';
import 'package:palette/providers/database_providers.dart';

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

  Future<Color> _extractDominantColour(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    // Sample a 40x40 region from the centre of the image
    final cx = image.width ~/ 2;
    final cy = image.height ~/ 2;
    const half = 20;
    final x0 = (cx - half).clamp(0, image.width - 1);
    final y0 = (cy - half).clamp(0, image.height - 1);
    final x1 = (cx + half).clamp(0, image.width);
    final y1 = (cy + half).clamp(0, image.height);

    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();

    if (byteData == null) return const Color(0xFF808080);

    var rTotal = 0;
    var gTotal = 0;
    var bTotal = 0;
    var count = 0;

    for (var py = y0; py < y1; py++) {
      for (var px = x0; px < x1; px++) {
        final offset = (py * image.width + px) * 4;
        rTotal += byteData.getUint8(offset);
        gTotal += byteData.getUint8(offset + 1);
        bTotal += byteData.getUint8(offset + 2);
        count++;
      }
    }

    if (count == 0) return const Color(0xFF808080);
    return Color.fromARGB(
      255,
      rTotal ~/ count,
      gTotal ~/ count,
      bTotal ~/ count,
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Captured colour swatch
        _buildCapturedSwatch(undertoneResult),
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
