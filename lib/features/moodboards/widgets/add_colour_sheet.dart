import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/colour/colour_conversions.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/features/palette/providers/palette_providers.dart';

/// Result from the add-to-moodboard bottom sheet.
class AddItemResult {
  const AddItemResult({
    required this.type,
    this.colourHex,
    this.colourName,
    this.imageUrl,
    this.label,
  });

  final String type;
  final String? colourHex;
  final String? colourName;
  final String? imageUrl;
  final String? label;
}

/// Bottom sheet for adding items to a moodboard.
///
/// Supports adding:
/// - Colour swatches from the user's palette
/// - Custom hex colours
/// - Web image URLs
class AddColourSheet extends ConsumerStatefulWidget {
  const AddColourSheet({required this.moodboardId, super.key});

  final String moodboardId;

  @override
  ConsumerState<AddColourSheet> createState() => _AddColourSheetState();
}

class _AddColourSheetState extends ConsumerState<AddColourSheet> {
  int _selectedTab = 0;
  final _hexController = TextEditingController();
  final _urlController = TextEditingController();
  final _labelController = TextEditingController();

  @override
  void dispose() {
    _hexController.dispose();
    _urlController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: PaletteColours.warmGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add to moodboard',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Tab selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('My palette')),
                  ButtonSegment(value: 1, label: Text('Custom colour')),
                  ButtonSegment(value: 2, label: Text('Image URL')),
                ],
                selected: {_selectedTab},
                onSelectionChanged:
                    (val) => setState(() => _selectedTab = val.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: PaletteColours.sageGreenLight,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tab content
            if (_selectedTab == 0) _buildPaletteTab(),
            if (_selectedTab == 1) _buildCustomColourTab(),
            if (_selectedTab == 2) _buildImageTab(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPaletteTab() {
    final dnaAsync = ref.watch(latestColourDnaProvider);
    return dnaAsync.when(
      loading:
          () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
      error:
          (_, __) => const SizedBox(
            height: 120,
            child: Center(child: Text('Could not load palette')),
          ),
      data: (dna) {
        if (dna == null) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: Text('Complete onboarding to see your palette'),
            ),
          );
        }
        final coloursAsync = ref.watch(paletteColoursProvider(dna.id));
        return coloursAsync.when(
          loading:
              () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
          error:
              (_, __) => const SizedBox(
                height: 120,
                child: Center(child: Text('Could not load colours')),
              ),
          data: (colours) {
            if (colours.isEmpty) {
              return const SizedBox(
                height: 120,
                child: Center(child: Text('No palette colours yet')),
              );
            }
            return SizedBox(
              height: 160,
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: colours.length,
                itemBuilder: (context, index) {
                  final colour = colours[index];
                  return _ColourSwatch(
                    hex: colour.hex,
                    onTap: () => _addColour(colour.hex, null),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomColourTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _hexController,
            decoration: const InputDecoration(
              hintText: '#A67B5B',
              labelText: 'Hex colour code',
              prefixIcon: Icon(Icons.color_lens_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              hintText: 'Optional name (e.g. Farrow & Ball Savage Ground)',
              labelText: 'Colour name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final hex = _hexController.text.trim();
                if (hex.isEmpty) return;
                final normalised = hex.startsWith('#') ? hex.substring(1) : hex;
                if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(normalised)) return;
                _addColour(normalised, _labelController.text.trim());
              },
              child: const Text('Add colour'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              hintText: 'https://...',
              labelText: 'Image URL',
              prefixIcon: Icon(Icons.image_outlined),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final url = _urlController.text.trim();
                if (url.isEmpty) return;
                _addImage(url);
              },
              child: const Text('Add image'),
            ),
          ),
        ],
      ),
    );
  }

  void _addColour(String hex, String? name) {
    Navigator.pop(
      context,
      AddItemResult(
        type: 'colour',
        colourHex: hex.replaceFirst('#', ''),
        colourName: name?.isNotEmpty == true ? name : null,
      ),
    );
  }

  void _addImage(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid HTTPS URL')),
      );
      return;
    }
    Navigator.pop(context, AddItemResult(type: 'image', imageUrl: url));
  }
}

class _ColourSwatch extends StatelessWidget {
  const _ColourSwatch({required this.hex, required this.onTap});

  final String hex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colour = hexToColor(hex);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colour,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: PaletteColours.divider, width: 1),
        ),
      ),
    );
  }
}
