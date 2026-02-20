import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../../learn/models/question.dart';
import '../models/mock_test.dart';
import '../providers/mock_test_providers.dart';
import 'mock_test_results_screen.dart';

class MockTestScreen extends ConsumerWidget {
  const MockTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(mockTestSessionProvider);

    if (session == null) {
      return const Scaffold(body: Center(child: WittLoading()));
    }

    if (session.status == TestStatus.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const MockTestResultsScreen(),
            ),
          );
        }
      });
      return const Scaffold(body: Center(child: WittLoading()));
    }

    if (session.status == TestStatus.paused) {
      return _PausedOverlay(session: session);
    }

    final currentSection = session.currentSection;
    final currentQuestion = session.currentQuestion;

    if (currentSection == null || currentQuestion == null) {
      return const Scaffold(body: Center(child: WittLoading()));
    }

    final selectedAnswers =
        session.answers[currentQuestion.id] ?? const [];
    final isFlagged = session.flagged.contains(currentQuestion.id);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            _MockTestHeader(session: session),

            // ── Section timer bar ─────────────────────────────────────
            _SectionTimerBar(section: currentSection),

            // ── Question ──────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(WittSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question number + flag
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: WittColors.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Q ${session.globalQuestionIndex + 1} of ${session.totalQuestions}',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: WittColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(width: WittSpacing.sm),
                        _DifficultyBadge(
                            difficulty: currentQuestion.difficulty),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            isFlagged ? Icons.flag : Icons.flag_outlined,
                            color: isFlagged
                                ? WittColors.secondary
                                : WittColors.textTertiary,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(mockTestSessionProvider.notifier)
                                .toggleFlag(currentQuestion.id);
                          },
                          tooltip: 'Flag for review',
                        ),
                      ],
                    ),
                    const SizedBox(height: WittSpacing.md),

                    // Passage (if any)
                    if (currentQuestion.passageText != null) ...[
                      Container(
                        padding: const EdgeInsets.all(WittSpacing.md),
                        decoration: BoxDecoration(
                          color: WittColors.surfaceVariant,
                          borderRadius:
                              BorderRadius.circular(WittSpacing.sm),
                          border: Border.all(color: WittColors.outline),
                        ),
                        child: Text(
                          currentQuestion.passageText!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(height: 1.6),
                        ),
                      ),
                      const SizedBox(height: WittSpacing.md),
                    ],

                    // Question text
                    Text(
                      currentQuestion.text,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: WittSpacing.lg),

                    // Options
                    ...currentQuestion.options.asMap().entries.map(
                      (entry) {
                        final option = entry.value;
                        final label = String.fromCharCode(
                            65 + entry.key); // A, B, C, D
                        final isSelected =
                            selectedAnswers.contains(option.id);

                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: WittSpacing.sm),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(mockTestSessionProvider.notifier)
                                  .selectAnswer(
                                      currentQuestion.id, option.id);
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
                                    WittSpacing.sm),
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
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom navigation ─────────────────────────────────────
            _MockTestBottomBar(session: session),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────

class _MockTestHeader extends ConsumerWidget {
  const _MockTestHeader({required this.session});
  final MockTestSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress =
        session.totalQuestions == 0
            ? 0.0
            : session.globalQuestionIndex / session.totalQuestions;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: WittSpacing.md, vertical: WittSpacing.sm),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.pause),
                onPressed: () =>
                    ref.read(mockTestSessionProvider.notifier).pauseTest(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: WittSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.exam.name,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      session.currentSection?.section.name ?? '',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: WittColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              // Stats
              Row(
                children: [
                  _HeaderStat(
                    icon: Icons.check_circle_outline,
                    value: '${session.answeredCount}',
                    color: WittColors.success,
                  ),
                  const SizedBox(width: WittSpacing.sm),
                  _HeaderStat(
                    icon: Icons.flag_outlined,
                    value: '${session.flaggedCount}',
                    color: WittColors.secondary,
                  ),
                ],
              ),
              const SizedBox(width: WittSpacing.sm),
              IconButton(
                icon: const Icon(Icons.grid_view),
                onPressed: () => _showQuestionGrid(context, session, ref),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: WittColors.outline,
          valueColor:
              const AlwaysStoppedAnimation<Color>(WittColors.primary),
          minHeight: 3,
        ),
      ],
    );
  }

  void _showQuestionGrid(BuildContext context, MockTestSessionState session,
      WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _QuestionGridSheet(session: session, ref: ref),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.icon,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Section timer bar ─────────────────────────────────────────────────────

class _SectionTimerBar extends StatelessWidget {
  const _SectionTimerBar({required this.section});
  final MockTestSection section;

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLow = section.timeRemainingSeconds < 300; // < 5 min
    final color = isLow ? WittColors.error : WittColors.accent;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: WittSpacing.lg, vertical: 6),
      color: color.withValues(alpha: 0.06),
      child: Row(
        children: [
          Icon(Icons.timer, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            section.section.name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: WittColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            _formatTime(section.timeRemainingSeconds),
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────

class _MockTestBottomBar extends ConsumerWidget {
  const _MockTestBottomBar({required this.session});
  final MockTestSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFirst = session.currentQuestionIndex == 0 &&
        session.currentSectionIndex == 0;
    final isLast = session.isLastSection && session.isLastQuestion;

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
          // Previous
          WittButton(
            label: 'Prev',
            onPressed: isFirst
                ? null
                : () => ref
                    .read(mockTestSessionProvider.notifier)
                    .previousQuestion(),
            variant: WittButtonVariant.outline,
            icon: Icons.arrow_back,
            size: WittButtonSize.sm,
          ),
          const Spacer(),
          // Section indicator
          Text(
            'Section ${session.currentSectionIndex + 1}/${session.sections.length}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: WittColors.textTertiary,
            ),
          ),
          const Spacer(),
          // Next / Submit
          WittButton(
            label: isLast ? 'Submit' : 'Next',
            onPressed: () {
              if (isLast) {
                _confirmSubmit(context, ref);
              } else {
                ref
                    .read(mockTestSessionProvider.notifier)
                    .nextQuestion();
              }
            },
            icon: isLast ? Icons.check : Icons.arrow_forward,
            size: WittButtonSize.sm,
          ),
        ],
      ),
    );
  }

  void _confirmSubmit(BuildContext context, WidgetRef ref) {
    final session = ref.read(mockTestSessionProvider);
    if (session == null) return;
    final unanswered =
        session.totalQuestions - session.answeredCount;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Test?'),
        content: Text(unanswered > 0
            ? 'You have $unanswered unanswered question${unanswered == 1 ? '' : 's'}. Submit anyway?'
            : 'Are you sure you want to submit your test?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Review'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(mockTestSessionProvider.notifier).submitTest();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

// ── Question grid sheet ───────────────────────────────────────────────────

class _QuestionGridSheet extends StatelessWidget {
  const _QuestionGridSheet({required this.session, required this.ref});
  final MockTestSessionState session;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        WittSpacing.lg,
        WittSpacing.lg,
        WittSpacing.lg,
        WittSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question Navigator',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: WittSpacing.sm),
          // Legend
          Row(
            children: [
              _LegendItem(color: WittColors.primary, label: 'Answered'),
              const SizedBox(width: WittSpacing.md),
              _LegendItem(color: WittColors.secondary, label: 'Flagged'),
              const SizedBox(width: WittSpacing.md),
              _LegendItem(
                  color: WittColors.textTertiary, label: 'Unanswered'),
            ],
          ),
          const SizedBox(height: WittSpacing.md),
          // Grid per section
          ...session.sections.asMap().entries.map((sEntry) {
            final sIdx = sEntry.key;
            final sec = sEntry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sec.section.name,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: WittColors.textSecondary,
                  ),
                ),
                const SizedBox(height: WittSpacing.xs),
                Wrap(
                  spacing: WittSpacing.xs,
                  runSpacing: WittSpacing.xs,
                  children: sec.questions.asMap().entries.map((qEntry) {
                    final qIdx = qEntry.key;
                    final q = qEntry.value;
                    final isAnswered =
                        session.answers.containsKey(q.id);
                    final isFlagged = session.flagged.contains(q.id);
                    final isCurrent = sIdx ==
                            session.currentSectionIndex &&
                        qIdx == session.currentQuestionIndex;

                    Color bgColor = WittColors.outline;
                    if (isAnswered) bgColor = WittColors.primary;
                    if (isFlagged) bgColor = WittColors.secondary;

                    return GestureDetector(
                      onTap: () {
                        ref
                            .read(mockTestSessionProvider.notifier)
                            .navigateToQuestion(sIdx, qIdx);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: bgColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isCurrent
                                ? WittColors.primary
                                : bgColor.withValues(alpha: 0.4),
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${qIdx + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isAnswered || isFlagged
                                ? bgColor
                                : WittColors.textTertiary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: WittSpacing.md),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: WittColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

// ── Paused overlay ────────────────────────────────────────────────────────

class _PausedOverlay extends ConsumerWidget {
  const _PausedOverlay({required this.session});
  final MockTestSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(WittSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pause_circle,
                    size: 80, color: WittColors.primary),
                const SizedBox(height: WittSpacing.lg),
                Text(
                  'Test Paused',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: WittSpacing.sm),
                Text(
                  '${session.exam.name} · ${session.answeredCount}/${session.totalQuestions} answered',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: WittColors.textSecondary,
                  ),
                ),
                const SizedBox(height: WittSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: WittButton(
                    label: 'Resume Test',
                    onPressed: () => ref
                        .read(mockTestSessionProvider.notifier)
                        .resumeTest(),
                    icon: Icons.play_arrow,
                  ),
                ),
                const SizedBox(height: WittSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: WittButton(
                    label: 'Abandon Test',
                    onPressed: () {
                      ref
                          .read(mockTestSessionProvider.notifier)
                          .abandonTest();
                      Navigator.of(context).pop();
                    },
                    variant: WittButtonVariant.danger,
                    icon: Icons.close,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Difficulty badge ──────────────────────────────────────────────────────

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});
  final DifficultyLevel difficulty;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (difficulty) {
      DifficultyLevel.easy => (WittColors.success, 'Easy'),
      DifficultyLevel.medium => (WittColors.secondary, 'Medium'),
      DifficultyLevel.hard => (WittColors.error, 'Hard'),
      DifficultyLevel.expert => (WittColors.accent, 'Expert'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
