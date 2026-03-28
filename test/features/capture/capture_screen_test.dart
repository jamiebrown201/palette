import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palette/features/capture/screens/capture_screen.dart';

void main() {
  group('CaptureScreen', () {
    testWidgets('shows empty state with capture buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: CaptureScreen())),
      );

      expect(find.text('Capture a Colour'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(
        find.text('For best results, capture in natural daylight.'),
        findsOneWidget,
      );
    });

    testWidgets('shows camera icon in empty state', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: CaptureScreen())),
      );

      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
    });

    testWidgets('does not show match results in empty state', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: CaptureScreen())),
      );

      expect(find.text('Closest Paint Matches'), findsNothing);
    });
  });
}
