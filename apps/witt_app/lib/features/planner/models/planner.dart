import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;

enum PlannerEventType {
  studySession,
  mockTest,
  revision,
  examDay,
  milestone,
  break_,
}

enum PlannerRepeat { none, daily, weekly, weekdays }

enum StudyGoalPeriod { daily, weekly, monthly }

@immutable
class PlannerEvent {
  const PlannerEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.startTime,
    required this.durationMinutes,
    this.examId,
    this.subject,
    this.notes,
    this.repeat = PlannerRepeat.none,
    this.isCompleted = false,
    this.color,
  });

  final String id;
  final String title;
  final PlannerEventType type;
  final DateTime date;
  final TimeOfDay startTime;
  final int durationMinutes;
  final String? examId;
  final String? subject;
  final String? notes;
  final PlannerRepeat repeat;
  final bool isCompleted;
  final int? color; // stored as ARGB int

  DateTime get startDateTime => DateTime(
    date.year,
    date.month,
    date.day,
    startTime.hour,
    startTime.minute,
  );

  DateTime get endDateTime =>
      startDateTime.add(Duration(minutes: durationMinutes));

  PlannerEvent copyWith({
    String? id,
    String? title,
    PlannerEventType? type,
    DateTime? date,
    TimeOfDay? startTime,
    int? durationMinutes,
    String? examId,
    String? subject,
    String? notes,
    PlannerRepeat? repeat,
    bool? isCompleted,
    int? color,
  }) => PlannerEvent(
    id: id ?? this.id,
    title: title ?? this.title,
    type: type ?? this.type,
    date: date ?? this.date,
    startTime: startTime ?? this.startTime,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    examId: examId ?? this.examId,
    subject: subject ?? this.subject,
    notes: notes ?? this.notes,
    repeat: repeat ?? this.repeat,
    isCompleted: isCompleted ?? this.isCompleted,
    color: color ?? this.color,
  );
}

@immutable
class StudyGoal {
  const StudyGoal({
    required this.id,
    required this.title,
    required this.targetMinutes,
    required this.period,
    this.examId,
    this.subject,
    this.currentMinutes = 0,
  });

  final String id;
  final String title;
  final int targetMinutes;
  final StudyGoalPeriod period;
  final String? examId;
  final String? subject;
  final int currentMinutes;

  double get progress =>
      targetMinutes == 0 ? 0 : (currentMinutes / targetMinutes).clamp(0.0, 1.0);
  bool get isAchieved => currentMinutes >= targetMinutes;

  StudyGoal copyWith({
    String? id,
    String? title,
    int? targetMinutes,
    StudyGoalPeriod? period,
    String? examId,
    String? subject,
    int? currentMinutes,
  }) => StudyGoal(
    id: id ?? this.id,
    title: title ?? this.title,
    targetMinutes: targetMinutes ?? this.targetMinutes,
    period: period ?? this.period,
    examId: examId ?? this.examId,
    subject: subject ?? this.subject,
    currentMinutes: currentMinutes ?? this.currentMinutes,
  );
}

@immutable
class ExamCountdown {
  const ExamCountdown({
    required this.examId,
    required this.examName,
    required this.examEmoji,
    required this.examDate,
    this.targetScore,
  });

  final String examId;
  final String examName;
  final String examEmoji;
  final DateTime examDate;
  final double? targetScore;

  int get daysRemaining =>
      examDate.difference(DateTime.now()).inDays.clamp(0, 9999);
  bool get isPast => examDate.isBefore(DateTime.now());
}
