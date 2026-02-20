import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _boxName = 'onboarding';
const _keyCompleted = 'completed';
const _keyStep = 'step';
const _keyLanguage = 'language';
const _keyRole = 'role';
const _keyEducationLevel = 'education_level';
const _keyCountry = 'country';
const _keyExams = 'exams';
const _keyExamDates = 'exam_dates';
const _keyTargetScores = 'target_scores';
const _keyStudyTime = 'study_time';
const _keySubjects = 'subjects';
const _keyLearningPrefs = 'learning_prefs';
const _keyGradeLevels = 'grade_levels';
const _keyChildSetupType = 'child_setup_type';
const _keyClassSize = 'class_size';
const _keyNotificationsEnabled = 'notifications_enabled';
const _keyBirthYear = 'birth_year';

class OnboardingData {
  const OnboardingData({
    this.isCompleted = false,
    this.currentStep = 0,
    this.language = 'en',
    this.role,
    this.educationLevel,
    this.country,
    this.selectedExams = const [],
    this.examDates = const {},
    this.targetScores = const {},
    this.studyTimeMinutes = 30,
    this.subjects = const [],
    this.learningPrefs = const [],
    this.gradeLevels = const [],
    this.childSetupType,
    this.classSize,
    this.notificationsEnabled = false,
    this.birthYear,
  });

  final bool isCompleted;
  final int currentStep;
  final String language;
  final String? role;
  final String? educationLevel;
  final String? country;
  final List<String> selectedExams;
  final Map<String, String> examDates;
  final Map<String, double> targetScores;
  final int studyTimeMinutes;
  final List<String> subjects;
  final List<String> learningPrefs;
  final List<String> gradeLevels;
  final String? childSetupType;
  final String? classSize;
  final bool notificationsEnabled;
  final int? birthYear;

  OnboardingData copyWith({
    bool? isCompleted,
    int? currentStep,
    String? language,
    String? role,
    String? educationLevel,
    String? country,
    List<String>? selectedExams,
    Map<String, String>? examDates,
    Map<String, double>? targetScores,
    int? studyTimeMinutes,
    List<String>? subjects,
    List<String>? learningPrefs,
    List<String>? gradeLevels,
    String? childSetupType,
    String? classSize,
    bool? notificationsEnabled,
    int? birthYear,
  }) {
    return OnboardingData(
      isCompleted: isCompleted ?? this.isCompleted,
      currentStep: currentStep ?? this.currentStep,
      language: language ?? this.language,
      role: role ?? this.role,
      educationLevel: educationLevel ?? this.educationLevel,
      country: country ?? this.country,
      selectedExams: selectedExams ?? this.selectedExams,
      examDates: examDates ?? this.examDates,
      targetScores: targetScores ?? this.targetScores,
      studyTimeMinutes: studyTimeMinutes ?? this.studyTimeMinutes,
      subjects: subjects ?? this.subjects,
      learningPrefs: learningPrefs ?? this.learningPrefs,
      gradeLevels: gradeLevels ?? this.gradeLevels,
      childSetupType: childSetupType ?? this.childSetupType,
      classSize: classSize ?? this.classSize,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      birthYear: birthYear ?? this.birthYear,
    );
  }
}

class OnboardingNotifier extends Notifier<OnboardingData> {
  late Box _box;

  @override
  OnboardingData build() {
    _box = Hive.box(_boxName);
    return _load();
  }

  OnboardingData _load() {
    final rawScores =
        _box.get(_keyTargetScores, defaultValue: <String, dynamic>{}) as Map;
    return OnboardingData(
      isCompleted: _box.get(_keyCompleted, defaultValue: false) as bool,
      currentStep: _box.get(_keyStep, defaultValue: 0) as int,
      language: _box.get(_keyLanguage, defaultValue: 'en') as String,
      role: _box.get(_keyRole) as String?,
      educationLevel: _box.get(_keyEducationLevel) as String?,
      country: _box.get(_keyCountry) as String?,
      selectedExams: List<String>.from(
        _box.get(_keyExams, defaultValue: <String>[]) as List,
      ),
      examDates: Map<String, String>.from(
        _box.get(_keyExamDates, defaultValue: <String, String>{}) as Map,
      ),
      targetScores: rawScores.map(
        (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
      ),
      studyTimeMinutes: _box.get(_keyStudyTime, defaultValue: 30) as int,
      subjects: List<String>.from(
        _box.get(_keySubjects, defaultValue: <String>[]) as List,
      ),
      learningPrefs: List<String>.from(
        _box.get(_keyLearningPrefs, defaultValue: <String>[]) as List,
      ),
      gradeLevels: List<String>.from(
        _box.get(_keyGradeLevels, defaultValue: <String>[]) as List,
      ),
      childSetupType: _box.get(_keyChildSetupType) as String?,
      classSize: _box.get(_keyClassSize) as String?,
      notificationsEnabled:
          _box.get(_keyNotificationsEnabled, defaultValue: false) as bool,
      birthYear: _box.get(_keyBirthYear) as int?,
    );
  }

  Future<void> _save(OnboardingData data) async {
    await _box.put(_keyCompleted, data.isCompleted);
    await _box.put(_keyStep, data.currentStep);
    await _box.put(_keyLanguage, data.language);
    await _box.put(_keyRole, data.role);
    await _box.put(_keyEducationLevel, data.educationLevel);
    await _box.put(_keyCountry, data.country);
    await _box.put(_keyExams, data.selectedExams);
    await _box.put(_keyExamDates, data.examDates);
    await _box.put(_keyTargetScores, data.targetScores);
    await _box.put(_keyStudyTime, data.studyTimeMinutes);
    await _box.put(_keySubjects, data.subjects);
    await _box.put(_keyLearningPrefs, data.learningPrefs);
    await _box.put(_keyGradeLevels, data.gradeLevels);
    await _box.put(_keyChildSetupType, data.childSetupType);
    await _box.put(_keyClassSize, data.classSize);
    await _box.put(_keyNotificationsEnabled, data.notificationsEnabled);
    if (data.birthYear != null) await _box.put(_keyBirthYear, data.birthYear);
    state = data;
  }

  Future<void> setLanguage(String code) async {
    await _save(state.copyWith(language: code));
  }

  Future<void> setRole(String role) async {
    await _save(state.copyWith(role: role, currentStep: 2));
  }

  Future<void> setEducationLevel(String level) async {
    await _save(state.copyWith(educationLevel: level, currentStep: 3));
  }

  Future<void> setCountry(String country) async {
    await _save(state.copyWith(country: country, currentStep: 4));
  }

  Future<void> setExams(List<String> exams) async {
    await _save(state.copyWith(selectedExams: exams, currentStep: 5));
  }

  Future<void> setExamDates(Map<String, String> dates) async {
    await _save(state.copyWith(examDates: dates, currentStep: 6));
  }

  Future<void> setTargetScores(Map<String, double> scores) async {
    await _save(state.copyWith(targetScores: scores, currentStep: 7));
  }

  Future<void> setStudyTime(int minutes) async {
    await _save(state.copyWith(studyTimeMinutes: minutes, currentStep: 8));
  }

  Future<void> setSubjects(List<String> subjects) async {
    await _save(state.copyWith(subjects: subjects, currentStep: 9));
  }

  Future<void> setLearningPrefs(List<String> prefs) async {
    await _save(state.copyWith(learningPrefs: prefs, currentStep: 10));
  }

  Future<void> setGradeLevels(List<String> levels) async {
    await _save(state.copyWith(gradeLevels: levels));
  }

  Future<void> setChildSetupType(String type) async {
    await _save(state.copyWith(childSetupType: type));
  }

  Future<void> setClassSize(String size) async {
    await _save(state.copyWith(classSize: size));
  }

  Future<void> setNotifications(bool enabled) async {
    await _save(state.copyWith(notificationsEnabled: enabled, currentStep: 11));
  }

  Future<void> setBirthYear(int year) async {
    await _save(state.copyWith(birthYear: year));
  }

  Future<void> setStep(int step) async {
    await _save(state.copyWith(currentStep: step));
  }

  Future<void> complete() async {
    await _save(state.copyWith(isCompleted: true));
  }

  Future<void> reset() async {
    await _box.clear();
    state = const OnboardingData();
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingData>(
  OnboardingNotifier.new,
);

/// Opens the Hive box needed by onboarding — call once in Bootstrap.run()
Future<void> openOnboardingBox() async {
  await Hive.openBox(_boxName);
}
