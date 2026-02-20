import 'package:flutter/material.dart';

import '../theme/witt_colors.dart';
import '../theme/witt_spacing.dart';

class WittBottomSheet extends StatelessWidget {
  const WittBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.actions,
    this.showDragHandle = true,
    this.isScrollable = true,
    this.maxHeightFraction = 0.9,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showDragHandle;
  final bool isScrollable;
  final double maxHeightFraction;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    String? subtitle,
    List<Widget>? actions,
    bool isDismissible = true,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      isScrollControlled: isScrollControlled,
      useSafeArea: true,
      builder: (_) => WittBottomSheet(
        title: title,
        subtitle: subtitle,
        actions: actions,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final maxHeight = MediaQuery.of(context).size.height * maxHeightFraction;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDragHandle)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: WittSpacing.md),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? WittColors.outlineDark : WittColors.outlineVariant,
                  borderRadius: WittSpacing.borderRadiusFull,
                ),
              ),
            ),
          if (title != null || subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WittSpacing.lg,
                WittSpacing.lg,
                WittSpacing.lg,
                WittSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(title!, style: theme.textTheme.titleLarge),
                  if (subtitle != null) ...[
                    const SizedBox(height: WittSpacing.xs),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? WittColors.textSecondaryDark
                            : WittColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Flexible(
            child: isScrollable
                ? SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      WittSpacing.lg,
                      WittSpacing.sm,
                      WittSpacing.lg,
                      WittSpacing.lg,
                    ),
                    child: child,
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(
                      WittSpacing.lg,
                      WittSpacing.sm,
                      WittSpacing.lg,
                      WittSpacing.lg,
                    ),
                    child: child,
                  ),
          ),
          if (actions != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WittSpacing.lg,
                0,
                WittSpacing.lg,
                WittSpacing.lg,
              ),
              child: Row(
                children: actions!
                    .map((a) => Expanded(child: a))
                    .toList(),
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
