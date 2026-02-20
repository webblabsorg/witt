import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/progress_models.dart';
import '../../learn/providers/exam_providers.dart';
import '../../quiz/providers/quiz_providers.dart';

// ── Streak tracking ───────────────────────────────────────────────────────

class StreakNotifier extends Notifier<StudyStreak> {
  @override
  StudyStreak build() => StudyStreak.empty;

  void recordActivity() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (state.isActiveToday) return; // already recorded today

    final yesterday = today.subtract(const Duration(days: 1));
    final wasActiveYesterday = state.studiedDates.any((d) {
      final day = DateTime(d.year, d.month, d.day);
      return day == yesterday;
    });

    final newCurrent = wasActiveYesterday ? state.currentDays + 1 : 1;
    final newLongest = newCurrent > state.longestDays
        ? newCurrent
        : state.longestDays;

    state = state.copyWith(
      currentDays: newCurrent,
      longestDays: newLongest,
      lastStudiedAt: now,
      studiedDates: [...state.studiedDates, today],
    );
  }
}

final streakProvider = NotifierProvider<StreakNotifier, StudyStreak>(
  StreakNotifier.new,
);

// ── Daily activity tracking ───────────────────────────────────────────────

class DailyActivityNotifier extends Notifier<Map<String, DailyActivity>> {
  @override
  Map<String, DailyActivity> build() => {};

  String _key(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  DailyActivity _today() {
    final key = _key(DateTime.now());
    return state[key] ?? DailyActivity.empty(DateTime.now());
  }

  void recordQuestion({required bool isCorrect}) {
    final key = _key(DateTime.now());
    final current = _today();
    state = {
      ...state,
      key: current.copyWith(
        questionsAnswered: current.questionsAnswered + 1,
        correctAnswers: current.correctAnswers + (isCorrect ? 1 : 0),
      ),
    };
    ref.read(streakProvider.notifier).recordActivity();
  }

  void recordMinutes(int minutes) {
    final key = _key(DateTime.now());
    final current = _today();
    state = {
      ...state,
      key: current.copyWith(minutesStudied: current.minutesStudied + minutes),
    };
  }

  void recordFlashcard() {
    final key = _key(DateTime.now());
    final current = _today();
    state = {
      ...state,
      key: current.copyWith(flashcardsReviewed: current.flashcardsReviewed + 1),
    };
    ref.read(streakProvider.notifier).recordActivity();
  }

  void recordNote() {
    final key = _key(DateTime.now());
    final current = _today();
    state = {
      ...state,
      key: current.copyWith(notesCreated: current.notesCreated + 1),
    };
  }

  void recordAiMessage() {
    final key = _key(DateTime.now());
    final current = _today();
    state = {
      ...state,
      key: current.copyWith(aiMessagesUsed: current.aiMessagesUsed + 1),
    };
  }

  List<DailyActivity> get last7Days {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final key = _key(day);
      return state[key] ?? DailyActivity.empty(day);
    });
  }
}

final dailyActivityProvider =
    NotifierProvider<DailyActivityNotifier, Map<String, DailyActivity>>(
      DailyActivityNotifier.new,
    );

final last7DaysActivityProvider = Provider<List<DailyActivity>>((ref) {
  ref.watch(dailyActivityProvider);
  return ref.read(dailyActivityProvider.notifier).last7Days;
});

// ── XP & Gamification ────────────────────────────────────────────────────

class XpNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void addXp(int points) {
    state = state + points;
  }

  int get level => (state ~/ 500) + 1;
}

final xpProvider = NotifierProvider<XpNotifier, int>(XpNotifier.new);

final levelProvider = Provider<int>((ref) {
  final xp = ref.watch(xpProvider);
  return (xp ~/ 500) + 1;
});

// ── Badges ────────────────────────────────────────────────────────────────

class BadgeNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void checkAndAward(Ref ref) {
    final streak = ref.read(streakProvider);
    final xp = ref.read(xpProvider);
    final activity = ref.read(dailyActivityProvider);

    final totalQ = activity.values.fold<int>(
      0,
      (sum, a) => sum + a.questionsAnswered,
    );
    final totalCorrect = activity.values.fold<int>(
      0,
      (sum, a) => sum + a.correctAnswers,
    );

    final newBadges = <String>[...state];

    void award(String badge) {
      if (!newBadges.contains(badge)) newBadges.add(badge);
    }

    if (streak.currentDays >= 3) award('3-Day Streak');
    if (streak.currentDays >= 7) award('7-Day Streak');
    if (streak.currentDays >= 30) award('30-Day Streak');
    if (totalQ >= 100) award('First 100 Questions');
    if (totalQ >= 500) award('500 Questions');
    if (totalQ >= 1000) award('1000 Questions');
    if (totalCorrect >= 50) award('50 Correct');
    if (xp >= 1000) award('1000 XP');
    if (xp >= 5000) award('5000 XP');

    state = newBadges;
  }
}

final badgeProvider = NotifierProvider<BadgeNotifier, List<String>>(
  BadgeNotifier.new,
);

// ── Full progress summary ─────────────────────────────────────────────────

final progressSummaryProvider = Provider<ProgressSummary>((ref) {
  final streak = ref.watch(streakProvider);
  final activity = ref.watch(dailyActivityProvider);
  final xp = ref.watch(xpProvider);
  final level = ref.watch(levelProvider);
  final badges = ref.watch(badgeProvider);
  final proficiency = ref.watch(userProficiencyProvider);
  final quizHistory = ref.watch(quizHistoryProvider);
  final myExams = ref.watch(myExamsProvider);

  final totalQ = activity.values.fold<int>(
    0,
    (sum, a) => sum + a.questionsAnswered,
  );
  final totalCorrect = activity.values.fold<int>(
    0,
    (sum, a) => sum + a.correctAnswers,
  );
  final totalMinutes = activity.values.fold<int>(
    0,
    (sum, a) => sum + a.minutesStudied,
  );
  final totalFlashcards = activity.values.fold<int>(
    0,
    (sum, a) => sum + a.flashcardsReviewed,
  );

  final now = DateTime.now();
  final last7 = List.generate(7, (i) {
    final day = now.subtract(Duration(days: 6 - i));
    final key =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return activity[key] ?? DailyActivity.empty(day);
  });

  final examReadiness = myExams.map((exam) {
    final prof = proficiency[exam.id];
    final attempted = prof?.questionsAttempted ?? 0;
    final accuracy = prof?.overallScore ?? 0.0;
    final readiness = (accuracy * 100).round().clamp(0, 100);
    return ExamReadiness(
      examId: exam.id,
      examName: exam.name,
      readinessPercent: readiness,
      questionsAttempted: attempted,
      accuracy: accuracy,
      weakTopics:
          prof?.topicScores.entries
              .where((e) => e.value < 0.5)
              .map((e) => e.key)
              .take(3)
              .toList() ??
          [],
      strongTopics:
          prof?.topicScores.entries
              .where((e) => e.value >= 0.75)
              .map((e) => e.key)
              .take(3)
              .toList() ??
          [],
    );
  }).toList();

  // If no real data yet, show sample data for onboarding
  if (totalQ == 0 && quizHistory.isEmpty) {
    return ProgressSummary.sample();
  }

  return ProgressSummary(
    streak: streak,
    totalQuestionsAnswered: totalQ,
    totalCorrect: totalCorrect,
    totalMinutesStudied: totalMinutes,
    totalFlashcardsReviewed: totalFlashcards,
    weeklyActivity: last7,
    examReadiness: examReadiness,
    xpPoints: xp,
    level: level,
    badges: badges,
  );
});
