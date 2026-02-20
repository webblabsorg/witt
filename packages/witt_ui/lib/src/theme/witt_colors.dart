import 'package:flutter/material.dart';

/// Witt brand color palette
abstract final class WittColors {
  // Primary brand — deep indigo/violet
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryContainer = Color(0xFFEEF2FF);

  // Secondary — warm amber (energy, gamification)
  static const Color secondary = Color(0xFFF59E0B);
  static const Color secondaryLight = Color(0xFFFCD34D);
  static const Color secondaryDark = Color(0xFFD97706);
  static const Color secondaryContainer = Color(0xFFFFFBEB);

  // Accent — teal (AI / Sage)
  static const Color accent = Color(0xFF0EA5E9);
  static const Color accentLight = Color(0xFF7DD3FC);
  static const Color accentDark = Color(0xFF0284C7);
  static const Color accentContainer = Color(0xFFE0F2FE);

  // Success / correct
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF6EE7B7);
  static const Color successContainer = Color(0xFFECFDF5);

  // Error / wrong
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFCA5A5);
  static const Color errorContainer = Color(0xFFFEF2F2);

  // Warning
  static const Color warning = Color(0xFFF97316);
  static const Color warningLight = Color(0xFFFDBA74);
  static const Color warningContainer = Color(0xFFFFF7ED);

  // Streak / gamification
  static const Color streak = Color(0xFFFF6B35);
  static const Color xp = Color(0xFFFFD700);

  // Neutrals — light mode
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8FAFC);
  static const Color background = Color(0xFFF1F5F9);
  static const Color outline = Color(0xFFE2E8F0);
  static const Color outlineVariant = Color(0xFFCBD5E1);

  // Text — light mode
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFF1C1917);

  // Neutrals — dark mode
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color surfaceVariantDark = Color(0xFF1E293B);
  static const Color backgroundDark = Color(0xFF020617);
  static const Color outlineDark = Color(0xFF334155);
  static const Color outlineVariantDark = Color(0xFF1E293B);

  // Text — dark mode
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF475569);
  static const Color textDisabledDark = Color(0xFF334155);

  // Subject-specific colors
  static const Color math = Color(0xFF6366F1);
  static const Color science = Color(0xFF10B981);
  static const Color english = Color(0xFFF59E0B);
  static const Color history = Color(0xFFEF4444);
  static const Color languages = Color(0xFF8B5CF6);
  static const Color arts = Color(0xFFEC4899);

  // Gradient presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sageGradient = LinearGradient(
    colors: [accent, Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient streakGradient = LinearGradient(
    colors: [streak, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
