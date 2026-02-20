import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/planner.dart';

// ── Events ────────────────────────────────────────────────────────────────

class PlannerEventsNotifier extends Notifier<List<PlannerEvent>> {
  @override
  List<PlannerEvent> build() => [];

  void addEvent(PlannerEvent event) {
    state = [...state, event];
  }

  void updateEvent(PlannerEvent event) {
    state = state.map((e) => e.id == event.id ? event : e).toList();
  }

  void deleteEvent(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  void toggleComplete(String id) {
    state = state
        .map((e) => e.id == id ? e.copyWith(isCompleted: !e.isCompleted) : e)
        .toList();
  }

  List<PlannerEvent> eventsForDay(DateTime day) {
    return state.where((e) {
      final d = e.date;
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList()..sort((a, b) {
      final aMin = a.startTime.hour * 60 + a.startTime.minute;
      final bMin = b.startTime.hour * 60 + b.startTime.minute;
      return aMin.compareTo(bMin);
    });
  }

  List<PlannerEvent> eventsForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return state
        .where(
          (e) =>
              e.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
              e.date.isBefore(weekEnd),
        )
        .toList();
  }

  int totalStudyMinutesForDay(DateTime day) {
    return eventsForDay(day)
        .where(
          (e) =>
              e.type == PlannerEventType.studySession ||
              e.type == PlannerEventType.revision,
        )
        .fold(0, (sum, e) => sum + e.durationMinutes);
  }
}

final plannerEventsProvider =
    NotifierProvider<PlannerEventsNotifier, List<PlannerEvent>>(
      PlannerEventsNotifier.new,
    );

// ── Events for selected day ───────────────────────────────────────────────

final selectedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final eventsForSelectedDayProvider = Provider<List<PlannerEvent>>((ref) {
  final day = ref.watch(selectedDayProvider);
  final notifier = ref.watch(plannerEventsProvider.notifier);
  return notifier.eventsForDay(day);
});

// ── Study goals ───────────────────────────────────────────────────────────

class StudyGoalsNotifier extends Notifier<List<StudyGoal>> {
  @override
  List<StudyGoal> build() => [];

  void addGoal(StudyGoal goal) {
    state = [...state, goal];
  }

  void updateGoal(StudyGoal goal) {
    state = state.map((g) => g.id == goal.id ? goal : g).toList();
  }

  void deleteGoal(String id) {
    state = state.where((g) => g.id != id).toList();
  }

  void logMinutes(String goalId, int minutes) {
    state = state
        .map(
          (g) => g.id == goalId
              ? g.copyWith(currentMinutes: g.currentMinutes + minutes)
              : g,
        )
        .toList();
  }
}

final studyGoalsProvider =
    NotifierProvider<StudyGoalsNotifier, List<StudyGoal>>(
      StudyGoalsNotifier.new,
    );

// ── Exam countdowns ───────────────────────────────────────────────────────

class ExamCountdownsNotifier extends Notifier<List<ExamCountdown>> {
  @override
  List<ExamCountdown> build() => [];

  void addCountdown(ExamCountdown countdown) {
    state = [...state, countdown];
  }

  void removeCountdown(String examId) {
    state = state.where((c) => c.examId != examId).toList();
  }
}

final examCountdownsProvider =
    NotifierProvider<ExamCountdownsNotifier, List<ExamCountdown>>(
      ExamCountdownsNotifier.new,
    );

// ── Weekly study stats ────────────────────────────────────────────────────

final weeklyStudyMinutesProvider = Provider<int>((ref) {
  final events = ref.watch(plannerEventsProvider);
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
  return events
      .where(
        (e) =>
            (e.type == PlannerEventType.studySession ||
                e.type == PlannerEventType.revision) &&
            e.isCompleted &&
            e.date.isAfter(weekStartDay.subtract(const Duration(days: 1))),
      )
      .fold(0, (sum, e) => sum + e.durationMinutes);
});
