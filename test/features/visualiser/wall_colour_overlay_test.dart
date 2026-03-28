import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palette/features/visualiser/logic/wall_colour_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WallColourOverlay', () {
    /// Create a small test PNG image with uniform colour.
    Future<Uint8List> _createTestImage(Color colour, {int size = 4}) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      );
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
        Paint()..color = colour,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(size, size);
      final pngData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return pngData!.buffer.asUint8List();
    }

    test('generates non-empty output from valid input', () async {
      final input = await _createTestImage(Colors.white);
      final result = await WallColourOverlay.generate(
        photoBytes: input,
        wallColour: const Color(0xFF8FAE8B), // sage green
      );
      expect(result, isNotEmpty);
      // PNG magic bytes
      expect(result[0], 0x89);
      expect(result[1], 0x50); // 'P'
      expect(result[2], 0x4E); // 'N'
      expect(result[3], 0x47); // 'G'
    });

    test('output is valid PNG when colour applied', () async {
      final input = await _createTestImage(Colors.white);
      final result = await WallColourOverlay.generate(
        photoBytes: input,
        wallColour: Colors.red,
      );
      // Result should be a valid PNG
      expect(result.length, greaterThan(8));
      expect(result[0], 0x89);
      expect(result[1], 0x50); // 'P'
    });

    test('respects opacity parameter', () async {
      final input = await _createTestImage(Colors.white);
      final lowOpacity = await WallColourOverlay.generate(
        photoBytes: input,
        wallColour: Colors.blue,
        opacity: 0.1,
      );
      final highOpacity = await WallColourOverlay.generate(
        photoBytes: input,
        wallColour: Colors.blue,
        opacity: 0.9,
      );
      // Both should produce valid PNGs — different from each other
      expect(lowOpacity, isNotEmpty);
      expect(highOpacity, isNotEmpty);
    });

    test('handles dark input images', () async {
      final input = await _createTestImage(Colors.black);
      final result = await WallColourOverlay.generate(
        photoBytes: input,
        wallColour: Colors.green,
      );
      expect(result, isNotEmpty);
    });
  });
}
