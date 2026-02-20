import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ai/witt_ai.dart';
import '../../features/progress/models/progress_models.dart';
import '../../features/progress/providers/progress_providers.dart'
    show StreakNotifier, DailyActivityNotifier, XpNotifier, BadgeNotifier;
import 'hive_boxes.dart';

// ── Hive-backed UsageNotifier ─────────────────────────────────────────────
//
// Persists AI usage counts across app restarts.
// Hydrates from Hive on build(), flushes on every recordUsage().

class HiveUsageNotifier extends UsageNotifier {
  @override
  UsageRecord build() => _load();

  UsageRecord _load() {
    final box = usageBox;
    final lastResetRaw = box.get(kKeyLastResetDate) as String?;
    final lastReset = lastResetRaw != null
        ? DateTime.tryParse(lastResetRaw) ?? DateTime.utc(2000)
        : DateTime.utc(2000);

    return UsageRecord(
      dailyMessages: box.get(kKeyDailyMessages, defaultValue: 0) as int,
      monthlyMessages: box.get(kKeyMonthlyMessages, defaultValue: 0) as int,
      dailyHomework: box.get(kKeyDailyHomework, defaultValue: 0) as int,
      dailyQuizGens: box.get(kKeyDailyQuizGens, defaultValue: 0) as int,
      dailyFlashcardGens:
          box.get(kKeyDailyFlashcardGens, defaultValue: 0) as int,
      dailySummarizations:
          box.get(kKeyDailySummarizations, defaultValue: 0) as int,
      dailyAttachments: box.get(kKeyDailyAttachments, defaultValue: 0) as int,
      lastResetDate: lastReset,
    );
  }

  void _save(UsageRecord r) {
    final box = usageBox;
    box.put(kKeyDailyMessages, r.dailyMessages);
    box.put(kKeyMonthlyMessages, r.monthlyMessages);
    box.put(kKeyDailyHomework, r.dailyHomework);
    box.put(kKeyDailyQuizGens, r.dailyQuizGens);
    box.put(kKeyDailyFlashcardGens, r.dailyFlashcardGens);
    box.put(kKeyDailySummarizations, r.dailySummarizations);
    box.put(kKeyDailyAttachments, r.dailyAttachments);
    box.put(kKeyLastResetDate, r.lastResetDate.toIso8601String());
  }

  @override
  bool canUse(AiFeature feature, bool isPaidUser) {
    if (isPaidUser) return true;
    _maybeResetDaily();
    return state.canUseFeature(feature);
  }

  @override
  String limitMessage(AiFeature feature) => state.limitMessage(feature);

  @override
  void recordUsage(AiFeature feature) {
    _maybeResetDaily();
    final next = state.increment(feature);
    state = next;
    _save(next);
  }

  void _maybeResetDaily() {
    final now = DateTime.now().toUtc();
    final last = state.lastResetDate;
    final sameDay =
        now.year == last.year && now.month == last.month && now.day == last.day;
    if (!sameDay) {
      final next = UsageRecord(
        dailyMessages: 0,
        monthlyMessages: _shouldResetMonthly(now, last)
            ? 0
            : state.monthlyMessages,
        dailyHomework: 0,
        dailyQuizGens: 0,
        dailyFlashcardGens: 0,
        dailySummarizations: 0,
        dailyAttachments: 0,
        lastResetDate: now,
      );
      state = next;
      _save(next);
    }
  }

  bool _shouldResetMonthly(DateTime now, DateTime last) =>
      now.year > last.year || now.month > last.month;
}

final hiveUsageProvider = NotifierProvider<HiveUsageNotifier, UsageRecord>(
  HiveUsageNotifier.new,
);

// ── Hive-backed XpNotifier ────────────────────────────────────────────────

class HiveXpNotifier extends XpNotifier {
  @override
  int build() => progressBox.get(kKeyXp, defaultValue: 0) as int;

  @override
  void addXp(int points) {
    state = state + points;
    progressBox.put(kKeyXp, state);
  }
}

final hiveXpProvider = NotifierProvider<HiveXpNotifier, int>(
  HiveXpNotifier.new,
);

// ── Hive-backed BadgeNotifier ─────────────────────────────────────────────

class HiveBadgeNotifier extends BadgeNotifier {
  @override
  List<String> build() {
    final raw = progressBox.get(kKeyBadges) as List?;
    return raw?.map((e) => e.toString()).toList() ?? [];
  }

  @override
  void checkAndAward(Ref ref) {
    final streak = ref.read(hiveStreakProvider);
    final xp = ref.read(hiveXpProvider);
    final activity = ref.read(hiveDailyActivityProvider);

    final totalQ = activity.values.fold<int>(
      0,
      (s, a) => s + a.questionsAnswered,
    );
    final totalCorrect = activity.values.fold<int>(
      0,
      (s, a) => s + a.correctAnswers,
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

    if (newBadges.length != state.length) {
      state = newBadges;
      progressBox.put(kKeyBadges, newBadges);
    }
  }
}

final hiveBadgeProvider = NotifierProvider<HiveBadgeNotifier, List<String>>(
  HiveBadgeNotifier.new,
);

// ── Hive-backed StreakNotifier ────────────────────────────────────────────

class HiveStreakNotifier extends StreakNotifier {
  @override
  StudyStreak build() {
    final box = progressBox;
    final lastRaw = box.get(kKeyStreakLastStudied) as String?;
    final datesRaw = box.get(kKeyStreakDates) as List?;
    return StudyStreak(
      currentDays: box.get(kKeyStreakCurrent, defaultValue: 0) as int,
      longestDays: box.get(kKeyStreakLongest, defaultValue: 0) as int,
      lastStudiedAt: lastRaw != null ? DateTime.tryParse(lastRaw) : null,
      studiedDates:
          datesRaw
              ?.map((e) => DateTime.tryParse(e.toString()))
              .whereType<DateTime>()
              .toList() ??
          [],
    );
  }

  void _save(StudyStreak s) {
    final box = progressBox;
    box.put(kKeyStreakCurrent, s.currentDays);
    box.put(kKeyStreakLongest, s.longestDays);
    if (s.lastStudiedAt != null) {
      box.put(kKeyStreakLastStudied, s.lastStudiedAt!.toIso8601String());
    }
    box.put(
      kKeyStreakDates,
      s.studiedDates.map((d) => d.toIso8601String()).toList(),
    );
  }

  @override
  void recordActivity() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (state.isActiveToday) return;

    final yesterday = today.subtract(const Duration(days: 1));
    final wasActiveYesterday = state.studiedDates.any((d) {
      final day = DateTime(d.year, d.month, d.day);
      return day == yesterday;
    });

    final newCurrent = wasActiveYesterday ? state.currentDays + 1 : 1;
    final newLongest = newCurrent > state.longestDays
        ? newCurrent
        : state.longestDays;

    final next = state.copyWith(
      currentDays: newCurrent,
      longestDays: newLongest,
      lastStudiedAt: now,
      studiedDates: [...state.studiedDates, today],
    );
    state = next;
    _save(next);
  }
}

final hiveStreakProvider = NotifierProvider<HiveStreakNotifier, StudyStreak>(
  HiveStreakNotifier.new,
);

// ── Hive-backed DailyActivityNotifier ────────────────────────────────────

class HiveDailyActivityNotifier extends DailyActivityNotifier {
  @override
  Map<String, DailyActivity> build() {
    final raw = progressBox.get(kKeyDailyActivity) as String?;
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) {
        final m = v as Map<String, dynamic>;
        return MapEntry(
          k,
          DailyActivity(
            date: DateTime.parse(k),
            questionsAnswered: m['qa'] as int? ?? 0,
            correctAnswers: m['ca'] as int? ?? 0,
            minutesStudied: m['ms'] as int? ?? 0,
            flashcardsReviewed: m['fr'] as int? ?? 0,
            notesCreated: m['nc'] as int? ?? 0,
            aiMessagesUsed: m['ai'] as int? ?? 0,
          ),
        );
      });
    } catch (_) {
      return {};
    }
  }

  void _save() {
    final encoded = jsonEncode(
      state.map(
        (k, v) => MapEntry(k, {
          'qa': v.questionsAnswered,
          'ca': v.correctAnswers,
          'ms': v.minutesStudied,
          'fr': v.flashcardsReviewed,
          'nc': v.notesCreated,
          'ai': v.aiMessagesUsed,
        }),
      ),
    );
    progressBox.put(kKeyDailyActivity, encoded);
  }

  String _key(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  DailyActivity _today() {
    final key = _key(DateTime.now());
    return state[key] ?? DailyActivity.empty(DateTime.now());
  }

  @override
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
    _save();
    ref.read(hiveStreakProvider.notifier).recordActivity();
  }

  @override
  void recordMinutes(int minutes) {
    final key = _key(DateTime.now());
    final current = _today();
    state = {
      ...state,
      key: current.copyWith(minutesStudied: current.minutesStudied + minutes),
    };
    _save();
  }

  @override
  void recordFlashcard() {
    final key = _key(DateTime.now());
    final current = _today();
    state = {
      ...state,
      key: current.copyWith(flashcardsReviewed: current.flashcardsReviewed + 1),
    };
    _save();
    ref.read(hiveStreakProvider.notifier).recordActivity();
  }

  @override
  void recordNote() {
    final key = _key(DateTime.now());
    final current = _today();
    state = {
      ...state,
      key: current.copyWith(notesCreated: current.notesCreated + 1),
    };
    _save();
  }

  @override
  void recordAiMessage() {
    final key = _key(DateTime.now());
    final current = _today();
    state = {
      ...state,
      key: current.copyWith(aiMessagesUsed: current.aiMessagesUsed + 1),
    };
    _save();
  }

  @override
  List<DailyActivity> get last7Days {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final key = _key(day);
      return state[key] ?? DailyActivity.empty(day);
    });
  }
}

final hiveDailyActivityProvider =
    NotifierProvider<HiveDailyActivityNotifier, Map<String, DailyActivity>>(
      HiveDailyActivityNotifier.new,
    );

final hiveLast7DaysProvider = Provider<List<DailyActivity>>((ref) {
  ref.watch(hiveDailyActivityProvider);
  return ref.read(hiveDailyActivityProvider.notifier).last7Days;
});
