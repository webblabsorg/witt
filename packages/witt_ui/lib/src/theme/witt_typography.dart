import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'witt_colors.dart';

/// Witt typography system
/// Display/Headline: Plus Jakarta Sans (modern, geometric)
/// Body/Label: Inter (clean, highly legible)
abstract final class WittTypography {
  static TextTheme get textTheme => TextTheme(
        // Display
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 57,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
          color: WittColors.textPrimary,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: WittColors.textPrimary,
        ),
        displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: WittColors.textPrimary,
        ),
        // Headline
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: WittColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: WittColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: WittColors.textPrimary,
        ),
        // Title
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: WittColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          color: WittColors.textPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: WittColors.textPrimary,
        ),
        // Body
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: WittColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: WittColors.textPrimary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: WittColors.textSecondary,
        ),
        // Label
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: WittColors.textPrimary,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: WittColors.textSecondary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: WittColors.textTertiary,
        ),
      );

  static TextTheme get darkTextTheme => textTheme.apply(
        bodyColor: WittColors.textPrimaryDark,
        displayColor: WittColors.textPrimaryDark,
        decorationColor: WittColors.textSecondaryDark,
      );
}
