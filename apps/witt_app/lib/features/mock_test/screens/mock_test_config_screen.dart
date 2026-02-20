import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../../learn/models/exam.dart';
import '../../learn/providers/exam_providers.dart';
import '../models/mock_test.dart';
import '../providers/mock_test_providers.dart';
import 'mock_test_screen.dart';

class MockTestConfigScreen extends ConsumerStatefulWidget {
  const MockTestConfigScreen({super.key, required this.examId});
  final String examId;

  @override
  ConsumerState<MockTestConfigScreen> createState() =>
      _MockTestConfigScreenState();
}

class _MockTestConfigScreenState extends ConsumerState<MockTestConfigScreen> {
  TestMode _mode = TestMode.fullLength;
  final Set<String> _selectedSections = {};
  int? _customQuestionCount;
  int? _customTimeLimitMinutes;
  bool _shuffleQuestions = true;
  bool _showExplanations = true;
  bool _allowReview = true;

  @override
  Widget build(BuildContext context) {
    final exam = ref.watch(examByIdProvider(widget.examId));
    final theme = Theme.of(context);

    if (exam == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mock Test')),
        body: const Center(child: Text('Exam not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('${exam.name} Mock Test')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WittSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Exam summary card ──────────────────────────────────────
            _ExamSummaryCard(exam: exam),
            const SizedBox(height: WittSpacing.lg),

            // ── Test mode ──────────────────────────────────────────────
            Text(
              'Test Mode',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: WittSpacing.sm),
            ...TestMode.values.map(
              (mode) => _ModeRadioTile(
                mode: mode,
                selected: _mode == mode,
                onTap: () => setState(() {
                  _mode = mode;
                  if (mode == TestMode.fullLength) {
                    _selectedSections.clear();
                  }
                }),
              ),
            ),
            const SizedBox(height: WittSpacing.lg),

            // ── Section selection (for sectionOnly mode) ───────────────
            if (_mode == TestMode.sectionOnly) ...[
              Text(
                'Select Sections',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: WittSpacing.sm),
              ...exam.sections.map(
                (section) => CheckboxListTile(
                  title: Text(section.name),
                  subtitle: Text(
                    '${section.questionCount} questions · ${section.timeLimitMinutes} min',
                  ),
                  value: _selectedSections.contains(section.id),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selectedSections.add(section.id);
                    } else {
                      _selectedSections.remove(section.id);
                    }
                  }),
                  activeColor: WittColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: WittSpacing.lg),
            ],

            // ── Custom settings (timed/untimed) ────────────────────────
            if (_mode == TestMode.timed || _mode == TestMode.untimed) ...[
              Text(
                'Custom Settings',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: WittSpacing.sm),
              _NumberInputTile(
                label: 'Number of questions',
                hint: 'Default: ${exam.totalQuestions}',
                value: _customQuestionCount,
                onChanged: (v) => setState(() => _customQuestionCount = v),
              ),
              if (_mode == TestMode.timed)
                _NumberInputTile(
                  label: 'Time limit (minutes)',
                  hint: 'Default: ${exam.totalTimeMinutes}',
                  value: _customTimeLimitMinutes,
                  onChanged: (v) => setState(() => _customTimeLimitMinutes = v),
                ),
              const SizedBox(height: WittSpacing.lg),
            ],

            // ── Options ────────────────────────────────────────────────
            Text(
              'Options',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: WittSpacing.sm),
            SwitchListTile(
              title: const Text('Shuffle questions'),
              value: _shuffleQuestions,
              onChanged: (v) => setState(() => _shuffleQuestions = v),
              activeThumbColor: WittColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Show explanations after test'),
              value: _showExplanations,
              onChanged: (v) => setState(() => _showExplanations = v),
              activeThumbColor: WittColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Allow question review'),
              value: _allowReview,
              onChanged: (v) => setState(() => _allowReview = v),
              activeThumbColor: WittColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: WittSpacing.xl),

            // ── Start button ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: WittButton(
                label: 'Start Test',
                onPressed: _canStart(exam) ? () => _startTest(exam) : null,
                icon: Icons.play_arrow,
              ),
            ),
            const SizedBox(height: WittSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: WittButton(
                label: 'Practice Mode (no timer)',
                onPressed: () => _startPractice(exam),
                variant: WittButtonVariant.outline,
                icon: Icons.school,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canStart(Exam exam) {
    if (_mode == TestMode.sectionOnly && _selectedSections.isEmpty) {
      return false;
    }
    return true;
  }

  void _startTest(Exam exam) {
    final config = MockTestConfig(
      examId: exam.id,
      mode: _mode,
      sectionIds: _selectedSections.toList(),
      questionCount: _customQuestionCount,
      timeLimitMinutes: _customTimeLimitMinutes,
      shuffleQuestions: _shuffleQuestions,
      showExplanationsAfter: _showExplanations,
      allowReview: _allowReview,
    );
    ref.read(mockTestSessionProvider.notifier).startTest(config);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MockTestScreen()));
  }

  void _startPractice(Exam exam) {
    final config = MockTestConfig(
      examId: exam.id,
      mode: TestMode.untimed,
      shuffleQuestions: _shuffleQuestions,
      showExplanationsAfter: true,
      allowReview: true,
      isPractice: true,
    );
    ref.read(mockTestSessionProvider.notifier).startTest(config);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MockTestScreen()));
  }
}

class _ExamSummaryCard extends StatelessWidget {
  const _ExamSummaryCard({required this.exam});
  final Exam exam;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(WittSpacing.md),
      decoration: BoxDecoration(
        color: WittColors.primaryContainer,
        borderRadius: BorderRadius.circular(WittSpacing.sm),
        border: Border.all(color: WittColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(exam.emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: WittSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  exam.fullName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: WittColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _InfoChip(
                      label: '${exam.totalQuestions} Qs',
                      icon: Icons.quiz,
                    ),
                    const SizedBox(width: 6),
                    _InfoChip(
                      label: '${exam.totalTimeMinutes} min',
                      icon: Icons.timer,
                    ),
                    const SizedBox(width: 6),
                    _InfoChip(
                      label: '${exam.sections.length} sections',
                      icon: Icons.segment,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: WittColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: WittColors.primary),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: WittColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeRadioTile extends StatelessWidget {
  const _ModeRadioTile({
    required this.mode,
    required this.selected,
    required this.onTap,
  });
  final TestMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, title, subtitle) = _modeInfo(mode);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: WittSpacing.sm),
        padding: const EdgeInsets.all(WittSpacing.md),
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
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? WittColors.primary : WittColors.textTertiary,
              size: 22,
            ),
            const SizedBox(width: WittSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected ? WittColors.primary : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: WittColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: WittColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  (IconData, String, String) _modeInfo(TestMode mode) => switch (mode) {
    TestMode.fullLength => (
      Icons.assignment,
      'Full Length',
      'Complete exam simulation with all sections',
    ),
    TestMode.sectionOnly => (
      Icons.segment,
      'Section Only',
      'Practice specific sections of the exam',
    ),
    TestMode.timed => (
      Icons.timer,
      'Custom Timed',
      'Set your own question count and time limit',
    ),
    TestMode.untimed => (
      Icons.timer_off,
      'Untimed Practice',
      'No time pressure — focus on understanding',
    ),
  };
}

class _NumberInputTile extends StatelessWidget {
  const _NumberInputTile({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String hint;
  final int? value;
  final void Function(int?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: WittSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          SizedBox(
            width: 100,
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: hint,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
              ),
              onChanged: (v) => onChanged(int.tryParse(v)),
            ),
          ),
        ],
      ),
    );
  }
}
