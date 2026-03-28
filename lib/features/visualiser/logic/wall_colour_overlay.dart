import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Applies a wall colour overlay to a room photo.
///
/// Uses colour blending at configurable opacity to simulate how a paint
/// colour would look on the walls. This is a local-only approximation
/// (no external API) — Decor8 AI integration is planned for Phase 3B.
///
/// The algorithm blends the target colour into lighter regions of the
/// image (likely walls) more heavily than darker regions (furniture,
/// shadows), creating a more natural result than a flat overlay.
class WallColourOverlay {
  const WallColourOverlay._();

  /// Generate a visualisation by blending [wallColour] onto [photoBytes].
  ///
  /// Returns the composited image as PNG bytes.
  static Future<Uint8List> generate({
    required Uint8List photoBytes,
    required Color wallColour,
    double opacity = 0.35,
  }) async {
    // Decode source image.
    final codec = await ui.instantiateImageCodec(photoBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final width = image.width;
    final height = image.height;

    // Read pixel data.
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) {
      throw StateError('Failed to read image pixel data');
    }

    final pixels = byteData.buffer.asUint8List();
    final result = Uint8List.fromList(pixels);

    final wr = (wallColour.r * 255).round();
    final wg = (wallColour.g * 255).round();
    final wb = (wallColour.b * 255).round();

    // Blend wall colour into each pixel.
    // Lighter pixels (higher luminance) get more colour — they're likely
    // walls. Darker pixels (furniture, shadows) get less.
    for (var i = 0; i < pixels.length; i += 4) {
      final r = pixels[i];
      final g = pixels[i + 1];
      final b = pixels[i + 2];
      // alpha at i+3 — preserve as-is.

      // Relative luminance (simplified).
      final lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;

      // Adaptive opacity: lighter areas get more colour overlay.
      // Minimum 15% even on dark areas, scaling up to full opacity on white.
      final adaptiveOpacity = (opacity * 0.4 + opacity * 0.6 * lum).clamp(
        0.0,
        1.0,
      );

      // Also consider saturation — highly saturated pixels are likely
      // colourful objects (not white/grey walls), so reduce overlay.
      final maxC = [r, g, b].reduce((a, c) => a > c ? a : c);
      final minC = [r, g, b].reduce((a, c) => a < c ? a : c);
      final saturation = maxC > 0 ? (maxC - minC) / maxC : 0.0;
      final satFactor = (1.0 - saturation * 0.5).clamp(0.0, 1.0);

      final finalOpacity = adaptiveOpacity * satFactor;

      result[i] = (r + (wr - r) * finalOpacity).round().clamp(0, 255);
      result[i + 1] = (g + (wg - g) * finalOpacity).round().clamp(0, 255);
      result[i + 2] = (b + (wb - b) * finalOpacity).round().clamp(0, 255);
    }

    // Encode result as PNG.
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );

    // Paint result pixels onto canvas.
    final resultImage = await _bytesToImage(result, width, height);
    canvas.drawImage(resultImage, Offset.zero, Paint());

    final picture = recorder.endRecording();
    final outputImage = await picture.toImage(width, height);
    final pngData = await outputImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    image.dispose();
    resultImage.dispose();
    outputImage.dispose();

    if (pngData == null) {
      throw StateError('Failed to encode result image');
    }

    return pngData.buffer.asUint8List();
  }

  static Future<ui.Image> _bytesToImage(
    Uint8List rgba,
    int width,
    int height,
  ) async {
    final completer = ui.ImmutableBuffer.fromUint8List(rgba);
    final buffer = await completer;
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    buffer.dispose();
    descriptor.dispose();
    codec.dispose();
    return frame.image;
  }
}
