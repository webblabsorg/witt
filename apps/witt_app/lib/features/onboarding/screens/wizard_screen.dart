import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';

import '../onboarding_state.dart';
import '../data/countries_by_continent.dart';
import '../../../core/security/privacy_service.dart';
import '../../../core/translation/live_text.dart';

enum _FlowStep {
  role,
  studentAge,
  level,
  country,
  parentSetup,
  teacherSubjects,
  teacherGradeLevels,
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
  List<String> _selectedSubjects = [];
  List<String> _selectedGradeLevels = [];
  String _countryQuery = '';
  final TextEditingController _ageController = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    final data = ref.read(onboardingProvider);
    _selectedRole = data.role;
    _selectedLevel = data.educationLevel;
    _selectedCountry = data.country;
    _selectedSubjects = List.from(data.subjects);
    _selectedGradeLevels = List.from(data.gradeLevels);
    _childSetupType = data.childSetupType;
    if (data.birthYear != null) {
      final age = DateTime.now().year - data.birthYear!;
      if (age > 0 && age < 120) {
        _ageController.text = '$age';
      }
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

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

  Widget _buildStudentAge(ThemeData theme, bool isDark, String continueLabel) {
    final parsedAge = int.tryParse(_ageController.text);
    final validAge = parsedAge != null && parsedAge >= 5 && parsedAge <= 100;

    return _StepWrapper(
      title: 'How old are you?',
      subtitle: 'This helps us personalize your student experience.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Enter your age',
              filled: true,
              fillColor: isDark
                  ? WittColors.surfaceVariantDark
                  : WittColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: WittSpacing.md),
          Wrap(
            spacing: WittSpacing.sm,
            runSpacing: WittSpacing.sm,
            children: [12, 15, 18, 21]
                .map(
                  (age) => WittChip(
                    label: '$age',
                    isSelected: _ageController.text == '$age',
                    onTap: () {
                      setState(() => _ageController.text = '$age');
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: WittSpacing.xxxl),
          WittButton(
            label: continueLabel,
            onPressed: !validAge
                ? null
                : () async {
                    final birthYear = DateTime.now().year - parsedAge;
                    await ref
                        .read(onboardingProvider.notifier)
                        .setBirthYear(birthYear);
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
      ],
      'teacher' => [
        _FlowStep.role,
        _FlowStep.teacherSubjects,
        _FlowStep.teacherGradeLevels,
        _FlowStep.country,
      ],
      _ => [_FlowStep.role, _FlowStep.studentAge],
    };
  }

  int get _totalSteps => _flowSteps.length;

  int get _resolvedStep => widget.step.clamp(1, _totalSteps);

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
      context.go('/onboarding/language');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final continueLabel =
        ref.watch(liveTextProvider('Continue')).valueOrNull ?? 'Continue';

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
                child: _buildStep(theme, isDark, continueLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(ThemeData theme, bool isDark, String continueLabel) {
    final step = _flowSteps[_resolvedStep - 1];
    return switch (step) {
      _FlowStep.role => _buildQ1(theme, isDark),
      _FlowStep.studentAge => _buildStudentAge(theme, isDark, continueLabel),
      _FlowStep.parentSetup => _buildParentSetup(theme, isDark),
      _FlowStep.level => _buildQ2(theme, isDark),
      _FlowStep.country => _buildQ3(theme, isDark),
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
