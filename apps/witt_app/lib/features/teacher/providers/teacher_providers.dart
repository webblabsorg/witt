import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/teacher_models.dart';

// ── Providers ─────────────────────────────────────────────────────────────

final classesProvider = Provider<List<SchoolClass>>((_) => []);

final studentsProvider = Provider.family<List<Student>, String>(
  (_, classId) => [],
);

final assignmentsProvider = Provider.family<List<Assignment>, String>(
  (_, classId) => [],
);

final childLinksProvider = Provider<List<ChildLink>>((_) => []);

// ── Selected class ────────────────────────────────────────────────────────

final selectedClassProvider = StateProvider<String?>((ref) {
  final classes = ref.watch(classesProvider);
  return classes.isNotEmpty ? classes.first.id : null;
});
