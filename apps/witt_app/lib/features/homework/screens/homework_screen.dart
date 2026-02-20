import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../models/homework.dart';
import '../providers/homework_providers.dart';

class HomeworkScreen extends ConsumerWidget {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(homeworkSessionProvider);
    final history = ref.watch(homeworkHistoryProvider);

    if (session.solution != null) {
      return _SolutionView(solution: session.solution!);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Homework Helper'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(WittSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InputMethodSelector(session: session),
                  const SizedBox(height: WittSpacing.lg),
                  _SubjectSelector(session: session),
                  const SizedBox(height: WittSpacing.lg),
                  _QuestionInput(session: session),
                  const SizedBox(height: WittSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: WittButton(
                      label: session.isLoading ? 'Solving…' : 'Solve Problem',
                      onPressed: session.isLoading || session.question.trim().isEmpty
                          ? null
                          : () => ref.read(homeworkSessionProvider.notifier).solve(),
                      icon: Icons.auto_fix_high,
                    ),
                  ),
                  if (session.errorMessage != null) ...[
                    const SizedBox(height: WittSpacing.sm),
                    Text(session.errorMessage!,
                        style: const TextStyle(color: WittColors.error)),
                  ],
                ],
              ),
            ),
          ),
          if (history.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    WittSpacing.lg, 0, WittSpacing.lg, WittSpacing.sm),
                child: Text('Recent',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _HistoryTile(
                  solution: history[index],
                  onTap: () => _openSolution(context, ref, history[index]),
                  onDelete: () => ref
                      .read(homeworkHistoryProvider.notifier)
                      .deleteSolution(history[index].id),
                ),
                childCount: history.take(10).length,
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _openSolution(
      BuildContext context, WidgetRef ref, HomeworkSolution solution) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _SolutionView(solution: solution)),
    );
  }
}

// ── Input method selector ─────────────────────────────────────────────────

class _InputMethodSelector extends ConsumerWidget {
  const _InputMethodSelector({required this.session});
  final HomeworkSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Input Method',
            style: theme.textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: WittSpacing.xs),
        Row(
          children: HomeworkInputMethod.values.map((m) {
            final selected = session.inputMethod == m;
            final (icon, label) = _methodInfo(m);
            final isAvailable = m == HomeworkInputMethod.text;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: isAvailable
                      ? () => ref
                          .read(homeworkSessionProvider.notifier)
                          .setInputMethod(m)
                      : () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Coming in Phase 3 with AI')),
                          ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? WittColors.primaryContainer
                          : WittColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(WittSpacing.sm),
                      border: Border.all(
                        color: selected ? WittColors.primary : WittColors.outline,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(icon,
                            size: 20,
                            color: selected
                                ? WittColors.primary
                                : isAvailable
                                    ? WittColors.textSecondary
                                    : WittColors.textDisabled),
                        const SizedBox(height: 2),
                        Text(label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: selected
                                  ? WittColors.primary
                                  : isAvailable
                                      ? WittColors.textSecondary
                                      : WittColors.textDisabled,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  (IconData, String) _methodInfo(HomeworkInputMethod m) => switch (m) {
        HomeworkInputMethod.text => (Icons.keyboard, 'Type'),
        HomeworkInputMethod.camera => (Icons.camera_alt, 'Camera'),
        HomeworkInputMethod.upload => (Icons.upload_file, 'Upload'),
        HomeworkInputMethod.voice => (Icons.mic, 'Voice'),
      };
}

// ── Subject selector ──────────────────────────────────────────────────────

class _SubjectSelector extends ConsumerWidget {
  const _SubjectSelector({required this.session});
  final HomeworkSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subject',
            style: theme.textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: WittSpacing.xs),
        Wrap(
          spacing: WittSpacing.sm,
          runSpacing: WittSpacing.sm,
          children: HomeworkSubject.values.map((s) {
            final selected = session.subject == s;
            final (emoji, label) = _subjectInfo(s);
            return GestureDetector(
              onTap: () =>
                  ref.read(homeworkSessionProvider.notifier).setSubject(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? WittColors.primaryContainer
                      : WittColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? WittColors.primary : WittColors.outline,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: selected
                              ? WittColors.primary
                              : WittColors.textSecondary,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  (String, String) _subjectInfo(HomeworkSubject s) => switch (s) {
        HomeworkSubject.mathematics => ('🔢', 'Math'),
        HomeworkSubject.physics => ('⚡', 'Physics'),
        HomeworkSubject.chemistry => ('⚗️', 'Chemistry'),
        HomeworkSubject.biology => ('🧬', 'Biology'),
        HomeworkSubject.english => ('📝', 'English'),
        HomeworkSubject.history => ('🏛️', 'History'),
        HomeworkSubject.geography => ('🌍', 'Geography'),
        HomeworkSubject.computerScience => ('💻', 'CS'),
        HomeworkSubject.economics => ('📊', 'Economics'),
        HomeworkSubject.other => ('📚', 'Other'),
      };
}

// ── Question input ────────────────────────────────────────────────────────

class _QuestionInput extends ConsumerWidget {
  const _QuestionInput({required this.session});
  final HomeworkSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Question',
            style: theme.textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: WittSpacing.xs),
        TextField(
          onChanged: (v) =>
              ref.read(homeworkSessionProvider.notifier).setQuestion(v),
          maxLines: 5,
          decoration: const InputDecoration(
            hintText:
                'Type your homework question here…\n\ne.g. "Solve for x: 2x + 5 = 13"',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: WittSpacing.xs),
        Text(
          '💡 AI-powered step-by-step solutions coming in Phase 3',
          style: theme.textTheme.labelSmall?.copyWith(
            color: WittColors.textTertiary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

// ── History tile ──────────────────────────────────────────────────────────

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.solution,
    required this.onTap,
    required this.onDelete,
  });
  final HomeworkSolution solution;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          WittSpacing.lg, 0, WittSpacing.lg, WittSpacing.sm),
      child: Dismissible(
        key: Key(solution.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: WittSpacing.lg),
          color: WittColors.error,
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) => onDelete(),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(WittSpacing.sm),
          child: Container(
            padding: const EdgeInsets.all(WittSpacing.md),
            decoration: BoxDecoration(
              color: WittColors.surfaceVariant,
              borderRadius: BorderRadius.circular(WittSpacing.sm),
              border: Border.all(color: WittColors.outline),
            ),
            child: Row(
              children: [
                Text(_subjectEmoji(solution.subject),
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(width: WittSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        solution.question,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${solution.steps.length} steps · ${solution.difficulty}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: WittColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: WittColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subjectEmoji(HomeworkSubject s) => switch (s) {
        HomeworkSubject.mathematics => '🔢',
        HomeworkSubject.physics => '⚡',
        HomeworkSubject.chemistry => '⚗️',
        HomeworkSubject.biology => '🧬',
        HomeworkSubject.english => '📝',
        HomeworkSubject.history => '🏛️',
        HomeworkSubject.geography => '🌍',
        HomeworkSubject.computerScience => '💻',
        HomeworkSubject.economics => '📊',
        HomeworkSubject.other => '📚',
      };
}

// ── Solution view ─────────────────────────────────────────────────────────

class _SolutionView extends ConsumerWidget {
  const _SolutionView({required this.solution});
  final HomeworkSolution solution;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solution'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(homeworkSessionProvider.notifier).clearSolution(),
            child: const Text('New Problem'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          WittSpacing.lg,
          WittSpacing.lg,
          WittSpacing.lg,
          WittSpacing.lg + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(WittSpacing.md),
              decoration: BoxDecoration(
                color: WittColors.primaryContainer,
                borderRadius: BorderRadius.circular(WittSpacing.sm),
                border: Border.all(
                    color: WittColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Question',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: WittColors.primary,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 4),
                  Text(solution.question,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
            const SizedBox(height: WittSpacing.lg),

            // Steps
            Text('Step-by-Step Solution',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: WittSpacing.sm),
            ...solution.steps.asMap().entries.map((entry) =>
                _StepCard(step: entry.value, isLast: entry.key == solution.steps.length - 1)),

            const SizedBox(height: WittSpacing.lg),

            // Final answer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(WittSpacing.md),
              decoration: BoxDecoration(
                color: WittColors.successContainer,
                borderRadius: BorderRadius.circular(WittSpacing.sm),
                border: Border.all(
                    color: WittColors.success.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: WittColors.success),
                      SizedBox(width: 6),
                      Text('Final Answer',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: WittColors.success,
                          )),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(solution.finalAnswer,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: WittColors.success,
                      )),
                ],
              ),
            ),
            const SizedBox(height: WittSpacing.md),

            // Related topics
            if (solution.relatedTopics.isNotEmpty) ...[
              Text('Related Topics',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: WittSpacing.xs),
              Wrap(
                spacing: WittSpacing.sm,
                runSpacing: WittSpacing.sm,
                children: solution.relatedTopics.map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: WittColors.accentContainer,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: WittColors.accentLight
                                .withValues(alpha: 0.4)),
                      ),
                      child: Text(t,
                          style: const TextStyle(
                            fontSize: 12,
                            color: WittColors.accent,
                            fontWeight: FontWeight.w500,
                          )),
                    )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.isLast});
  final SolutionStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _stepColor(step.type);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                alignment: Alignment.center,
                child: Text('${step.stepNumber}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color,
                    )),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: WittColors.outline,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: WittSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: isLast ? 0 : WittSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      )),
                  const SizedBox(height: 4),
                  Text(step.content,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.5,
                      )),
                  if (step.formula != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: WittColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: WittColors.outline),
                      ),
                      child: Text(step.formula!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _stepColor(SolutionStepType t) => switch (t) {
        SolutionStepType.setup => WittColors.accent,
        SolutionStepType.formula => WittColors.primary,
        SolutionStepType.calculation => WittColors.secondary,
        SolutionStepType.explanation => WittColors.textSecondary,
        SolutionStepType.conclusion => WittColors.success,
        SolutionStepType.hint => WittColors.warning,
      };
}
