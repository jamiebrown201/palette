import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette/core/theme/palette_colours.dart';

/// Typography system for the Palette app.
/// Uses Lora (editorial serif) for headings and DM Sans for body text.
abstract final class PaletteTypography {
  static TextStyle get displayLarge => GoogleFonts.lora(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: PaletteColours.textPrimary,
        height: 1.2,
      );

  static TextStyle get displayMedium => GoogleFonts.lora(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: PaletteColours.textPrimary,
        height: 1.2,
      );

  static TextStyle get displaySmall => GoogleFonts.lora(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: PaletteColours.textPrimary,
        height: 1.3,
      );

  static TextStyle get headlineLarge => GoogleFonts.lora(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: PaletteColours.textPrimary,
        height: 1.3,
      );

  static TextStyle get headlineMedium => GoogleFonts.lora(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: PaletteColours.textPrimary,
        height: 1.3,
      );

  static TextStyle get headlineSmall => GoogleFonts.lora(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: PaletteColours.textPrimary,
        height: 1.4,
      );

  static TextStyle get titleLarge => GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: PaletteColours.textPrimary,
        height: 1.4,
      );

  static TextStyle get titleMedium => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: PaletteColours.textPrimary,
        height: 1.4,
      );

  static TextStyle get titleSmall => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: PaletteColours.textPrimary,
        height: 1.4,
      );

  static TextStyle get bodyLarge => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: PaletteColours.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: PaletteColours.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: PaletteColours.textSecondary,
        height: 1.5,
      );

  static TextStyle get labelLarge => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: PaletteColours.textPrimary,
        height: 1.4,
      );

  static TextStyle get labelMedium => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: PaletteColours.textPrimary,
        height: 1.4,
      );

  static TextStyle get labelSmall => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: PaletteColours.textSecondary,
        height: 1.4,
      );

  static TextTheme get textTheme => TextTheme(
        displayLarge: PaletteTypography.displayLarge,
        displayMedium: PaletteTypography.displayMedium,
        displaySmall: PaletteTypography.displaySmall,
        headlineLarge: PaletteTypography.headlineLarge,
        headlineMedium: PaletteTypography.headlineMedium,
        headlineSmall: PaletteTypography.headlineSmall,
        titleLarge: PaletteTypography.titleLarge,
        titleMedium: PaletteTypography.titleMedium,
        titleSmall: PaletteTypography.titleSmall,
        bodyLarge: PaletteTypography.bodyLarge,
        bodyMedium: PaletteTypography.bodyMedium,
        bodySmall: PaletteTypography.bodySmall,
        labelLarge: PaletteTypography.labelLarge,
        labelMedium: PaletteTypography.labelMedium,
        labelSmall: PaletteTypography.labelSmall,
      );
}
