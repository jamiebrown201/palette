import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/constants/enums.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/widgets/section_header.dart';
import 'package:palette/data/models/room.dart';
import 'package:palette/features/rooms/providers/room_providers.dart';
import 'package:palette/features/visualiser/logic/wall_colour_overlay.dart';
import 'package:palette/features/visualiser/providers/visualiser_providers.dart';
import 'package:palette/providers/analytics_provider.dart';
import 'package:palette/providers/app_providers.dart';

/// AI Room Visualiser screen (Phase 3.1).
///
/// Users photograph their room, pick a wall colour, and see a preview
/// of how the colour will look. Comparison mode shows two colours
/// side-by-side (2 credits).
class VisualiserScreen extends ConsumerStatefulWidget {
  const VisualiserScreen({this.roomId, this.initialColourHex, super.key});

  /// Optional room context for pre-selecting colours.
  final String? roomId;

  /// Optional initial colour hex to pre-select.
  final String? initialColourHex;

  @override
  ConsumerState<VisualiserScreen> createState() => _VisualiserScreenState();
}

class _VisualiserScreenState extends ConsumerState<VisualiserScreen> {
  final _picker = ImagePicker();

  Uint8List? _photoBytes;
  bool _isProcessing = false;

  // Single mode state
  Color? _selectedColour;
  Uint8List? _resultBytes;

  // Comparison mode state
  bool _comparisonMode = false;
  Color? _comparisonColour;
  Uint8List? _comparisonResultBytes;

  // Recent colours for quick access
  final List<Color> _recentColours = [];

  Room? _room;

  @override
  void initState() {
    super.initState();
    if (widget.initialColourHex != null) {
      _selectedColour = hexToColor(widget.initialColourHex!);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    setState(() {
      _photoBytes = bytes;
      _resultBytes = null;
      _comparisonResultBytes = null;
    });

    ref.read(analyticsProvider).track('visualiser_photo_selected', {
      'source': source == ImageSource.camera ? 'camera' : 'gallery',
      if (widget.roomId != null) 'room_id': widget.roomId,
    });
  }

  Future<void> _generatePreview() async {
    if (_photoBytes == null || _selectedColour == null) return;

    final credits = ref.read(visualiserCreditsProvider.notifier);
    final needed = _comparisonMode ? 2 : 1;

    if (ref.read(visualiserCreditsProvider) < needed) {
      _showCreditDialog();
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await WallColourOverlay.generate(
        photoBytes: _photoBytes!,
        wallColour: _selectedColour!,
      );

      Uint8List? compResult;
      if (_comparisonMode && _comparisonColour != null) {
        compResult = await WallColourOverlay.generate(
          photoBytes: _photoBytes!,
          wallColour: _comparisonColour!,
        );
      }

      if (!mounted) return;

      // Deduct credits
      final success =
          _comparisonMode
              ? credits.useComparisonCredits()
              : credits.useCredit();

      if (!success) {
        _showCreditDialog();
        return;
      }

      setState(() {
        _resultBytes = result;
        if (compResult != null) _comparisonResultBytes = compResult;
      });

      // Track recently used colours
      if (!_recentColours.contains(_selectedColour)) {
        _recentColours.insert(0, _selectedColour!);
        if (_recentColours.length > 6) _recentColours.removeLast();
      }

      ref.read(analyticsProvider).track('visualiser_generated', {
        'colour': colorToHex(_selectedColour!),
        'comparison_mode': _comparisonMode,
        if (widget.roomId != null) 'room_id': widget.roomId,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not generate preview. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showCreditDialog() {
    final tier = ref.read(subscriptionTierProvider);
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Credits needed'),
            content: Text(
              tier == SubscriptionTier.free
                  ? 'Upgrade to Palette Plus to get 5 AI Visualiser '
                      'credits per month, or purchase a top-up.'
                  : 'You have run out of credits this month. '
                      'Top up with 10 credits for \u00a31.99.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _purchaseCredits();
                },
                child: Text(
                  tier == SubscriptionTier.free ? 'Upgrade' : 'Buy 10 credits',
                ),
              ),
            ],
          ),
    );
  }

  void _purchaseCredits() {
    // Simulate top-up purchase (in-app purchase integration is future work)
    ref.read(visualiserCreditsProvider.notifier).addCredits(10);
    ref.read(analyticsProvider).track('visualiser_credits_purchased', {
      'credits': 10,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('10 credits added to your balance.')),
    );
  }

  void _pickColour() {
    _showColourPicker(
      currentColour: _selectedColour,
      onSelected:
          (c) => setState(() {
            _selectedColour = c;
            _resultBytes = null;
          }),
    );
  }

  void _pickComparisonColour() {
    _showColourPicker(
      currentColour: _comparisonColour,
      onSelected:
          (c) => setState(() {
            _comparisonColour = c;
            _comparisonResultBytes = null;
          }),
    );
  }

  void _showColourPicker({
    required Color? currentColour,
    required ValueChanged<Color> onSelected,
  }) {
    // Build palette colours from room + DNA
    final paletteColours = <_PaletteOption>[];

    if (_room != null) {
      if (_room!.heroColourHex != null) {
        paletteColours.add(
          _PaletteOption('Hero colour', hexToColor(_room!.heroColourHex!)),
        );
      }
      if (_room!.betaColourHex != null) {
        paletteColours.add(
          _PaletteOption('Beta colour', hexToColor(_room!.betaColourHex!)),
        );
      }
      if (_room!.surpriseColourHex != null) {
        paletteColours.add(
          _PaletteOption(
            'Accent colour',
            hexToColor(_room!.surpriseColourHex!),
          ),
        );
      }
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.5,
            maxChildSize: 0.7,
            builder:
                (ctx, scrollController) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Text(
                        'Choose wall colour',
                        style: Theme.of(ctx).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),

                      // Room palette colours
                      if (paletteColours.isNotEmpty) ...[
                        Text(
                          'From your room palette',
                          style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                            color: PaletteColours.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children:
                              paletteColours
                                  .map(
                                    (p) => _ColourChip(
                                      colour: p.colour,
                                      label: p.label,
                                      isSelected: currentColour == p.colour,
                                      onTap: () {
                                        onSelected(p.colour);
                                        Navigator.pop(ctx);
                                      },
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Recent colours
                      if (_recentColours.isNotEmpty) ...[
                        Text(
                          'Recently used',
                          style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                            color: PaletteColours.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children:
                              _recentColours
                                  .map(
                                    (c) => _ColourChip(
                                      colour: c,
                                      label: colorToHex(c),
                                      isSelected: currentColour == c,
                                      onTap: () {
                                        onSelected(c);
                                        Navigator.pop(ctx);
                                      },
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Common wall colours
                      Text(
                        'Popular wall colours',
                        style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                          color: PaletteColours.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children:
                            _popularWallColours
                                .map(
                                  (p) => _ColourChip(
                                    colour: p.colour,
                                    label: p.label,
                                    isSelected: currentColour == p.colour,
                                    onTap: () {
                                      onSelected(p.colour);
                                      Navigator.pop(ctx);
                                    },
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final credits = ref.watch(visualiserCreditsProvider);

    // Load room data if we have a roomId.
    if (widget.roomId != null) {
      ref.listen(roomByIdProvider(widget.roomId!), (_, next) {
        next.whenData((r) {
          if (r != null && _room == null) {
            setState(() {
              _room = r;
              if (_selectedColour == null && r.heroColourHex != null) {
                _selectedColour = hexToColor(r.heroColourHex!);
              }
            });
          }
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Room Visualiser'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: Icon(
                Icons.auto_awesome,
                size: 16,
                color:
                    credits > 0
                        ? PaletteColours.premiumGold
                        : PaletteColours.textTertiary,
              ),
              label: Text(
                '$credits credit${credits == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              backgroundColor: PaletteColours.softCream,
              side: BorderSide.none,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Privacy notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PaletteColours.softCream,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: PaletteColours.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your room photo is processed locally on your device '
                        'and is not stored or sent to any server.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PaletteColours.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Step 1: Photo
              const SectionHeader(
                title: '1. Take a photo',
                subtitle: "Photograph your room's walls",
              ),
              const SizedBox(height: 8),
              if (_photoBytes == null)
                _PhotoPrompt(
                  onCamera: () => _pickPhoto(ImageSource.camera),
                  onGallery: () => _pickPhoto(ImageSource.gallery),
                )
              else
                _PhotoPreview(
                  photoBytes: _photoBytes!,
                  onRetake:
                      () => setState(() {
                        _photoBytes = null;
                        _resultBytes = null;
                        _comparisonResultBytes = null;
                      }),
                ),
              const SizedBox(height: 24),

              // Step 2: Choose colour
              const SectionHeader(
                title: '2. Choose a colour',
                subtitle: 'Pick the wall colour you want to preview',
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _ColourPickButton(
                    colour: _selectedColour,
                    label: _comparisonMode ? 'Colour A' : 'Wall colour',
                    onTap: _pickColour,
                  ),
                  if (_comparisonMode) ...[
                    const SizedBox(width: 12),
                    Text('vs', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(width: 12),
                    _ColourPickButton(
                      colour: _comparisonColour,
                      label: 'Colour B',
                      onTap: _pickComparisonColour,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilterChip(
                    label: Text(
                      'Compare two colours',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    selected: _comparisonMode,
                    onSelected: (v) {
                      setState(() {
                        _comparisonMode = v;
                        _comparisonResultBytes = null;
                      });
                    },
                    avatar:
                        _comparisonMode
                            ? const Icon(Icons.check, size: 16)
                            : const Icon(Icons.compare, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _comparisonMode ? '2 credits' : '1 credit',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PaletteColours.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Generate button
              FilledButton.icon(
                onPressed:
                    _canGenerate && !_isProcessing ? _generatePreview : null,
                icon:
                    _isProcessing
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.auto_awesome),
                label: Text(
                  _isProcessing ? 'Generating...' : 'Preview wall colour',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: PaletteColours.sageGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 24),

              // Results
              if (_resultBytes != null) ...[
                const SectionHeader(title: '3. Your preview'),
                const SizedBox(height: 8),
                if (_comparisonMode && _comparisonResultBytes != null)
                  _ComparisonResult(
                    resultA: _resultBytes!,
                    resultB: _comparisonResultBytes!,
                    colourA: _selectedColour!,
                    colourB: _comparisonColour!,
                  )
                else
                  _SingleResult(
                    original: _photoBytes!,
                    result: _resultBytes!,
                    colour: _selectedColour!,
                  ),
                const SizedBox(height: 12),
                // Disclaimer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PaletteColours.softCream,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Colours on screens are approximations. The preview is '
                    'a helpful guide, not a photorealistic simulation. '
                    'Always test physical samples before committing.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PaletteColours.textSecondary,
                    ),
                  ),
                ),
              ],

              // Privacy notice
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.privacy_tip_outlined,
                    size: 14,
                    color: PaletteColours.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Your room photo is processed locally on your device '
                      'and is not stored or sent to any server.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PaletteColours.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canGenerate {
    if (_photoBytes == null || _selectedColour == null) return false;
    if (_comparisonMode && _comparisonColour == null) return false;
    return true;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoPrompt extends StatelessWidget {
  const _PhotoPrompt({required this.onCamera, required this.onGallery});

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: PaletteColours.softCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PaletteColours.warmGrey,
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.camera_alt_outlined,
            size: 40,
            color: PaletteColours.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'Photograph your room',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: PaletteColours.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Camera'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('Gallery'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photoBytes, required this.onRetake});

  final Uint8List photoBytes;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            photoBytes,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: FilledButton.tonalIcon(
            onPressed: onRetake,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retake'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _ColourPickButton extends StatelessWidget {
  const _ColourPickButton({
    required this.colour,
    required this.label,
    required this.onTap,
  });

  final Color? colour;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PaletteColours.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PaletteColours.warmGrey),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colour ?? PaletteColours.warmGrey,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PaletteColours.divider),
                ),
                child:
                    colour == null
                        ? const Icon(
                          Icons.add,
                          size: 20,
                          color: PaletteColours.textTertiary,
                        )
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: PaletteColours.textTertiary,
                      ),
                    ),
                    Text(
                      colour != null ? colorToHex(colour!) : 'Tap to choose',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: PaletteColours.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColourChip extends StatelessWidget {
  const _ColourChip({
    required this.colour,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final Color colour;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colour,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected
                        ? PaletteColours.sageGreen
                        : PaletteColours.divider,
                width: isSelected ? 3 : 1,
              ),
            ),
            child:
                isSelected
                    ? const Icon(Icons.check, size: 20, color: Colors.white)
                    : null,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 56,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: PaletteColours.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleResult extends StatefulWidget {
  const _SingleResult({
    required this.original,
    required this.result,
    required this.colour,
  });

  final Uint8List original;
  final Uint8List result;
  final Color colour;

  @override
  State<_SingleResult> createState() => _SingleResultState();
}

class _SingleResultState extends State<_SingleResult> {
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Image.memory(
              _showOriginal ? widget.original : widget.result,
              key: ValueKey(_showOriginal),
              width: double.infinity,
              height: 260,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: widget.colour,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: PaletteColours.divider),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              colorToHex(widget.colour),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: () => setState(() => _showOriginal = !_showOriginal),
              icon: Icon(
                _showOriginal ? Icons.visibility : Icons.visibility_off,
                size: 18,
              ),
              label: Text(_showOriginal ? 'Show preview' : 'Show original'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ComparisonResult extends StatelessWidget {
  const _ComparisonResult({
    required this.resultA,
    required this.resultB,
    required this.colourA,
    required this.colourB,
  });

  final Uint8List resultA;
  final Uint8List resultB;
  final Color colourA;
  final Color colourB;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      resultA,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: colourA,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: PaletteColours.divider),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('A', style: Theme.of(context).textTheme.labelMedium),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      resultB,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: colourB,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: PaletteColours.divider),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('B', style: Theme.of(context).textTheme.labelMedium),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PaletteOption {
  const _PaletteOption(this.label, this.colour);
  final String label;
  final Color colour;
}

// Popular UK wall colours from common paint brands.
const _popularWallColours = [
  _PaletteOption('Cornforth White', Color(0xFFD4CFC7)),
  _PaletteOption("Elephant's Breath", Color(0xFFCBC0B4)),
  _PaletteOption('Skimming Stone', Color(0xFFD8CFBE)),
  _PaletteOption('Hague Blue', Color(0xFF344152)),
  _PaletteOption('Railings', Color(0xFF3E4348)),
  _PaletteOption('Ammonite', Color(0xFFD5CFC5)),
  _PaletteOption('Purbeck Stone', Color(0xFFBCB49F)),
  _PaletteOption('Stiffkey Blue', Color(0xFF51616F)),
  _PaletteOption('Setting Plaster', Color(0xFFDDC8BA)),
  _PaletteOption('Jitney', Color(0xFFC8B89A)),
  _PaletteOption('Sage Green', Color(0xFF8FAE8B)),
  _PaletteOption('Calamine', Color(0xFFDCBFBE)),
];
