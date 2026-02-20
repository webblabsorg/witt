import '../models/exam.dart';
import 'exam_catalog_us.dart';
// 🌍 Non-US catalogs — commented out for US-only launch. Re-enable per region when expanding.
// import 'exam_catalog_africa.dart';
// import 'exam_catalog_uk.dart';
// import 'exam_catalog_india.dart';
// import 'exam_catalog_global.dart';

/// Active exam catalog — US only for launch.
final List<Exam> allExams = [
  ...usExams,
  // ...africaExams,
  // ...ukExams,
  // ...indiaExams,
  // ...globalExams,
];

/// Lookup map for O(1) access by exam ID.
final Map<String, Exam> examById = {for (final exam in allExams) exam.id: exam};

/// Exams grouped by region.
Map<ExamRegion, List<Exam>> get examsByRegion {
  final Map<ExamRegion, List<Exam>> map = {};
  for (final exam in allExams) {
    map.putIfAbsent(exam.region, () => []).add(exam);
  }
  return map;
}

/// Featured exams shown on the Learn tab home — US only.
final List<String> featuredExamIds = [
  'sat',
  'act',
  'gre',
  'gmat',
  'lsat',
  'mcat',
  'ap',
  'ged',
];

List<Exam> get featuredExams =>
    featuredExamIds.map((id) => examById[id]).whereType<Exam>().toList();
