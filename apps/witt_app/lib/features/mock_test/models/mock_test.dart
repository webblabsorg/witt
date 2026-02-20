import 'package:flutter/foundation.dart';
import '../../learn/models/exam.dart';
import '../../learn/models/question.dart';

// ── Test configuration ────────────────────────────────────────────────────

enum TestMode {
  fullLength,   // Complete exam simulation
  sectionOnly,  // Single section practice
  timed,        // Custom timed test
  untimed,      // No time pressure
}

enum TestStatus {
  notStarted,
  inProgress,
  paused,
  completed,
  abandoned,
}

@immutable
class MockTestConfig {
  const MockTestConfig({
    required this.examId,
    required this.mode,
    this.sectionIds = const [],
    this.questionCount,
    this.timeLimitMinutes,
    this.shuffleQuestions = true,
    this.showExplanationsAfter = true,
    this.allowReview = true,
    this.isPractice = false,
  });

  final String examId;
  final TestMode mode;
  final List<String> sectionIds;
  final int? questionCount;
  final int? timeLimitMinutes;
  final bool shuffleQuestions;
  final bool showExplanationsAfter;
  final bool allowReview;
  final bool isPractice;

  MockTestConfig copyWith({
    String? examId,
    TestMode? mode,
    List<String>? sectionIds,
    int? questionCount,
    int? timeLimitMinutes,
    bool? shuffleQuestions,
    bool? showExplanationsAfter,
    bool? allowReview,
    bool? isPractice,
  }) =>
      MockTestConfig(
        examId: examId ?? this.examId,
        mode: mode ?? this.mode,
        sectionIds: sectionIds ?? this.sectionIds,
        questionCount: questionCount ?? this.questionCount,
        timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
        shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
        showExplanationsAfter:
            showExplanationsAfter ?? this.showExplanationsAfter,
        allowReview: allowReview ?? this.allowReview,
        isPractice: isPractice ?? this.isPractice,
      );
}

// ── Section result ────────────────────────────────────────────────────────

@immutable
class SectionResult {
  const SectionResult({
    required this.sectionId,
    required this.sectionName,
    required this.totalQuestions,
    required this.attempted,
    required this.correct,
    required this.timeSpentSeconds,
    required this.rawScore,
    required this.scaledScore,
    this.topicBreakdown = const {},
  });

  final String sectionId;
  final String sectionName;
  final int totalQuestions;
  final int attempted;
  final int correct;
  final int timeSpentSeconds;
  final double rawScore;
  final double scaledScore;
  final Map<String, double> topicBreakdown;

  double get accuracy => attempted == 0 ? 0 : correct / attempted;
  int get skipped => totalQuestions - attempted;
}

// ── Mock test result ──────────────────────────────────────────────────────

@immutable
class MockTestResult {
  const MockTestResult({
    required this.id,
    required this.examId,
    required this.examName,
    required this.config,
    required this.sectionResults,
    required this.attempts,
    required this.totalTimeSeconds,
    required this.totalScore,
    required this.scaledScore,
    required this.percentile,
    required this.completedAt,
    required this.status,
  });

  final String id;
  final String examId;
  final String examName;
  final MockTestConfig config;
  final List<SectionResult> sectionResults;
  final List<QuestionAttempt> attempts;
  final int totalTimeSeconds;
  final double totalScore;
  final double scaledScore;
  final double percentile;
  final DateTime completedAt;
  final TestStatus status;

  int get totalQuestions =>
      sectionResults.fold(0, (sum, s) => sum + s.totalQuestions);
  int get totalCorrect =>
      sectionResults.fold(0, (sum, s) => sum + s.correct);
  int get totalAttempted =>
      sectionResults.fold(0, (sum, s) => sum + s.attempted);
  double get overallAccuracy =>
      totalAttempted == 0 ? 0 : totalCorrect / totalAttempted;
  int get xpEarned =>
      (totalCorrect * 8 + (overallAccuracy * 100).round()).clamp(0, 1000);
}

// ── Mock test session state ───────────────────────────────────────────────

@immutable
class MockTestSection {
  const MockTestSection({
    required this.section,
    required this.questions,
    required this.timeLimitSeconds,
    required this.timeRemainingSeconds,
    required this.isCompleted,
    required this.startedAt,
  });

  final ExamSection section;
  final List<Question> questions;
  final int timeLimitSeconds;
  final int timeRemainingSeconds;
  final bool isCompleted;
  final DateTime? startedAt;

  double get progress => timeLimitSeconds == 0
      ? 0
      : 1 - (timeRemainingSeconds / timeLimitSeconds);

  MockTestSection copyWith({
    ExamSection? section,
    List<Question>? questions,
    int? timeLimitSeconds,
    int? timeRemainingSeconds,
    bool? isCompleted,
    DateTime? startedAt,
  }) =>
      MockTestSection(
        section: section ?? this.section,
        questions: questions ?? this.questions,
        timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
        timeRemainingSeconds:
            timeRemainingSeconds ?? this.timeRemainingSeconds,
        isCompleted: isCompleted ?? this.isCompleted,
        startedAt: startedAt ?? this.startedAt,
      );
}

class MockTestSessionState {
  const MockTestSessionState({
    required this.config,
    required this.exam,
    required this.sections,
    required this.currentSectionIndex,
    required this.currentQuestionIndex,
    required this.answers,
    required this.flagged,
    required this.status,
    required this.startedAt,
    this.pausedAt,
    this.completedAt,
  });

  final MockTestConfig config;
  final Exam exam;
  final List<MockTestSection> sections;
  final int currentSectionIndex;
  final int currentQuestionIndex;
  final Map<String, List<String>> answers; // questionId -> selectedOptionIds
  final Set<String> flagged;
  final TestStatus status;
  final DateTime startedAt;
  final DateTime? pausedAt;
  final DateTime? completedAt;

  MockTestSection? get currentSection =>
      currentSectionIndex < sections.length
          ? sections[currentSectionIndex]
          : null;

  Question? get currentQuestion {
    final sec = currentSection;
    if (sec == null) return null;
    if (currentQuestionIndex >= sec.questions.length) return null;
    return sec.questions[currentQuestionIndex];
  }

  bool get isLastSection => currentSectionIndex + 1 >= sections.length;
  bool get isLastQuestion {
    final sec = currentSection;
    if (sec == null) return true;
    return currentQuestionIndex + 1 >= sec.questions.length;
  }

  int get totalQuestions =>
      sections.fold(0, (sum, s) => sum + s.questions.length);
  int get answeredCount => answers.length;
  int get flaggedCount => flagged.length;

  int get globalQuestionIndex {
    int idx = 0;
    for (int i = 0; i < currentSectionIndex; i++) {
      idx += sections[i].questions.length;
    }
    return idx + currentQuestionIndex;
  }

  MockTestSessionState copyWith({
    MockTestConfig? config,
    Exam? exam,
    List<MockTestSection>? sections,
    int? currentSectionIndex,
    int? currentQuestionIndex,
    Map<String, List<String>>? answers,
    Set<String>? flagged,
    TestStatus? status,
    DateTime? startedAt,
    DateTime? pausedAt,
    DateTime? completedAt,
  }) =>
      MockTestSessionState(
        config: config ?? this.config,
        exam: exam ?? this.exam,
        sections: sections ?? this.sections,
        currentSectionIndex:
            currentSectionIndex ?? this.currentSectionIndex,
        currentQuestionIndex:
            currentQuestionIndex ?? this.currentQuestionIndex,
        answers: answers ?? this.answers,
        flagged: flagged ?? this.flagged,
        status: status ?? this.status,
        startedAt: startedAt ?? this.startedAt,
        pausedAt: pausedAt ?? this.pausedAt,
        completedAt: completedAt ?? this.completedAt,
      );
}
