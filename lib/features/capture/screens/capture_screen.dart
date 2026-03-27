import 'package:flutter/material.dart';
import 'package:palette/core/theme/palette_colours.dart';

class CaptureScreen extends StatelessWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
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
                'Colour Capture',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Point your camera at any surface to capture its colour '
                'and find matching paints from our library.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: PaletteColours.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: PaletteColours.warmGrey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Coming Soon',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: PaletteColours.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
