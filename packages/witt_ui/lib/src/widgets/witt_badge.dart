import 'package:flutter/material.dart';

import '../theme/witt_colors.dart';
import '../theme/witt_spacing.dart';

enum WittBadgeVariant { primary, secondary, success, error, warning, neutral }

class WittBadge extends StatelessWidget {
  const WittBadge({
    super.key,
    required this.label,
    this.variant = WittBadgeVariant.primary,
    this.icon,
    this.isSmall = false,
  });

  final String label;
  final WittBadgeVariant variant;
  final IconData? icon;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg) = switch (variant) {
      WittBadgeVariant.primary => (WittColors.primaryContainer, WittColors.primary),
      WittBadgeVariant.secondary => (WittColors.secondaryContainer, WittColors.secondaryDark),
      WittBadgeVariant.success => (WittColors.successContainer, WittColors.success),
      WittBadgeVariant.error => (WittColors.errorContainer, WittColors.error),
      WittBadgeVariant.warning => (WittColors.warningContainer, WittColors.warning),
      WittBadgeVariant.neutral => (
          theme.brightness == Brightness.dark
              ? WittColors.surfaceVariantDark
              : WittColors.surfaceVariant,
          theme.brightness == Brightness.dark
              ? WittColors.textSecondaryDark
              : WittColors.textSecondary,
        ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? WittSpacing.xs : WittSpacing.sm,
        vertical: isSmall ? 2 : WittSpacing.xs,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: WittSpacing.borderRadiusFull),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isSmall ? 10 : WittSpacing.iconXs, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: (isSmall ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)
                ?.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Red dot notification badge overlay
class WittDotBadge extends StatelessWidget {
  const WittDotBadge({
    super.key,
    required this.child,
    this.count,
    this.show = true,
    this.color,
  });

  final Widget child;
  final int? count;
  final bool show;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (!show) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            padding: count != null && count! > 0
                ? const EdgeInsets.symmetric(horizontal: 4, vertical: 1)
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: color ?? WittColors.error,
              borderRadius: WittSpacing.borderRadiusFull,
            ),
            child: count != null && count! > 0
                ? Text(
                    count! > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  )
                : const SizedBox(width: 8, height: 8),
          ),
        ),
      ],
    );
  }
}
