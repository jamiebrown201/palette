import 'package:flutter/material.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/theme/palette_typography.dart';

/// App theme configuration.
abstract final class PaletteTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: PaletteColours.warmWhite,
        textTheme: PaletteTypography.textTheme,
        colorScheme: const ColorScheme.light(
          primary: PaletteColours.sageGreen,
          onPrimary: PaletteColours.textOnAccent,
          primaryContainer: PaletteColours.sageGreenLight,
          secondary: PaletteColours.softGold,
          onSecondary: PaletteColours.textOnAccent,
          secondaryContainer: PaletteColours.softGoldLight,
          surface: PaletteColours.warmWhite,
          onSurface: PaletteColours.textPrimary,
          onSurfaceVariant: PaletteColours.textSecondary,
          outline: PaletteColours.warmGrey,
          outlineVariant: PaletteColours.divider,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: PaletteColours.warmWhite,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          centerTitle: false,
          titleTextStyle: PaletteTypography.titleLarge,
          iconTheme: const IconThemeData(
            color: PaletteColours.textPrimary,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: PaletteColours.warmWhite,
          selectedItemColor: PaletteColours.sageGreen,
          unselectedItemColor: PaletteColours.textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        cardTheme: CardThemeData(
          color: PaletteColours.cardBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: PaletteColours.divider),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: PaletteColours.sageGreen,
            foregroundColor: PaletteColours.textOnAccent,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: PaletteColours.sageGreen,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: const BorderSide(color: PaletteColours.sageGreen),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: PaletteColours.sageGreen,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: PaletteColours.softCream,
          selectedColor: PaletteColours.sageGreenLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: PaletteColours.warmWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          showDragHandle: true,
        ),
        dividerTheme: const DividerThemeData(
          color: PaletteColours.warmGrey,
          thickness: 1,
          space: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: PaletteColours.cardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: PaletteColours.warmGrey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: PaletteColours.warmGrey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: PaletteColours.sageGreen,
              width: 2,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: PaletteColours.sageGreen,
          foregroundColor: PaletteColours.textOnAccent,
          elevation: 4,
        ),
      );

  /// Theme variant for Colour Blind Mode.
  /// Swaps sage green accent for accessible blue.
  static ThemeData get colourBlindLight {
    final base = light;
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: PaletteColours.accessibleBlue,
        primaryContainer: PaletteColours.accessibleBlueLight,
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        selectedItemColor: PaletteColours.accessibleBlue,
      ),
      floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
        backgroundColor: PaletteColours.accessibleBlue,
      ),
    );
  }
}
