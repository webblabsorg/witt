import '../models/exam.dart';
import 'exam_catalog_us.dart';
import 'exam_catalog_africa.dart';
import 'exam_catalog_uk.dart';
import 'exam_catalog_india.dart';
import 'exam_catalog_global.dart';

/// Complete exam catalog — 30 exams across US, Africa, UK, India, and Global.
final List<Exam> allExams = [
  ...usExams,
  ...africaExams,
  ...ukExams,
  ...indiaExams,
  ...globalExams,
];

/// Lookup map for O(1) access by exam ID.
final Map<String, Exam> examById = {
  for (final exam in allExams) exam.id: exam,
};

/// Exams grouped by region.
Map<ExamRegion, List<Exam>> get examsByRegion {
  final Map<ExamRegion, List<Exam>> map = {};
  for (final exam in allExams) {
    map.putIfAbsent(exam.region, () => []).add(exam);
  }
  return map;
}

/// Featured exams shown on the Learn tab home.
final List<String> featuredExamIds = [
  'sat',
  'waec',
  'jamb',
  'ielts',
  'jee_main',
  'a_levels',
  'gre',
  'neet_ug',
];

List<Exam> get featuredExams =>
    featuredExamIds.map((id) => examById[id]!).toList();
