import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/exam_catalog.dart';
import '../models/exam.dart';
import '../models/question.dart';

// ── Exam catalog providers ────────────────────────────────────────────────

final allExamsProvider = Provider<List<Exam>>((ref) => allExams);

final featuredExamsProvider = Provider<List<Exam>>((ref) => featuredExams);

final examByIdProvider = Provider.family<Exam?, String>((ref, id) {
  return examById[id];
});

final examsByRegionProvider = Provider.family<List<Exam>, ExamRegion>((
  ref,
  region,
) {
  return allExams.where((e) => e.region == region).toList();
});

// ── User exam selection ───────────────────────────────────────────────────

class UserExamsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void addExam(String examId) {
    if (!state.contains(examId)) {
      state = [...state, examId];
    }
  }

  void removeExam(String examId) {
    state = state.where((id) => id != examId).toList();
  }

  bool isAdded(String examId) => state.contains(examId);
}

final userExamsProvider = NotifierProvider<UserExamsNotifier, List<String>>(
  UserExamsNotifier.new,
);

final userExamListProvider = Provider<List<Exam>>((ref) {
  final ids = ref.watch(userExamsProvider);
  return ids.map((id) => examById[id]).whereType<Exam>().toList();
});

final myExamsProvider = Provider<List<Exam>>((ref) {
  return ref.watch(userExamListProvider);
});

// ── Question session state ────────────────────────────────────────────────

class QuestionSessionState {
  const QuestionSessionState({
    required this.questions,
    required this.currentIndex,
    required this.attempts,
    required this.isComplete,
    required this.startedAt,
    this.selectedAnswerIds = const [],
    this.hasSubmitted = false,
    this.isBookmarked = false,
  });

  final List<Question> questions;
  final int currentIndex;
  final List<QuestionAttempt> attempts;
  final bool isComplete;
  final DateTime startedAt;
  final List<String> selectedAnswerIds;
  final bool hasSubmitted;
  final bool isBookmarked;

  Question? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  int get correctCount => attempts.where((a) => a.isCorrect).length;
  double get accuracy => attempts.isEmpty ? 0 : correctCount / attempts.length;

  QuestionSessionState copyWith({
    List<Question>? questions,
    int? currentIndex,
    List<QuestionAttempt>? attempts,
    bool? isComplete,
    DateTime? startedAt,
    List<String>? selectedAnswerIds,
    bool? hasSubmitted,
    bool? isBookmarked,
  }) => QuestionSessionState(
    questions: questions ?? this.questions,
    currentIndex: currentIndex ?? this.currentIndex,
    attempts: attempts ?? this.attempts,
    isComplete: isComplete ?? this.isComplete,
    startedAt: startedAt ?? this.startedAt,
    selectedAnswerIds: selectedAnswerIds ?? this.selectedAnswerIds,
    hasSubmitted: hasSubmitted ?? this.hasSubmitted,
    isBookmarked: isBookmarked ?? this.isBookmarked,
  );
}

class QuestionSessionNotifier extends Notifier<QuestionSessionState?> {
  @override
  QuestionSessionState? build() => null;

  void startSession(List<Question> questions) {
    state = QuestionSessionState(
      questions: questions,
      currentIndex: 0,
      attempts: [],
      isComplete: false,
      startedAt: DateTime.now(),
    );
  }

  void toggleAnswer(String optionId) {
    final s = state;
    if (s == null || s.hasSubmitted) return;
    final q = s.currentQuestion;
    if (q == null) return;

    List<String> updated;
    if (q.type == QuestionType.multiSelect) {
      updated = s.selectedAnswerIds.contains(optionId)
          ? s.selectedAnswerIds.where((id) => id != optionId).toList()
          : [...s.selectedAnswerIds, optionId];
    } else {
      updated = [optionId];
    }
    state = s.copyWith(selectedAnswerIds: updated);
  }

  void submitAnswer(String userId) {
    final s = state;
    if (s == null || s.hasSubmitted || s.currentQuestion == null) return;
    final q = s.currentQuestion!;

    final selected = s.selectedAnswerIds;
    final correct = q.correctAnswerIds.toSet();
    final isCorrect =
        selected.isNotEmpty &&
        selected.toSet().containsAll(correct) &&
        correct.containsAll(selected.toSet());

    final attempt = QuestionAttempt(
      id: '${q.id}_${DateTime.now().millisecondsSinceEpoch}',
      questionId: q.id,
      examId: q.examId,
      userId: userId,
      selectedAnswerIds: selected,
      isCorrect: isCorrect,
      timeSpentSeconds: DateTime.now().difference(s.startedAt).inSeconds,
      attemptedAt: DateTime.now(),
    );

    state = s.copyWith(attempts: [...s.attempts, attempt], hasSubmitted: true);
  }

  void nextQuestion() {
    final s = state;
    if (s == null) return;
    final nextIndex = s.currentIndex + 1;
    if (nextIndex >= s.questions.length) {
      state = s.copyWith(isComplete: true);
    } else {
      state = s.copyWith(
        currentIndex: nextIndex,
        selectedAnswerIds: [],
        hasSubmitted: false,
        isBookmarked: false,
      );
    }
  }

  void toggleBookmark() {
    final s = state;
    if (s == null) return;
    state = s.copyWith(isBookmarked: !s.isBookmarked);
  }

  void endSession() {
    state = null;
  }
}

final questionSessionProvider =
    NotifierProvider<QuestionSessionNotifier, QuestionSessionState?>(
      QuestionSessionNotifier.new,
    );

// ── Bookmarked questions ──────────────────────────────────────────────────

class BookmarkedQuestionsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String questionId) {
    if (state.contains(questionId)) {
      state = {...state}..remove(questionId);
    } else {
      state = {...state, questionId};
    }
  }

  bool isBookmarked(String questionId) => state.contains(questionId);
}

final bookmarkedQuestionsProvider =
    NotifierProvider<BookmarkedQuestionsNotifier, Set<String>>(
      BookmarkedQuestionsNotifier.new,
    );

// ── User proficiency per exam/topic ──────────────────────────────────────

class UserProficiency {
  const UserProficiency({
    required this.examId,
    required this.topicScores,
    required this.overallScore,
    required this.questionsAttempted,
  });

  final String examId;
  final Map<String, double> topicScores;
  final double overallScore;
  final int questionsAttempted;

  UserProficiency copyWith({
    Map<String, double>? topicScores,
    double? overallScore,
    int? questionsAttempted,
  }) => UserProficiency(
    examId: examId,
    topicScores: topicScores ?? this.topicScores,
    overallScore: overallScore ?? this.overallScore,
    questionsAttempted: questionsAttempted ?? this.questionsAttempted,
  );
}

class UserProficiencyNotifier extends Notifier<Map<String, UserProficiency>> {
  @override
  Map<String, UserProficiency> build() => {};

  void updateFromAttempt(QuestionAttempt attempt, String topic) {
    final current =
        state[attempt.examId] ??
        UserProficiency(
          examId: attempt.examId,
          topicScores: {},
          overallScore: 0.5,
          questionsAttempted: 0,
        );

    final topicScores = Map<String, double>.from(current.topicScores);
    final prevScore = topicScores[topic] ?? 0.5;
    topicScores[topic] = attempt.isCorrect
        ? prevScore + (1 - prevScore) * 0.1
        : prevScore - prevScore * 0.1;

    final allScores = topicScores.values;
    final overall = allScores.isEmpty
        ? 0.5
        : allScores.reduce((a, b) => a + b) / allScores.length;

    state = {
      ...state,
      attempt.examId: current.copyWith(
        topicScores: topicScores,
        overallScore: overall,
        questionsAttempted: current.questionsAttempted + 1,
      ),
    };
  }
}

final userProficiencyProvider =
    NotifierProvider<UserProficiencyNotifier, Map<String, UserProficiency>>(
      UserProficiencyNotifier.new,
    );
