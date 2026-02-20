import 'package:flutter/material.dart';

import '../theme/witt_colors.dart';
import '../theme/witt_spacing.dart';

class WittChip extends StatelessWidget {
  const WittChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.color,
    this.selectedColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isSelected
        ? (selectedColor ?? WittColors.primaryContainer)
        : (color ?? (isDark ? WittColors.surfaceVariantDark : WittColors.surfaceVariant));

    final textColor = isSelected
        ? WittColors.primary
        : (isDark ? WittColors.textSecondaryDark : WittColors.textSecondary);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: WittSpacing.md,
          vertical: WittSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: WittSpacing.borderRadiusFull,
          border: Border.all(
            color: isSelected
                ? WittColors.primary
                : (isDark ? WittColors.outlineDark : WittColors.outline),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: WittSpacing.iconSm, color: textColor),
              const SizedBox(width: WittSpacing.xs),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
