import 'package:flutter/material.dart';

/// App UI colour constants.
/// These are the colours used in Palette's own interface,
/// not the paint colours in the database.
abstract final class PaletteColours {
  // Backgrounds
  static const warmWhite = Color(0xFFFAF8F5);
  static const softCream = Color(0xFFF5F0E8);
  static const warmGrey = Color(0xFFE8E4DE);

  // Primary accent: sage green
  static const sageGreen = Color(0xFF8FAE8B);
  static const sageGreenLight = Color(0xFFB5CDB2);
  static const sageGreenDark = Color(0xFF6B8A67);

  // Secondary accent: soft gold
  static const softGold = Color(0xFFC9A96E);
  static const softGoldLight = Color(0xFFDCC799);
  static const softGoldDark = Color(0xFFA88B4A);

  // Colour Blind Mode accent: blue
  static const accessibleBlue = Color(0xFF5B8DB8);
  static const accessibleBlueLight = Color(0xFF89B4D4);
  static const accessibleBlueDark = Color(0xFF3A6E96);

  // Text
  static const textPrimary = Color(0xFF2C2C2C);
  static const textSecondary = Color(0xFF6B6B6B);
  static const textTertiary = Color(0xFF9B9B9B);
  static const textOnAccent = Color(0xFFFFFFFF);

  // Status (accessible: no red/green pairings)
  static const statusPositive = Color(0xFF5B8DB8);
  static const statusWarning = Color(0xFFC9A96E);
  static const statusInfo = Color(0xFF8FAE8B);
  static const statusNeutral = Color(0xFFE8E4DE);

  // Surfaces
  static const cardBackground = Color(0xFFFFFFFF);
  static const divider = Color(0xFFE8E4DE);
  static const overlay = Color(0x80000000);

  // Premium
  static const premiumGold = Color(0xFFCBA135);
  static const premiumGradientStart = Color(0xFFC9A96E);
  static const premiumGradientEnd = Color(0xFF8FAE8B);
}
