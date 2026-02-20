import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';

import '../onboarding_state.dart';
import '../../../core/security/privacy_service.dart';

class WizardScreen extends ConsumerStatefulWidget {
  const WizardScreen({super.key, required this.step});
  final int step;

  @override
  ConsumerState<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends ConsumerState<WizardScreen> {
  static const int _totalSteps = 10;

  String? _selectedRole;
  String? _selectedLevel;
  String? _selectedCountry;
  List<String> _selectedExams = [];
  int _studyMinutes = 30;
  List<String> _selectedSubjects = [];
  List<String> _selectedPrefs = [];

  static const _roles = [
    _Option('student', '🎓', 'Student'),
    _Option('teacher', '👨‍🏫', 'Teacher'),
    _Option('parent', '👨‍👩‍👧', 'Parent'),
  ];

  static const _levels = [
    'Middle School',
    'High School',
    'College',
    'Graduate School',
    'Professional',
    'Other',
  ];

  static const _exams = [
    'SAT',
    'ACT',
    'GRE',
    'GMAT',
    'IELTS',
    'TOEFL',
    'WAEC',
    'JAMB',
    'NECO',
    'BECE',
    'PSAT',
    'AP',
    'A-Levels',
    'GCSE',
    'USMLE',
    'LSAT',
    'MCAT',
  ];

  static const _studyOptions = [
    _StudyOption(15, '15 min', 'Casual'),
    _StudyOption(30, '30 min', 'Regular'),
    _StudyOption(60, '1 hour', 'Serious'),
    _StudyOption(120, '2+ hrs', 'Intense'),
  ];

  static const _subjects = [
    'Math',
    'Reading',
    'Writing',
    'Science',
    'History',
    'Languages',
    'Economics',
    'Computer Science',
  ];

  static const _prefs = [
    _Option('flashcards', '🃏', 'Flashcards'),
    _Option('tests', '📝', 'Practice Tests'),
    _Option('games', '🎮', 'Games'),
    _Option('reading', '📖', 'Reading'),
    _Option('lectures', '🎥', 'Video & Lectures'),
    _Option('ai', '🤖', 'AI Tutoring'),
  ];

  @override
  void initState() {
    super.initState();
    final data = ref.read(onboardingProvider);
    _selectedRole = data.role;
    _selectedLevel = data.educationLevel;
    _selectedCountry = data.country;
    _selectedExams = List.from(data.selectedExams);
    _studyMinutes = data.studyTimeMinutes;
    _selectedSubjects = List.from(data.subjects);
    _selectedPrefs = List.from(data.learningPrefs);
  }

  void _next() {
    if (widget.step < _totalSteps) {
      context.go('/onboarding/wizard/${widget.step + 1}');
    } else {
      context.go('/onboarding/auth');
    }
  }

  void _back() {
    if (widget.step > 1) {
      context.go('/onboarding/wizard/${widget.step - 1}');
    } else {
      context.go('/onboarding/language');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with back + progress
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: WittSpacing.lg,
                vertical: WittSpacing.md,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: _back,
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? WittColors.surfaceVariantDark
                          : WittColors.surfaceVariant,
                    ),
                  ),
                  const SizedBox(width: WittSpacing.md),
                  Expanded(
                    child: WittProgressBar(
                      value: widget.step / _totalSteps,
                      height: 6,
                      gradient: WittColors.primaryGradient,
                    ),
                  ),
                  const SizedBox(width: WittSpacing.md),
                  Text(
                    '${widget.step}/$_totalSteps',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: WittSpacing.pagePadding,
                child: _buildStep(theme, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(ThemeData theme, bool isDark) {
    return switch (widget.step) {
      1 => _buildQ1(theme, isDark),
      2 => _buildQ2(theme, isDark),
      3 => _buildQ3(theme, isDark),
      4 => _buildQ4(theme, isDark),
      5 => _buildQ5(theme, isDark),
      6 => _buildQ6(theme, isDark),
      7 => _buildQ7(theme, isDark),
      8 => _buildQ8(theme, isDark),
      9 => _buildQ9(theme, isDark),
      10 => _buildQ10(theme, isDark),
      _ => const SizedBox.shrink(),
    };
  }

  // Q1: Who are you?
  Widget _buildQ1(ThemeData theme, bool isDark) {
    return _StepWrapper(
      title: 'Who are you?',
      subtitle: 'This helps us personalise your experience.',
      child: Column(
        children: _roles.map((r) {
          final isSelected = _selectedRole == r.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: WittSpacing.md),
            child: GestureDetector(
              onTap: () async {
                setState(() => _selectedRole = r.value);
                await ref.read(onboardingProvider.notifier).setRole(r.value);
                if (mounted) _next();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(WittSpacing.lg),
                decoration: BoxDecoration(
                  color: isSelected
                      ? WittColors.primaryContainer
                      : (isDark
                            ? WittColors.surfaceVariantDark
                            : WittColors.surfaceVariant),
                  borderRadius: WittSpacing.borderRadiusLg,
                  border: Border.all(
                    color: isSelected ? WittColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Text(r.emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: WittSpacing.lg),
                    Text(r.label, style: theme.textTheme.titleMedium),
                    const Spacer(),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: WittColors.primary,
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _handleEducationLevel(String level) async {
    setState(() => _selectedLevel = level);
    // COPPA: Middle School implies potential under-13 — collect birth year then
    // show parental consent dialog if the user is actually under 13.
    if (level == 'Middle School') {
      final birthYear = await _showBirthYearPicker();
      if (birthYear == null) {
        setState(() => _selectedLevel = null);
        return;
      }
      await ref.read(onboardingProvider.notifier).setBirthYear(birthYear);
      if (PrivacyService.isUnder13(birthYear)) {
        final consented = await _showCoppaGate();
        if (!consented) {
          setState(() => _selectedLevel = null);
          return;
        }
      }
    }
    await ref.read(onboardingProvider.notifier).setEducationLevel(level);
    if (mounted) _next();
  }

  /// Shows a year-picker dialog and returns the selected birth year, or null if
  /// the user cancelled.
  Future<int?> _showBirthYearPicker() async {
    final currentYear = DateTime.now().year;
    int selectedYear = currentYear - 13;
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('What year were you born?'),
          content: SizedBox(
            height: 200,
            child: ListWheelScrollView.useDelegate(
              itemExtent: 44,
              diameterRatio: 1.4,
              physics: const FixedExtentScrollPhysics(),
              controller: FixedExtentScrollController(
                initialItem: currentYear - 13 - (currentYear - 30),
              ),
              onSelectedItemChanged: (index) {
                setDialogState(() => selectedYear = currentYear - 30 + index);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: 20,
                builder: (_, index) {
                  final year = currentYear - 30 + index;
                  final isSelected = year == selectedYear;
                  return Center(
                    child: Text(
                      '$year',
                      style: TextStyle(
                        fontSize: isSelected ? 22 : 16,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? WittColors.primary
                            : Theme.of(ctx).textTheme.bodyMedium?.color,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, selectedYear),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showCoppaGate() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CoppaConsentDialog(),
    );
    if (result == true) {
      await PrivacyService.recordParentalConsent();
    }
    return result ?? false;
  }

  // Q2: Education level
  Widget _buildQ2(ThemeData theme, bool isDark) {
    return _StepWrapper(
      title: "What's your education level?",
      child: Column(
        children: _levels.map((level) {
          final isSelected = _selectedLevel == level;
          return Padding(
            padding: const EdgeInsets.only(bottom: WittSpacing.sm),
            child: GestureDetector(
              onTap: () => _handleEducationLevel(level),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: WittSpacing.lg,
                  vertical: WittSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? WittColors.primaryContainer
                      : (isDark
                            ? WittColors.surfaceVariantDark
                            : WittColors.surfaceVariant),
                  borderRadius: WittSpacing.borderRadiusMd,
                  border: Border.all(
                    color: isSelected ? WittColors.primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(level, style: theme.textTheme.bodyLarge),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: WittColors.primary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Q3: Country
  Widget _buildQ3(ThemeData theme, bool isDark) {
    final countries = [
      'United States',
      'United Kingdom',
      'Nigeria',
      'Ghana',
      'Kenya',
      'India',
      'Canada',
      'Australia',
      'South Africa',
      'Germany',
      'France',
      'Brazil',
      'Mexico',
      'China',
      'Japan',
      'Other',
    ];
    return _StepWrapper(
      title: "Where are you based?",
      subtitle: 'Sets your currency and suggests relevant exams.',
      child: Column(
        children: [
          ...countries.map((c) {
            final isSelected = _selectedCountry == c;
            return Padding(
              padding: const EdgeInsets.only(bottom: WittSpacing.sm),
              child: GestureDetector(
                onTap: () async {
                  setState(() => _selectedCountry = c);
                  await ref.read(onboardingProvider.notifier).setCountry(c);
                  if (mounted) _next();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: WittSpacing.lg,
                    vertical: WittSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? WittColors.primaryContainer
                        : (isDark
                              ? WittColors.surfaceVariantDark
                              : WittColors.surfaceVariant),
                    borderRadius: WittSpacing.borderRadiusMd,
                    border: Border.all(
                      color: isSelected
                          ? WittColors.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(c, style: theme.textTheme.bodyLarge),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: WittColors.primary,
                          size: 20,
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

  // Q4: Exams
  Widget _buildQ4(ThemeData theme, bool isDark) {
    return _StepWrapper(
      title: 'What are you preparing for?',
      subtitle: 'Select one or more exams.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: WittSpacing.sm,
            runSpacing: WittSpacing.sm,
            children: _exams.map((exam) {
              final isSelected = _selectedExams.contains(exam);
              return WittChip(
                label: exam,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedExams.remove(exam);
                    } else {
                      _selectedExams.add(exam);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: WittSpacing.xxxl),
          WittButton(
            label: 'Continue',
            onPressed: _selectedExams.isEmpty
                ? null
                : () async {
                    await ref
                        .read(onboardingProvider.notifier)
                        .setExams(_selectedExams);
                    if (mounted) _next();
                  },
            isFullWidth: true,
            size: WittButtonSize.lg,
          ),
        ],
      ),
    );
  }

  // Q5: Exam dates
  Widget _buildQ5(ThemeData theme, bool isDark) {
    final exams = ref.read(onboardingProvider).selectedExams;
    return _StepWrapper(
      title: 'When is your exam?',
      subtitle: "Select dates for each exam, or tap \"I don't know yet\".",
      child: Column(
        children: [
          ...exams.map((exam) {
            final dateStr = ref.read(onboardingProvider).examDates[exam];
            return Padding(
              padding: const EdgeInsets.only(bottom: WittSpacing.md),
              child: WittCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(exam, style: theme.textTheme.titleSmall),
                          if (dateStr != null)
                            Text(
                              dateStr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: WittColors.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 30),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 730),
                          ),
                        );
                        if (picked != null) {
                          final dates = Map<String, String>.from(
                            ref.read(onboardingProvider).examDates,
                          );
                          dates[exam] =
                              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                          await ref
                              .read(onboardingProvider.notifier)
                              .setExamDates(dates);
                          setState(() {});
                        }
                      },
                      child: Text(dateStr == null ? 'Set date' : 'Change'),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: WittSpacing.lg),
          WittButton(
            label: 'Continue',
            onPressed: _next,
            isFullWidth: true,
            size: WittButtonSize.lg,
          ),
        ],
      ),
    );
  }

  // Q6: Target scores
  Widget _buildQ6(ThemeData theme, bool isDark) {
    final exams = ref.read(onboardingProvider).selectedExams;
    return _StepWrapper(
      title: "What's your target score?",
      subtitle: 'Drag the slider or tap "Not sure".',
      child: Column(
        children: [
          ...exams.map((exam) {
            final max = _examMaxScore(exam);
            final current =
                ref.read(onboardingProvider).targetScores[exam] ?? (max ~/ 2);
            return Padding(
              padding: const EdgeInsets.only(bottom: WittSpacing.lg),
              child: WittCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(exam, style: theme.textTheme.titleSmall),
                        Text(
                          '$current / $max',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: WittColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: current.toDouble(),
                      min: 0,
                      max: max.toDouble(),
                      divisions: max ~/ 10,
                      activeColor: WittColors.primary,
                      onChanged: (v) async {
                        final scores = Map<String, int>.from(
                          ref.read(onboardingProvider).targetScores,
                        );
                        scores[exam] = v.round();
                        await ref
                            .read(onboardingProvider.notifier)
                            .setTargetScores(scores);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: WittSpacing.lg),
          WittButton(
            label: 'Continue',
            onPressed: _next,
            isFullWidth: true,
            size: WittButtonSize.lg,
          ),
        ],
      ),
    );
  }

  int _examMaxScore(String exam) => switch (exam) {
    'SAT' => 1600,
    'ACT' => 36,
    'GRE' => 340,
    'GMAT' => 800,
    'IELTS' => 9,
    'TOEFL' => 120,
    _ => 100,
  };

  // Q7: Study time
  Widget _buildQ7(ThemeData theme, bool isDark) {
    return _StepWrapper(
      title: 'How much time can you study daily?',
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: WittSpacing.md,
            mainAxisSpacing: WittSpacing.md,
            childAspectRatio: 1.6,
            children: _studyOptions.map((opt) {
              final isSelected = _studyMinutes == opt.minutes;
              return GestureDetector(
                onTap: () async {
                  setState(() => _studyMinutes = opt.minutes);
                  await ref
                      .read(onboardingProvider.notifier)
                      .setStudyTime(opt.minutes);
                  if (mounted) _next();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? WittColors.primaryContainer
                        : (isDark
                              ? WittColors.surfaceVariantDark
                              : WittColors.surfaceVariant),
                    borderRadius: WittSpacing.borderRadiusLg,
                    border: Border.all(
                      color: isSelected
                          ? WittColors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        opt.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isSelected ? WittColors.primary : null,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(opt.sublabel, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Q8: Subjects
  Widget _buildQ8(ThemeData theme, bool isDark) {
    return _StepWrapper(
      title: 'What subjects do you want to focus on?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._subjects.map((subject) {
            final isSelected = _selectedSubjects.contains(subject);
            return SwitchListTile(
              value: isSelected,
              onChanged: (v) {
                setState(() {
                  if (v) {
                    _selectedSubjects.add(subject);
                  } else {
                    _selectedSubjects.remove(subject);
                  }
                });
              },
              title: Text(subject, style: theme.textTheme.bodyLarge),
              activeThumbColor: WittColors.primary,
              contentPadding: EdgeInsets.zero,
            );
          }),
          const SizedBox(height: WittSpacing.xxl),
          WittButton(
            label: 'Continue',
            onPressed: () async {
              await ref
                  .read(onboardingProvider.notifier)
                  .setSubjects(_selectedSubjects);
              if (mounted) _next();
            },
            isFullWidth: true,
            size: WittButtonSize.lg,
          ),
        ],
      ),
    );
  }

  // Q9: Learning preferences
  Widget _buildQ9(ThemeData theme, bool isDark) {
    return _StepWrapper(
      title: 'How do you like to learn?',
      subtitle: 'Select all that apply. Optional.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: WittSpacing.sm,
            runSpacing: WittSpacing.sm,
            children: _prefs.map((p) {
              final isSelected = _selectedPrefs.contains(p.value);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedPrefs.remove(p.value);
                    } else {
                      _selectedPrefs.add(p.value);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: WittSpacing.lg,
                    vertical: WittSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? WittColors.primaryContainer
                        : (isDark
                              ? WittColors.surfaceVariantDark
                              : WittColors.surfaceVariant),
                    borderRadius: WittSpacing.borderRadiusMd,
                    border: Border.all(
                      color: isSelected
                          ? WittColors.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(p.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: WittSpacing.sm),
                      Text(p.label, style: theme.textTheme.labelLarge),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: WittSpacing.xxxl),
          WittButton(
            label: 'Continue',
            onPressed: () async {
              await ref
                  .read(onboardingProvider.notifier)
                  .setLearningPrefs(_selectedPrefs);
              if (mounted) _next();
            },
            isFullWidth: true,
            size: WittButtonSize.lg,
          ),
        ],
      ),
    );
  }

  // Q10: Notifications
  Widget _buildQ10(ThemeData theme, bool isDark) {
    return _StepWrapper(
      title: 'Enable notifications?',
      subtitle: 'Stay on track with reminders and alerts.',
      child: Column(
        children: [
          WittCard(
            child: Column(
              children: [
                _NotifRow(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: WittColors.streak,
                  label: 'Streak alerts',
                  subtitle: 'Get reminded to keep your streak alive',
                ),
                const Divider(height: WittSpacing.lg),
                _NotifRow(
                  icon: Icons.calendar_today_rounded,
                  iconColor: WittColors.primary,
                  label: 'Exam date reminders',
                  subtitle: 'Countdowns and prep reminders',
                ),
                const Divider(height: WittSpacing.lg),
                _NotifRow(
                  icon: Icons.schedule_rounded,
                  iconColor: WittColors.accent,
                  label: 'Study reminders',
                  subtitle: 'Daily nudges to hit your study goal',
                ),
                const Divider(height: WittSpacing.lg),
                _NotifRow(
                  icon: Icons.new_releases_rounded,
                  iconColor: WittColors.success,
                  label: 'New content alerts',
                  subtitle: 'New exams, packs, and features',
                ),
              ],
            ),
          ),
          const SizedBox(height: WittSpacing.xxxl),
          WittButton(
            label: 'Enable Notifications',
            onPressed: () async {
              await ref
                  .read(onboardingProvider.notifier)
                  .setNotifications(true);
              if (mounted) _next();
            },
            isFullWidth: true,
            size: WittButtonSize.lg,
          ),
          const SizedBox(height: WittSpacing.md),
          WittButton(
            label: 'Not now',
            variant: WittButtonVariant.ghost,
            onPressed: () async {
              await ref
                  .read(onboardingProvider.notifier)
                  .setNotifications(false);
              if (mounted) _next();
            },
            isFullWidth: true,
            size: WittButtonSize.lg,
          ),
        ],
      ),
    );
  }
}

class _StepWrapper extends StatelessWidget {
  const _StepWrapper({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: WittSpacing.lg),
        Text(title, style: theme.textTheme.headlineSmall),
        if (subtitle != null) ...[
          const SizedBox(height: WittSpacing.sm),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? WittColors.textSecondaryDark
                  : WittColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: WittSpacing.xxl),
        child,
        const SizedBox(height: WittSpacing.massive),
      ],
    );
  }
}

class _Option {
  const _Option(this.value, this.emoji, this.label);
  final String value;
  final String emoji;
  final String label;
}

class _StudyOption {
  const _StudyOption(this.minutes, this.label, this.sublabel);
  final int minutes;
  final String label;
  final String sublabel;
}

// ── COPPA parental consent dialog ─────────────────────────────────────────

class _CoppaConsentDialog extends StatelessWidget {
  const _CoppaConsentDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Parental Consent Required'),
      content: const Text(
        'Witt collects personal data to personalise your learning experience. '
        'Because you may be under 13, we need a parent or guardian to confirm '
        'they consent to your use of this app and the collection of your data '
        'in accordance with COPPA (Children\'s Online Privacy Protection Act).\n\n'
        'A parent or guardian must tap "I Consent" below to continue.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('I Consent (Parent/Guardian)'),
        ),
      ],
    );
  }
}

class _NotifRow extends StatelessWidget {
  const _NotifRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withAlpha(26),
            borderRadius: WittSpacing.borderRadiusMd,
          ),
          child: Icon(icon, color: iconColor, size: WittSpacing.iconMd),
        ),
        const SizedBox(width: WittSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.titleSmall),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
