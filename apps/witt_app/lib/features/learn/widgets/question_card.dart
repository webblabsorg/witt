import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../models/question.dart';

class QuestionCard extends ConsumerWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.selectedAnswerIds,
    required this.hasSubmitted,
    required this.onOptionTap,
    this.isBookmarked = false,
    this.onBookmarkTap,
  });

  final Question question;
  final List<String> selectedAnswerIds;
  final bool hasSubmitted;
  final void Function(String optionId) onOptionTap;
  final bool isBookmarked;
  final VoidCallback? onBookmarkTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(WittSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Passage (if any) ──────────────────────────────────────────
          if (question.passageText != null) ...[
            _PassageBlock(text: question.passageText!),
            const SizedBox(height: WittSpacing.lg),
          ],

          // ── Question text ─────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  question.text,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    color: isDark
                        ? WittColors.textPrimary
                        : WittColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: WittSpacing.sm),
              IconButton(
                onPressed: onBookmarkTap,
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked
                      ? WittColors.secondary
                      : WittColors.textTertiary,
                ),
              ),
            ],
          ),

          // ── Question image ────────────────────────────────────────────
          if (question.imageUrl != null) ...[
            const SizedBox(height: WittSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(WittSpacing.sm),
              child: Image.network(
                question.imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],

          const SizedBox(height: WittSpacing.lg),

          // ── Options ───────────────────────────────────────────────────
          if (question.type == QuestionType.trueFalse)
            _TrueFalseOptions(
              selectedIds: selectedAnswerIds,
              correctIds: question.correctAnswerIds,
              hasSubmitted: hasSubmitted,
              onTap: onOptionTap,
            )
          else if (question.options.isNotEmpty)
            ...question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final label = String.fromCharCode(65 + index); // A, B, C, D
              return _OptionTile(
                label: label,
                option: option,
                isSelected: selectedAnswerIds.contains(option.id),
                isCorrect: question.correctAnswerIds.contains(option.id),
                hasSubmitted: hasSubmitted,
                onTap: () => onOptionTap(option.id),
              );
            }),

          // ── Explanation (shown after submit) ──────────────────────────
          if (hasSubmitted && question.explanation.isNotEmpty) ...[
            const SizedBox(height: WittSpacing.lg),
            _ExplanationPanel(explanation: question.explanation),
          ],

          const SizedBox(height: WittSpacing.xl),
        ],
      ),
    );
  }
}

// ── Passage block ─────────────────────────────────────────────────────────

class _PassageBlock extends StatefulWidget {
  const _PassageBlock({required this.text});
  final String text;

  @override
  State<_PassageBlock> createState() => _PassageBlockState();
}

class _PassageBlockState extends State<_PassageBlock> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: WittColors.primaryContainer,
        borderRadius: BorderRadius.circular(WittSpacing.sm),
        border: Border.all(
          color: WittColors.primaryLight.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              WittSpacing.md,
              WittSpacing.md,
              WittSpacing.md,
              WittSpacing.xs,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.article_outlined,
                  size: 16,
                  color: WittColors.primary,
                ),
                const SizedBox(width: WittSpacing.xs),
                Text(
                  'Passage',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: WittColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? 'Collapse' : 'Expand',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: WittColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                WittSpacing.md,
                0,
                WittSpacing.md,
                WittSpacing.md,
              ),
              child: Text(
                widget.text,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
              ),
            ),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                WittSpacing.md,
                0,
                WittSpacing.md,
                WittSpacing.md,
              ),
              child: Text(
                widget.text,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

// ── Option tile ───────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.option,
    required this.isSelected,
    required this.isCorrect,
    required this.hasSubmitted,
    required this.onTap,
  });

  final String label;
  final QuestionOption option;
  final bool isSelected;
  final bool isCorrect;
  final bool hasSubmitted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color borderColor = WittColors.outline;
    Color bgColor = Colors.transparent;
    Color labelBg = WittColors.outline;
    Color labelText = WittColors.textSecondary;
    Widget? trailingIcon;

    if (hasSubmitted) {
      if (isCorrect) {
        borderColor = WittColors.success;
        bgColor = WittColors.successContainer;
        labelBg = WittColors.success;
        labelText = Colors.white;
        trailingIcon = const Icon(
          Icons.check_circle,
          color: WittColors.success,
          size: 20,
        );
      } else if (isSelected && !isCorrect) {
        borderColor = WittColors.error;
        bgColor = WittColors.errorContainer;
        labelBg = WittColors.error;
        labelText = Colors.white;
        trailingIcon = const Icon(
          Icons.cancel,
          color: WittColors.error,
          size: 20,
        );
      }
    } else if (isSelected) {
      borderColor = WittColors.primary;
      bgColor = WittColors.primaryContainer;
      labelBg = WittColors.primary;
      labelText = Colors.white;
    }

    return GestureDetector(
      onTap: hasSubmitted ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: WittSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: WittSpacing.md,
          vertical: WittSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(WittSpacing.sm),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            // Label circle
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: labelBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: labelText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: WittSpacing.md),
            Expanded(
              child: Text(
                option.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: WittSpacing.sm),
              trailingIcon,
            ],
          ],
        ),
      ),
    );
  }
}

// ── True/False options ────────────────────────────────────────────────────

class _TrueFalseOptions extends StatelessWidget {
  const _TrueFalseOptions({
    required this.selectedIds,
    required this.correctIds,
    required this.hasSubmitted,
    required this.onTap,
  });

  final List<String> selectedIds;
  final List<String> correctIds;
  final bool hasSubmitted;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TFButton(
            id: 'true',
            label: 'True',
            icon: Icons.check,
            isSelected: selectedIds.contains('true'),
            isCorrect: correctIds.contains('true'),
            hasSubmitted: hasSubmitted,
            onTap: () => onTap('true'),
          ),
        ),
        const SizedBox(width: WittSpacing.md),
        Expanded(
          child: _TFButton(
            id: 'false',
            label: 'False',
            icon: Icons.close,
            isSelected: selectedIds.contains('false'),
            isCorrect: correctIds.contains('false'),
            hasSubmitted: hasSubmitted,
            onTap: () => onTap('false'),
          ),
        ),
      ],
    );
  }
}

class _TFButton extends StatelessWidget {
  const _TFButton({
    required this.id,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isCorrect,
    required this.hasSubmitted,
    required this.onTap,
  });

  final String id;
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isCorrect;
  final bool hasSubmitted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color bg = WittColors.surfaceVariant;
    Color border = WittColors.outline;
    Color fg = WittColors.textSecondary;

    if (hasSubmitted && isCorrect) {
      bg = WittColors.successContainer;
      border = WittColors.success;
      fg = WittColors.success;
    } else if (hasSubmitted && isSelected && !isCorrect) {
      bg = WittColors.errorContainer;
      border = WittColors.error;
      fg = WittColors.error;
    } else if (isSelected) {
      bg = WittColors.primaryContainer;
      border = WittColors.primary;
      fg = WittColors.primary;
    }

    return GestureDetector(
      onTap: hasSubmitted ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: WittSpacing.md),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(WittSpacing.sm),
          border: Border.all(color: border, width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: fg, size: 28),
            const SizedBox(height: WittSpacing.xs),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Explanation panel ─────────────────────────────────────────────────────

class _ExplanationPanel extends StatelessWidget {
  const _ExplanationPanel({required this.explanation});
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(WittSpacing.md),
      decoration: BoxDecoration(
        color: WittColors.accentContainer,
        borderRadius: BorderRadius.circular(WittSpacing.sm),
        border: Border.all(
          color: WittColors.accentLight.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: WittColors.accent,
              ),
              const SizedBox(width: WittSpacing.xs),
              Text(
                'Explanation',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: WittColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: WittSpacing.sm),
          Text(
            explanation,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}

// ── Progress header ───────────────────────────────────────────────────────

class QuestionProgressHeader extends ConsumerWidget {
  const QuestionProgressHeader({
    super.key,
    required this.examName,
    required this.sectionName,
    required this.currentIndex,
    required this.totalQuestions,
    this.elapsedSeconds = 0,
    this.onClose,
  });

  final String examName;
  final String sectionName;
  final int currentIndex;
  final int totalQuestions;
  final int elapsedSeconds;
  final VoidCallback? onClose;

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = totalQuestions == 0
        ? 0.0
        : (currentIndex + 1) / totalQuestions;

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
                      examName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: WittColors.textTertiary,
                      ),
                    ),
                    Text(
                      sectionName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
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
              const SizedBox(width: WittSpacing.sm),
              Text(
                '${currentIndex + 1}/$totalQuestions',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: WittColors.primary,
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
