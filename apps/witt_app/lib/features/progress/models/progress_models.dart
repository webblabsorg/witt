import 'package:flutter/foundation.dart';

@immutable
class StudyStreak {
  const StudyStreak({
    required this.currentDays,
    required this.longestDays,
    required this.lastStudiedAt,
    required this.studiedDates,
  });

  final int currentDays;
  final int longestDays;
  final DateTime? lastStudiedAt;
  final List<DateTime> studiedDates;

  bool get isActiveToday {
    if (lastStudiedAt == null) return false;
    final now = DateTime.now();
    final last = lastStudiedAt!;
    return now.year == last.year &&
        now.month == last.month &&
        now.day == last.day;
  }

  static const empty = StudyStreak(
    currentDays: 0,
    longestDays: 0,
    lastStudiedAt: null,
    studiedDates: [],
  );

  StudyStreak copyWith({
    int? currentDays,
    int? longestDays,
    DateTime? lastStudiedAt,
    List<DateTime>? studiedDates,
  }) =>
      StudyStreak(
        currentDays: currentDays ?? this.currentDays,
        longestDays: longestDays ?? this.longestDays,
        lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
        studiedDates: studiedDates ?? this.studiedDates,
      );
}

@immutable
class DailyActivity {
  const DailyActivity({
    required this.date,
    required this.questionsAnswered,
    required this.correctAnswers,
    required this.minutesStudied,
    required this.flashcardsReviewed,
    required this.notesCreated,
    required this.aiMessagesUsed,
  });

  final DateTime date;
  final int questionsAnswered;
  final int correctAnswers;
  final int minutesStudied;
  final int flashcardsReviewed;
  final int notesCreated;
  final int aiMessagesUsed;

  double get accuracy =>
      questionsAnswered == 0 ? 0 : correctAnswers / questionsAnswered;

  static DailyActivity empty(DateTime date) => DailyActivity(
        date: date,
        questionsAnswered: 0,
        correctAnswers: 0,
        minutesStudied: 0,
        flashcardsReviewed: 0,
        notesCreated: 0,
        aiMessagesUsed: 0,
      );

  DailyActivity copyWith({
    DateTime? date,
    int? questionsAnswered,
    int? correctAnswers,
    int? minutesStudied,
    int? flashcardsReviewed,
    int? notesCreated,
    int? aiMessagesUsed,
  }) =>
      DailyActivity(
        date: date ?? this.date,
        questionsAnswered: questionsAnswered ?? this.questionsAnswered,
        correctAnswers: correctAnswers ?? this.correctAnswers,
        minutesStudied: minutesStudied ?? this.minutesStudied,
        flashcardsReviewed: flashcardsReviewed ?? this.flashcardsReviewed,
        notesCreated: notesCreated ?? this.notesCreated,
        aiMessagesUsed: aiMessagesUsed ?? this.aiMessagesUsed,
      );
}

@immutable
class ExamReadiness {
  const ExamReadiness({
    required this.examId,
    required this.examName,
    required this.readinessPercent,
    required this.questionsAttempted,
    required this.accuracy,
    required this.weakTopics,
    required this.strongTopics,
  });

  final String examId;
  final String examName;
  final int readinessPercent;
  final int questionsAttempted;
  final double accuracy;
  final List<String> weakTopics;
  final List<String> strongTopics;
}

@immutable
class ProgressSummary {
  const ProgressSummary({
    required this.streak,
    required this.totalQuestionsAnswered,
    required this.totalCorrect,
    required this.totalMinutesStudied,
    required this.totalFlashcardsReviewed,
    required this.weeklyActivity,
    required this.examReadiness,
    required this.xpPoints,
    required this.level,
    required this.badges,
  });

  final StudyStreak streak;
  final int totalQuestionsAnswered;
  final int totalCorrect;
  final int totalMinutesStudied;
  final int totalFlashcardsReviewed;
  final List<DailyActivity> weeklyActivity;
  final List<ExamReadiness> examReadiness;
  final int xpPoints;
  final int level;
  final List<String> badges;

  double get overallAccuracy =>
      totalQuestionsAnswered == 0
          ? 0
          : totalCorrect / totalQuestionsAnswered;

  int get xpToNextLevel => (level * 500) - xpPoints;

  double get levelProgress {
    final levelStart = (level - 1) * 500;
    final levelEnd = level * 500;
    return (xpPoints - levelStart) / (levelEnd - levelStart);
  }

  static ProgressSummary sample() {
    final now = DateTime.now();
    return ProgressSummary(
      streak: StudyStreak(
        currentDays: 7,
        longestDays: 14,
        lastStudiedAt: now,
        studiedDates: List.generate(
          7,
          (i) => now.subtract(Duration(days: i)),
        ),
      ),
      totalQuestionsAnswered: 342,
      totalCorrect: 271,
      totalMinutesStudied: 1840,
      totalFlashcardsReviewed: 215,
      weeklyActivity: List.generate(7, (i) {
        final day = now.subtract(Duration(days: 6 - i));
        return DailyActivity(
          date: day,
          questionsAnswered: 20 + (i * 8) % 30,
          correctAnswers: 14 + (i * 5) % 22,
          minutesStudied: 25 + (i * 12) % 45,
          flashcardsReviewed: 10 + (i * 4) % 20,
          notesCreated: i % 3 == 0 ? 1 : 0,
          aiMessagesUsed: 3 + i % 4,
        );
      }),
      examReadiness: const [
        ExamReadiness(
          examId: 'sat',
          examName: 'SAT',
          readinessPercent: 72,
          questionsAttempted: 145,
          accuracy: 0.74,
          weakTopics: ['Geometry', 'Data Analysis'],
          strongTopics: ['Algebra', 'Reading Comprehension'],
        ),
        ExamReadiness(
          examId: 'waec',
          examName: 'WAEC',
          readinessPercent: 58,
          questionsAttempted: 97,
          accuracy: 0.61,
          weakTopics: ['Organic Chemistry', 'Genetics'],
          strongTopics: ['Cell Biology', 'Mechanics'],
        ),
      ],
      xpPoints: 2340,
      level: 5,
      badges: ['7-Day Streak', 'First 100 Questions', 'Night Owl', 'Speed Demon'],
    );
  }
}
