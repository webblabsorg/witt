import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_monetization/witt_monetization.dart';
import '../data/exam_catalog.dart';
import '../models/exam.dart';
import '../models/question.dart';
import '../providers/exam_providers.dart';
import '../services/test_prep_engine.dart';

// ── TestPrepEngine provider ───────────────────────────────────────────────

final testPrepEngineProvider = Provider.family<TestPrepEngine, String>((
  ref,
  examId,
) {
  final exam =
      examById[examId] ??
      Exam(
        id: examId,
        name: examId,
        fullName: examId,
        region: ExamRegion.global,
        tier: ExamTier.tier1,
        sections: const [],
        scoringMethod: ScoringMethod.scaledScore,
        minScore: 0,
        maxScore: 100,
        purpose: '',
      );
  return TestPrepEngine(exam: exam, userId: 'local_user');
});

// ── Topic drill state ─────────────────────────────────────────────────────

enum DrillStatus { idle, loading, active, paywalled, complete }

class TopicDrillState {
  const TopicDrillState({
    required this.examId,
    required this.sectionId,
    required this.topic,
    required this.status,
    required this.questions,
    required this.currentIndex,
    required this.attempts,
    required this.selectedAnswerIds,
    required this.hasSubmitted,
    required this.userTheta,
    required this.questionsAttemptedTotal,
    this.startedAt,
    this.error,
  });

  final String examId;
  final String sectionId;
  final String topic;
  final DrillStatus status;
  final List<Question> questions;
  final int currentIndex;
  final List<QuestionAttempt> attempts;
  final List<String> selectedAnswerIds;
  final bool hasSubmitted;
  final double userTheta;
  final int questionsAttemptedTotal;
  final DateTime? startedAt;
  final String? error;

  Question? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  int get correctCount => attempts.where((a) => a.isCorrect).length;
  double get accuracy => attempts.isEmpty ? 0 : correctCount / attempts.length;
  bool get isLast => currentIndex + 1 >= questions.length;

  TopicDrillState copyWith({
    String? examId,
    String? sectionId,
    String? topic,
    DrillStatus? status,
    List<Question>? questions,
    int? currentIndex,
    List<QuestionAttempt>? attempts,
    List<String>? selectedAnswerIds,
    bool? hasSubmitted,
    double? userTheta,
    int? questionsAttemptedTotal,
    DateTime? startedAt,
    String? error,
  }) => TopicDrillState(
    examId: examId ?? this.examId,
    sectionId: sectionId ?? this.sectionId,
    topic: topic ?? this.topic,
    status: status ?? this.status,
    questions: questions ?? this.questions,
    currentIndex: currentIndex ?? this.currentIndex,
    attempts: attempts ?? this.attempts,
    selectedAnswerIds: selectedAnswerIds ?? this.selectedAnswerIds,
    hasSubmitted: hasSubmitted ?? this.hasSubmitted,
    userTheta: userTheta ?? this.userTheta,
    questionsAttemptedTotal:
        questionsAttemptedTotal ?? this.questionsAttemptedTotal,
    startedAt: startedAt ?? this.startedAt,
    error: error ?? this.error,
  );

  static TopicDrillState initial(String examId) => TopicDrillState(
    examId: examId,
    sectionId: '',
    topic: '',
    status: DrillStatus.idle,
    questions: const [],
    currentIndex: 0,
    attempts: const [],
    selectedAnswerIds: const [],
    hasSubmitted: false,
    userTheta: 0.0,
    questionsAttemptedTotal: 0,
  );
}

class TopicDrillNotifier extends FamilyNotifier<TopicDrillState, String> {
  @override
  TopicDrillState build(String examId) => TopicDrillState.initial(examId);

  TestPrepEngine get _engine => ref.read(testPrepEngineProvider(arg));

  void startDrill({
    required String sectionId,
    required String topic,
    required bool isPaidUser,
    int count = 10,
  }) {
    final proficiency = ref.read(userProficiencyProvider)[arg];
    final attempted = proficiency?.questionsAttempted ?? 0;

    final questions = _engine.getPreGeneratedQuestions(
      sectionId: sectionId,
      topic: topic,
      count: count,
      alreadyAttempted: attempted,
      isPaidUser: isPaidUser,
    );

    if (questions.isEmpty && !isPaidUser) {
      state = state.copyWith(
        sectionId: sectionId,
        topic: topic,
        status: DrillStatus.paywalled,
      );
      return;
    }

    state = TopicDrillState(
      examId: arg,
      sectionId: sectionId,
      topic: topic,
      status: DrillStatus.active,
      questions: questions,
      currentIndex: 0,
      attempts: const [],
      selectedAnswerIds: const [],
      hasSubmitted: false,
      userTheta: proficiency?.overallScore != null
          ? (proficiency!.overallScore * 6 - 3)
          : 0.0,
      questionsAttemptedTotal: attempted,
      startedAt: DateTime.now(),
    );
  }

  void toggleAnswer(String optionId) {
    final q = state.currentQuestion;
    if (q == null || state.hasSubmitted) return;

    List<String> updated;
    if (q.type == QuestionType.multiSelect) {
      updated = state.selectedAnswerIds.contains(optionId)
          ? state.selectedAnswerIds.where((id) => id != optionId).toList()
          : [...state.selectedAnswerIds, optionId];
    } else {
      updated = [optionId];
    }
    state = state.copyWith(selectedAnswerIds: updated);
  }

  void submitAnswer() {
    final q = state.currentQuestion;
    if (q == null || state.hasSubmitted) return;

    final selected = state.selectedAnswerIds;
    final correct = q.correctAnswerIds.toSet();
    final isCorrect =
        selected.isNotEmpty &&
        selected.toSet().containsAll(correct) &&
        correct.containsAll(selected.toSet());

    final attempt = QuestionAttempt(
      id: '${q.id}_${DateTime.now().millisecondsSinceEpoch}',
      questionId: q.id,
      examId: arg,
      userId: 'local_user',
      selectedAnswerIds: selected,
      isCorrect: isCorrect,
      timeSpentSeconds: state.startedAt != null
          ? DateTime.now().difference(state.startedAt!).inSeconds
          : 0,
      attemptedAt: DateTime.now(),
      sessionId: 'drill_${state.startedAt?.millisecondsSinceEpoch}',
    );

    // Update IRT theta
    final newTheta = _engine.updateProficiency(
      currentTheta: state.userTheta,
      questionDifficulty: q.difficulty,
      isCorrect: isCorrect,
    );

    // Update proficiency in global state
    ref
        .read(userProficiencyProvider.notifier)
        .updateFromAttempt(attempt, q.topic);

    state = state.copyWith(
      attempts: [...state.attempts, attempt],
      hasSubmitted: true,
      userTheta: newTheta,
      questionsAttemptedTotal: state.questionsAttemptedTotal + 1,
    );
  }

  void nextQuestion({required bool isPaidUser}) {
    final nextIndex = state.currentIndex + 1;

    // Check paywall before advancing
    if (_engine.shouldTriggerPaywall(
      questionsAttempted: state.questionsAttemptedTotal,
      isPaidUser: isPaidUser,
    )) {
      state = state.copyWith(status: DrillStatus.paywalled);
      return;
    }

    if (nextIndex >= state.questions.length) {
      state = state.copyWith(status: DrillStatus.complete);
    } else {
      state = state.copyWith(
        currentIndex: nextIndex,
        selectedAnswerIds: const [],
        hasSubmitted: false,
      );
    }
  }

  void reset() {
    state = TopicDrillState.initial(arg);
  }

  int get readiness => _engine.thetaToReadiness(state.userTheta);
}

final topicDrillProvider =
    NotifierProviderFamily<TopicDrillNotifier, TopicDrillState, String>(
      TopicDrillNotifier.new,
    );

// ── Paywall state ─────────────────────────────────────────────────────────

class PaywallTrigger {
  const PaywallTrigger({
    required this.examId,
    required this.examName,
    required this.questionsUsed,
    required this.freeLimit,
    required this.weeklyPrice,
    required this.monthlyPrice,
    required this.yearlyPrice,
  });

  final String examId;
  final String examName;
  final int questionsUsed;
  final int freeLimit;
  final double weeklyPrice;
  final double monthlyPrice;
  final double yearlyPrice;
}

final paywallTriggerProvider = Provider.family<PaywallTrigger?, String>((
  ref,
  examId,
) {
  final exam = examById[examId];
  if (exam == null) return null;
  final proficiency = ref.watch(userProficiencyProvider)[examId];
  return PaywallTrigger(
    examId: examId,
    examName: exam.name,
    questionsUsed: proficiency?.questionsAttempted ?? 0,
    freeLimit: exam.freeQuestionCount,
    weeklyPrice: exam.weeklyPriceUsd,
    monthlyPrice: exam.monthlyPriceUsd,
    yearlyPrice: exam.yearlyPriceUsd,
  );
});

// ── Paid user — wired to real entitlement state (Phase 3) ────────────────

final isPaidUserProvider = Provider<bool>((ref) {
  return ref.watch(isPaidProvider);
});

final isExamUnlockedProvider = Provider.family<bool, String>((ref, examId) {
  return ref.watch(isExamUnlockedByEntitlementProvider(examId));
});
