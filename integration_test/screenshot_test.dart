// Integration test that navigates through all key screens and captures
// screenshots. Run with:
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshot_test.dart \
//     -d emulator-5554
//
// This is an offline-first app — no backend required. The database seeds
// paint colours and products on first launch. We skip onboarding to reach
// the main screens quickly, then navigate through each key journey.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:palette/main.dart' as app;

late IntegrationTestWidgetsFlutterBinding _binding;

Future<void> takeScreenshot(String name) async {
  await _binding.takeScreenshot(name);
}

/// Pumps for [seconds] to let async operations resolve, then settles.
Future<void> pumpForData(WidgetTester tester, {int seconds = 3}) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pumpAndSettle();
}

/// Finds and taps a back button. Returns true if found.
Future<bool> goBack(WidgetTester tester) async {
  final backIcon = find.byIcon(Icons.arrow_back);
  if (backIcon.evaluate().isNotEmpty) {
    await tester.tap(backIcon.first);
    await tester.pumpAndSettle();
    return true;
  }
  final backIos = find.byIcon(Icons.arrow_back_ios_new);
  if (backIos.evaluate().isNotEmpty) {
    await tester.tap(backIos.first);
    await tester.pumpAndSettle();
    return true;
  }
  final backTooltip = find.byTooltip('Back');
  if (backTooltip.evaluate().isNotEmpty) {
    await tester.tap(backTooltip.first);
    await tester.pumpAndSettle();
    return true;
  }
  return false;
}

/// Taps a NavigationDestination by label text.
Future<void> tapTab(WidgetTester tester, String label) async {
  final tab = find.text(label);
  if (tab.evaluate().isNotEmpty) {
    await tester.tap(tab.last);
    await pumpForData(tester, seconds: 2);
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  _binding = binding;

  group('screenshot journey', () {
    testWidgets('captures all key screens', (tester) async {
      app.main();

      // On Android, convert surface to image for screenshot capture.
      if (!kIsWeb && Platform.isAndroid) {
        await binding.convertFlutterSurfaceToImage();
      }

      // Wait for app to initialise (DB seeding, paint data load).
      await pumpForData(tester, seconds: 5);

      // ── 00: Onboarding — Memory Prompts ──────────────────────────────
      await takeScreenshot('00_onboarding_memory_prompts');

      // Tap a colour-mood card to advance through first prompt.
      final cards = find.byType(Card);
      if (cards.evaluate().length >= 2) {
        await tester.tap(cards.at(1));
        await pumpForData(tester, seconds: 2);
        await takeScreenshot('01_onboarding_prompt_2');
      }

      // Skip the rest of the quiz to reach home quickly.
      final skipBtn = find.text('Skip');
      if (skipBtn.evaluate().isNotEmpty) {
        await tester.tap(skipBtn.last);
        await pumpForData(tester, seconds: 3);
      }

      // ── 02: Home Screen ("Your Design Plan") ────────────────────────
      await takeScreenshot('02_home_screen');

      // ── 03: Rooms Tab ───────────────────────────────────────────────
      await tapTab(tester, 'Rooms');
      await takeScreenshot('03_rooms_list');

      // ── 04: Create Room flow ────────────────────────────────────────
      // Look for a FAB or "Add Room" / "+" button
      final addRoomFab = find.byIcon(Icons.add);
      if (addRoomFab.evaluate().isNotEmpty) {
        await tester.tap(addRoomFab.first);
        await pumpForData(tester, seconds: 2);
        await takeScreenshot('04_create_room');

        // Close create room screen
        final closeBtn = find.byIcon(Icons.close);
        if (closeBtn.evaluate().isNotEmpty) {
          await tester.tap(closeBtn.first);
          await pumpForData(tester, seconds: 2);
        } else {
          await goBack(tester);
        }
      }

      // ── 05: Capture Tab ─────────────────────────────────────────────
      await tapTab(tester, 'Capture');
      await takeScreenshot('05_capture_screen');

      // ── 06: Explore Tab ─────────────────────────────────────────────
      await tapTab(tester, 'Explore');
      await takeScreenshot('06_explore_screen');

      // ── 07: Colour Wheel (via Explore) ──────────────────────────────
      final colourWheel = find.text('Colour Wheel');
      if (colourWheel.evaluate().isNotEmpty) {
        await tester.tap(colourWheel.first);
        await pumpForData(tester, seconds: 2);
        await takeScreenshot('07_colour_wheel');
        await goBack(tester);
      }

      // ── 08: White Finder (via Explore) ──────────────────────────────
      final whiteFinder = find.text('White Finder');
      if (whiteFinder.evaluate().isNotEmpty) {
        await tester.tap(whiteFinder.first);
        await pumpForData(tester, seconds: 2);
        await takeScreenshot('08_white_finder');
        await goBack(tester);
      }

      // ── 09: Paint Library (via Explore) ─────────────────────────────
      final paintLibrary = find.text('Paint Library');
      if (paintLibrary.evaluate().isNotEmpty) {
        await tester.tap(paintLibrary.first);
        await pumpForData(tester, seconds: 2);
        await takeScreenshot('09_paint_library');
        await goBack(tester);
      }

      // ── 10: Profile Tab ─────────────────────────────────────────────
      await tapTab(tester, 'Profile');
      await takeScreenshot('10_profile_screen');

      // ── 11: My Palette (via Home appbar icon) ───────────────────────
      await tapTab(tester, 'Home');
      await pumpForData(tester, seconds: 1);
      final paletteIcon = find.byIcon(Icons.palette_outlined);
      if (paletteIcon.evaluate().isNotEmpty) {
        await tester.tap(paletteIcon.first);
        await pumpForData(tester, seconds: 2);
        await takeScreenshot('11_my_palette');
        await goBack(tester);
      }

      // ── 12: Paywall ─────────────────────────────────────────────────
      // Navigate to paywall if there's a CTA on the home screen
      final upgradeCta = find.textContaining('Unlock');
      if (upgradeCta.evaluate().isNotEmpty) {
        await tester.tap(upgradeCta.first);
        await pumpForData(tester, seconds: 2);
        await takeScreenshot('12_paywall');
        await goBack(tester);
      }

      // ── 13: Red Thread ──────────────────────────────────────────────
      await tapTab(tester, 'Explore');
      await pumpForData(tester, seconds: 1);
      final redThread = find.text('Red Thread');
      if (redThread.evaluate().isNotEmpty) {
        await tester.tap(redThread.first);
        await pumpForData(tester, seconds: 2);
        await takeScreenshot('13_red_thread');
        await goBack(tester);
      }

      // ── 14: Shopping List ───────────────────────────────────────────
      // Navigate via Profile or Home if there's a shopping list link
      await tapTab(tester, 'Home');
      await pumpForData(tester, seconds: 1);
      final shoppingList = find.textContaining('Shopping');
      if (shoppingList.evaluate().isNotEmpty) {
        await tester.tap(shoppingList.first);
        await pumpForData(tester, seconds: 2);
        await takeScreenshot('14_shopping_list');
        await goBack(tester);
      }

      // ── 15: Sample List ─────────────────────────────────────────────
      final samples = find.textContaining('Sample');
      if (samples.evaluate().isNotEmpty) {
        await tester.tap(samples.first);
        await pumpForData(tester, seconds: 2);
        await takeScreenshot('15_sample_list');
        await goBack(tester);
      }

      // ── 16: AI Design Assistant ─────────────────────────────────────
      await tapTab(tester, 'Profile');
      await pumpForData(tester, seconds: 1);
      final assistant = find.textContaining('Design Assistant');
      if (assistant.evaluate().isNotEmpty) {
        await tester.tap(assistant.first);
        await pumpForData(tester, seconds: 2);
        await takeScreenshot('16_ai_assistant');
        await goBack(tester);
      }

      // ── 17: Partner Mode ────────────────────────────────────────────
      final partner = find.textContaining('Partner');
      if (partner.evaluate().isNotEmpty) {
        await tester.tap(partner.first);
        await pumpForData(tester, seconds: 2);
        await takeScreenshot('17_partner_mode');
        await goBack(tester);
      }

      // ── Done ────────────────────────────────────────────────────────
      await takeScreenshot('99_final_state');
    });
  });
}
