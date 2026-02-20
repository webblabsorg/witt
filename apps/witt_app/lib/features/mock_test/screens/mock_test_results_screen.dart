import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../models/mock_test.dart';
import '../providers/mock_test_providers.dart';

class MockTestResultsScreen extends ConsumerWidget {
  const MockTestResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(mockTestHistoryProvider);
    if (history.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: const Center(child: Text('No results available')),
      );
    }
    final result = history.first;
    return _ResultsView(result: result);
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.result});
  final MockTestResult result;

  String _formatTime(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${sec}s';
    return '${sec}s';
  }

  Color _scoreColor(double accuracy) {
    if (accuracy >= 0.8) return WittColors.success;
    if (accuracy >= 0.6) return WittColors.secondary;
    return WittColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = result.overallAccuracy;
    final scoreColor = _scoreColor(accuracy);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar ────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            title: Text('${result.examName} Results'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {},
                tooltip: 'Share results',
              ),
            ],
          ),

          // ── Score hero ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(WittSpacing.xl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scoreColor.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Score circle
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scoreColor.withValues(alpha: 0.1),
                      border: Border.all(color: scoreColor, width: 3),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          result.scaledScore.round().toString(),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: scoreColor,
                          ),
                        ),
                        Text(
                          'Score',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: WittColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: WittSpacing.md),
                  Text(
                    _scoreLabel(accuracy),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: WittSpacing.xs),
                  Text(
                    '${result.examName} · ${result.config.mode.name}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: WittColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Stats row ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: WittSpacing.lg),
              child: Row(
                children: [
                  _StatBox(
                    label: 'Accuracy',
                    value: '${(accuracy * 100).round()}%',
                    icon: Icons.percent,
                    color: scoreColor,
                  ),
                  const SizedBox(width: WittSpacing.sm),
                  _StatBox(
                    label: 'Correct',
                    value:
                        '${result.totalCorrect}/${result.totalQuestions}',
                    icon: Icons.check_circle_outline,
                    color: WittColors.success,
                  ),
                  const SizedBox(width: WittSpacing.sm),
                  _StatBox(
                    label: 'Time',
                    value: _formatTime(result.totalTimeSeconds),
                    icon: Icons.timer_outlined,
                    color: WittColors.accent,
                  ),
                  const SizedBox(width: WittSpacing.sm),
                  _StatBox(
                    label: 'XP',
                    value: '+${result.xpEarned}',
                    icon: Icons.bolt,
                    color: WittColors.xp,
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
              child: SizedBox(height: WittSpacing.lg)),

          // ── Percentile banner ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: WittSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(WittSpacing.md),
                decoration: BoxDecoration(
                  color: WittColors.accentContainer,
                  borderRadius: BorderRadius.circular(WittSpacing.sm),
                  border: Border.all(
                      color: WittColors.accentLight
                          .withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.leaderboard,
                        color: WittColors.accent, size: 20),
                    const SizedBox(width: WittSpacing.sm),
                    Expanded(
                      child: Text(
                        'You scored better than ${result.percentile.round()}% of test takers',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: WittColors.accentDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(
              child: SizedBox(height: WittSpacing.lg)),

          // ── Section breakdown ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: WittSpacing.lg),
              child: Text(
                'Section Breakdown',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
              child: SizedBox(height: WittSpacing.sm)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.fromLTRB(
                    WittSpacing.lg, 0, WittSpacing.lg, WittSpacing.sm),
                child: _SectionResultCard(
                    section: result.sectionResults[index]),
              ),
              childCount: result.sectionResults.length,
            ),
          ),

          const SliverToBoxAdapter(
              child: SizedBox(height: WittSpacing.lg)),

          // ── Topic breakdown ────────────────────────────────────────
          if (result.sectionResults.any(
              (s) => s.topicBreakdown.isNotEmpty)) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: WittSpacing.lg),
                child: Text(
                  'Topic Performance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
                child: SizedBox(height: WittSpacing.sm)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: WittSpacing.lg),
                child: _TopicBreakdownCard(
                    sectionResults: result.sectionResults),
              ),
            ),
            const SliverToBoxAdapter(
                child: SizedBox(height: WittSpacing.lg)),
          ],

          // ── Actions ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                WittSpacing.lg,
                0,
                WittSpacing.lg,
                WittSpacing.lg +
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: WittButton(
                      label: 'Retake Test',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icons.refresh,
                    ),
                  ),
                  const SizedBox(height: WittSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: WittButton(
                      label: 'Back to Exam Hub',
                      onPressed: () {
                        Navigator.of(context)
                          ..pop()
                          ..pop();
                      },
                      variant: WittButtonVariant.outline,
                      icon: Icons.home,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _scoreLabel(double accuracy) {
    if (accuracy >= 0.9) return 'Outstanding! 🎉';
    if (accuracy >= 0.8) return 'Excellent! 👏';
    if (accuracy >= 0.7) return 'Great Work! 💪';
    if (accuracy >= 0.6) return 'Good Effort! 📚';
    if (accuracy >= 0.4) return 'Keep Practicing! 🔥';
    return 'More Practice Needed 📖';
  }
}

// ── Stat box ──────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  const _StatBox({
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: WittSpacing.xs, vertical: WittSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(WittSpacing.xs),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: WittColors.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section result card ───────────────────────────────────────────────────

class _SectionResultCard extends StatelessWidget {
  const _SectionResultCard({required this.section});
  final SectionResult section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = section.accuracy;
    final color = accuracy >= 0.8
        ? WittColors.success
        : accuracy >= 0.6
            ? WittColors.secondary
            : WittColors.error;

    return Container(
      padding: const EdgeInsets.all(WittSpacing.md),
      decoration: BoxDecoration(
        color: WittColors.surfaceVariant,
        borderRadius: BorderRadius.circular(WittSpacing.sm),
        border: Border.all(color: WittColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  section.sectionName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(accuracy * 100).round()}%',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: WittSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: accuracy,
              backgroundColor: WittColors.outline,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: WittSpacing.sm),
          Row(
            children: [
              _SectionStat(
                  label: 'Correct',
                  value: '${section.correct}/${section.totalQuestions}'),
              const SizedBox(width: WittSpacing.md),
              _SectionStat(
                  label: 'Skipped', value: '${section.skipped}'),
              const SizedBox(width: WittSpacing.md),
              _SectionStat(
                  label: 'Time',
                  value: _formatTime(section.timeSpentSeconds)),
              const SizedBox(width: WittSpacing.md),
              _SectionStat(
                  label: 'Scaled',
                  value: section.scaledScore.round().toString()),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m}m ${sec}s';
  }
}

class _SectionStat extends StatelessWidget {
  const _SectionStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: WittColors.textTertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ── Topic breakdown card ──────────────────────────────────────────────────

class _TopicBreakdownCard extends StatelessWidget {
  const _TopicBreakdownCard({required this.sectionResults});
  final List<SectionResult> sectionResults;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Merge all topic breakdowns
    final allTopics = <String, double>{};
    for (final section in sectionResults) {
      allTopics.addAll(section.topicBreakdown);
    }

    final sorted = allTopics.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Container(
      padding: const EdgeInsets.all(WittSpacing.md),
      decoration: BoxDecoration(
        color: WittColors.surfaceVariant,
        borderRadius: BorderRadius.circular(WittSpacing.sm),
        border: Border.all(color: WittColors.outline),
      ),
      child: Column(
        children: sorted.map((entry) {
          final color = entry.value >= 0.8
              ? WittColors.success
              : entry.value >= 0.6
                  ? WittColors.secondary
                  : WittColors.error;
          return Padding(
            padding:
                const EdgeInsets.only(bottom: WittSpacing.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    entry.key,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: WittSpacing.sm),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: entry.value,
                      backgroundColor: WittColors.outline,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: WittSpacing.sm),
                Text(
                  '${(entry.value * 100).round()}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
