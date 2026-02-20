import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';

import '../../../features/auth/auth_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authNotifierProvider);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          auth.user != null ? '$greeting 👋' : 'Home',
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          // Search
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search',
            onPressed: () => context.push('/home/search'),
          ),
          // Notifications
          WittDotBadge(
            show: true,
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Notifications',
              onPressed: () => context.push('/home/notifications'),
            ),
          ),
          // Play Hub
          WittDotBadge(
            show: true,
            color: WittColors.secondary,
            child: IconButton(
              icon: const Icon(Icons.sports_esports_outlined),
              tooltip: 'Play Hub',
              onPressed: () => context.push('/home/play'),
            ),
          ),
          const SizedBox(width: WittSpacing.sm),
        ],
      ),
      body: RefreshIndicator(
        color: WittColors.primary,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            WittSpacing.lg,
            WittSpacing.md,
            WittSpacing.lg,
            WittSpacing.massive,
          ),
          children: [
            // Daily Streak Banner
            _StreakBanner(),
            const SizedBox(height: WittSpacing.lg),

            // Today's Study Plan
            _SectionHeader(title: "Today's Study Plan", onSeeAll: () {}),
            const SizedBox(height: WittSpacing.md),
            _StudyPlanCard(),
            const SizedBox(height: WittSpacing.lg),

            // Continue Studying
            _SectionHeader(title: 'Continue Studying', onSeeAll: () {}),
            const SizedBox(height: WittSpacing.md),
            _ContinueStudyingCard(),
            const SizedBox(height: WittSpacing.lg),

            // Quick Actions
            _SectionHeader(title: 'Quick Actions'),
            const SizedBox(height: WittSpacing.md),
            _QuickActionsRow(),
            const SizedBox(height: WittSpacing.lg),

            // Exam Countdowns
            _SectionHeader(title: 'Exam Countdowns', onSeeAll: () {}),
            const SizedBox(height: WittSpacing.md),
            _ExamCountdownsRow(),
            const SizedBox(height: WittSpacing.lg),

            // Daily Brain Challenge
            _SectionHeader(title: 'Daily Brain Challenge'),
            const SizedBox(height: WittSpacing.md),
            _BrainChallengeCard(),
            const SizedBox(height: WittSpacing.lg),

            // Word of the Day
            _SectionHeader(title: 'Word of the Day'),
            const SizedBox(height: WittSpacing.md),
            _WordOfTheDayCard(),
            const SizedBox(height: WittSpacing.lg),

            // Recent Activity
            _SectionHeader(title: 'Recent Activity', onSeeAll: () {}),
            const SizedBox(height: WittSpacing.md),
            _RecentActivityList(),
            const SizedBox(height: WittSpacing.lg),

            // Recommended for You
            _SectionHeader(title: 'Recommended for You'),
            const SizedBox(height: WittSpacing.md),
            _RecommendedCard(),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: WittSpacing.sm),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('See all'),
          ),
      ],
    );
  }
}

// ─── Streak Banner ─────────────────────────────────────────────────────────────

class _StreakBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WittCard(
      gradient: WittColors.streakGradient,
      padding: const EdgeInsets.all(WittSpacing.lg),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 36)),
          const SizedBox(width: WittSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '7-day streak!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Keep it up — study today to maintain your streak',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withAlpha(204),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '120',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'XP today',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withAlpha(204),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Study Plan Card ───────────────────────────────────────────────────────────

class _StudyPlanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return WittCard(
      child: Column(
        children: [
          _PlanItem(
            subject: 'SAT Math',
            topic: 'Algebra — Linear Equations',
            duration: '30 min',
            color: WittColors.math,
            isDone: true,
          ),
          Divider(
            height: WittSpacing.lg,
            color: isDark ? WittColors.outlineDark : WittColors.outline,
          ),
          _PlanItem(
            subject: 'SAT Reading',
            topic: 'Evidence-Based Reading',
            duration: '25 min',
            color: WittColors.english,
          ),
          Divider(
            height: WittSpacing.lg,
            color: isDark ? WittColors.outlineDark : WittColors.outline,
          ),
          _PlanItem(
            subject: 'Vocabulary',
            topic: 'Word of the Day + 5 new words',
            duration: '10 min',
            color: WittColors.languages,
          ),
        ],
      ),
    );
  }
}

class _PlanItem extends StatelessWidget {
  const _PlanItem({
    required this.subject,
    required this.topic,
    required this.duration,
    required this.color,
    this.isDone = false,
  });
  final String subject;
  final String topic;
  final String duration;
  final Color color;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: isDone ? WittColors.success : color,
            borderRadius: WittSpacing.borderRadiusFull,
          ),
        ),
        const SizedBox(width: WittSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject,
                style: theme.textTheme.labelMedium?.copyWith(color: color),
              ),
              Text(
                topic,
                style: theme.textTheme.bodyMedium?.copyWith(
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
        ),
        if (isDone)
          const Icon(
            Icons.check_circle_rounded,
            color: WittColors.success,
            size: 20,
          )
        else
          WittBadge(label: duration, variant: WittBadgeVariant.neutral),
      ],
    );
  }
}

// ─── Continue Studying ─────────────────────────────────────────────────────────

class _ContinueStudyingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WittCard(
      onTap: () {},
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: WittColors.primaryContainer,
              borderRadius: WittSpacing.borderRadiusMd,
            ),
            child: const Icon(Icons.quiz_rounded, color: WittColors.primary),
          ),
          const SizedBox(width: WittSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SAT Practice Test #3', style: theme.textTheme.titleSmall),
                const SizedBox(height: WittSpacing.xs),
                WittProgressBar(
                  value: 0.62,
                  height: 6,
                  gradient: WittColors.primaryGradient,
                ),
                const SizedBox(height: WittSpacing.xs),
                Text(
                  '62% complete • 38 questions left',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: WittSpacing.md),
          const Icon(
            Icons.play_circle_rounded,
            color: WittColors.primary,
            size: 32,
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions ─────────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  static const _actions = [
    _Action(
      Icons.document_scanner_outlined,
      'Scan\nHomework',
      WittColors.accent,
    ),
    _Action(Icons.mic_rounded, 'Record\nLecture', WittColors.error),
    _Action(Icons.style_rounded, 'Create\nFlashcard', WittColors.secondary),
    _Action(Icons.assignment_rounded, 'Mock\nTest', WittColors.primary),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: _actions.map((a) {
        return Expanded(
          child: GestureDetector(
            onTap: () {},
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: a.color.withAlpha(26),
                    borderRadius: WittSpacing.borderRadiusLg,
                  ),
                  child: Icon(a.icon, color: a.color, size: WittSpacing.iconXl),
                ),
                const SizedBox(height: WittSpacing.xs),
                Text(
                  a.label,
                  style: theme.textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Action {
  const _Action(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;
}

// ─── Exam Countdowns ───────────────────────────────────────────────────────────

class _ExamCountdownsRow extends StatelessWidget {
  static const _exams = [
    _ExamCountdown('SAT', 42, 0.68, WittColors.primary),
    _ExamCountdown('IELTS', 87, 0.45, WittColors.accent),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _exams.length,
        separatorBuilder: (_, __) => const SizedBox(width: WittSpacing.md),
        itemBuilder: (context, i) => _ExamCountdownCard(exam: _exams[i]),
      ),
    );
  }
}

class _ExamCountdown {
  const _ExamCountdown(this.name, this.days, this.readiness, this.color);
  final String name;
  final int days;
  final double readiness;
  final Color color;
}

class _ExamCountdownCard extends StatelessWidget {
  const _ExamCountdownCard({required this.exam});
  final _ExamCountdown exam;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WittCard(
      padding: const EdgeInsets.all(WittSpacing.lg),
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                WittBadge(label: exam.name, variant: WittBadgeVariant.primary),
                Text(
                  '${exam.days}d',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: exam.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: WittSpacing.sm),
            Text('days remaining', style: theme.textTheme.bodySmall),
            const SizedBox(height: WittSpacing.md),
            WittProgressBar(
              value: exam.readiness,
              height: 6,
              color: exam.color,
              label: 'Readiness',
              showPercentage: true,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Brain Challenge Card ──────────────────────────────────────────────────────

class _BrainChallengeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WittCard(
      onTap: () {},
      gradient: const LinearGradient(
        colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.all(WittSpacing.lg),
      child: Row(
        children: [
          const Text('🧠', style: TextStyle(fontSize: 40)),
          const SizedBox(width: WittSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Challenge",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: WittColors.primaryLight,
                  ),
                ),
                Text(
                  'Logic Puzzle #47',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: WittSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: Colors.white54,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '23:14:05 remaining',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: WittSpacing.md,
              vertical: WittSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: WittColors.primary,
              borderRadius: WittSpacing.borderRadiusMd,
            ),
            child: Text(
              'Play',
              style: theme.textTheme.labelMedium?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Word of the Day ───────────────────────────────────────────────────────────

class _WordOfTheDayCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return WittCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              WittBadge(
                label: 'WORD OF THE DAY',
                variant: WittBadgeVariant.secondary,
                icon: Icons.auto_stories_rounded,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.volume_up_outlined, size: 20),
                onPressed: () {},
                style: IconButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.all(WittSpacing.xs),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: WittSpacing.md),
          Text('Ephemeral', style: theme.textTheme.headlineSmall),
          Text(
            '/ɪˈfem.ər.əl/',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? WittColors.textSecondaryDark
                  : WittColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: WittSpacing.sm),
          Text(
            'adjective — lasting for a very short time',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: WittSpacing.sm),
          Text(
            '"The ephemeral beauty of cherry blossoms makes them all the more precious."',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? WittColors.textSecondaryDark
                  : WittColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recent Activity ───────────────────────────────────────────────────────────

class _RecentActivityList extends StatelessWidget {
  static const _items = [
    _Activity(
      Icons.quiz_rounded,
      'Completed SAT Math Quiz',
      '85% score',
      '2h ago',
      WittColors.primary,
    ),
    _Activity(
      Icons.style_rounded,
      'Reviewed Vocabulary Deck',
      '24 cards',
      '5h ago',
      WittColors.secondary,
    ),
    _Activity(
      Icons.emoji_events_rounded,
      'Earned "7-Day Streak" badge',
      'Achievement',
      'Yesterday',
      WittColors.streak,
    ),
    _Activity(
      Icons.assignment_rounded,
      'Started SAT Practice Test #3',
      'In progress',
      'Yesterday',
      WittColors.accent,
    ),
    _Activity(
      Icons.auto_awesome_rounded,
      'Sage AI session',
      '12 messages',
      '2 days ago',
      WittColors.accentDark,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return WittCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final isLast = i == _items.length - 1;
          return _ActivityRow(item: item, isLast: isLast);
        }),
      ),
    );
  }
}

class _Activity {
  const _Activity(this.icon, this.title, this.subtitle, this.time, this.color);
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item, required this.isLast});
  final _Activity item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(WittSpacing.lg),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark ? WittColors.outlineDark : WittColors.outline,
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.color.withAlpha(26),
              borderRadius: WittSpacing.borderRadiusMd,
            ),
            child: Icon(item.icon, color: item.color, size: WittSpacing.iconMd),
          ),
          const SizedBox(width: WittSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: theme.textTheme.titleSmall),
                Text(item.subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            item.time,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark
                  ? WittColors.textTertiaryDark
                  : WittColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recommended ──────────────────────────────────────────────────────────────

class _RecommendedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WittCard(
      onTap: () {},
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: WittColors.sageGradient,
              borderRadius: WittSpacing.borderRadiusMd,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: WittSpacing.iconXl,
            ),
          ),
          const SizedBox(width: WittSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WittBadge(
                  label: 'AI RECOMMENDED',
                  variant: WittBadgeVariant.primary,
                  isSmall: true,
                ),
                const SizedBox(height: WittSpacing.xs),
                Text(
                  'Review Algebra Weak Areas',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  'You scored 58% on your last algebra quiz',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: WittColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
