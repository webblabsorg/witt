import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';
import '../models/question.dart';
import '../providers/exam_providers.dart';

class SessionResultsScreen extends ConsumerWidget {
  const SessionResultsScreen({
    super.key,
    required this.examId,
    required this.sectionName,
    required this.attempts,
    required this.questions,
    required this.totalTimeSeconds,
  });

  final String examId;
  final String sectionName;
  final List<QuestionAttempt> attempts;
  final List<Question> questions;
  final int totalTimeSeconds;

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exam = ref.watch(examByIdProvider(examId));
    final examName = exam?.name ?? examId.toUpperCase();

    final correct = attempts.where((a) => a.isCorrect).length;
    final total = attempts.length;
    final accuracy = total == 0 ? 0.0 : correct / total;
    final xpEarned = (correct * 10 + (accuracy * 50)).round();

    // Topic breakdown
    final Map<String, List<bool>> topicResults = {};
    for (int i = 0; i < attempts.length; i++) {
      if (i < questions.length) {
        final topic = questions[i].topic;
        topicResults.putIfAbsent(topic, () => []).add(attempts[i].isCorrect);
      }
    }

    final Color scoreColor = accuracy >= 0.8
        ? WittColors.success
        : accuracy >= 0.6
            ? WittColors.secondary
            : WittColors.error;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(WittSpacing.lg),
                child: Column(
                  children: [
                    // Score circle
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scoreColor.withValues(alpha: 0.12),
                        border: Border.all(color: scoreColor, width: 3),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(accuracy * 100).round()}%',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scoreColor,
                            ),
                          ),
                          Text(
                            '$correct/$total',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: WittColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: WittSpacing.md),
                    Text(
                      _scoreLabel(accuracy),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: WittSpacing.xs),
                    Text(
                      '$examName · $sectionName',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: WittColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Stats row ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: WittSpacing.lg),
                child: Row(
                  children: [
                    _StatChip(
                      icon: Icons.timer_outlined,
                      label: 'Time',
                      value: _formatTime(totalTimeSeconds),
                    ),
                    const SizedBox(width: WittSpacing.sm),
                    _StatChip(
                      icon: Icons.bolt,
                      label: 'XP Earned',
                      value: '+$xpEarned',
                      valueColor: WittColors.xp,
                    ),
                    const SizedBox(width: WittSpacing.sm),
                    _StatChip(
                      icon: Icons.trending_up,
                      label: 'Accuracy',
                      value: '${(accuracy * 100).round()}%',
                      valueColor: scoreColor,
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: WittSpacing.lg),
            ),

            // ── Topic breakdown ────────────────────────────────────────
            if (topicResults.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: WittSpacing.lg),
                  child: Text(
                    'Topic Breakdown',
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
                  (context, index) {
                    final entry =
                        topicResults.entries.elementAt(index);
                    final topicCorrect =
                        entry.value.where((b) => b).length;
                    final topicTotal = entry.value.length;
                    final topicAcc = topicTotal == 0
                        ? 0.0
                        : topicCorrect / topicTotal;
                    return _TopicRow(
                      topic: entry.key,
                      correct: topicCorrect,
                      total: topicTotal,
                      accuracy: topicAcc,
                    );
                  },
                  childCount: topicResults.length,
                ),
              ),
              const SliverToBoxAdapter(
                  child: SizedBox(height: WittSpacing.lg)),
            ],

            // ── Question review ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: WittSpacing.lg),
                child: Text(
                  'Question Review',
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
                (context, index) {
                  final attempt = attempts[index];
                  final question = index < questions.length
                      ? questions[index]
                      : null;
                  return _ReviewRow(
                    index: index,
                    attempt: attempt,
                    question: question,
                  );
                },
                childCount: attempts.length,
              ),
            ),

            // ── Actions ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  WittSpacing.lg,
                  WittSpacing.lg,
                  WittSpacing.lg,
                  WittSpacing.lg +
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: WittButton(
                        label: 'Try Again',
                        onPressed: () => context.pop(),
                        icon: Icons.refresh,
                      ),
                    ),
                    const SizedBox(height: WittSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: WittButton(
                        label: 'Back to Exam Hub',
                        onPressed: () => context.pop(),
                        variant: WittButtonVariant.outline,
                        icon: Icons.arrow_back,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _scoreLabel(double accuracy) {
    if (accuracy >= 0.9) return 'Excellent! 🎉';
    if (accuracy >= 0.8) return 'Great Work! 👏';
    if (accuracy >= 0.6) return 'Good Effort! 💪';
    if (accuracy >= 0.4) return 'Keep Practicing! 📚';
    return 'Don\'t Give Up! 🔥';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: WittSpacing.sm,
          vertical: WittSpacing.md,
        ),
        decoration: BoxDecoration(
          color: WittColors.surfaceVariant,
          borderRadius: BorderRadius.circular(WittSpacing.sm),
          border: Border.all(color: WittColors.outline),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: WittColors.textTertiary),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: WittColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({
    required this.topic,
    required this.correct,
    required this.total,
    required this.accuracy,
  });

  final String topic;
  final int correct;
  final int total;
  final double accuracy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accuracy >= 0.7
        ? WittColors.success
        : accuracy >= 0.4
            ? WittColors.secondary
            : WittColors.error;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          WittSpacing.lg, 0, WittSpacing.lg, WittSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: accuracy,
                    backgroundColor: WittColors.outline,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: WittSpacing.md),
          Text(
            '$correct/$total',
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.index,
    required this.attempt,
    required this.question,
  });

  final int index;
  final QuestionAttempt attempt;
  final Question? question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCorrect = attempt.isCorrect;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          WittSpacing.lg, 0, WittSpacing.lg, WittSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCorrect
                  ? WittColors.successContainer
                  : WittColors.errorContainer,
            ),
            alignment: Alignment.center,
            child: Icon(
              isCorrect ? Icons.check : Icons.close,
              size: 14,
              color: isCorrect ? WittColors.success : WittColors.error,
            ),
          ),
          const SizedBox(width: WittSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Q${index + 1}${question != null ? ' · ${question!.topic}' : ''}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: WittColors.textTertiary,
                  ),
                ),
                if (question != null)
                  Text(
                    question!.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(width: WittSpacing.sm),
          Text(
            '${attempt.timeSpentSeconds}s',
            style: theme.textTheme.labelSmall?.copyWith(
              color: WittColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
