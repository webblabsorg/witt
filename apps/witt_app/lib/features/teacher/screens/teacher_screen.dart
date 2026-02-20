import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';

import '../models/teacher_models.dart';
import '../providers/teacher_providers.dart';

class TeacherScreen extends ConsumerStatefulWidget {
  const TeacherScreen({super.key});

  @override
  ConsumerState<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends ConsumerState<TeacherScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final classes = ref.watch(classesProvider);
    final selectedId = ref.watch(selectedClassProvider);
    final selectedClass = classes.firstWhere(
      (c) => c.id == selectedId,
      orElse: () => classes.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New Class',
            onPressed: () => _showCreateClass(context),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Roster'),
            Tab(text: 'Assignments'),
            Tab(text: 'Grades'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Class selector
          if (classes.length > 1)
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: WittSpacing.lg),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: classes.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: WittSpacing.sm),
                itemBuilder: (_, i) {
                  final c = classes[i];
                  final isSelected = c.id == selectedId;
                  return GestureDetector(
                    onTap: () =>
                        ref.read(selectedClassProvider.notifier).state = c.id,
                    child: Chip(
                      label: Text(c.name),
                      backgroundColor: isSelected ? WittColors.primary : null,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: isSelected ? FontWeight.w600 : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          // Class summary card
          Padding(
            padding: const EdgeInsets.fromLTRB(
              WittSpacing.lg,
              WittSpacing.sm,
              WittSpacing.lg,
              0,
            ),
            child: WittCard(
              padding: const EdgeInsets.all(WittSpacing.md),
              child: Row(
                children: [
                  Text(
                    selectedClass.coverEmoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: WittSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedClass.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${selectedClass.studentCount} students · ${selectedClass.examTag}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Invite Code',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        selectedClass.inviteCode,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: WittColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: WittSpacing.sm),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _RosterTab(classId: selectedClass.id, isDark: isDark),
                _AssignmentsTab(classId: selectedClass.id, isDark: isDark),
                _GradesTab(classId: selectedClass.id, isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Create class action — not yet implemented.
  void _showCreateClass(BuildContext context) {}
}

// ── Roster Tab ────────────────────────────────────────────────────────────

class _RosterTab extends ConsumerWidget {
  const _RosterTab({required this.classId, required this.isDark});
  final String classId;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(studentsProvider(classId));
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        WittSpacing.lg,
        WittSpacing.sm,
        WittSpacing.lg,
        100,
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${students.length} students',
              style: theme.textTheme.bodySmall,
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_add_outlined, size: 16),
              label: const Text('Invite'),
            ),
          ],
        ),
        ...students.map((s) => _StudentRow(student: s, isDark: isDark)),
      ],
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.student, required this.isDark});
  final Student student;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = DateTime.now().difference(student.lastActive);
    final lastSeen = diff.inMinutes < 60
        ? '${diff.inMinutes}m ago'
        : diff.inHours < 24
        ? '${diff.inHours}h ago'
        : '${diff.inDays}d ago';

    return Padding(
      padding: const EdgeInsets.only(bottom: WittSpacing.sm),
      child: WittCard(
        padding: const EdgeInsets.all(WittSpacing.md),
        child: Row(
          children: [
            WittAvatar(
              initials: student.avatarInitials,
              size: WittAvatarSize.md,
            ),
            const SizedBox(width: WittSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name, style: theme.textTheme.titleSmall),
                  Text(
                    'Last active: $lastSeen · ${student.xp} XP · 🔥${student.streak}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? WittColors.textSecondaryDark
                          : WittColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (student.pendingAssignments > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: WittSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: WittColors.error.withAlpha(26),
                  borderRadius: WittSpacing.borderRadiusFull,
                ),
                child: Text(
                  '${student.pendingAssignments} pending',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: WittColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Assignments Tab ───────────────────────────────────────────────────────

class _AssignmentsTab extends ConsumerWidget {
  const _AssignmentsTab({required this.classId, required this.isDark});
  final String classId;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignments = ref.watch(assignmentsProvider(classId));
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        WittSpacing.lg,
        WittSpacing.sm,
        WittSpacing.lg,
        100,
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${assignments.length} assignments',
              style: theme.textTheme.bodySmall,
            ),
            WittButton(
              label: 'Assign',
              onPressed: () {},
              variant: WittButtonVariant.primary,
              size: WittButtonSize.sm,
            ),
          ],
        ),
        const SizedBox(height: WittSpacing.sm),
        ...assignments.map((a) => _AssignmentCard(a: a, isDark: isDark)),
      ],
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.a, required this.isDark});
  final Assignment a;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysLeft = a.dueDate.difference(DateTime.now()).inDays;
    final isOverdue = daysLeft < 0;
    final typeIcon = switch (a.type) {
      AssignmentType.quiz => Icons.quiz_rounded,
      AssignmentType.flashcards => Icons.style_rounded,
      AssignmentType.mockTest => Icons.assignment_rounded,
      AssignmentType.homework => Icons.home_work_rounded,
      AssignmentType.reading => Icons.menu_book_rounded,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: WittSpacing.sm),
      child: WittCard(
        padding: const EdgeInsets.all(WittSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(typeIcon, size: 18, color: WittColors.primary),
                const SizedBox(width: WittSpacing.sm),
                Expanded(
                  child: Text(a.title, style: theme.textTheme.titleSmall),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: WittSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? WittColors.error.withAlpha(26)
                        : WittColors.success.withAlpha(26),
                    borderRadius: WittSpacing.borderRadiusFull,
                  ),
                  child: Text(
                    isOverdue ? 'Overdue' : 'Due in ${daysLeft}d',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isOverdue ? WittColors.error : WittColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: WittSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: WittProgressBar(
                    value: a.submissionRate,
                    color: WittColors.primary,
                  ),
                ),
                const SizedBox(width: WittSpacing.md),
                Text(
                  '${a.submittedCount}/${a.totalCount}',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
            if (a.avgGrade != null) ...[
              const SizedBox(height: WittSpacing.xs),
              Text(
                'Avg grade: ${a.avgGrade!.toStringAsFixed(1)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? WittColors.textSecondaryDark
                      : WittColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Grades Tab ────────────────────────────────────────────────────────────

class _GradesTab extends ConsumerWidget {
  const _GradesTab({required this.classId, required this.isDark});
  final String classId;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(studentsProvider(classId));
    final theme = Theme.of(context);

    final sorted = [...students]
      ..sort((a, b) => b.avgScore.compareTo(a.avgScore));

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        WittSpacing.lg,
        WittSpacing.sm,
        WittSpacing.lg,
        100,
      ),
      children: [
        // Class leaderboard header
        WittCard(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF4338CA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          padding: const EdgeInsets.all(WittSpacing.md),
          child: Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 28)),
              const SizedBox(width: WittSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Class Leaderboard',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Ranked by average score',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: WittSpacing.md),
        ...sorted.asMap().entries.map((e) {
          final rank = e.key + 1;
          final s = e.value;
          final medal = rank == 1
              ? '🥇'
              : rank == 2
              ? '🥈'
              : rank == 3
              ? '🥉'
              : '$rank';
          return Padding(
            padding: const EdgeInsets.only(bottom: WittSpacing.sm),
            child: WittCard(
              padding: const EdgeInsets.all(WittSpacing.md),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      medal,
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: WittSpacing.sm),
                  WittAvatar(
                    initials: s.avatarInitials,
                    size: WittAvatarSize.sm,
                  ),
                  const SizedBox(width: WittSpacing.sm),
                  Expanded(
                    child: Text(s.name, style: theme.textTheme.titleSmall),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${s.avgScore.toStringAsFixed(1)}%',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: WittColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text('${s.xp} XP', style: theme.textTheme.labelSmall),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
