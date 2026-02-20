import 'package:flutter/foundation.dart';
import '../../learn/models/question.dart';

enum QuizSource {
  manual,
  fromNote,
  fromVocabList,
  fromExam,
  aiGenerated,
}

enum QuizDifficulty { easy, mixed, hard }

enum QuizResultStatus { pass, fail, incomplete }

@immutable
class QuizConfig {
  const QuizConfig({
    required this.title,
    required this.source,
    this.sourceId,
    this.questionCount = 10,
    this.difficulty = QuizDifficulty.mixed,
    this.includeMultipleChoice = true,
    this.includeTrueFalse = true,
    this.includeFillBlank = false,
    this.timeLimitMinutes,
    this.shuffleQuestions = true,
    this.shuffleOptions = true,
  });

  final String title;
  final QuizSource source;
  final String? sourceId;
  final int questionCount;
  final QuizDifficulty difficulty;
  final bool includeMultipleChoice;
  final bool includeTrueFalse;
  final bool includeFillBlank;
  final int? timeLimitMinutes;
  final bool shuffleQuestions;
  final bool shuffleOptions;

  QuizConfig copyWith({
    String? title,
    QuizSource? source,
    String? sourceId,
    int? questionCount,
    QuizDifficulty? difficulty,
    bool? includeMultipleChoice,
    bool? includeTrueFalse,
    bool? includeFillBlank,
    int? timeLimitMinutes,
    bool? shuffleQuestions,
    bool? shuffleOptions,
  }) =>
      QuizConfig(
        title: title ?? this.title,
        source: source ?? this.source,
        sourceId: sourceId ?? this.sourceId,
        questionCount: questionCount ?? this.questionCount,
        difficulty: difficulty ?? this.difficulty,
        includeMultipleChoice:
            includeMultipleChoice ?? this.includeMultipleChoice,
        includeTrueFalse: includeTrueFalse ?? this.includeTrueFalse,
        includeFillBlank: includeFillBlank ?? this.includeFillBlank,
        timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
        shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
        shuffleOptions: shuffleOptions ?? this.shuffleOptions,
      );
}

@immutable
class QuizResult {
  const QuizResult({
    required this.id,
    required this.config,
    required this.questions,
    required this.answers,
    required this.timeSpentSeconds,
    required this.completedAt,
  });

  final String id;
  final QuizConfig config;
  final List<Question> questions;
  final Map<String, List<String>> answers;
  final int timeSpentSeconds;
  final DateTime completedAt;

  int get totalQuestions => questions.length;
  int get correctCount {
    int count = 0;
    for (final q in questions) {
      final selected = answers[q.id] ?? [];
      if (selected.isNotEmpty &&
          selected.toSet().containsAll(q.correctAnswerIds.toSet()) &&
          q.correctAnswerIds.toSet().containsAll(selected.toSet())) {
        count++;
      }
    }
    return count;
  }

  double get accuracy =>
      totalQuestions == 0 ? 0 : correctCount / totalQuestions;
  QuizResultStatus get status =>
      accuracy >= 0.7 ? QuizResultStatus.pass : QuizResultStatus.fail;
  int get xpEarned => (correctCount * 5).clamp(0, 200);
}

class QuizSessionState {
  const QuizSessionState({
    required this.config,
    required this.questions,
    required this.currentIndex,
    required this.answers,
    required this.isComplete,
    required this.startedAt,
    this.timeRemainingSeconds,
  });

  final QuizConfig config;
  final List<Question> questions;
  final int currentIndex;
  final Map<String, List<String>> answers;
  final bool isComplete;
  final DateTime startedAt;
  final int? timeRemainingSeconds;

  Question? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;
  bool get isLastQuestion => currentIndex + 1 >= questions.length;
  int get answeredCount => answers.length;

  QuizSessionState copyWith({
    QuizConfig? config,
    List<Question>? questions,
    int? currentIndex,
    Map<String, List<String>>? answers,
    bool? isComplete,
    DateTime? startedAt,
    int? timeRemainingSeconds,
  }) =>
      QuizSessionState(
        config: config ?? this.config,
        questions: questions ?? this.questions,
        currentIndex: currentIndex ?? this.currentIndex,
        answers: answers ?? this.answers,
        isComplete: isComplete ?? this.isComplete,
        startedAt: startedAt ?? this.startedAt,
        timeRemainingSeconds:
            timeRemainingSeconds ?? this.timeRemainingSeconds,
      );
}
