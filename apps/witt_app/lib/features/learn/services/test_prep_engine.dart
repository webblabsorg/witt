import '../models/exam.dart';
import '../models/question.dart';

/// IRT-based difficulty levels mapped to numeric theta values.
const Map<DifficultyLevel, double> _difficultyTheta = {
  DifficultyLevel.easy: -1.0,
  DifficultyLevel.medium: 0.0,
  DifficultyLevel.hard: 1.0,
  DifficultyLevel.expert: 2.0,
};

/// TestPrepEngine — core logic for topic drills and adaptive question selection.
///
/// Phase 2: AI generation is a stub. Real wiring happens in Phase 3.
class TestPrepEngine {
  TestPrepEngine({
    required this.exam,
    required this.userId,
    this.freeQuestionLimit = 15,
  });

  final Exam exam;
  final String userId;
  final int freeQuestionLimit;

  // ── Pre-generated question pool ───────────────────────────────────────────

  /// Returns questions from the pre-generated pool for a given section/topic.
  /// Free users get up to [freeQuestionLimit] questions total per exam.
  List<Question> getPreGeneratedQuestions({
    required String sectionId,
    required String topic,
    required int count,
    required int alreadyAttempted,
    required bool isPaidUser,
  }) {
    final remaining = isPaidUser
        ? count
        : (freeQuestionLimit - alreadyAttempted).clamp(0, count);

    if (remaining == 0) return [];

    final section = exam.sections.firstWhere(
      (s) => s.id == sectionId,
      orElse: () => exam.sections.first,
    );

    return List.generate(remaining, (i) {
      final difficulty = _pickDifficulty(i, remaining);
      return Question(
        id: '${exam.id}_${sectionId}_${topic.replaceAll(' ', '_')}_$i',
        examId: exam.id,
        sectionId: sectionId,
        type: _pickQuestionType(section, i),
        text: _sampleQuestionText(exam.name, topic, i + 1 + alreadyAttempted),
        options: _sampleOptions(i),
        correctAnswerIds: const ['a'],
        difficulty: difficulty,
        topic: topic,
        estimatedTimeSeconds:
            section.timeLimitMinutes * 60 ~/ section.questionCount,
        explanation: _sampleExplanation(topic),
        isPreGenerated: true,
        tags: [topic, exam.name, difficulty.name],
      );
    });
  }

  /// Placeholder for AI-generated adaptive questions (Phase 3).
  Future<List<Question>> generateAdaptiveQuestions({
    required String sectionId,
    required String topic,
    required double userTheta,
    required int count,
  }) async {
    // Phase 2 stub — returns pre-generated questions with difficulty matched to theta
    final targetDifficulty = _thetaToDifficulty(userTheta);
    final section = exam.sections.firstWhere(
      (s) => s.id == sectionId,
      orElse: () => exam.sections.first,
    );

    return List.generate(
      count,
      (i) => Question(
        id: '${exam.id}_${sectionId}_adaptive_${DateTime.now().millisecondsSinceEpoch}_$i',
        examId: exam.id,
        sectionId: sectionId,
        type: _pickQuestionType(section, i),
        text: '[AI-Generated] ${_sampleQuestionText(exam.name, topic, i + 1)}',
        options: _sampleOptions(i),
        correctAnswerIds: const ['a'],
        difficulty: targetDifficulty,
        topic: topic,
        estimatedTimeSeconds: 60,
        explanation: _sampleExplanation(topic),
        isPreGenerated: false,
        tags: [topic, exam.name, 'adaptive', targetDifficulty.name],
      ),
    );
  }

  // ── Proficiency update (IRT-lite) ─────────────────────────────────────────

  /// Updates user proficiency using a simplified IRT model.
  /// Returns updated theta value for the topic.
  double updateProficiency({
    required double currentTheta,
    required DifficultyLevel questionDifficulty,
    required bool isCorrect,
  }) {
    final b = _difficultyTheta[questionDifficulty] ?? 0.0;
    // 3PL IRT probability of correct response
    const c = 0.25; // guessing parameter
    const a = 1.0; // discrimination
    final p = c + (1 - c) / (1 + _exp(-a * (currentTheta - b)));

    // Update theta using Newton-Raphson step
    final delta = isCorrect ? (1 - p) * 0.3 : -p * 0.3;
    return (currentTheta + delta).clamp(-3.0, 3.0);
  }

  /// Converts theta to a 0–100 readiness score.
  int thetaToReadiness(double theta) {
    // Sigmoid mapping: theta -3→5%, 0→50%, 3→95%
    final p = 1 / (1 + _exp(-theta));
    return (p * 100).round().clamp(0, 100);
  }

  // ── Session XP calculation ────────────────────────────────────────────────

  int calculateXp({
    required int correctCount,
    required int totalCount,
    required int timeSpentSeconds,
    required DifficultyLevel averageDifficulty,
    required bool isStreak,
  }) {
    if (totalCount == 0) return 0;

    final accuracy = correctCount / totalCount;
    final baseXp = correctCount * 10;
    final accuracyBonus = accuracy >= 0.9
        ? 20
        : accuracy >= 0.7
        ? 10
        : 0;
    final difficultyMultiplier = switch (averageDifficulty) {
      DifficultyLevel.easy => 1.0,
      DifficultyLevel.medium => 1.2,
      DifficultyLevel.hard => 1.5,
      DifficultyLevel.expert => 2.0,
    };
    final streakBonus = isStreak ? 15 : 0;
    final speedBonus = timeSpentSeconds < totalCount * 30 ? 5 : 0;

    return ((baseXp + accuracyBonus + streakBonus + speedBonus) *
            difficultyMultiplier)
        .round();
  }

  // ── Paywall check ─────────────────────────────────────────────────────────

  /// Returns true if the user has exhausted their free question pool for this exam.
  bool shouldTriggerPaywall({
    required int questionsAttempted,
    required bool isPaidUser,
  }) {
    if (isPaidUser) return false;
    return questionsAttempted >= freeQuestionLimit;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  DifficultyLevel _pickDifficulty(int index, int total) {
    final ratio = total == 0 ? 0.5 : index / total;
    if (ratio < 0.3) return DifficultyLevel.easy;
    if (ratio < 0.6) return DifficultyLevel.medium;
    if (ratio < 0.85) return DifficultyLevel.hard;
    return DifficultyLevel.expert;
  }

  DifficultyLevel _thetaToDifficulty(double theta) {
    if (theta < -0.5) return DifficultyLevel.easy;
    if (theta < 0.5) return DifficultyLevel.medium;
    if (theta < 1.5) return DifficultyLevel.hard;
    return DifficultyLevel.expert;
  }

  QuestionType _pickQuestionType(ExamSection section, int index) {
    // Rotate through MCQ and T/F for pre-generated questions
    return index % 5 == 4 ? QuestionType.trueFalse : QuestionType.mcq;
  }

  List<QuestionOption> _sampleOptions(int seed) {
    return [
      QuestionOption(id: 'a', text: 'Option A — the correct answer'),
      QuestionOption(id: 'b', text: 'Option B — a plausible distractor'),
      QuestionOption(id: 'c', text: 'Option C — another distractor'),
      QuestionOption(id: 'd', text: 'Option D — the least likely choice'),
    ];
  }

  String _sampleQuestionText(String examName, String topic, int n) =>
      'Question $n: Which of the following best describes a key concept in $topic as tested on the $examName?';

  String _sampleExplanation(String topic) =>
      'The correct answer is A. This tests your understanding of $topic. '
      'In a real question, this explanation would provide a detailed step-by-step '
      'breakdown of the concept and why the other options are incorrect.';

  static double _exp(double x) =>
      x >= 0 ? _expPositive(x) : 1 / _expPositive(-x);

  static double _expPositive(double x) {
    // Fast approximation for IRT calculations
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 10; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }
}
