import 'package:flutter/material.dart';

import '../theme/witt_colors.dart';
import '../theme/witt_spacing.dart';

class WittProgressBar extends StatelessWidget {
  const WittProgressBar({
    super.key,
    required this.value,
    this.height = 8.0,
    this.color,
    this.backgroundColor,
    this.borderRadius,
    this.label,
    this.showPercentage = false,
    this.gradient,
    this.animate = true,
  });

  final double value; // 0.0 to 1.0
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final String? label;
  final bool showPercentage;
  final Gradient? gradient;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final clampedValue = value.clamp(0.0, 1.0);
    final effectiveBg = backgroundColor ??
        (isDark ? WittColors.outlineDark : WittColors.outline);
    final effectiveRadius = borderRadius ?? WittSpacing.borderRadiusFull;

    Widget bar = LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              height: height,
              decoration: BoxDecoration(
                color: effectiveBg,
                borderRadius: effectiveRadius,
              ),
            ),
            AnimatedContainer(
              duration: animate ? const Duration(milliseconds: 400) : Duration.zero,
              curve: Curves.easeOut,
              height: height,
              width: constraints.maxWidth * clampedValue,
              decoration: BoxDecoration(
                color: gradient == null ? (color ?? WittColors.primary) : null,
                gradient: gradient,
                borderRadius: effectiveRadius,
              ),
            ),
          ],
        );
      },
    );

    if (label != null || showPercentage) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null || showPercentage)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(label!, style: theme.textTheme.labelSmall),
                if (showPercentage)
                  Text(
                    '${(clampedValue * 100).round()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color ?? WittColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          const SizedBox(height: WittSpacing.xs),
          bar,
        ],
      );
    }

    return bar;
  }
}
