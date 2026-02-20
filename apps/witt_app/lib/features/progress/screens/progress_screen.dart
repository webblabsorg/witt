import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../models/progress_models.dart';
import '../providers/progress_providers.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(progressSummaryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: const Text('Progress'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: WittSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Level & XP bar
                  _LevelCard(summary: summary),
                  const SizedBox(height: WittSpacing.md),

                  // Streak + quick stats row
                  _StatsRow(summary: summary),
                  const SizedBox(height: WittSpacing.md),

                  // Weekly activity chart
                  _WeeklyActivityCard(activity: summary.weeklyActivity),
                  const SizedBox(height: WittSpacing.md),

                  // Exam readiness
                  if (summary.examReadiness.isNotEmpty) ...[
                    Text(
                      'Exam Readiness',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: WittSpacing.sm),
                    ...summary.examReadiness
                        .map((e) => _ExamReadinessCard(readiness: e)),
                    const SizedBox(height: WittSpacing.md),
                  ],

                  // Badges
                  if (summary.badges.isNotEmpty) ...[
                    Text(
                      'Badges',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: WittSpacing.sm),
                    _BadgesRow(badges: summary.badges),
                    const SizedBox(height: WittSpacing.md),
                  ],

                  // All-time stats
                  _AllTimeStats(summary: summary),
                  const SizedBox(height: WittSpacing.xxxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Level & XP ────────────────────────────────────────────────────────────

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.summary});
  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(WittSpacing.lg),
      decoration: BoxDecoration(
        gradient: WittColors.primaryGradient,
        borderRadius: BorderRadius.circular(WittSpacing.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'L${summary.level}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: WittSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${summary.level}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${summary.xpPoints} XP · ${summary.xpToNextLevel} to next level',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: WittSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: summary.levelProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.summary});
  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            icon: '🔥',
            value: '${summary.streak.currentDays}',
            label: 'Day streak',
            color: const Color(0xFFF97316),
          ),
        ),
        const SizedBox(width: WittSpacing.sm),
        Expanded(
          child: _StatChip(
            icon: '🎯',
            value: '${(summary.overallAccuracy * 100).round()}%',
            label: 'Accuracy',
            color: WittColors.success,
          ),
        ),
        const SizedBox(width: WittSpacing.sm),
        Expanded(
          child: _StatChip(
            icon: '⏱️',
            value: _formatMinutes(summary.totalMinutesStudied),
            label: 'Study time',
            color: WittColors.primary,
          ),
        ),
      ],
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final String icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(WittSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(WittSpacing.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: WittColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Weekly activity chart ─────────────────────────────────────────────────

class _WeeklyActivityCard extends StatelessWidget {
  const _WeeklyActivityCard({required this.activity});
  final List<DailyActivity> activity;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxQ = activity.fold<int>(
      1,
      (m, a) => a.questionsAnswered > m ? a.questionsAnswered : m,
    );

    return Container(
      padding: const EdgeInsets.all(WittSpacing.md),
      decoration: BoxDecoration(
        color: WittColors.surfaceVariant,
        borderRadius: BorderRadius.circular(WittSpacing.md),
        border: Border.all(color: WittColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This Week',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                '${activity.fold<int>(0, (s, a) => s + a.questionsAnswered)} questions',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: WittColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: WittSpacing.md),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: activity.asMap().entries.map((entry) {
                final i = entry.key;
                final a = entry.value;
                final heightFraction =
                    maxQ == 0 ? 0.0 : a.questionsAnswered / maxQ;
                final isToday = i == activity.length - 1;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300 + i * 50),
                          height: (heightFraction * 56).clamp(4.0, 56.0),
                          decoration: BoxDecoration(
                            color: isToday
                                ? WittColors.primary
                                : WittColors.primary.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _days[a.date.weekday - 1],
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            color: isToday
                                ? WittColors.primary
                                : WittColors.textTertiary,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Exam readiness ────────────────────────────────────────────────────────

class _ExamReadinessCard extends StatelessWidget {
  const _ExamReadinessCard({required this.readiness});
  final ExamReadiness readiness;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = readiness.readinessPercent >= 70
        ? WittColors.success
        : readiness.readinessPercent >= 40
            ? WittColors.warning
            : WittColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: WittSpacing.sm),
      padding: const EdgeInsets.all(WittSpacing.md),
      decoration: BoxDecoration(
        color: WittColors.surfaceVariant,
        borderRadius: BorderRadius.circular(WittSpacing.md),
        border: Border.all(color: WittColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                readiness.examName,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: WittSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${readiness.readinessPercent}% ready',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: WittSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: readiness.readinessPercent / 100,
              backgroundColor: WittColors.outline,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: WittSpacing.sm),
          Row(
            children: [
              Text(
                '${readiness.questionsAttempted} questions · '
                '${(readiness.accuracy * 100).round()}% accuracy',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: WittColors.textSecondary,
                ),
              ),
            ],
          ),
          if (readiness.weakTopics.isNotEmpty) ...[
            const SizedBox(height: WittSpacing.xs),
            Wrap(
              spacing: 4,
              children: readiness.weakTopics.take(3).map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: WittColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '⚠ $t',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: WittColors.error,
                      fontSize: 10,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Badges ────────────────────────────────────────────────────────────────

class _BadgesRow extends StatelessWidget {
  const _BadgesRow({required this.badges});
  final List<String> badges;

  static const _badgeEmojis = {
    '7-Day Streak': '🔥',
    '3-Day Streak': '🔥',
    '30-Day Streak': '🔥',
    'First 100 Questions': '💯',
    '500 Questions': '🏆',
    '1000 Questions': '🌟',
    '50 Correct': '✅',
    '1000 XP': '⚡',
    '5000 XP': '💎',
    'Night Owl': '🦉',
    'Speed Demon': '⚡',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: badges.length,
        separatorBuilder: (_, __) => const SizedBox(width: WittSpacing.sm),
        itemBuilder: (_, i) {
          final badge = badges[i];
          final emoji = _badgeEmojis[badge] ?? '🏅';
          return Container(
            width: 72,
            padding: const EdgeInsets.all(WittSpacing.sm),
            decoration: BoxDecoration(
              color: WittColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(WittSpacing.md),
              border: Border.all(
                color: WittColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(
                  badge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: WittColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── All-time stats ────────────────────────────────────────────────────────

class _AllTimeStats extends StatelessWidget {
  const _AllTimeStats({required this.summary});
  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(WittSpacing.md),
      decoration: BoxDecoration(
        color: WittColors.surfaceVariant,
        borderRadius: BorderRadius.circular(WittSpacing.md),
        border: Border.all(color: WittColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All-Time Stats',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: WittSpacing.md),
          _StatRow(
            icon: Icons.quiz_outlined,
            label: 'Questions answered',
            value: '${summary.totalQuestionsAnswered}',
          ),
          _StatRow(
            icon: Icons.check_circle_outline,
            label: 'Correct answers',
            value: '${summary.totalCorrect}',
          ),
          _StatRow(
            icon: Icons.style_outlined,
            label: 'Flashcards reviewed',
            value: '${summary.totalFlashcardsReviewed}',
          ),
          _StatRow(
            icon: Icons.local_fire_department_outlined,
            label: 'Longest streak',
            value: '${summary.streak.longestDays} days',
          ),
          _StatRow(
            icon: Icons.emoji_events_outlined,
            label: 'Total XP',
            value: '${summary.xpPoints}',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: WittSpacing.sm),
          child: Row(
            children: [
              Icon(icon, size: 18, color: WittColors.primary),
              const SizedBox(width: WittSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: WittColors.primary,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: WittColors.outline),
      ],
    );
  }
}
