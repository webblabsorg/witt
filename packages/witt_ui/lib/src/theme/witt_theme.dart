import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'witt_colors.dart';
import 'witt_spacing.dart';
import 'witt_typography.dart';

/// Witt app theme — light and dark variants
abstract final class WittTheme {
  static ThemeData get light => _buildTheme(brightness: Brightness.light);
  static ThemeData get dark => _buildTheme(brightness: Brightness.dark);

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = isDark ? _darkColorScheme : _lightColorScheme;
    final textTheme = isDark ? WittTypography.darkTextTheme : WittTypography.textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: isDark ? WittColors.backgroundDark : WittColors.background,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: isDark ? WittColors.surfaceDark : WittColors.surface,
        foregroundColor: isDark ? WittColors.textPrimaryDark : WittColors.textPrimary,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(
          color: isDark ? WittColors.textPrimaryDark : WittColors.textPrimary,
          size: WittSpacing.iconLg,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: WittSpacing.bottomNavHeight,
        elevation: 0,
        backgroundColor: isDark ? WittColors.surfaceDark : WittColors.surface,
        indicatorColor: WittColors.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: WittColors.primary, size: WittSpacing.iconLg);
          }
          return IconThemeData(
            color: isDark ? WittColors.textSecondaryDark : WittColors.textSecondary,
            size: WittSpacing.iconLg,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(
              color: WittColors.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return textTheme.labelSmall?.copyWith(
            color: isDark ? WittColors.textSecondaryDark : WittColors.textSecondary,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? WittColors.surfaceDark : WittColors.surface,
        indicatorColor: WittColors.primaryContainer,
        selectedIconTheme: const IconThemeData(color: WittColors.primary, size: WittSpacing.iconLg),
        unselectedIconTheme: IconThemeData(
          color: isDark ? WittColors.textSecondaryDark : WittColors.textSecondary,
          size: WittSpacing.iconLg,
        ),
        selectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          color: WittColors.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          color: isDark ? WittColors.textSecondaryDark : WittColors.textSecondary,
        ),
        useIndicator: true,
        minWidth: 72,
        minExtendedWidth: 200,
      ),
      cardTheme: CardThemeData(
        elevation: WittSpacing.elevationXs,
        shape: const RoundedRectangleBorder(borderRadius: WittSpacing.borderRadiusLg),
        color: isDark ? WittColors.surfaceVariantDark : WittColors.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WittColors.primary,
          foregroundColor: WittColors.textOnPrimary,
          elevation: 0,
          padding: WittSpacing.buttonPadding,
          shape: const RoundedRectangleBorder(borderRadius: WittSpacing.borderRadiusMd),
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(0, WittSpacing.touchTarget),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: WittColors.primary,
          side: const BorderSide(color: WittColors.primary, width: 1.5),
          padding: WittSpacing.buttonPadding,
          shape: const RoundedRectangleBorder(borderRadius: WittSpacing.borderRadiusMd),
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(0, WittSpacing.touchTarget),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: WittColors.primary,
          padding: WittSpacing.buttonPadding,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(0, WittSpacing.touchTarget),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? WittColors.surfaceVariantDark : WittColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: WittSpacing.borderRadiusMd,
          borderSide: BorderSide(
            color: isDark ? WittColors.outlineDark : WittColors.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: WittSpacing.borderRadiusMd,
          borderSide: BorderSide(
            color: isDark ? WittColors.outlineDark : WittColors.outline,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: WittSpacing.borderRadiusMd,
          borderSide: BorderSide(color: WittColors.primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: WittSpacing.borderRadiusMd,
          borderSide: BorderSide(color: WittColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: WittSpacing.lg,
          vertical: WittSpacing.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? WittColors.textTertiaryDark : WittColors.textTertiary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? WittColors.surfaceVariantDark : WittColors.surfaceVariant,
        selectedColor: WittColors.primaryContainer,
        labelStyle: textTheme.labelMedium,
        padding: WittSpacing.chipPadding,
        shape: const RoundedRectangleBorder(borderRadius: WittSpacing.borderRadiusFull),
        side: BorderSide(color: isDark ? WittColors.outlineDark : WittColors.outline),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? WittColors.outlineDark : WittColors.outline,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: WittSpacing.borderRadiusMd),
        backgroundColor: isDark ? WittColors.surfaceVariantDark : WittColors.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(WittSpacing.radiusXxl)),
        ),
        showDragHandle: true,
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: WittSpacing.borderRadiusXl),
        elevation: WittSpacing.elevationLg,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return WittColors.primary;
          return isDark ? WittColors.textTertiaryDark : WittColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return WittColors.primaryContainer;
          return isDark ? WittColors.outlineDark : WittColors.outline;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: WittColors.primary,
        linearTrackColor: WittColors.primaryContainer,
        circularTrackColor: WittColors.primaryContainer,
      ),
    );
  }

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: WittColors.primary,
    onPrimary: WittColors.textOnPrimary,
    primaryContainer: WittColors.primaryContainer,
    onPrimaryContainer: WittColors.primaryDark,
    secondary: WittColors.secondary,
    onSecondary: WittColors.textOnSecondary,
    secondaryContainer: WittColors.secondaryContainer,
    onSecondaryContainer: WittColors.secondaryDark,
    tertiary: WittColors.accent,
    onTertiary: WittColors.textOnPrimary,
    tertiaryContainer: WittColors.accentContainer,
    onTertiaryContainer: WittColors.accentDark,
    error: WittColors.error,
    onError: WittColors.textOnPrimary,
    errorContainer: WittColors.errorContainer,
    onErrorContainer: WittColors.error,
    surface: WittColors.surface,
    onSurface: WittColors.textPrimary,
    surfaceContainerHighest: WittColors.surfaceVariant,
    onSurfaceVariant: WittColors.textSecondary,
    outline: WittColors.outline,
    outlineVariant: WittColors.outlineVariant,
    shadow: Color(0x1A000000),
    scrim: Color(0x80000000),
    inverseSurface: WittColors.textPrimary,
    onInverseSurface: WittColors.surface,
    inversePrimary: WittColors.primaryLight,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: WittColors.primaryLight,
    onPrimary: WittColors.primaryDark,
    primaryContainer: WittColors.primaryDark,
    onPrimaryContainer: WittColors.primaryLight,
    secondary: WittColors.secondaryLight,
    onSecondary: WittColors.textOnSecondary,
    secondaryContainer: WittColors.secondaryDark,
    onSecondaryContainer: WittColors.secondaryLight,
    tertiary: WittColors.accentLight,
    onTertiary: WittColors.accentDark,
    tertiaryContainer: WittColors.accentDark,
    onTertiaryContainer: WittColors.accentLight,
    error: WittColors.errorLight,
    onError: WittColors.primaryDark,
    errorContainer: WittColors.error,
    onErrorContainer: WittColors.errorLight,
    surface: WittColors.surfaceDark,
    onSurface: WittColors.textPrimaryDark,
    surfaceContainerHighest: WittColors.surfaceVariantDark,
    onSurfaceVariant: WittColors.textSecondaryDark,
    outline: WittColors.outlineDark,
    outlineVariant: WittColors.outlineVariantDark,
    shadow: Color(0x40000000),
    scrim: Color(0x80000000),
    inverseSurface: WittColors.textPrimaryDark,
    onInverseSurface: WittColors.surfaceDark,
    inversePrimary: WittColors.primary,
  );
}
