import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';
import '../models/question.dart';
import '../providers/exam_providers.dart';
import '../widgets/question_card.dart';
import 'session_results_screen.dart';

class QuestionScreen extends ConsumerStatefulWidget {
  const QuestionScreen({
    super.key,
    required this.examId,
    required this.sectionName,
    required this.questions,
  });

  final String examId;
  final String sectionName;
  final List<Question> questions;

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen> {
  late Timer _timer;
  int _elapsedSeconds = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(questionSessionProvider.notifier).startSession(widget.questions);
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    HapticFeedback.lightImpact();
    ref.read(questionSessionProvider.notifier).submitAnswer('local_user');
  }

  void _onNext() {
    final session = ref.read(questionSessionProvider);
    if (session == null) return;

    if (session.isComplete ||
        session.currentIndex + 1 >= session.questions.length) {
      _goToResults(session);
      return;
    }

    ref.read(questionSessionProvider.notifier).nextQuestion();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToResults(QuestionSessionState session) {
    _timer.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SessionResultsScreen(
          examId: widget.examId,
          sectionName: widget.sectionName,
          attempts: session.attempts,
          questions: session.questions,
          totalTimeSeconds: _elapsedSeconds,
        ),
      ),
    );
  }

  void _onClose() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quit session?'),
        content: const Text('Your progress in this session will be lost.'),
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
        ref.read(questionSessionProvider.notifier).endSession();
        context.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(questionSessionProvider);
    if (session == null) return const SizedBox.shrink();

    final exam = ref.watch(examByIdProvider(widget.examId));
    final examName = exam?.name ?? widget.examId.toUpperCase();
    final q = session.currentQuestion;
    final isBookmarked = ref.watch(bookmarkedQuestionsProvider).contains(q?.id);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress header ─────────────────────────────────────────
            QuestionProgressHeader(
              examName: examName,
              sectionName: widget.sectionName,
              currentIndex: session.currentIndex,
              totalQuestions: session.questions.length,
              elapsedSeconds: _elapsedSeconds,
              onClose: _onClose,
            ),

            // ── Question content ────────────────────────────────────────
            Expanded(
              child: q == null
                  ? const Center(child: WittLoading())
                  : QuestionCard(
                      question: q,
                      selectedAnswerIds: session.selectedAnswerIds,
                      hasSubmitted: session.hasSubmitted,
                      isBookmarked: isBookmarked,
                      onOptionTap: (optionId) {
                        if (!session.hasSubmitted) {
                          ref
                              .read(questionSessionProvider.notifier)
                              .toggleAnswer(optionId);
                        }
                      },
                      onBookmarkTap: () {
                        ref
                            .read(bookmarkedQuestionsProvider.notifier)
                            .toggle(q.id);
                      },
                    ),
            ),

            // ── Bottom action bar ───────────────────────────────────────
            _BottomBar(session: session, onSubmit: _onSubmit, onNext: _onNext),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.session,
    required this.onSubmit,
    required this.onNext,
  });

  final QuestionSessionState session;
  final VoidCallback onSubmit;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSelected = session.selectedAnswerIds.isNotEmpty;
    final isLast = session.currentIndex + 1 >= session.questions.length;

    return Container(
      padding: EdgeInsets.fromLTRB(
        WittSpacing.lg,
        WittSpacing.md,
        WittSpacing.lg,
        WittSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: WittColors.outline, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Feedback row (after submit) ─────────────────────────────
          if (session.hasSubmitted) ...[
            _FeedbackRow(session: session),
            const SizedBox(height: WittSpacing.md),
          ],

          // ── Action button ───────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: session.hasSubmitted
                ? WittButton(
                    label: isLast ? 'See Results' : 'Next Question',
                    onPressed: onNext,
                    icon: isLast ? Icons.bar_chart : Icons.arrow_forward,
                  )
                : WittButton(
                    label: 'Submit Answer',
                    onPressed: hasSelected ? onSubmit : null,
                    variant: WittButtonVariant.primary,
                  ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackRow extends StatelessWidget {
  const _FeedbackRow({required this.session});
  final QuestionSessionState session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastAttempt = session.attempts.isNotEmpty
        ? session.attempts.last
        : null;
    if (lastAttempt == null) return const SizedBox.shrink();

    final isCorrect = lastAttempt.isCorrect;
    final color = isCorrect ? WittColors.success : WittColors.error;
    final icon = isCorrect ? Icons.check_circle : Icons.cancel;
    final label = isCorrect ? 'Correct!' : 'Incorrect';

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: WittSpacing.xs),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          '${session.correctCount}/${session.attempts.length} correct',
          style: theme.textTheme.labelMedium?.copyWith(
            color: WittColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
