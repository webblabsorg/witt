import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../learn/models/question.dart';
import '../../learn/providers/test_prep_providers.dart';
import '../models/quiz.dart';

// ── Quiz history ──────────────────────────────────────────────────────────

class QuizHistoryNotifier extends Notifier<List<QuizResult>> {
  @override
  List<QuizResult> build() => const [];

  void addResult(QuizResult result) {
    state = [result, ...state];
  }
}

final quizHistoryProvider =
    NotifierProvider<QuizHistoryNotifier, List<QuizResult>>(
        QuizHistoryNotifier.new);

// ── Quiz session ──────────────────────────────────────────────────────────

class QuizSessionNotifier extends Notifier<QuizSessionState?> {
  Timer? _timer;

  @override
  QuizSessionState? build() => null;

  void startQuiz(QuizConfig config) {
    _timer?.cancel();

    // Generate questions from exam catalog via TestPrepEngine
    final examId = config.sourceId ?? 'sat';
    final engine = ref.read(testPrepEngineProvider(examId));
    final questions = engine.getPreGeneratedQuestions(
      sectionId: 'all',
      topic: config.title,
      count: config.questionCount,
      alreadyAttempted: 0,
      isPaidUser: ref.read(isPaidUserProvider),
    );

    final timeLimitSecs = config.timeLimitMinutes != null
        ? config.timeLimitMinutes! * 60
        : null;

    state = QuizSessionState(
      config: config,
      questions: questions,
      currentIndex: 0,
      answers: const {},
      isComplete: false,
      startedAt: DateTime.now(),
      timeRemainingSeconds: timeLimitSecs,
    );

    if (timeLimitSecs != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        final s = state;
        if (s == null || s.isComplete) {
          _timer?.cancel();
          return;
        }
        final remaining = (s.timeRemainingSeconds ?? 0) - 1;
        if (remaining <= 0) {
          _timer?.cancel();
          submitQuiz();
        } else {
          state = s.copyWith(timeRemainingSeconds: remaining);
        }
      });
    }
  }

  void selectAnswer(String questionId, String optionId) {
    final s = state;
    if (s == null || s.isComplete) return;
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

  void nextQuestion() {
    final s = state;
    if (s == null) return;
    if (s.isLastQuestion) {
      submitQuiz();
    } else {
      state = s.copyWith(currentIndex: s.currentIndex + 1);
    }
  }

  void previousQuestion() {
    final s = state;
    if (s == null || s.currentIndex == 0) return;
    state = s.copyWith(currentIndex: s.currentIndex - 1);
  }

  void submitQuiz() {
    _timer?.cancel();
    final s = state;
    if (s == null) return;
    state = s.copyWith(isComplete: true);

    final result = QuizResult(
      id: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
      config: s.config,
      questions: s.questions,
      answers: s.answers,
      timeSpentSeconds: DateTime.now().difference(s.startedAt).inSeconds,
      completedAt: DateTime.now(),
    );
    ref.read(quizHistoryProvider.notifier).addResult(result);
  }

  void resetQuiz() {
    _timer?.cancel();
    state = null;
  }
}

final quizSessionProvider =
    NotifierProvider<QuizSessionNotifier, QuizSessionState?>(
        QuizSessionNotifier.new);

// ── Quiz config builder ───────────────────────────────────────────────────

class QuizConfigNotifier extends Notifier<QuizConfig> {
  @override
  QuizConfig build() => const QuizConfig(
        title: 'Quick Quiz',
        source: QuizSource.manual,
        questionCount: 10,
        difficulty: QuizDifficulty.mixed,
      );

  void setTitle(String title) => state = state.copyWith(title: title);
  void setSource(QuizSource source, {String? sourceId}) =>
      state = state.copyWith(source: source, sourceId: sourceId);
  void setQuestionCount(int count) =>
      state = state.copyWith(questionCount: count);
  void setDifficulty(QuizDifficulty difficulty) =>
      state = state.copyWith(difficulty: difficulty);
  void setTimeLimitMinutes(int? minutes) =>
      state = state.copyWith(timeLimitMinutes: minutes);
  void toggleMultipleChoice(bool v) =>
      state = state.copyWith(includeMultipleChoice: v);
  void toggleTrueFalse(bool v) =>
      state = state.copyWith(includeTrueFalse: v);
  void toggleFillBlank(bool v) =>
      state = state.copyWith(includeFillBlank: v);
  void toggleShuffle(bool v) =>
      state = state.copyWith(shuffleQuestions: v);
  void reset() => ref.invalidateSelf();
}

final quizConfigProvider =
    NotifierProvider<QuizConfigNotifier, QuizConfig>(QuizConfigNotifier.new);
