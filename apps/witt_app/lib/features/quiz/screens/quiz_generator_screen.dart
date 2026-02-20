import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../../learn/data/exam_catalog.dart';
import '../models/quiz.dart';
import '../providers/quiz_providers.dart';
import 'quiz_session_screen.dart';

class QuizGeneratorScreen extends ConsumerWidget {
  const QuizGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(quizConfigProvider);
    final history = ref.watch(quizHistoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Quiz Generator'),
          ),

          // ── Quick start ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(WittSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Start',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: WittSpacing.sm),
                  Row(
                    children: [
                      _QuickStartCard(
                        icon: '⚡',
                        label: '5 Questions',
                        subtitle: '~2 min',
                        onTap: () => _quickStart(context, ref, 5),
                      ),
                      const SizedBox(width: WittSpacing.sm),
                      _QuickStartCard(
                        icon: '🎯',
                        label: '10 Questions',
                        subtitle: '~5 min',
                        onTap: () => _quickStart(context, ref, 10),
                      ),
                      const SizedBox(width: WittSpacing.sm),
                      _QuickStartCard(
                        icon: '🏆',
                        label: '20 Questions',
                        subtitle: '~10 min',
                        onTap: () => _quickStart(context, ref, 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Custom quiz builder ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                WittSpacing.lg,
                0,
                WittSpacing.lg,
                WittSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Custom Quiz',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: WittSpacing.sm),
                  _QuizBuilderCard(config: config),
                ],
              ),
            ),
          ),

          // ── Recent quizzes ─────────────────────────────────────────
          if (history.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  WittSpacing.lg,
                  0,
                  WittSpacing.lg,
                  WittSpacing.sm,
                ),
                child: Text(
                  'Recent Quizzes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _QuizHistoryTile(result: history[index]),
                childCount: history.take(5).length,
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startCustomQuiz(context, ref, config),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Quiz'),
        backgroundColor: WittColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _quickStart(BuildContext context, WidgetRef ref, int count) {
    final config = QuizConfig(
      title: 'Quick Quiz ($count Qs)',
      source: QuizSource.fromExam,
      sourceId: allExams.isNotEmpty ? allExams.first.id : 'sat',
      questionCount: count,
      difficulty: QuizDifficulty.mixed,
    );
    ref.read(quizSessionProvider.notifier).startQuiz(config);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const QuizSessionScreen()));
  }

  void _startCustomQuiz(
    BuildContext context,
    WidgetRef ref,
    QuizConfig config,
  ) {
    ref.read(quizSessionProvider.notifier).startQuiz(config);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const QuizSessionScreen()));
  }
}

// ── Quick start card ──────────────────────────────────────────────────────

class _QuickStartCard extends StatelessWidget {
  const _QuickStartCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
  final String icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: WittSpacing.md,
            horizontal: WittSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: WittColors.primaryContainer,
            borderRadius: BorderRadius.circular(WittSpacing.sm),
            border: Border.all(
              color: WittColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: WittColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: WittColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quiz builder card ─────────────────────────────────────────────────────

class _QuizBuilderCard extends ConsumerWidget {
  const _QuizBuilderCard({required this.config});
  final QuizConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(quizConfigProvider.notifier);

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
          // Source
          Text(
            'Source',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: WittSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: QuizSource.values.map((s) {
                final selected = config.source == s;
                return Padding(
                  padding: const EdgeInsets.only(right: WittSpacing.sm),
                  child: GestureDetector(
                    onTap: () => notifier.setSource(s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? WittColors.primary
                            : WittColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? WittColors.primary
                              : WittColors.outline,
                        ),
                      ),
                      child: Text(
                        _sourceLabel(s),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: selected
                              ? Colors.white
                              : WittColors.textSecondary,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: WittSpacing.md),

          // Exam picker (when fromExam)
          if (config.source == QuizSource.fromExam) ...[
            Text(
              'Exam',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: WittSpacing.xs),
            DropdownButtonFormField<String>(
              initialValue: config.sourceId ?? allExams.first.id,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: allExams
                  .take(10)
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.id,
                      child: Text('${e.emoji} ${e.name}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) =>
                  notifier.setSource(QuizSource.fromExam, sourceId: v),
            ),
            const SizedBox(height: WittSpacing.md),
          ],

          // Question count
          Text(
            'Questions: ${config.questionCount}',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Slider(
            value: config.questionCount.toDouble(),
            min: 5,
            max: 30,
            divisions: 5,
            label: '${config.questionCount}',
            activeColor: WittColors.primary,
            onChanged: (v) => notifier.setQuestionCount(v.round()),
          ),

          // Difficulty
          Text(
            'Difficulty',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: WittSpacing.xs),
          Row(
            children: QuizDifficulty.values.map((d) {
              final selected = config.difficulty == d;
              final color = switch (d) {
                QuizDifficulty.easy => WittColors.success,
                QuizDifficulty.mixed => WittColors.secondary,
                QuizDifficulty.hard => WittColors.error,
              };
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: GestureDetector(
                    onTap: () => notifier.setDifficulty(d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withValues(alpha: 0.15)
                            : WittColors.surface,
                        borderRadius: BorderRadius.circular(WittSpacing.xs),
                        border: Border.all(
                          color: selected ? color : WittColors.outline,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        d.name[0].toUpperCase() + d.name.substring(1),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: selected ? color : WittColors.textSecondary,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: WittSpacing.md),

          // Time limit
          Row(
            children: [
              Expanded(
                child: Text(
                  'Time limit',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DropdownButton<int?>(
                value: config.timeLimitMinutes,
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...[5, 10, 15, 20, 30].map(
                    (m) => DropdownMenuItem(value: m, child: Text('$m min')),
                  ),
                ],
                onChanged: notifier.setTimeLimitMinutes,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _sourceLabel(QuizSource s) => switch (s) {
    QuizSource.manual => 'Manual',
    QuizSource.fromNote => 'From Note',
    QuizSource.fromVocabList => 'Vocabulary',
    QuizSource.fromExam => 'Exam',
    QuizSource.aiGenerated => 'AI (soon)',
  };
}

// ── Quiz history tile ─────────────────────────────────────────────────────

class _QuizHistoryTile extends StatelessWidget {
  const _QuizHistoryTile({required this.result});
  final QuizResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = result.status == QuizResultStatus.pass
        ? WittColors.success
        : WittColors.error;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WittSpacing.lg,
        0,
        WittSpacing.lg,
        WittSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(WittSpacing.md),
        decoration: BoxDecoration(
          color: WittColors.surfaceVariant,
          borderRadius: BorderRadius.circular(WittSpacing.sm),
          border: Border.all(color: WittColors.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              alignment: Alignment.center,
              child: Text(
                '${(result.accuracy * 100).round()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: WittSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.config.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${result.correctCount}/${result.totalQuestions} correct · +${result.xpEarned} XP',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: WittColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _timeAgo(result.completedAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: WittColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
