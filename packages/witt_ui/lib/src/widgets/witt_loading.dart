import 'package:flutter/material.dart';

import '../theme/witt_colors.dart';

class WittLoading extends StatelessWidget {
  const WittLoading({super.key, this.size = 24.0, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: color ?? WittColors.primary,
        ),
      ),
    );
  }
}

class WittLoadingOverlay extends StatelessWidget {
  const WittLoadingOverlay({super.key, required this.child, required this.isLoading});

  final Widget child;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          const ColoredBox(
            color: Color(0x80000000),
            child: WittLoading(color: Colors.white),
          ),
      ],
    );
  }
}
