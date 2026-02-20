import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/witt_colors.dart';
import '../theme/witt_spacing.dart';
import '../widgets/witt_badge.dart';

/// Navigation destination model
class WittNavDestination {
  const WittNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount,
    this.showDot = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int? badgeCount;
  final bool showDot;
}

/// The 5-tab scaffold with responsive bottom nav / sidebar rail
class WittScaffoldWithNav extends StatelessWidget {
  const WittScaffoldWithNav({
    super.key,
    required this.navigationShell,
    required this.destinations,
  });

  final StatefulNavigationShell navigationShell;
  final List<WittNavDestination> destinations;

  static const double _railBreakpoint = 600.0;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= _railBreakpoint;

    if (isWide) {
      return _buildRailLayout(context);
    }
    return _buildBottomNavLayout(context);
  }

  Widget _buildBottomNavLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? WittColors.surfaceDark : WittColors.surface,
          border: Border(
            top: BorderSide(
              color: isDark ? WittColors.outlineDark : WittColors.outline,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: WittSpacing.bottomNavHeight,
            child: Row(
              children: List.generate(destinations.length, (i) {
                final dest = destinations[i];
                final isSelected = navigationShell.currentIndex == i;
                return Expanded(
                  child: _NavItem(
                    destination: dest,
                    isSelected: isSelected,
                    onTap: () => _onTap(i),
                    isDark: isDark,
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRailLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? WittColors.surfaceDark : WittColors.surface,
              border: Border(
                right: BorderSide(
                  color: isDark ? WittColors.outlineDark : WittColors.outline,
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: NavigationRail(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _onTap,
                labelType: NavigationRailLabelType.all,
                backgroundColor: Colors.transparent,
                destinations: destinations.map((dest) {
                  return NavigationRailDestination(
                    icon: WittDotBadge(
                      show: dest.showDot,
                      count: dest.badgeCount,
                      child: Icon(dest.icon),
                    ),
                    selectedIcon: WittDotBadge(
                      show: dest.showDot,
                      count: dest.badgeCount,
                      child: Icon(dest.selectedIcon),
                    ),
                    label: Text(dest.label),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  final WittNavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = isSelected
        ? WittColors.primary
        : (isDark ? WittColors.textSecondaryDark : WittColors.textSecondary);
    final labelColor = isSelected
        ? WittColors.primary
        : (isDark ? WittColors.textSecondaryDark : WittColors.textSecondary);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: WittSpacing.lg,
              vertical: WittSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isSelected ? WittColors.primaryContainer : Colors.transparent,
              borderRadius: WittSpacing.borderRadiusFull,
            ),
            child: WittDotBadge(
              show: destination.showDot,
              count: destination.badgeCount,
              child: Icon(
                isSelected ? destination.selectedIcon : destination.icon,
                color: iconColor,
                size: WittSpacing.iconLg,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            destination.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: labelColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
