import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';

import '../onboarding_state.dart';
import '../data/countries_by_continent.dart';
import '../data/exam_catalog.dart';
import '../../../core/security/privacy_service.dart';
import '../../../core/translation/live_text.dart';

enum _FlowStep {
  role,
  level,
  purpose,
  country,
  exams,
  examDates,
  studentPrefs,
  parentSetup,
  parentGoals,
  teacherSubjects,
  teacherGradeLevels,
  teacherClassSize,
  teacherGoals,
  notifications,
}

class WizardScreen extends ConsumerStatefulWidget {
  const WizardScreen({super.key, required this.step});
  final int step;

  @override
  ConsumerState<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends ConsumerState<WizardScreen> {
  String? _selectedRole;
  String? _selectedLevel;
  String? _selectedCountry;
  String? _childSetupType;
  String? _classSize;
  List<String> _selectedExams = [];
  List<String> _selectedSubjects = [];
  List<String> _selectedPrefs = [];
  List<String> _selectedGradeLevels = [];
  List<String> _selectedPurposes = [];
  String _countryQuery = '';
  final Set<String> _expandedContinents = <String>{
    'North America',
    'South America',
    'Europe',
    'Africa',
    'Asia',
    'Oceania',
  };

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

  static const _purposes = [
    _Option('exam_prep', '🎯', 'Preparing for an exam'),
    _Option('general_study', '📚', 'General study support'),
    _Option('flashcards', '🃏', 'Creating flashcards'),
    _Option('study_planning', '📅', 'Building a study timetable'),
    _Option('progress_tracking', '📊', 'Tracking academic progress'),
    _Option('study_habits', '🧠', 'Improving study habits'),
    _Option('learn_topics', '💡', 'Learning new topics'),
    _Option('productivity', '⏱️', 'Productivity & focus'),
  ];

  static const _prefs = [
    _Option('flashcards', '🃏', 'Flashcards'),
    _Option('tests', '📝', 'Practice Tests'),
    _Option('games', '🎮', 'Games'),
    _Option('reading', '📖', 'Reading'),
    _Option('lectures', '🎥', 'Video & Lectures'),
    _Option('ai', '🤖', 'AI Tutoring'),
  ];

  static const _parentGoals = [
    _Option('track_progress', '📈', 'Track progress'),
    _Option('improve_grades', '🏆', 'Improve grades'),
    _Option('exam_readiness', '🎯', 'Prepare for exams'),
    _Option('daily_accountability', '🗓️', 'Daily accountability'),
  ];

  static const _teacherGoals = [
    _Option('track_students', '📊', 'Track student performance'),
    _Option('assign_tests', '🧪', 'Assign practice tests'),
    _Option('analyze_weak_areas', '🧠', 'Analyze weak areas'),
    _Option('improve_outcomes', '🚀', 'Improve exam outcomes'),
  ];

  static const _teacherSubjects = [
    'Math',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'History',
    'Economics',
    'Computer Science',
  ];

  static const _gradeLevels = [
    'Grade 6-8',
    'Grade 9-10',
    'Grade 11-12',
    'College Year 1-2',
    'College Year 3+',
  ];

  static const _classSizes = [
    '1-10 students',
    '11-25 students',
    '26-40 students',
    '41+ students',
  ];

  @override
  void initState() {
    super.initState();
    final data = ref.read(onboardingProvider);
    _selectedRole = data.role;
    _selectedLevel = data.educationLevel;
    _selectedCountry = data.country;
    _selectedExams = List.from(data.selectedExams);
    _selectedSubjects = List.from(data.subjects);
    _selectedPrefs = List.from(data.learningPrefs);
    _selectedGradeLevels = List.from(data.gradeLevels);
    _selectedPurposes = List.from(data.learningPrefs);
    _childSetupType = data.childSetupType;
    _classSize = data.classSize;
  }

  bool get _wantsExamPrep => _selectedPurposes.contains('exam_prep');

  Widget _buildParentSetup(ThemeData theme, bool isDark) {
    const options = [
      _Option('one_child', '🧒', 'One child'),
      _Option('multiple_children', '👨‍👩‍👧‍👦', 'Multiple children'),
    ];

    return _StepWrapper(
      title: 'Who are you setting up for?',
      subtitle: 'We will shape your parent dashboard around your family setup.',
      child: Column(
        children: options
            .map((opt) {
              final isSelected = _childSetupType == opt.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: WittSpacing.md),
                child: GestureDetector(
                  onTap: () async {
                    setState(() => _childSetupType = opt.value);
                    await ref
                        .read(onboardingProvider.notifier)
                        .setChildSetupType(opt.value);
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
                        color: isSelected
                            ? WittColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(opt.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: WittSpacing.lg),
                        Expanded(
                          child: Text(
                            opt.label,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
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
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _buildTeacherSubjects(
    ThemeData theme,
    bool isDark,
    String continueLabel,
  ) {
    return _StepWrapper(
      title: 'Which subjects do you teach?',
      subtitle: 'Select all that apply.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._teacherSubjects.map((subject) {
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
            label: continueLabel,
            onPressed: _selectedSubjects.isEmpty
                ? null
                : () async {
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

  Widget _buildTeacherGradeLevels(
    ThemeData theme,
    bool isDark,
    String continueLabel,
  ) {
    return _StepWrapper(
      title: 'Which grade levels do you support?',
      subtitle: 'Select all that apply.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: WittSpacing.sm,
            runSpacing: WittSpacing.sm,
            children: _gradeLevels
                .map((grade) {
                  final isSelected = _selectedGradeLevels.contains(grade);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedGradeLevels.remove(grade);
                        } else {
                          _selectedGradeLevels.add(grade);
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
                      child: Text(grade, style: theme.textTheme.labelLarge),
                    ),
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: WittSpacing.xxxl),
          WittButton(
            label: continueLabel,
            onPressed: _selectedGradeLevels.isEmpty
                ? null
                : () async {
                    await ref
                        .read(onboardingProvider.notifier)
                        .setGradeLevels(_selectedGradeLevels);
                    if (mounted) _next();
                  },
            isFullWidth: true,
            size: WittButtonSize.lg,
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherClassSize(ThemeData theme, bool isDark) {
    return _StepWrapper(
      title: 'How big is your class?',
      subtitle: 'Optional — helps tailor pacing and recommendations.',
      child: Column(
        children: [
          ..._classSizes.map((size) {
            final isSelected = _classSize == size;
            return Padding(
              padding: const EdgeInsets.only(bottom: WittSpacing.sm),
              child: GestureDetector(
                onTap: () async {
                  setState(() => _classSize = size);
                  await ref
                      .read(onboardingProvider.notifier)
                      .setClassSize(size);
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
                        child: Text(size, style: theme.textTheme.bodyLarge),
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
          const SizedBox(height: WittSpacing.xxl),
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

  Widget _buildGoalSelection(
    ThemeData theme,
    bool isDark,
    String continueLabel, {
    required String title,
    required String subtitle,
    required List<_Option> options,
  }) {
    return _StepWrapper(
      title: title,
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: WittSpacing.sm,
            runSpacing: WittSpacing.sm,
            children: options
                .map((p) {
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
                })
                .toList(growable: false),
          ),
          const SizedBox(height: WittSpacing.xxxl),
          WittButton(
            label: continueLabel,
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

  Widget _buildPurposeStep(ThemeData theme, bool isDark, String continueLabel) {
    return _StepWrapper(
      title: 'What are you using Witt for?',
      subtitle: 'Select all that apply — we\'ll tailor your experience.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._purposes.map((p) {
            final isSelected = _selectedPurposes.contains(p.value);
            return Padding(
              padding: const EdgeInsets.only(bottom: WittSpacing.sm),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedPurposes.remove(p.value);
                    } else {
                      _selectedPurposes.add(p.value);
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
                    children: [
                      Text(p.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: WittSpacing.md),
                      Expanded(
                        child: Text(p.label, style: theme.textTheme.bodyLarge),
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
          const SizedBox(height: WittSpacing.xxl),
          WittButton(
            label: continueLabel,
            onPressed: _selectedPurposes.isEmpty
                ? null
                : () async {
                    await ref
                        .read(onboardingProvider.notifier)
                        .setLearningPrefs(_selectedPurposes);
                    if (mounted) _next();
                  },
            isFullWidth: true,
            size: WittButtonSize.lg,
          ),
        ],
      ),
    );
  }

  List<_FlowStep> get _flowSteps {
    return switch (_selectedRole) {
      'parent' => [
        _FlowStep.role,
        _FlowStep.parentSetup,
        _FlowStep.level,
        _FlowStep.country,
        _FlowStep.exams,
        _FlowStep.examDates,
        _FlowStep.parentGoals,
        _FlowStep.notifications,
      ],
      'teacher' => [
        _FlowStep.role,
        _FlowStep.teacherSubjects,
        _FlowStep.teacherGradeLevels,
        _FlowStep.country,
        _FlowStep.exams,
        _FlowStep.teacherClassSize,
        _FlowStep.teacherGoals,
        _FlowStep.notifications,
      ],
      _ => [
        _FlowStep.role,
        _FlowStep.level,
        _FlowStep.purpose,
        _FlowStep.country,
        if (_wantsExamPrep) _FlowStep.exams,
        if (_wantsExamPrep) _FlowStep.examDates,
        _FlowStep.studentPrefs,
        _FlowStep.notifications,
      ],
    };
  }

  int get _totalSteps => _flowSteps.length;

  int get _resolvedStep => widget.step.clamp(1, _totalSteps);

  List<ExamDefinition> get _generalExams => examCatalog
      .where((e) => e.category == ExamCategory.general)
      .toList(growable: false);

  List<ExamDefinition> get _countrySpecificExams {
    final country = _selectedCountry;
    if (country == null || country.isEmpty) return const [];
    return examCatalog
        .where(
          (e) =>
              e.category == ExamCategory.countrySpecific &&
              e.countries.contains(country),
        )
        .toList(growable: false);
  }

  void _next() {
    if (_resolvedStep < _totalSteps) {
      context.go('/onboarding/wizard/${_resolvedStep + 1}');
    } else {
      context.go('/onboarding/auth');
    }
  }

  void _back() {
    if (_resolvedStep > 1) {
      context.go('/onboarding/wizard/${_resolvedStep - 1}');
    } else {
      context.go('/onboarding/intro');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final continueLabel =
        ref.watch(liveTextProvider('Continue')).valueOrNull ?? 'Continue';
    final enableNotificationsLabel =
        ref.watch(liveTextProvider('Enable Notifications')).valueOrNull ??
        'Enable Notifications';
    final notNowLabel =
        ref.watch(liveTextProvider('Not now')).valueOrNull ?? 'Not now';

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
                      value: _resolvedStep / _totalSteps,
                      height: 6,
                      gradient: WittColors.primaryGradient,
                    ),
                  ),
                  const SizedBox(width: WittSpacing.md),
                  Text(
                    '$_resolvedStep/$_totalSteps',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: WittSpacing.pagePadding,
                child: _buildStep(
                  theme,
                  isDark,
                  continueLabel,
                  enableNotificationsLabel,
                  notNowLabel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
    ThemeData theme,
    bool isDark,
    String continueLabel,
    String enableNotificationsLabel,
    String notNowLabel,
  ) {
    final step = _flowSteps[_resolvedStep - 1];
    return switch (step) {
      _FlowStep.role => _buildQ1(theme, isDark),
      _FlowStep.parentSetup => _buildParentSetup(theme, isDark),
      _FlowStep.level => _buildQ2(theme, isDark),
      _FlowStep.purpose => _buildPurposeStep(theme, isDark, continueLabel),
      _FlowStep.country => _buildQ3(theme, isDark),
      _FlowStep.exams => _buildQ4(theme, isDark, continueLabel),
      _FlowStep.examDates => _buildQ5(theme, isDark, continueLabel),
      _FlowStep.studentPrefs => _buildQ9(theme, isDark, continueLabel),
      _FlowStep.parentGoals => _buildGoalSelection(
        theme,
        isDark,
        continueLabel,
        title: 'What are your goals as a parent?',
        subtitle: 'Choose what matters most for your child.',
        options: _parentGoals,
      ),
      _FlowStep.teacherSubjects => _buildTeacherSubjects(
        theme,
        isDark,
        continueLabel,
      ),
      _FlowStep.teacherGradeLevels => _buildTeacherGradeLevels(
        theme,
        isDark,
        continueLabel,
      ),
      _FlowStep.teacherClassSize => _buildTeacherClassSize(theme, isDark),
      _FlowStep.teacherGoals => _buildGoalSelection(
        theme,
        isDark,
        continueLabel,
        title: 'What outcomes matter most to you?',
        subtitle: 'We will tailor the teacher dashboard accordingly.',
        options: _teacherGoals,
      ),
      _FlowStep.notifications => _buildQ10(
        theme,
        isDark,
        enableNotificationsLabel,
        notNowLabel,
      ),
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
                    LiveText(r.label, style: theme.textTheme.titleMedium),
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
          title: const LiveText('What year were you born?'),
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
              child: const LiveText('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, selectedYear),
              child: const LiveText('Continue'),
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
    final title = _selectedRole == 'parent'
        ? "What is your child's education level?"
        : "What's your education level?";
    return _StepWrapper(
      title: title,
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

  // Q3: Country — with search
  Widget _buildQ3(ThemeData theme, bool isDark) {
    final query = _countryQuery.toLowerCase();
    final hasQuery = query.isNotEmpty;

    // When searching, show flat filtered list; otherwise show continent groups
    List<String> filteredCountries = const [];
    if (hasQuery) {
      filteredCountries = onboardingContinents
          .expand((g) => g.countries)
          .where((c) => c.toLowerCase().contains(query))
          .toList(growable: false);
    }

    return _StepWrapper(
      title: "Where are you based?",
      subtitle: 'Sets your currency and suggests relevant content.',
      child: Column(
        children: [
          // Search box
          TextField(
            onChanged: (v) => setState(() => _countryQuery = v),
            decoration: InputDecoration(
              hintText: 'Search countries…',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              fillColor: isDark
                  ? WittColors.surfaceVariantDark
                  : WittColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: WittSpacing.md,
                vertical: WittSpacing.sm,
              ),
            ),
          ),
          const SizedBox(height: WittSpacing.md),

          if (hasQuery)
            // Flat filtered results
            ...filteredCountries.map((country) {
              final isSelected = _selectedCountry == country;
              return ListTile(
                title: Text(country),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: WittColors.primary,
                        size: 20,
                      )
                    : null,
                onTap: () async {
                  setState(() => _selectedCountry = country);
                  await ref
                      .read(onboardingProvider.notifier)
                      .setCountry(country);
                  if (mounted) _next();
                },
              );
            })
          else
            // Continent-grouped list
            ...onboardingContinents.map((group) {
              final expanded = _expandedContinents.contains(group.continent);
              return Container(
                margin: const EdgeInsets.only(bottom: WittSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? WittColors.surfaceVariantDark
                      : WittColors.surfaceVariant,
                  borderRadius: WittSpacing.borderRadiusMd,
                ),
                child: ExpansionTile(
                  key: PageStorageKey<String>('continent-${group.continent}'),
                  initiallyExpanded: expanded,
                  onExpansionChanged: (open) {
                    setState(() {
                      if (open) {
                        _expandedContinents.add(group.continent);
                      } else {
                        _expandedContinents.remove(group.continent);
                      }
                    });
                  },
                  title: Text(
                    group.continent,
                    style: theme.textTheme.titleSmall,
                  ),
                  children: group.countries
                      .map((country) {
                        final isSelected = _selectedCountry == country;
                        return ListTile(
                          title: Text(country),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: WittColors.primary,
                                  size: 20,
                                )
                              : null,
                          onTap: () async {
                            setState(() => _selectedCountry = country);
                            await ref
                                .read(onboardingProvider.notifier)
                                .setCountry(country);
                            if (mounted) _next();
                          },
                        );
                      })
                      .toList(growable: false),
                ),
              );
            }),
        ],
      ),
    );
  }

  // Q4: Exams
  Widget _buildQ4(ThemeData theme, bool isDark, String continueLabel) {
    final countrySpecific = _countrySpecificExams;
    final general = _generalExams;
    final title = _selectedRole == 'teacher'
        ? 'What exams are your students preparing for?'
        : _selectedRole == 'parent'
        ? 'What exams is your child preparing for?'
        : 'What are you preparing for?';
    return _StepWrapper(
      title: title,
      subtitle: 'Select one or more exams.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExamSection(
            title: 'Country-specific exams',
            subtitle: _selectedCountry == null
                ? 'Select your country in the previous step to prioritize relevant exams.'
                : 'Prioritized for ${_selectedCountry!}.',
            exams: countrySpecific,
            selectedExams: _selectedExams,
            onToggle: (exam) {
              setState(() {
                if (_selectedExams.contains(exam)) {
                  _selectedExams.remove(exam);
                } else {
                  _selectedExams.add(exam);
                }
              });
            },
          ),
          const SizedBox(height: WittSpacing.lg),
          _ExamSection(
            title: 'General and international exams',
            subtitle: 'Widely used tests across regions and institutions.',
            exams: general,
            selectedExams: _selectedExams,
            onToggle: (exam) {
              setState(() {
                if (_selectedExams.contains(exam)) {
                  _selectedExams.remove(exam);
                } else {
                  _selectedExams.add(exam);
                }
              });
            },
          ),
          const SizedBox(height: WittSpacing.xxxl),
          WittButton(
            label: continueLabel,
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
  Widget _buildQ5(ThemeData theme, bool isDark, String continueLabel) {
    final exams = ref.read(onboardingProvider).selectedExams;
    final title = _selectedRole == 'parent'
        ? "When is your child's exam?"
        : 'When is your exam?';
    return _StepWrapper(
      title: title,
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
            label: continueLabel,
            onPressed: _next,
            isFullWidth: true,
            size: WittButtonSize.lg,
          ),
        ],
      ),
    );
  }

  // Q9: Learning preferences
  Widget _buildQ9(ThemeData theme, bool isDark, String continueLabel) {
    return _StepWrapper(
      title: _selectedRole == 'student'
          ? 'How do you like to learn?'
          : 'Your goals and preferences',
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
            label: continueLabel,
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
  Widget _buildQ10(
    ThemeData theme,
    bool isDark,
    String enableNotificationsLabel,
    String notNowLabel,
  ) {
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
            label: enableNotificationsLabel,
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
            label: notNowLabel,
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
        LiveText(title, style: theme.textTheme.headlineSmall),
        if (subtitle != null) ...[
          const SizedBox(height: WittSpacing.sm),
          LiveText(
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

class _ExamSection extends StatelessWidget {
  const _ExamSection({
    required this.title,
    required this.subtitle,
    required this.exams,
    required this.selectedExams,
    required this.onToggle,
  });

  final String title;
  final String subtitle;
  final List<ExamDefinition> exams;
  final List<String> selectedExams;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WittSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? WittColors.surfaceVariantDark
            : WittColors.surfaceVariant,
        borderRadius: WittSpacing.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LiveText(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: WittSpacing.xs),
          LiveText(subtitle, style: theme.textTheme.bodySmall),
          const SizedBox(height: WittSpacing.md),
          Wrap(
            spacing: WittSpacing.sm,
            runSpacing: WittSpacing.sm,
            children: exams
                .map((exam) {
                  final isSelected = selectedExams.contains(exam.name);
                  return WittChip(
                    label: exam.name,
                    isSelected: isSelected,
                    onTap: () => onToggle(exam.name),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _Option {
  const _Option(this.value, this.emoji, this.label);
  final String value;
  final String emoji;
  final String label;
}

// ── COPPA parental consent dialog ─────────────────────────────────────────

class _CoppaConsentDialog extends StatelessWidget {
  const _CoppaConsentDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const LiveText('Parental Consent Required'),
      content: const LiveText(
        'Witt collects personal data to personalise your learning experience. '
        'Because you may be under 13, we need a parent or guardian to confirm '
        'they consent to your use of this app and the collection of your data '
        'in accordance with COPPA (Children\'s Online Privacy Protection Act).\n\n'
        'A parent or guardian must tap "I Consent" below to continue.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const LiveText('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const LiveText('I Consent (Parent/Guardian)'),
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
              LiveText(label, style: theme.textTheme.titleSmall),
              LiveText(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
