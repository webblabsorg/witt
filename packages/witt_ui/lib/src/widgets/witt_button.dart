import 'package:flutter/material.dart';

import '../theme/witt_colors.dart';
import '../theme/witt_spacing.dart';

enum WittButtonVariant { primary, secondary, outline, ghost, danger }

enum WittButtonSize { sm, md, lg }

class WittButton extends StatelessWidget {
  const WittButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = WittButtonVariant.primary,
    this.size = WittButtonSize.md,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.gradient,
  });

  final String label;
  final VoidCallback? onPressed;
  final WittButtonVariant variant;
  final WittButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = switch (size) {
      WittButtonSize.sm => 36.0,
      WittButtonSize.md => WittSpacing.touchTarget,
      WittButtonSize.lg => 56.0,
    };
    final fontSize = switch (size) {
      WittButtonSize.sm => 13.0,
      WittButtonSize.md => 14.0,
      WittButtonSize.lg => 16.0,
    };
    final hPad = switch (size) {
      WittButtonSize.sm => WittSpacing.md,
      WittButtonSize.md => WittSpacing.xxl,
      WittButtonSize.lg => WittSpacing.xxxl,
    };

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _foregroundColor(theme),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(
              icon,
              size: WittSpacing.iconMd,
              color: _foregroundColor(theme),
            ),
            const SizedBox(width: WittSpacing.sm),
          ],
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: fontSize,
              color: _foregroundColor(theme),
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: WittSpacing.sm),
            Icon(
              trailingIcon,
              size: WittSpacing.iconMd,
              color: _foregroundColor(theme),
            ),
          ],
        ],
      ],
    );

    if (gradient != null && variant == WittButtonVariant.primary) {
      return SizedBox(
        width: isFullWidth ? double.infinity : null,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: onPressed == null ? null : gradient,
            color: onPressed == null ? theme.disabledColor : null,
            borderRadius: WittSpacing.borderRadiusMd,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: WittSpacing.borderRadiusMd,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      );
    }

    final style = switch (variant) {
      WittButtonVariant.primary => ElevatedButton.styleFrom(
        backgroundColor: WittColors.primary, // deep black
        foregroundColor: WittColors.textOnPrimary, // white
        minimumSize: Size(isFullWidth ? double.infinity : 0, height),
        padding: EdgeInsets.symmetric(horizontal: hPad),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: WittSpacing.borderRadiusMd,
        ),
      ),
      WittButtonVariant.secondary => ElevatedButton.styleFrom(
        backgroundColor: WittColors.secondary,
        foregroundColor: WittColors.textOnSecondary,
        minimumSize: Size(isFullWidth ? double.infinity : 0, height),
        padding: EdgeInsets.symmetric(horizontal: hPad),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: WittSpacing.borderRadiusMd,
        ),
      ),
      WittButtonVariant.outline => OutlinedButton.styleFrom(
        foregroundColor: WittColors.primary,
        side: const BorderSide(color: WittColors.primary, width: 1.5),
        minimumSize: Size(isFullWidth ? double.infinity : 0, height),
        padding: EdgeInsets.symmetric(horizontal: hPad),
        shape: const RoundedRectangleBorder(
          borderRadius: WittSpacing.borderRadiusMd,
        ),
      ),
      WittButtonVariant.ghost => TextButton.styleFrom(
        foregroundColor: WittColors.primary,
        minimumSize: Size(isFullWidth ? double.infinity : 0, height),
        padding: EdgeInsets.symmetric(horizontal: hPad),
      ),
      WittButtonVariant.danger => ElevatedButton.styleFrom(
        backgroundColor: WittColors.error,
        foregroundColor: WittColors.textOnPrimary,
        minimumSize: Size(isFullWidth ? double.infinity : 0, height),
        padding: EdgeInsets.symmetric(horizontal: hPad),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: WittSpacing.borderRadiusMd,
        ),
      ),
    };

    return switch (variant) {
      WittButtonVariant.outline => OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: child,
      ),
      WittButtonVariant.ghost => TextButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: child,
      ),
      _ => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: child,
      ),
    };
  }

  Color _foregroundColor(ThemeData theme) => switch (variant) {
    WittButtonVariant.primary => WittColors.textOnPrimary,
    WittButtonVariant.secondary => WittColors.textOnSecondary,
    WittButtonVariant.outline => WittColors.primary,
    WittButtonVariant.ghost => WittColors.primary,
    WittButtonVariant.danger => WittColors.textOnPrimary,
  };
}
