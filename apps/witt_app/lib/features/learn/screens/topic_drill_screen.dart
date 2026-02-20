import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../models/question.dart';
import '../providers/exam_providers.dart';
import '../providers/test_prep_providers.dart';
import '../widgets/question_card.dart';
import 'exam_paywall_screen.dart';
import 'drill_results_screen.dart';

class TopicDrillScreen extends ConsumerStatefulWidget {
  const TopicDrillScreen({
    super.key,
    required this.examId,
    required this.sectionId,
    required this.sectionName,
    required this.topic,
  });

  final String examId;
  final String sectionId;
  final String sectionName;
  final String topic;

  @override
  ConsumerState<TopicDrillScreen> createState() => _TopicDrillScreenState();
}

class _TopicDrillScreenState extends ConsumerState<TopicDrillScreen> {
  late Timer _timer;
  int _elapsedSeconds = 0;
  bool _timerRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isPaid = ref.read(isPaidUserProvider);
      ref
          .read(topicDrillProvider(widget.examId).notifier)
          .startDrill(
            sectionId: widget.sectionId,
            topic: widget.topic,
            isPaidUser: isPaid,
          );
      _startTimer();
    });
  }

  void _startTimer() {
    _timerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _timerRunning) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _onSubmit() {
    HapticFeedback.lightImpact();
    ref.read(topicDrillProvider(widget.examId).notifier).submitAnswer();
  }

  void _onNext() {
    final isPaid = ref.read(isPaidUserProvider);
    ref
        .read(topicDrillProvider(widget.examId).notifier)
        .nextQuestion(isPaidUser: isPaid);
  }

  void _onClose() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quit drill?'),
        content: const Text('Your progress in this drill will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Quit', style: TextStyle(color: WittColors.error)),
          ),
        ],
      ),
    ).then((quit) {
      if (quit == true && mounted) {
        ref.read(topicDrillProvider(widget.examId).notifier).reset();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final drill = ref.watch(topicDrillProvider(widget.examId));
    final exam = ref.watch(examByIdProvider(widget.examId));
    final isBookmarked =
        drill.currentQuestion != null &&
        ref
            .watch(bookmarkedQuestionsProvider)
            .contains(drill.currentQuestion!.id);

    // ── Status transitions ──────────────────────────────────────────────
    if (drill.status == DrillStatus.paywalled) {
      _timerRunning = false;
      return ExamPaywallScreen(
        examId: widget.examId,
        questionsUsed: drill.questionsAttemptedTotal,
        onDismiss: () {
          ref.read(topicDrillProvider(widget.examId).notifier).reset();
          Navigator.of(context).pop();
        },
      );
    }

    if (drill.status == DrillStatus.complete) {
      _timerRunning = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => DrillResultsScreen(
                examId: widget.examId,
                sectionName: widget.sectionName,
                topic: widget.topic,
                attempts: drill.attempts,
                questions: drill.questions,
                totalTimeSeconds: _elapsedSeconds,
                finalTheta: drill.userTheta,
              ),
            ),
          );
        }
      });
      return const Scaffold(body: Center(child: WittLoading()));
    }

    if (drill.status == DrillStatus.idle ||
        drill.status == DrillStatus.loading) {
      return const Scaffold(body: Center(child: WittLoading()));
    }

    final q = drill.currentQuestion;
    if (q == null) {
      return const Scaffold(body: Center(child: WittLoading()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            QuestionProgressHeader(
              examName: exam?.name ?? widget.examId.toUpperCase(),
              sectionName: '${widget.sectionName} · ${widget.topic}',
              currentIndex: drill.currentIndex,
              totalQuestions: drill.questions.length,
              elapsedSeconds: _elapsedSeconds,
              onClose: _onClose,
            ),

            // ── Difficulty badge ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: WittSpacing.lg,
                vertical: 4,
              ),
              child: Row(
                children: [
                  _DifficultyBadge(difficulty: q.difficulty),
                  const SizedBox(width: WittSpacing.xs),
                  Text(
                    q.topic,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: WittColors.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '~${q.estimatedTimeSeconds}s',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: WittColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Question card ──────────────────────────────────────────
            Expanded(
              child: QuestionCard(
                question: q,
                selectedAnswerIds: drill.selectedAnswerIds,
                hasSubmitted: drill.hasSubmitted,
                isBookmarked: isBookmarked,
                onOptionTap: (optionId) {
                  if (!drill.hasSubmitted) {
                    ref
                        .read(topicDrillProvider(widget.examId).notifier)
                        .toggleAnswer(optionId);
                  }
                },
                onBookmarkTap: () {
                  ref.read(bookmarkedQuestionsProvider.notifier).toggle(q.id);
                },
              ),
            ),

            // ── Bottom bar ─────────────────────────────────────────────
            _DrillBottomBar(drill: drill, onSubmit: _onSubmit, onNext: _onNext),
          ],
        ),
      ),
    );
  }
}

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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _DrillBottomBar extends StatelessWidget {
  const _DrillBottomBar({
    required this.drill,
    required this.onSubmit,
    required this.onNext,
  });

  final TopicDrillState drill;
  final VoidCallback onSubmit;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSelected = drill.selectedAnswerIds.isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(
        WittSpacing.lg,
        WittSpacing.md,
        WittSpacing.lg,
        WittSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: WittColors.outline)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (drill.hasSubmitted) ...[
            _FeedbackRow(drill: drill),
            const SizedBox(height: WittSpacing.md),
          ],
          SizedBox(
            width: double.infinity,
            child: drill.hasSubmitted
                ? WittButton(
                    label: drill.isLast ? 'See Results' : 'Next Question',
                    onPressed: onNext,
                    icon: drill.isLast ? Icons.bar_chart : Icons.arrow_forward,
                  )
                : WittButton(
                    label: 'Submit Answer',
                    onPressed: hasSelected ? onSubmit : null,
                  ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackRow extends StatelessWidget {
  const _FeedbackRow({required this.drill});
  final TopicDrillState drill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (drill.attempts.isEmpty) return const SizedBox.shrink();
    final last = drill.attempts.last;
    final isCorrect = last.isCorrect;
    final color = isCorrect ? WittColors.success : WittColors.error;

    return Row(
      children: [
        Icon(
          isCorrect ? Icons.check_circle : Icons.cancel,
          color: color,
          size: 20,
        ),
        const SizedBox(width: WittSpacing.xs),
        Text(
          isCorrect ? 'Correct!' : 'Incorrect',
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          '${drill.correctCount}/${drill.attempts.length} correct',
          style: theme.textTheme.labelMedium?.copyWith(
            color: WittColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
