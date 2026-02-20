import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../../learn/models/question.dart';
import '../models/quiz.dart';
import '../providers/quiz_providers.dart';

class QuizSessionScreen extends ConsumerWidget {
  const QuizSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(quizSessionProvider);

    if (session == null) {
      return const Scaffold(body: Center(child: WittLoading()));
    }

    if (session.isComplete) {
      return _QuizResultsView(session: session);
    }

    final q = session.currentQuestion;
    if (q == null) {
      return const Scaffold(body: Center(child: WittLoading()));
    }

    final selected = session.answers[q.id] ?? const [];
    final progress = session.questions.isEmpty
        ? 0.0
        : session.currentIndex / session.questions.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            _QuizHeader(
              session: session,
              progress: progress,
              onClose: () => _confirmClose(context, ref),
            ),

            // ── Question ──────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(WittSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question number
                    Text(
                      'Question ${session.currentIndex + 1} of ${session.questions.length}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: WittColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: WittSpacing.sm),

                    // Question text
                    Text(
                      q.text,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: WittSpacing.lg),

                    // Options
                    ...q.options.asMap().entries.map((entry) {
                      final option = entry.value;
                      final label = String.fromCharCode(65 + entry.key);
                      final isSelected = selected.contains(option.id);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: WittSpacing.sm),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref
                                .read(quizSessionProvider.notifier)
                                .selectAnswer(q.id, option.id);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: WittSpacing.md,
                              vertical: WittSpacing.sm + 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? WittColors.primaryContainer
                                  : WittColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(
                                WittSpacing.sm,
                              ),
                              border: Border.all(
                                color: isSelected
                                    ? WittColors.primary
                                    : WittColors.outline,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? WittColors.primary
                                        : WittColors.outline,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isSelected
                                          ? Colors.white
                                          : WittColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: WittSpacing.md),
                                Expanded(
                                  child: Text(
                                    option.text,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : null,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ── Bottom bar ────────────────────────────────────────────
            _QuizBottomBar(session: session),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClose(BuildContext context, WidgetRef ref) async {
    final nav = Navigator.of(context);
    final end = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End quiz?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End quiz'),
          ),
        ],
      ),
    );
    if (end == true) {
      ref.read(quizSessionProvider.notifier).resetQuiz();
      nav.pop();
    }
  }
}

// ── Quiz header ───────────────────────────────────────────────────────────

class _QuizHeader extends StatelessWidget {
  const _QuizHeader({
    required this.session,
    required this.progress,
    required this.onClose,
  });
  final QuizSessionState session;
  final double progress;
  final VoidCallback onClose;

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = session.timeRemainingSeconds;
    final isLow = remaining != null && remaining < 60;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WittSpacing.md,
            vertical: WittSpacing.sm,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: WittSpacing.sm),
              Expanded(
                child: Text(
                  session.config.title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (remaining != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: WittSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isLow
                        ? WittColors.error.withValues(alpha: 0.1)
                        : WittColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isLow
                          ? WittColors.error.withValues(alpha: 0.4)
                          : WittColors.outline,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 14,
                        color: isLow
                            ? WittColors.error
                            : WittColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(remaining),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isLow
                              ? WittColors.error
                              : WittColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: WittColors.outline,
          valueColor: const AlwaysStoppedAnimation<Color>(WittColors.primary),
          minHeight: 3,
        ),
      ],
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────

class _QuizBottomBar extends ConsumerWidget {
  const _QuizBottomBar({required this.session});
  final QuizSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFirst = session.currentIndex == 0;
    final hasAnswer = session.answers.containsKey(session.currentQuestion?.id);

    return Container(
      padding: EdgeInsets.fromLTRB(
        WittSpacing.lg,
        WittSpacing.sm,
        WittSpacing.lg,
        WittSpacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: const Border(top: BorderSide(color: WittColors.outline)),
      ),
      child: Row(
        children: [
          WittButton(
            label: 'Prev',
            onPressed: isFirst
                ? null
                : () =>
                      ref.read(quizSessionProvider.notifier).previousQuestion(),
            variant: WittButtonVariant.outline,
            icon: Icons.arrow_back,
            size: WittButtonSize.sm,
          ),
          const Spacer(),
          Text(
            '${session.answeredCount}/${session.questions.length}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: WittColors.textTertiary,
            ),
          ),
          const Spacer(),
          WittButton(
            label: session.isLastQuestion ? 'Submit' : 'Next',
            onPressed: hasAnswer
                ? () => ref.read(quizSessionProvider.notifier).nextQuestion()
                : null,
            icon: session.isLastQuestion ? Icons.check : Icons.arrow_forward,
            size: WittButtonSize.sm,
          ),
        ],
      ),
    );
  }
}

// ── Quiz results view ─────────────────────────────────────────────────────

class _QuizResultsView extends ConsumerWidget {
  const _QuizResultsView({required this.session});
  final QuizSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(quizHistoryProvider);
    final result = history.isNotEmpty ? history.first : null;
    final theme = Theme.of(context);

    final accuracy = result?.accuracy ?? 0.0;
    final correct = result?.correctCount ?? 0;
    final total = session.questions.length;
    final xp = result?.xpEarned ?? 0;
    final isPassed = accuracy >= 0.7;
    final scoreColor = isPassed ? WittColors.success : WittColors.error;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              title: const Text('Quiz Complete'),
              actions: [
                TextButton(
                  onPressed: () {
                    ref.read(quizSessionProvider.notifier).resetQuiz();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ],
            ),

            // Score circle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(WittSpacing.xl),
                child: Column(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scoreColor.withValues(alpha: 0.1),
                        border: Border.all(color: scoreColor, width: 3),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(accuracy * 100).round()}%',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: scoreColor,
                            ),
                          ),
                          Text(
                            '$correct/$total',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: WittColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: WittSpacing.md),
                    Text(
                      isPassed ? 'Quiz Passed! 🎉' : 'Keep Practicing! 💪',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: WittSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: WittColors.xp.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '+$xp XP earned',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: WittColors.xp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Question review
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: WittSpacing.lg),
                child: Text(
                  'Review',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: WittSpacing.sm)),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final q = session.questions[index];
                final selected = session.answers[q.id] ?? [];
                final isCorrect =
                    selected.isNotEmpty &&
                    selected.toSet().containsAll(q.correctAnswerIds.toSet()) &&
                    q.correctAnswerIds.toSet().containsAll(selected.toSet());

                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    WittSpacing.lg,
                    0,
                    WittSpacing.lg,
                    WittSpacing.sm,
                  ),
                  child: _ReviewTile(
                    question: q,
                    selectedIds: selected,
                    isCorrect: isCorrect,
                    index: index,
                  ),
                );
              }, childCount: session.questions.length),
            ),

            // Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  WittSpacing.lg,
                  WittSpacing.lg,
                  WittSpacing.lg,
                  WittSpacing.lg + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: WittButton(
                        label: 'Retake Quiz',
                        onPressed: () {
                          final config = session.config;
                          if (config.source == QuizSource.aiGenerated) {
                            ref
                                .read(quizSessionProvider.notifier)
                                .startQuizAi(config);
                          } else {
                            ref
                                .read(quizSessionProvider.notifier)
                                .startQuiz(config);
                          }
                        },
                        icon: Icons.refresh,
                      ),
                    ),
                    const SizedBox(height: WittSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: WittButton(
                        label: 'New Quiz',
                        onPressed: () {
                          ref.read(quizSessionProvider.notifier).resetQuiz();
                          Navigator.of(context).pop();
                        },
                        variant: WittButtonVariant.outline,
                        icon: Icons.add,
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
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.question,
    required this.selectedIds,
    required this.isCorrect,
    required this.index,
  });
  final Question question;
  final List<String> selectedIds;
  final bool isCorrect;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isCorrect ? WittColors.success : WittColors.error;

    return Container(
      padding: const EdgeInsets.all(WittSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(WittSpacing.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Q${index + 1}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            question.text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (!isCorrect && question.explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '💡 ${question.explanation}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: WittColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
