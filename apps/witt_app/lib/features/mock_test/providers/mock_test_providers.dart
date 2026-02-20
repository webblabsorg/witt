import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../learn/data/exam_catalog.dart';
import '../../learn/models/question.dart';
import '../../learn/providers/test_prep_providers.dart';
import '../models/mock_test.dart';

// ── Mock test history ─────────────────────────────────────────────────────

class MockTestHistoryNotifier extends Notifier<List<MockTestResult>> {
  @override
  List<MockTestResult> build() => const [];

  void addResult(MockTestResult result) {
    state = [result, ...state];
  }

  List<MockTestResult> resultsForExam(String examId) =>
      state.where((r) => r.examId == examId).toList();
}

final mockTestHistoryProvider =
    NotifierProvider<MockTestHistoryNotifier, List<MockTestResult>>(
      MockTestHistoryNotifier.new,
    );

// ── Mock test session ─────────────────────────────────────────────────────

class MockTestSessionNotifier extends Notifier<MockTestSessionState?> {
  Timer? _sectionTimer;

  @override
  MockTestSessionState? build() => null;

  void startTest(MockTestConfig config) {
    final exam = examById[config.examId];
    if (exam == null) return;

    final sectionsToTest = config.sectionIds.isEmpty
        ? exam.sections
        : exam.sections.where((s) => config.sectionIds.contains(s.id)).toList();

    final engine = ref.read(testPrepEngineProvider(config.examId));
    final sections = sectionsToTest.map((section) {
      final questions = engine.getPreGeneratedQuestions(
        sectionId: section.id,
        topic: section.topics.isNotEmpty ? section.topics.first : section.name,
        count: config.questionCount != null
            ? (config.questionCount! / sectionsToTest.length).ceil()
            : section.questionCount.clamp(5, 20),
        alreadyAttempted: 0,
        isPaidUser: ref.read(isPaidUserProvider),
      );

      final timeLimitSecs =
          (config.timeLimitMinutes != null
                  ? (config.timeLimitMinutes! * 60 / sectionsToTest.length)
                        .round()
                  : section.timeLimitMinutes * 60)
              .clamp(60, 10800);

      return MockTestSection(
        section: section,
        questions: questions,
        timeLimitSeconds: timeLimitSecs,
        timeRemainingSeconds: timeLimitSecs,
        isCompleted: false,
        startedAt: null,
      );
    }).toList();

    state = MockTestSessionState(
      config: config,
      exam: exam,
      sections: sections,
      currentSectionIndex: 0,
      currentQuestionIndex: 0,
      answers: const {},
      flagged: const {},
      status: TestStatus.inProgress,
      startedAt: DateTime.now(),
    );

    _startSectionTimer();
  }

  void _startSectionTimer() {
    _sectionTimer?.cancel();
    final s = state;
    if (s == null || s.config.mode == TestMode.untimed) return;

    _sectionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state;
      if (current == null) {
        _sectionTimer?.cancel();
        return;
      }

      final sectionIdx = current.currentSectionIndex;
      if (sectionIdx >= current.sections.length) return;

      final section = current.sections[sectionIdx];
      final remaining = section.timeRemainingSeconds - 1;

      if (remaining <= 0) {
        // Time's up for this section — auto-advance
        _advanceSection();
      } else {
        final updatedSections = List<MockTestSection>.from(current.sections);
        updatedSections[sectionIdx] = section.copyWith(
          timeRemainingSeconds: remaining,
        );
        state = current.copyWith(sections: updatedSections);
      }
    });
  }

  void selectAnswer(String questionId, String optionId) {
    final s = state;
    if (s == null) return;
    final q = s.currentQuestion;
    if (q == null) return;

    final current = Map<String, List<String>>.from(s.answers);
    if (q.type == QuestionType.multiSelect) {
      final existing = List<String>.from(current[questionId] ?? []);
      if (existing.contains(optionId)) {
        existing.remove(optionId);
      } else {
        existing.add(optionId);
      }
      current[questionId] = existing;
    } else {
      current[questionId] = [optionId];
    }
    state = s.copyWith(answers: current);
  }

  void toggleFlag(String questionId) {
    final s = state;
    if (s == null) return;
    final flagged = Set<String>.from(s.flagged);
    if (flagged.contains(questionId)) {
      flagged.remove(questionId);
    } else {
      flagged.add(questionId);
    }
    state = s.copyWith(flagged: flagged);
  }

  void navigateToQuestion(int sectionIndex, int questionIndex) {
    final s = state;
    if (s == null) return;
    state = s.copyWith(
      currentSectionIndex: sectionIndex,
      currentQuestionIndex: questionIndex,
    );
  }

  void nextQuestion() {
    final s = state;
    if (s == null) return;

    if (!s.isLastQuestion) {
      state = s.copyWith(currentQuestionIndex: s.currentQuestionIndex + 1);
    } else if (!s.isLastSection) {
      _advanceSection();
    } else {
      submitTest();
    }
  }

  void previousQuestion() {
    final s = state;
    if (s == null) return;
    if (s.currentQuestionIndex > 0) {
      state = s.copyWith(currentQuestionIndex: s.currentQuestionIndex - 1);
    }
  }

  void _advanceSection() {
    final s = state;
    if (s == null) return;

    final updatedSections = List<MockTestSection>.from(s.sections);
    updatedSections[s.currentSectionIndex] =
        updatedSections[s.currentSectionIndex].copyWith(isCompleted: true);

    if (s.isLastSection) {
      state = s.copyWith(
        sections: updatedSections,
        status: TestStatus.completed,
        completedAt: DateTime.now(),
      );
      _sectionTimer?.cancel();
      _saveResult();
    } else {
      final nextIdx = s.currentSectionIndex + 1;
      updatedSections[nextIdx] = updatedSections[nextIdx].copyWith(
        startedAt: DateTime.now(),
      );
      state = s.copyWith(
        sections: updatedSections,
        currentSectionIndex: nextIdx,
        currentQuestionIndex: 0,
      );
      _startSectionTimer();
    }
  }

  void submitTest() {
    _sectionTimer?.cancel();
    final s = state;
    if (s == null) return;

    final updatedSections = s.sections
        .map((sec) => sec.copyWith(isCompleted: true))
        .toList();

    state = s.copyWith(
      sections: updatedSections,
      status: TestStatus.completed,
      completedAt: DateTime.now(),
    );
    _saveResult();
  }

  void pauseTest() {
    _sectionTimer?.cancel();
    final s = state;
    if (s == null) return;
    state = s.copyWith(status: TestStatus.paused, pausedAt: DateTime.now());
  }

  void resumeTest() {
    final s = state;
    if (s == null) return;
    state = s.copyWith(status: TestStatus.inProgress);
    _startSectionTimer();
  }

  void abandonTest() {
    _sectionTimer?.cancel();
    state = null;
  }

  void _saveResult() {
    final s = state;
    if (s == null) return;

    final sectionResults = s.sections.map((sec) {
      final sectionAnswers = s.answers.entries
          .where((e) => sec.questions.any((q) => q.id == e.key))
          .toList();

      int correct = 0;
      final topicBreakdown = <String, List<bool>>{};

      for (final q in sec.questions) {
        final selected = s.answers[q.id] ?? [];
        final isCorrect =
            selected.isNotEmpty &&
            selected.toSet().containsAll(q.correctAnswerIds.toSet()) &&
            q.correctAnswerIds.toSet().containsAll(selected.toSet());
        if (isCorrect) correct++;
        topicBreakdown.putIfAbsent(q.topic, () => []).add(isCorrect);
      }

      final topicAccuracy = topicBreakdown.map(
        (topic, results) => MapEntry(
          topic,
          results.isEmpty
              ? 0.0
              : results.where((b) => b).length / results.length,
        ),
      );

      final rawScore = sec.questions.isEmpty
          ? 0.0
          : correct / sec.questions.length;
      final scaledScore =
          rawScore * (s.exam.maxScore - s.exam.minScore) + s.exam.minScore;

      return SectionResult(
        sectionId: sec.section.id,
        sectionName: sec.section.name,
        totalQuestions: sec.questions.length,
        attempted: sectionAnswers.length,
        correct: correct,
        timeSpentSeconds: sec.timeLimitSeconds - sec.timeRemainingSeconds,
        rawScore: rawScore,
        scaledScore: scaledScore,
        topicBreakdown: topicAccuracy,
      );
    }).toList();

    final totalCorrect = sectionResults.fold(0, (sum, r) => sum + r.correct);
    final totalQ = sectionResults.fold(0, (sum, r) => sum + r.totalQuestions);
    final rawScore = totalQ == 0 ? 0.0 : totalCorrect / totalQ;
    final scaledScore =
        rawScore * (s.exam.maxScore - s.exam.minScore) + s.exam.minScore;

    final result = MockTestResult(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      examId: s.exam.id,
      examName: s.exam.name,
      config: s.config,
      sectionResults: sectionResults,
      attempts: const [],
      totalTimeSeconds: DateTime.now().difference(s.startedAt).inSeconds,
      totalScore: rawScore,
      scaledScore: scaledScore,
      percentile: _estimatePercentile(rawScore),
      completedAt: DateTime.now(),
      status: TestStatus.completed,
    );

    ref.read(mockTestHistoryProvider.notifier).addResult(result);
  }

  double _estimatePercentile(double rawScore) {
    // Simplified percentile estimate based on raw score
    if (rawScore >= 0.95) return 99;
    if (rawScore >= 0.90) return 95;
    if (rawScore >= 0.80) return 85;
    if (rawScore >= 0.70) return 70;
    if (rawScore >= 0.60) return 55;
    if (rawScore >= 0.50) return 40;
    return rawScore * 80;
  }
}

final mockTestSessionProvider =
    NotifierProvider<MockTestSessionNotifier, MockTestSessionState?>(
      MockTestSessionNotifier.new,
    );

// ── Score trajectory ──────────────────────────────────────────────────────

final scoreTrajectoryProvider =
    Provider.family<List<({DateTime date, double score})>, String>((
      ref,
      examId,
    ) {
      final history = ref.watch(mockTestHistoryProvider);
      return history
          .where((r) => r.examId == examId)
          .map((r) => (date: r.completedAt, score: r.scaledScore))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    });
