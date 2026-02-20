import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../models/flashcard.dart';
import '../providers/flashcard_providers.dart';
import '../services/sm2_algorithm.dart';
import 'study_complete_screen.dart';

class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({
    super.key,
    required this.deckId,
    required this.mode,
    required this.cards,
  });

  final String deckId;
  final StudyMode mode;
  final List<Flashcard> cards;

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  late Timer _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(studySessionProvider.notifier)
          .startSession(
            deckId: widget.deckId,
            mode: widget.mode,
            cards: widget.cards,
          );
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(studySessionProvider);

    if (session == null) {
      return const Scaffold(body: Center(child: WittLoading()));
    }

    if (session.status == StudySessionStatus.complete) {
      _timer.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => StudyCompleteScreen(
                deckId: widget.deckId,
                mode: widget.mode,
                session: session,
                totalTimeSeconds: _elapsedSeconds,
              ),
            ),
          );
        }
      });
      return const Scaffold(body: Center(child: WittLoading()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _StudyHeader(
              session: session,
              elapsedSeconds: _elapsedSeconds,
              onClose: () => _confirmClose(context),
            ),
            Expanded(
              child: switch (session.mode) {
                StudyMode.flashcard => _FlashcardMode(session: session),
                StudyMode.learn => _LearnMode(session: session),
                StudyMode.write => _WriteMode(session: session),
                StudyMode.match => _MatchMode(session: session),
                StudyMode.test => _TestMode(session: session),
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClose(BuildContext context) async {
    final nav = Navigator.of(context);
    final end = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End session?'),
        content: const Text('Your progress will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep studying'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End session'),
          ),
        ],
      ),
    );
    if (end == true && mounted) {
      ref.read(studySessionProvider.notifier).endSession();
      nav.pop();
    }
  }
}

// ── Study header ──────────────────────────────────────────────────────────

class _StudyHeader extends StatelessWidget {
  const _StudyHeader({
    required this.session,
    required this.elapsedSeconds,
    required this.onClose,
  });

  final StudySessionState session;
  final int elapsedSeconds;
  final VoidCallback onClose;

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String get _modeLabel => switch (session.mode) {
    StudyMode.flashcard => 'Flashcard',
    StudyMode.learn => 'Learn',
    StudyMode.write => 'Write',
    StudyMode.match => 'Match',
    StudyMode.test => 'Test',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = session.queue.isEmpty
        ? 0.0
        : session.currentIndex / session.queue.length;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _modeLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${session.currentIndex + 1} / ${session.queue.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: WittColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: WittSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: WittColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: WittColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(elapsedSeconds),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: WittColors.textSecondary,
                        fontWeight: FontWeight.w600,
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

// ── Flashcard mode ────────────────────────────────────────────────────────

class _FlashcardMode extends ConsumerWidget {
  const _FlashcardMode({required this.session});
  final StudySessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = session.currentCard;
    if (card == null) return const SizedBox.shrink();

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(WittSpacing.lg),
            child: GestureDetector(
              onTap: () => ref.read(studySessionProvider.notifier).flip(),
              child: _FlipCard(card: card, isFlipped: session.isFlipped),
            ),
          ),
        ),
        if (!session.isFlipped)
          Padding(
            padding: EdgeInsets.fromLTRB(
              WittSpacing.lg,
              0,
              WittSpacing.lg,
              WittSpacing.lg + MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              child: WittButton(
                label: 'Show Answer',
                onPressed: () => ref.read(studySessionProvider.notifier).flip(),
                variant: WittButtonVariant.outline,
                icon: Icons.flip,
              ),
            ),
          )
        else
          _RatingBar(card: card),
      ],
    );
  }
}

// ── Flip card widget ──────────────────────────────────────────────────────

class _FlipCard extends StatefulWidget {
  const _FlipCard({required this.card, required this.isFlipped});
  final Flashcard card;
  final bool isFlipped;

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_FlipCard old) {
    super.didUpdateWidget(old);
    if (widget.isFlipped != old.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * 3.14159;
        final showBack = _animation.value > 0.5;
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: showBack
              ? Transform(
                  transform: Matrix4.identity()..rotateY(3.14159),
                  alignment: Alignment.center,
                  child: _CardFace(
                    text: widget.card.back,
                    label: 'Answer',
                    color: WittColors.primaryContainer,
                    borderColor: WittColors.primary,
                  ),
                )
              : _CardFace(
                  text: widget.card.front,
                  label: 'Question',
                  hint: widget.card.hint,
                  color: WittColors.surfaceVariant,
                  borderColor: WittColors.outline,
                ),
        );
      },
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.text,
    required this.label,
    required this.color,
    required this.borderColor,
    this.hint,
  });

  final String text;
  final String label;
  final Color color;
  final Color borderColor;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(WittSpacing.lg),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: WittSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: borderColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: borderColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: WittSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: WittSpacing.xl),
            child: Text(
              text,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: WittSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: WittSpacing.xl),
              child: Text(
                '💡 $hint',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: WittColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: WittSpacing.lg),
          Text(
            'Tap to flip',
            style: theme.textTheme.labelSmall?.copyWith(
              color: WittColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rating bar ────────────────────────────────────────────────────────────

class _RatingBar extends ConsumerWidget {
  const _RatingBar({required this.card});
  final Flashcard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        WittSpacing.lg,
        0,
        WittSpacing.lg,
        WittSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        children: [
          Text(
            'How well did you know this?',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: WittColors.textSecondary),
          ),
          const SizedBox(height: WittSpacing.sm),
          Row(
            children: Sm2Rating.values.map((rating) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _RatingButton(
                    rating: rating,
                    card: card,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(studySessionProvider.notifier).rate(rating);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.rating,
    required this.card,
    required this.onTap,
  });

  final Sm2Rating rating;
  final Flashcard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, label, icon) = switch (rating) {
      Sm2Rating.again => (WittColors.error, 'Again', Icons.replay),
      Sm2Rating.hard => (
        WittColors.warning,
        'Hard',
        Icons.sentiment_dissatisfied,
      ),
      Sm2Rating.good => (
        WittColors.secondary,
        'Good',
        Icons.sentiment_satisfied,
      ),
      Sm2Rating.easy => (
        WittColors.success,
        'Easy',
        Icons.sentiment_very_satisfied,
      ),
    };
    final interval = Sm2Algorithm.intervalLabel(rating, card);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: WittSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(WittSpacing.sm),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              interval,
              style: theme.textTheme.labelSmall?.copyWith(
                color: WittColors.textTertiary,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Learn mode ────────────────────────────────────────────────────────────

class _LearnMode extends ConsumerWidget {
  const _LearnMode({required this.session});
  final StudySessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = session.currentCard;
    if (card == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(WittSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Front
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(WittSpacing.lg),
            decoration: BoxDecoration(
              color: WittColors.primaryContainer,
              borderRadius: BorderRadius.circular(WittSpacing.md),
              border: Border.all(
                color: WittColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Term',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: WittColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: WittSpacing.sm),
                Text(
                  card.front,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: WittSpacing.md),

          // Back
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(WittSpacing.lg),
            decoration: BoxDecoration(
              color: WittColors.surfaceVariant,
              borderRadius: BorderRadius.circular(WittSpacing.md),
              border: Border.all(color: WittColors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Definition',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: WittColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: WittSpacing.sm),
                Text(
                  card.back,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                if (card.hint != null) ...[
                  const SizedBox(height: WittSpacing.sm),
                  Text(
                    '💡 ${card.hint}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: WittColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: WittSpacing.xl),

          _RatingBar(card: card),
        ],
      ),
    );
  }
}

// ── Write mode ────────────────────────────────────────────────────────────

class _WriteMode extends ConsumerStatefulWidget {
  const _WriteMode({required this.session});
  final StudySessionState session;

  @override
  ConsumerState<_WriteMode> createState() => _WriteModeState();
}

class _WriteModeState extends ConsumerState<_WriteMode> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.session.currentCard;
    if (card == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        WittSpacing.lg,
        WittSpacing.lg,
        WittSpacing.lg,
        WittSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(WittSpacing.lg),
            decoration: BoxDecoration(
              color: WittColors.primaryContainer,
              borderRadius: BorderRadius.circular(WittSpacing.md),
              border: Border.all(
                color: WittColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              card.front,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: WittSpacing.xl),
          Text(
            'Type your answer:',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: WittSpacing.sm),
          TextField(
            controller: _controller,
            onChanged: (v) =>
                ref.read(studySessionProvider.notifier).updateTypedAnswer(v),
            decoration: const InputDecoration(
              hintText: 'Enter answer…',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: WittSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: WittButton(
              label: 'Check Answer',
              onPressed: _controller.text.trim().isEmpty
                  ? null
                  : () {
                      ref
                          .read(studySessionProvider.notifier)
                          .submitTypedAnswer();
                      _controller.clear();
                    },
              icon: Icons.check,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Match mode ────────────────────────────────────────────────────────────

class _MatchMode extends ConsumerWidget {
  const _MatchMode({required this.session});
  final StudySessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairs = session.matchPairs;
    final completed = session.matchCompleted;
    final selected = session.matchSelected;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(WittSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Match the terms with their definitions',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: WittColors.textSecondary,
            ),
          ),
          const SizedBox(height: WittSpacing.md),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: WittSpacing.sm,
                mainAxisSpacing: WittSpacing.sm,
                childAspectRatio: 1.4,
              ),
              itemCount: pairs.length * 2,
              itemBuilder: (context, index) {
                final pairIndex = index % pairs.length;
                final isFront = index < pairs.length;
                final pair = pairs[pairIndex];
                final id = isFront ? pair.id : '${pair.id}_back';
                final text = isFront ? pair.front : pair.back;
                final isCompleted = completed.contains(pair.id);
                final isSelected = selected == id;

                return GestureDetector(
                  onTap: isCompleted
                      ? null
                      : () => ref
                            .read(studySessionProvider.notifier)
                            .selectMatchItem(id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(WittSpacing.sm),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? WittColors.successContainer
                          : isSelected
                          ? WittColors.primaryContainer
                          : WittColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(WittSpacing.sm),
                      border: Border.all(
                        color: isCompleted
                            ? WittColors.success
                            : isSelected
                            ? WittColors.primary
                            : WittColors.outline,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      text,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isCompleted
                            ? WittColors.success
                            : isSelected
                            ? WittColors.primary
                            : null,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Test mode ─────────────────────────────────────────────────────────────

class _TestMode extends ConsumerWidget {
  const _TestMode({required this.session});
  final StudySessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = session.currentCard;
    if (card == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    // Build 4 options: 1 correct + 3 distractors from other cards
    final allCards = ref.watch(cardsForDeckProvider(session.deckId));
    final distractors = allCards.where((c) => c.id != card.id).toList()
      ..shuffle();
    final options = [card.back, ...distractors.take(3).map((c) => c.back)]
      ..shuffle();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(WittSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(WittSpacing.lg),
            decoration: BoxDecoration(
              color: WittColors.primaryContainer,
              borderRadius: BorderRadius.circular(WittSpacing.md),
              border: Border.all(
                color: WittColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              card.front,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: WittSpacing.lg),
          Text(
            'Choose the correct answer:',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: WittSpacing.sm),
          ...options.asMap().entries.map((entry) {
            final label = String.fromCharCode(65 + entry.key); // A, B, C, D
            final isCorrect = entry.value == card.back;
            return Padding(
              padding: const EdgeInsets.only(bottom: WittSpacing.sm),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref
                      .read(studySessionProvider.notifier)
                      .rate(isCorrect ? Sm2Rating.good : Sm2Rating.again);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: WittSpacing.md,
                    vertical: WittSpacing.sm + 2,
                  ),
                  decoration: BoxDecoration(
                    color: WittColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(WittSpacing.sm),
                    border: Border.all(color: WittColors.outline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: WittColors.outline,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: WittSpacing.md),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: theme.textTheme.bodyMedium,
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
    );
  }
}
