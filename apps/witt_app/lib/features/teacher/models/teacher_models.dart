import 'package:flutter/foundation.dart';

// ── Enums ─────────────────────────────────────────────────────────────────

enum AssignmentStatus { pending, submitted, graded, overdue }

enum AssignmentType { quiz, flashcards, reading, homework, mockTest }

// ── Class ─────────────────────────────────────────────────────────────────

@immutable
class SchoolClass {
  const SchoolClass({
    required this.id,
    required this.name,
    required this.subject,
    required this.examTag,
    required this.studentCount,
    required this.inviteCode,
    this.coverEmoji = '🏫',
  });

  final String id;
  final String name;
  final String subject;
  final String examTag;
  final int studentCount;
  final String inviteCode;
  final String coverEmoji;
}

// ── Student ───────────────────────────────────────────────────────────────

@immutable
class Student {
  const Student({
    required this.userId,
    required this.name,
    required this.avatarInitials,
    required this.classId,
    required this.xp,
    required this.streak,
    required this.avgScore,
    required this.lastActive,
    this.pendingAssignments = 0,
  });

  final String userId;
  final String name;
  final String avatarInitials;
  final String classId;
  final int xp;
  final int streak;
  final double avgScore;
  final DateTime lastActive;
  final int pendingAssignments;
}

// ── Assignment ────────────────────────────────────────────────────────────

@immutable
class Assignment {
  const Assignment({
    required this.id,
    required this.classId,
    required this.title,
    required this.type,
    required this.dueDate,
    required this.submittedCount,
    required this.totalCount,
    this.status = AssignmentStatus.pending,
    this.avgGrade,
  });

  final String id;
  final String classId;
  final String title;
  final AssignmentType type;
  final DateTime dueDate;
  final int submittedCount;
  final int totalCount;
  final AssignmentStatus status;
  final double? avgGrade;

  double get submissionRate =>
      totalCount > 0 ? submittedCount / totalCount : 0;
}

// ── Parent child link ─────────────────────────────────────────────────────

@immutable
class ChildLink {
  const ChildLink({
    required this.childId,
    required this.childName,
    required this.avatarInitials,
    required this.xp,
    required this.streak,
    required this.studyMinutesToday,
    required this.weeklyGoalMinutes,
    required this.activeExams,
    required this.lastActive,
  });

  final String childId;
  final String childName;
  final String avatarInitials;
  final int xp;
  final int streak;
  final int studyMinutesToday;
  final int weeklyGoalMinutes;
  final List<String> activeExams;
  final DateTime lastActive;
}
