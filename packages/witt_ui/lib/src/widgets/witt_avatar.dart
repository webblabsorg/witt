import 'package:flutter/material.dart';

import '../theme/witt_colors.dart';
import '../theme/witt_spacing.dart';

enum WittAvatarSize { xs, sm, md, lg, xl }

class WittAvatar extends StatelessWidget {
  const WittAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = WittAvatarSize.md,
    this.color,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
  });

  final String? imageUrl;
  final String? initials;
  final WittAvatarSize size;
  final Color? color;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;

  double get _diameter => switch (size) {
        WittAvatarSize.xs => 24,
        WittAvatarSize.sm => 32,
        WittAvatarSize.md => 40,
        WittAvatarSize.lg => 56,
        WittAvatarSize.xl => 80,
      };

  double get _fontSize => switch (size) {
        WittAvatarSize.xs => 10,
        WittAvatarSize.sm => 12,
        WittAvatarSize.md => 16,
        WittAvatarSize.lg => 22,
        WittAvatarSize.xl => 32,
      };

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? WittColors.primaryContainer;

    Widget avatar = Container(
      width: _diameter,
      height: _diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: imageUrl != null ? null : bgColor,
        image: imageUrl != null
            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
            : null,
        border: showBorder
            ? Border.all(
                color: borderColor ?? WittColors.primary,
                width: 2,
              )
            : null,
      ),
      child: imageUrl == null
          ? Center(
              child: Text(
                initials?.toUpperCase() ?? '?',
                style: TextStyle(
                  color: WittColors.primary,
                  fontSize: _fontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
    );

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }
}
