import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_monetization/witt_monetization.dart';
import 'package:witt_ui/witt_ui.dart';

import '../models/game_models.dart';
import '../providers/game_providers.dart';

class PlayHubScreen extends ConsumerStatefulWidget {
  const PlayHubScreen({super.key});

  @override
  ConsumerState<PlayHubScreen> createState() => _PlayHubScreenState();
}

class _PlayHubScreenState extends ConsumerState<PlayHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Play Hub'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tab,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Games'),
            Tab(text: 'Brain'),
            Tab(text: 'Multiplayer'),
            Tab(text: 'Leaderboard'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _GamesTab(isDark: isDark),
          _BrainTab(isDark: isDark),
          _MultiplayerTab(isDark: isDark),
          _LeaderboardTab(isDark: isDark),
        ],
      ),
    );
  }
}

// ── Games Tab ─────────────────────────────────────────────────────────────

class _GamesTab extends ConsumerWidget {
  const _GamesTab({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(gamesProvider);
    final isPaid = ref.watch(isPaidProvider);
    final canPlay = ref.watch(canPlayGameProvider);
    final played = ref.watch(gamesPlayedTodayProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        WittSpacing.lg,
        WittSpacing.md,
        WittSpacing.lg,
        100,
      ),
      children: [
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
                        color: Colors.white70,
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
        const SizedBox(height: WittSpacing.md),
        if (!isPaid)
          _LimitBanner(
            message: 'Free plan: $played/3 games today. Upgrade for unlimited.',
            isFull: !canPlay,
          ),
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                label: 'Played',
                value: '47',
                icon: Icons.sports_esports_rounded,
                color: WittColors.primary,
              ),
            ),
            const SizedBox(width: WittSpacing.sm),
            Expanded(
              child: _MiniStat(
                label: 'Win Rate',
                value: '68%',
                icon: Icons.emoji_events_rounded,
                color: WittColors.secondary,
              ),
            ),
            const SizedBox(width: WittSpacing.sm),
            Expanded(
              child: _MiniStat(
                label: 'Rank',
                value: '#342',
                icon: Icons.leaderboard_rounded,
                color: WittColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: WittSpacing.lg),
        for (final cat in GameCategory.values)
          _CategorySection(
            category: cat,
            games: games.where((g) => g.category == cat).toList(),
            isDark: isDark,
            isPaid: isPaid,
            canPlay: canPlay,
          ),
      ],
    );
  }
}

class _CategorySection extends ConsumerWidget {
  const _CategorySection({
    required this.category,
    required this.games,
    required this.isDark,
    required this.isPaid,
    required this.canPlay,
  });
  final GameCategory category;
  final List<GameDefinition> games;
  final bool isDark;
  final bool isPaid;
  final bool canPlay;

  String get _label => switch (category) {
    GameCategory.wordGames => 'Word Games',
    GameCategory.mathGames => 'Math Games',
    GameCategory.generalKnowledge => 'General Knowledge',
    GameCategory.memory => 'Memory',
    GameCategory.challenge => 'Boss Challenges',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (games.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_label, style: theme.textTheme.titleSmall),
        const SizedBox(height: WittSpacing.sm),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: WittSpacing.sm,
          mainAxisSpacing: WittSpacing.sm,
          childAspectRatio: 1.15,
          children: games
              .map(
                (g) => _GameCard(
                  game: g,
                  isDark: isDark,
                  isPaid: isPaid,
                  canPlay: canPlay,
                  onTap: () => _launch(context, ref, g),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: WittSpacing.lg),
      ],
    );
  }

  void _launch(BuildContext context, WidgetRef ref, GameDefinition game) {
    if (game.isPaidOnly && !isPaid) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Premium Game'),
          content: Text('${game.title} requires a premium subscription.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Upgrade'),
            ),
          ],
        ),
      );
      return;
    }
    if (!canPlay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily game limit reached. Upgrade for unlimited!'),
        ),
      );
      return;
    }
    ref.read(gamesPlayedTodayProvider.notifier).state++;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GameLaunchSheet(game: game),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.game,
    required this.isDark,
    required this.isPaid,
    required this.canPlay,
    required this.onTap,
  });
  final GameDefinition game;
  final bool isDark;
  final bool isPaid;
  final bool canPlay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locked = game.isPaidOnly && !isPaid;
    return GestureDetector(
      onTap: onTap,
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
                Text(game.emoji, style: const TextStyle(fontSize: 28)),
                if (locked)
                  const Icon(
                    Icons.lock_rounded,
                    size: 16,
                    color: WittColors.textSecondary,
                  )
                else if (game.supportsMultiplayer)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: WittSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: game.color.withAlpha(26),
                      borderRadius: WittSpacing.borderRadiusFull,
                      border: Border.all(color: game.color),
                    ),
                    child: Text(
                      'LIVE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: game.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(game.title, style: theme.textTheme.titleSmall),
            const SizedBox(height: WittSpacing.xs),
            Text(
              game.description,
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

// ── Brain Tab ─────────────────────────────────────────────────────────────

class _BrainTab extends ConsumerWidget {
  const _BrainTab({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(brainChallengesProvider);
    final theme = Theme.of(context);
    final daily = challenges.where((c) => c.isDaily).toList();
    final regular = challenges.where((c) => !c.isDaily).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        WittSpacing.lg,
        WittSpacing.md,
        WittSpacing.lg,
        100,
      ),
      children: [
        if (daily.isNotEmpty) ...[
          Text('Daily Challenge', style: theme.textTheme.titleSmall),
          const SizedBox(height: WittSpacing.sm),
          WittCard(
            gradient: const LinearGradient(
              colors: [Color(0xFF065F46), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            padding: const EdgeInsets.all(WittSpacing.lg),
            child: Row(
              children: [
                const Text('🧠', style: TextStyle(fontSize: 32)),
                const SizedBox(width: WittSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        daily.first.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '+${daily.first.xpReward} XP',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: WittSpacing.xs),
                      Text(
                        daily.first.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                if (daily.first.isCompleted)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 28,
                  )
                else
                  WittButton(
                    label: 'Start',
                    onPressed: () {
                      ref
                          .read(brainChallengesProvider.notifier)
                          .complete(daily.first.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Daily challenge complete! +${daily.first.xpReward} XP',
                          ),
                        ),
                      );
                    },
                    size: WittButtonSize.sm,
                  ),
              ],
            ),
          ),
          const SizedBox(height: WittSpacing.lg),
        ],
        Text('All Challenges', style: theme.textTheme.titleSmall),
        const SizedBox(height: WittSpacing.sm),
        ...regular.map((c) {
          final diffColor = switch (c.difficulty) {
            GameDifficulty.easy => WittColors.success,
            GameDifficulty.medium => WittColors.streak,
            GameDifficulty.hard => WittColors.error,
          };
          final diffLabel = switch (c.difficulty) {
            GameDifficulty.easy => 'Easy',
            GameDifficulty.medium => 'Medium',
            GameDifficulty.hard => 'Hard',
          };
          return Padding(
            padding: const EdgeInsets.only(bottom: WittSpacing.sm),
            child: WittCard(
              padding: const EdgeInsets.all(WittSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.title, style: theme.textTheme.titleSmall),
                        const SizedBox(height: WittSpacing.xs),
                        Text(
                          c.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? WittColors.textSecondaryDark
                                : WittColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: WittSpacing.xs),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: WittSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: diffColor.withAlpha(26),
                                borderRadius: WittSpacing.borderRadiusFull,
                              ),
                              child: Text(
                                diffLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: diffColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: WittSpacing.sm),
                            Text(
                              '+${c.xpReward} XP',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: WittColors.streak,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (c.isCompleted)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: WittColors.success,
                      size: 24,
                    )
                  else
                    WittButton(
                      label: 'Start',
                      onPressed: () {
                        ref
                            .read(brainChallengesProvider.notifier)
                            .complete(c.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${c.title} complete! +${c.xpReward} XP',
                            ),
                          ),
                        );
                      },
                      variant: WittButtonVariant.outline,
                      size: WittButtonSize.sm,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Multiplayer Tab ───────────────────────────────────────────────────────

class _MultiplayerTab extends ConsumerWidget {
  const _MultiplayerTab({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPaid = ref.watch(isPaidProvider);
    final status = ref.watch(multiplayerStatusProvider);
    final theme = Theme.of(context);

    if (!isPaid) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(WittSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚔️', style: TextStyle(fontSize: 64)),
              const SizedBox(height: WittSpacing.lg),
              Text(
                'Multiplayer is Premium',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: WittSpacing.sm),
              Text(
                'Challenge friends and compete globally with a premium subscription.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: WittSpacing.xl),
              WittButton(
                label: 'Upgrade to Premium',
                onPressed: () {},
                variant: WittButtonVariant.primary,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        WittSpacing.lg,
        WittSpacing.md,
        WittSpacing.lg,
        100,
      ),
      children: [
        WittCard(
          padding: const EdgeInsets.all(WittSpacing.md),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: status == MultiplayerStatus.offline
                      ? Colors.grey
                      : WittColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: WittSpacing.sm),
              Text(switch (status) {
                MultiplayerStatus.offline => 'Offline',
                MultiplayerStatus.searching => 'Searching…',
                MultiplayerStatus.inLobby => 'In Lobby',
                MultiplayerStatus.inGame => 'In Game',
              }, style: theme.textTheme.titleSmall),
              const Spacer(),
              WittButton(
                label: status == MultiplayerStatus.offline
                    ? 'Go Online'
                    : 'Disconnect',
                onPressed: () =>
                    ref
                        .read(multiplayerStatusProvider.notifier)
                        .state = status == MultiplayerStatus.offline
                    ? MultiplayerStatus.searching
                    : MultiplayerStatus.offline,
                variant: status == MultiplayerStatus.offline
                    ? WittButtonVariant.primary
                    : WittButtonVariant.outline,
                size: WittButtonSize.sm,
              ),
            ],
          ),
        ),
        const SizedBox(height: WittSpacing.lg),
        Text('Multiplayer Games', style: theme.textTheme.titleSmall),
        const SizedBox(height: WittSpacing.sm),
        ...allGames
            .where((g) => g.supportsMultiplayer)
            .map(
              (g) => Padding(
                padding: const EdgeInsets.only(bottom: WittSpacing.sm),
                child: WittCard(
                  padding: const EdgeInsets.all(WittSpacing.md),
                  child: Row(
                    children: [
                      Text(g.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: WittSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.title, style: theme.textTheme.titleSmall),
                            Text(
                              g.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? WittColors.textSecondaryDark
                                    : WittColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      WittButton(
                        label: 'Find Match',
                        onPressed: () {
                          ref.read(multiplayerStatusProvider.notifier).state =
                              MultiplayerStatus.searching;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Searching for ${g.title} opponent…',
                              ),
                            ),
                          );
                        },
                        size: WittButtonSize.sm,
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

// ── Leaderboard Tab ───────────────────────────────────────────────────────

class _LeaderboardTab extends ConsumerWidget {
  const _LeaderboardTab({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(leaderboardProvider);
    final top3 = entries.where((e) => e.rank <= 3).toList();
    final rest = entries.where((e) => e.rank > 3 && !e.isCurrentUser).toList();
    final me = entries.where((e) => e.isCurrentUser).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        WittSpacing.lg,
        WittSpacing.md,
        WittSpacing.lg,
        100,
      ),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Global', 'Friends', 'School', 'Weekly']
                .map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(right: WittSpacing.sm),
                    child: WittChip(label: t, onTap: () {}),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: WittSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (top3.length > 1)
              Expanded(
                child: _PodiumCard(entry: top3[1], height: 80, isDark: isDark),
              ),
            const SizedBox(width: WittSpacing.sm),
            if (top3.isNotEmpty)
              Expanded(
                child: _PodiumCard(entry: top3[0], height: 100, isDark: isDark),
              ),
            const SizedBox(width: WittSpacing.sm),
            if (top3.length > 2)
              Expanded(
                child: _PodiumCard(entry: top3[2], height: 60, isDark: isDark),
              ),
          ],
        ),
        const SizedBox(height: WittSpacing.lg),
        ...rest.map((e) => _LeaderboardRow(entry: e, isDark: isDark)),
        if (me.isNotEmpty) ...[
          const Divider(),
          ...me.map(
            (e) => _LeaderboardRow(entry: e, isDark: isDark, highlight: true),
          ),
        ],
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.entry,
    required this.height,
    required this.isDark,
  });
  final LeaderboardEntry entry;
  final double height;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medal = entry.rank == 1
        ? '🥇'
        : entry.rank == 2
        ? '🥈'
        : '🥉';
    return Column(
      children: [
        Text(medal, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: WittSpacing.xs),
        WittAvatar(initials: entry.avatarInitials, size: WittAvatarSize.md),
        const SizedBox(height: WittSpacing.xs),
        Text(
          entry.name.split(' ').first,
          style: theme.textTheme.labelSmall,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${(entry.score / 1000).toStringAsFixed(1)}K',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: WittColors.primary,
          ),
        ),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: entry.rank == 1
                ? WittColors.streak.withAlpha(51)
                : WittColors.primary.withAlpha(26),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              '#${entry.rank}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: entry.rank == 1 ? WittColors.streak : WittColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.entry,
    required this.isDark,
    this.highlight = false,
  });
  final LeaderboardEntry entry;
  final bool isDark;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: WittSpacing.sm),
      padding: const EdgeInsets.all(WittSpacing.md),
      decoration: BoxDecoration(
        color: highlight
            ? WittColors.primary.withAlpha(26)
            : (isDark ? WittColors.surfaceVariantDark : WittColors.surface),
        borderRadius: WittSpacing.borderRadiusMd,
        border: Border.all(
          color: highlight
              ? WittColors.primary
              : (isDark ? WittColors.outlineDark : WittColors.outline),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: highlight ? WittColors.primary : null,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: WittSpacing.sm),
          Text(entry.country, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: WittSpacing.sm),
          WittAvatar(initials: entry.avatarInitials, size: WittAvatarSize.sm),
          const SizedBox(width: WittSpacing.sm),
          Expanded(
            child: Text(
              entry.name,
              style: theme.textTheme.titleSmall?.copyWith(
                color: highlight ? WittColors.primary : null,
              ),
            ),
          ),
          Text(
            '${(entry.score / 1000).toStringAsFixed(1)}K',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: highlight ? WittColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────

class _LimitBanner extends StatelessWidget {
  const _LimitBanner({required this.message, required this.isFull});
  final String message;
  final bool isFull;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: WittSpacing.md),
      padding: const EdgeInsets.all(WittSpacing.md),
      decoration: BoxDecoration(
        color: (isFull ? WittColors.error : WittColors.secondary).withAlpha(26),
        borderRadius: WittSpacing.borderRadiusMd,
        border: Border.all(
          color: (isFull ? WittColors.error : WittColors.secondary).withAlpha(
            77,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isFull ? Icons.block_rounded : Icons.info_outline_rounded,
            color: isFull ? WittColors.error : WittColors.secondary,
            size: 18,
          ),
          const SizedBox(width: WittSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isFull ? WittColors.error : WittColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
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

// ── Game Launch Sheet ─────────────────────────────────────────────────────

class _GameLaunchSheet extends StatelessWidget {
  const _GameLaunchSheet({required this.game});
  final GameDefinition game;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(WittSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(game.emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: WittSpacing.md),
          Text(game.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: WittSpacing.sm),
          Text(
            game.description,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WittSpacing.xl),
          WittButton(
            label: 'Start Game',
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${game.title} — full game engine coming in Phase 5',
                  ),
                ),
              );
            },
            variant: WittButtonVariant.primary,
          ),
          const SizedBox(height: WittSpacing.sm),
          WittButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
            variant: WittButtonVariant.outline,
          ),
        ],
      ),
    );
  }
}
