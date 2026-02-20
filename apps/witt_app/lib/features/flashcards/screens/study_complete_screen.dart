import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../models/flashcard.dart';
import '../providers/flashcard_providers.dart';

class StudyCompleteScreen extends ConsumerWidget {
  const StudyCompleteScreen({
    super.key,
    required this.deckId,
    required this.mode,
    required this.session,
    required this.totalTimeSeconds,
  });

  final String deckId;
  final StudyMode mode;
  final StudySessionState session;
  final int totalTimeSeconds;

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    if (m == 0) return '${sec}s';
    return '${m}m ${sec}s';
  }

  String get _modeLabel => switch (mode) {
        StudyMode.flashcard => 'Flashcard',
        StudyMode.learn => 'Learn',
        StudyMode.write => 'Write',
        StudyMode.match => 'Match',
        StudyMode.test => 'Test',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final deck = ref.watch(deckByIdProvider(deckId));
    final total = session.queue.length;
    final correct = session.correctCount;
    final accuracy = total == 0 ? 0.0 : correct / total;
    final xpEarned = (correct * 5 +
            session.ratings
                    .where((r) => r == Sm2Rating.easy)
                    .length *
                3)
        .clamp(0, 500);

    final againCount =
        session.ratings.where((r) => r == Sm2Rating.again).length;
    final hardCount =
        session.ratings.where((r) => r == Sm2Rating.hard).length;
    final goodCount =
        session.ratings.where((r) => r == Sm2Rating.good).length;
    final easyCount =
        session.ratings.where((r) => r == Sm2Rating.easy).length;

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
                    // Trophy / score circle
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scoreColor.withValues(alpha: 0.12),
                        border: Border.all(color: scoreColor, width: 3),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            mode == StudyMode.match
                                ? '🎉'
                                : '${(accuracy * 100).round()}%',
                            style: mode == StudyMode.match
                                ? const TextStyle(fontSize: 36)
                                : theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: scoreColor,
                                  ),
                          ),
                          if (mode != StudyMode.match)
                            Text(
                              '$correct/$total',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: WittColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: WittSpacing.md),
                    Text(
                      _scoreLabel(accuracy, mode),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: WittSpacing.xs),
                    Text(
                      '${deck?.name ?? 'Deck'} · $_modeLabel',
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
                      label: 'XP',
                      value: '+$xpEarned',
                      valueColor: WittColors.xp,
                    ),
                    const SizedBox(width: WittSpacing.sm),
                    _StatChip(
                      icon: Icons.style,
                      label: 'Cards',
                      value: '$total',
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
                child: SizedBox(height: WittSpacing.lg)),

            // ── Rating breakdown (flashcard/learn modes) ───────────────
            if (session.ratings.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: WittSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rating Breakdown',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: WittSpacing.sm),
                      _RatingRow(
                          label: 'Again',
                          count: againCount,
                          total: total,
                          color: WittColors.error),
                      _RatingRow(
                          label: 'Hard',
                          count: hardCount,
                          total: total,
                          color: WittColors.warning),
                      _RatingRow(
                          label: 'Good',
                          count: goodCount,
                          total: total,
                          color: WittColors.secondary),
                      _RatingRow(
                          label: 'Easy',
                          count: easyCount,
                          total: total,
                          color: WittColors.success),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                  child: SizedBox(height: WittSpacing.lg)),
            ],

            // ── Next review info ───────────────────────────────────────
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
                      const Icon(Icons.schedule,
                          color: WittColors.accent, size: 20),
                      const SizedBox(width: WittSpacing.sm),
                      Expanded(
                        child: Text(
                          againCount > 0
                              ? '$againCount card${againCount == 1 ? '' : 's'} need more practice. Review again tomorrow.'
                              : 'Great job! All cards scheduled for spaced review.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: WittColors.accentDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                        label: 'Study Again',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icons.refresh,
                      ),
                    ),
                    const SizedBox(height: WittSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: WittButton(
                        label: 'Back to Deck',
                        onPressed: () {
                          Navigator.of(context)
                            ..pop()
                            ..pop();
                        },
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

  String _scoreLabel(double accuracy, StudyMode mode) {
    if (mode == StudyMode.match) return 'All Matched! 🎉';
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
            horizontal: WittSpacing.sm, vertical: WittSpacing.md),
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

class _RatingRow extends StatelessWidget {
  const _RatingRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = total == 0 ? 0.0 : count / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: WittSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: WittSpacing.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: WittColors.outline,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: WittSpacing.sm),
          Text(
            '$count',
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
