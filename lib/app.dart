import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/theme/palette_theme.dart';
import 'package:palette/providers/app_providers.dart';
import 'package:palette/routing/app_router.dart';

class PaletteApp extends ConsumerWidget {
  const PaletteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isColourBlindMode = ref.watch(colourBlindModeProvider);

    return MaterialApp.router(
      title: 'Palette',
      debugShowCheckedModeBanner: false,
      theme:
          isColourBlindMode ? PaletteTheme.colourBlindLight : PaletteTheme.light,
      routerConfig: router,
    );
  }
}
