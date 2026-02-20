import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';

class PlayHubScreen extends StatelessWidget {
  const PlayHubScreen({super.key});

  static const _modes = [
    _GameMode(
      icon: Icons.flash_on_rounded,
      emoji: '⚡',
      title: 'Quick Fire',
      subtitle: '60-second rapid questions',
      color: WittColors.secondary,
      badge: 'HOT',
    ),
    _GameMode(
      icon: Icons.people_rounded,
      emoji: '⚔️',
      title: 'Math Duel',
      subtitle: '1v1 live multiplayer',
      color: WittColors.primary,
      badge: 'LIVE',
    ),
    _GameMode(
      icon: Icons.groups_rounded,
      emoji: '🏆',
      title: 'Tournament',
      subtitle: 'Compete with 100+ students',
      color: WittColors.accent,
      badge: null,
    ),
    _GameMode(
      icon: Icons.style_rounded,
      emoji: '🃏',
      title: 'Flashcard Blitz',
      subtitle: 'Race through your decks',
      color: WittColors.success,
      badge: null,
    ),
    _GameMode(
      icon: Icons.psychology_rounded,
      emoji: '🧠',
      title: 'Brain Challenge',
      subtitle: 'Daily logic puzzle',
      color: WittColors.streak,
      badge: 'DAILY',
    ),
    _GameMode(
      icon: Icons.leaderboard_rounded,
      emoji: '📊',
      title: 'Leaderboard',
      subtitle: 'See how you rank globally',
      color: WittColors.primaryDark,
      badge: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Play Hub'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          WittSpacing.lg,
          WittSpacing.md,
          WittSpacing.lg,
          WittSpacing.massive,
        ),
        children: [
          // Live activity banner
          WittCard(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF4338CA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            padding: const EdgeInsets.all(WittSpacing.lg),
            child: Row(
              children: [
                const Text('🎮', style: TextStyle(fontSize: 32)),
                const SizedBox(width: WittSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1,247 students playing now',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Jump into a live game',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withAlpha(178),
                        ),
                      ),
                    ],
                  ),
                ),
                WittButton(
                  label: 'Join',
                  onPressed: () {},
                  size: WittButtonSize.sm,
                ),
              ],
            ),
          ),
          const SizedBox(height: WittSpacing.xxl),

          Text('Game Modes', style: theme.textTheme.titleMedium),
          const SizedBox(height: WittSpacing.md),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: WittSpacing.md,
            mainAxisSpacing: WittSpacing.md,
            childAspectRatio: 1.1,
            children: _modes.map((m) => _GameCard(mode: m, isDark: isDark)).toList(),
          ),

          const SizedBox(height: WittSpacing.xxl),
          Text('Your Stats', style: theme.textTheme.titleMedium),
          const SizedBox(height: WittSpacing.md),

          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Games Played',
                  value: '47',
                  icon: Icons.sports_esports_rounded,
                  color: WittColors.primary,
                ),
              ),
              const SizedBox(width: WittSpacing.md),
              Expanded(
                child: _StatCard(
                  label: 'Win Rate',
                  value: '68%',
                  icon: Icons.emoji_events_rounded,
                  color: WittColors.secondary,
                ),
              ),
              const SizedBox(width: WittSpacing.md),
              Expanded(
                child: _StatCard(
                  label: 'Global Rank',
                  value: '#342',
                  icon: Icons.leaderboard_rounded,
                  color: WittColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GameMode {
  const _GameMode({
    required this.icon,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    this.badge,
  });
  final IconData icon;
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final String? badge;
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.mode, required this.isDark});
  final _GameMode mode;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? WittColors.surfaceVariantDark : WittColors.surface,
          borderRadius: WittSpacing.borderRadiusLg,
          border: Border.all(
            color: isDark ? WittColors.outlineDark : WittColors.outline,
          ),
        ),
        padding: const EdgeInsets.all(WittSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(mode.emoji, style: const TextStyle(fontSize: 28)),
                if (mode.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: WittSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: mode.color.withAlpha(26),
                      borderRadius: WittSpacing.borderRadiusFull,
                      border: Border.all(color: mode.color, width: 1),
                    ),
                    child: Text(
                      mode.badge!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: mode.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(mode.title, style: theme.textTheme.titleSmall),
            const SizedBox(height: WittSpacing.xs),
            Text(
              mode.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? WittColors.textSecondaryDark
                    : WittColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WittCard(
      padding: const EdgeInsets.all(WittSpacing.md),
      child: Column(
        children: [
          Icon(icon, color: color, size: WittSpacing.iconLg),
          const SizedBox(height: WittSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
