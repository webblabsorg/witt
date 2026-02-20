import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/teacher_models.dart';

// ── Sample data ───────────────────────────────────────────────────────────

final _sampleClasses = [
  const SchoolClass(
    id: 'c1',
    name: 'SAT Prep — Period 3',
    subject: 'Mathematics',
    examTag: 'SAT',
    studentCount: 28,
    inviteCode: 'SAT-P3-2026',
    coverEmoji: '📐',
  ),
  const SchoolClass(
    id: 'c2',
    name: 'English Language Arts',
    subject: 'English',
    examTag: 'SAT',
    studentCount: 31,
    inviteCode: 'ELA-2026',
    coverEmoji: '📝',
  ),
];

final _sampleStudents = [
  Student(
    userId: 's1',
    name: 'Amara Osei',
    avatarInitials: 'AO',
    classId: 'c1',
    xp: 4200,
    streak: 15,
    avgScore: 87.5,
    lastActive: DateTime.now().subtract(const Duration(hours: 1)),
    pendingAssignments: 0,
  ),
  Student(
    userId: 's2',
    name: 'Kwame Mensah',
    avatarInitials: 'KM',
    classId: 'c1',
    xp: 3100,
    streak: 8,
    avgScore: 74.2,
    lastActive: DateTime.now().subtract(const Duration(hours: 3)),
    pendingAssignments: 1,
  ),
  Student(
    userId: 's3',
    name: 'Sofia Reyes',
    avatarInitials: 'SR',
    classId: 'c1',
    xp: 5600,
    streak: 22,
    avgScore: 92.1,
    lastActive: DateTime.now().subtract(const Duration(minutes: 30)),
    pendingAssignments: 0,
  ),
  Student(
    userId: 's4',
    name: 'Liam O\'Brien',
    avatarInitials: 'LO',
    classId: 'c1',
    xp: 1800,
    streak: 3,
    avgScore: 61.0,
    lastActive: DateTime.now().subtract(const Duration(days: 2)),
    pendingAssignments: 2,
  ),
  Student(
    userId: 's5',
    name: 'Yuki Tanaka',
    avatarInitials: 'YT',
    classId: 'c2',
    xp: 6200,
    streak: 30,
    avgScore: 95.4,
    lastActive: DateTime.now().subtract(const Duration(hours: 2)),
    pendingAssignments: 0,
  ),
];

final _sampleAssignments = [
  Assignment(
    id: 'a1',
    classId: 'c1',
    title: 'SAT Math Practice — Algebra',
    type: AssignmentType.quiz,
    dueDate: DateTime.now().add(const Duration(days: 3)),
    submittedCount: 21,
    totalCount: 28,
    avgGrade: 78.4,
  ),
  Assignment(
    id: 'a2',
    classId: 'c1',
    title: 'Vocabulary Flashcards — Week 4',
    type: AssignmentType.flashcards,
    dueDate: DateTime.now().add(const Duration(days: 1)),
    submittedCount: 14,
    totalCount: 28,
  ),
  Assignment(
    id: 'a3',
    classId: 'c1',
    title: 'Full SAT Mock Test',
    type: AssignmentType.mockTest,
    dueDate: DateTime.now().subtract(const Duration(days: 1)),
    submittedCount: 26,
    totalCount: 28,
    status: AssignmentStatus.graded,
    avgGrade: 82.1,
  ),
];

final _sampleChildLinks = [
  ChildLink(
    childId: 'ch1',
    childName: 'Aisha Johnson',
    avatarInitials: 'AJ',
    xp: 2800,
    streak: 12,
    studyMinutesToday: 45,
    weeklyGoalMinutes: 300,
    activeExams: ['SAT', 'PSAT'],
    lastActive: DateTime.now().subtract(const Duration(hours: 2)),
  ),
];

// ── Providers ─────────────────────────────────────────────────────────────

final classesProvider = Provider<List<SchoolClass>>((_) => _sampleClasses);

final studentsProvider = Provider.family<List<Student>, String>(
  (_, classId) => _sampleStudents.where((s) => s.classId == classId).toList(),
);

final assignmentsProvider = Provider.family<List<Assignment>, String>(
  (_, classId) =>
      _sampleAssignments.where((a) => a.classId == classId).toList(),
);

final childLinksProvider = Provider<List<ChildLink>>((_) => _sampleChildLinks);

// ── Selected class ────────────────────────────────────────────────────────

final selectedClassProvider = StateProvider<String?>((ref) {
  final classes = ref.watch(classesProvider);
  return classes.isNotEmpty ? classes.first.id : null;
});
