import 'package:flutter/material.dart';

import '../theme/witt_colors.dart';
import '../theme/witt_spacing.dart';

class WittCard extends StatelessWidget {
  const WittCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.borderRadius,
    this.elevation,
    this.border,
    this.gradient,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BorderRadius? borderRadius;
  final double? elevation;
  final Border? border;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveRadius = borderRadius ?? WittSpacing.borderRadiusLg;
    final effectiveColor = color ?? (isDark ? WittColors.surfaceVariantDark : WittColors.surface);

    return Material(
      color: gradient != null ? Colors.transparent : effectiveColor,
      elevation: elevation ?? WittSpacing.elevationXs,
      borderRadius: effectiveRadius,
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: effectiveRadius,
          border: border ??
              Border.all(
                color: isDark ? WittColors.outlineDark : WittColors.outline,
                width: 0.5,
              ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          child: Padding(
            padding: padding ?? WittSpacing.cardPadding,
            child: child,
          ),
        ),
      ),
    );
  }
}
