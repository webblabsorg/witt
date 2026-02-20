import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../data/exam_catalog.dart';
import '../models/exam.dart';
import '../providers/exam_providers.dart';
import 'exam_hub_screen.dart';
import 'exam_browser_screen.dart';
import '../../flashcards/screens/deck_list_screen.dart';
import '../../notes/screens/notes_screen.dart';
import '../../vocabulary/screens/vocabulary_screen.dart';
import '../../mock_test/screens/mock_test_config_screen.dart';
import '../../quiz/screens/quiz_generator_screen.dart';
import '../../homework/screens/homework_screen.dart';

class LearnHomeScreen extends ConsumerWidget {
  const LearnHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myExams = ref.watch(userExamListProvider);
    final featured = ref.watch(featuredExamsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Learn'),
            actions: [
              IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            ],
          ),

          // ── My Exams section ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                WittSpacing.lg,
                WittSpacing.md,
                WittSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  Text(
                    'My Exams',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _openExamBrowser(context),
                    child: const Text('Browse All'),
                  ),
                ],
              ),
            ),
          ),

          if (myExams.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: WittSpacing.lg,
                  vertical: WittSpacing.sm,
                ),
                child: _AddExamBanner(onTap: () => _openExamBrowser(context)),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: WittSpacing.lg,
                    vertical: WittSpacing.sm,
                  ),
                  itemCount: myExams.length + 1,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: WittSpacing.sm),
                  itemBuilder: (context, index) {
                    if (index == myExams.length) {
                      return _AddExamChip(
                        onTap: () => _openExamBrowser(context),
                      );
                    }
                    return _MyExamChip(
                      exam: myExams[index],
                      onTap: () => _openExamHub(context, myExams[index].id),
                    );
                  },
                ),
              ),
            ),
          ],

          // ── Continue learning ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                WittSpacing.lg,
                WittSpacing.lg,
                WittSpacing.lg,
                WittSpacing.sm,
              ),
              child: Text(
                'Continue Learning',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: WittSpacing.lg),
                itemCount: myExams.isEmpty
                    ? featured.take(4).length
                    : myExams.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: WittSpacing.sm),
                itemBuilder: (context, index) {
                  final exam = myExams.isEmpty
                      ? featured[index]
                      : myExams[index];
                  return _ContinueLearningCard(
                    exam: exam,
                    onTap: () => _openExamHub(context, exam.id),
                  );
                },
              ),
            ),
          ),

          // ── Study tools ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                WittSpacing.lg,
                WittSpacing.lg,
                WittSpacing.lg,
                WittSpacing.sm,
              ),
              child: Text(
                'Study Tools',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: WittSpacing.lg),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: WittSpacing.sm,
                crossAxisSpacing: WittSpacing.sm,
                childAspectRatio: 1.0,
                children: [
                  _ToolCard(
                    emoji: '🃏',
                    label: 'Flashcards',
                    color: WittColors.primary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DeckListScreen()),
                    ),
                  ),
                  _ToolCard(
                    emoji: '📝',
                    label: 'Notes',
                    color: WittColors.secondary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotesScreen()),
                    ),
                  ),
                  _ToolCard(
                    emoji: '📖',
                    label: 'Vocabulary',
                    color: WittColors.accent,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const VocabularyScreen(),
                      ),
                    ),
                  ),
                  _ToolCard(
                    emoji: '📋',
                    label: 'Mock Test',
                    color: WittColors.error,
                    onTap: () {
                      final examId = myExams.isNotEmpty
                          ? myExams.first.id
                          : (allExams.isNotEmpty ? allExams.first.id : 'sat');
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MockTestConfigScreen(examId: examId),
                        ),
                      );
                    },
                  ),
                  _ToolCard(
                    emoji: '⚡',
                    label: 'Quiz',
                    color: WittColors.success,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const QuizGeneratorScreen(),
                      ),
                    ),
                  ),
                  _ToolCard(
                    emoji: '🧮',
                    label: 'Homework',
                    color: WittColors.warning,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HomeworkScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Explore by region ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                WittSpacing.lg,
                WittSpacing.lg,
                WittSpacing.lg,
                WittSpacing.sm,
              ),
              child: Text(
                'Explore by Region',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: WittSpacing.lg),
                children: ExamRegion.values.map((region) {
                  final count = allExams
                      .where((e) => e.region == region)
                      .length;
                  if (count == 0) return const SizedBox.shrink();
                  return _RegionChip(
                    region: region,
                    count: count,
                    onTap: () => _openExamBrowser(context, region: region),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Featured exams ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                WittSpacing.lg,
                WittSpacing.lg,
                WittSpacing.lg,
                WittSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    'Featured Exams',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _openExamBrowser(context),
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final exam = featured[index];
              return _FeaturedExamTile(
                exam: exam,
                isAdded: ref.watch(userExamsProvider).contains(exam.id),
                onTap: () => _openExamHub(context, exam.id),
                onAdd: () =>
                    ref.read(userExamsProvider.notifier).addExam(exam.id),
              );
            }, childCount: featured.length),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: WittSpacing.xl)),
        ],
      ),
    );
  }

  void _openExamHub(BuildContext context, String examId) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ExamHubScreen(examId: examId)));
  }

  void _openExamBrowser(BuildContext context, {ExamRegion? region}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExamBrowserScreen(initialRegion: region),
      ),
    );
  }
}

// ── Tool card ─────────────────────────────────────────────────────────────

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(WittSpacing.sm),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add exam banner ───────────────────────────────────────────────────────

class _AddExamBanner extends StatelessWidget {
  const _AddExamBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WittSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(WittSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              WittColors.primary.withValues(alpha: 0.08),
              WittColors.accent.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(WittSpacing.sm),
          border: Border.all(color: WittColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: WittColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: WittColors.primary),
            ),
            const SizedBox(width: WittSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add your first exam',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Choose from 30+ exams across the globe',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: WittColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: WittColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ── My exam chip ──────────────────────────────────────────────────────────

class _MyExamChip extends StatelessWidget {
  const _MyExamChip({required this.exam, required this.onTap});
  final Exam exam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WittSpacing.sm),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(WittSpacing.sm),
        decoration: BoxDecoration(
          color: WittColors.primaryContainer,
          borderRadius: BorderRadius.circular(WittSpacing.sm),
          border: Border.all(color: WittColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(exam.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              exam.name,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: WittColors.primary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddExamChip extends StatelessWidget {
  const _AddExamChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WittSpacing.sm),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: WittColors.surfaceVariant,
          borderRadius: BorderRadius.circular(WittSpacing.sm),
          border: Border.all(
            color: WittColors.outline,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline,
              color: WittColors.textTertiary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              'Add Exam',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: WittColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Continue learning card ────────────────────────────────────────────────

class _ContinueLearningCard extends StatelessWidget {
  const _ContinueLearningCard({required this.exam, required this.onTap});
  final Exam exam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WittSpacing.sm),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(WittSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              WittColors.primary.withValues(alpha: 0.15),
              WittColors.accent.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(WittSpacing.sm),
          border: Border.all(color: WittColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exam.emoji, style: const TextStyle(fontSize: 28)),
            const Spacer(),
            Text(
              exam.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${exam.sections.length} sections · ${exam.totalQuestions} Qs',
              style: theme.textTheme.labelSmall?.copyWith(
                color: WittColors.textSecondary,
              ),
            ),
            const SizedBox(height: WittSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: 0,
                backgroundColor: WittColors.outline,
                valueColor: AlwaysStoppedAnimation<Color>(WittColors.primary),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Region chip ───────────────────────────────────────────────────────────

class _RegionChip extends StatelessWidget {
  const _RegionChip({
    required this.region,
    required this.count,
    required this.onTap,
  });

  final ExamRegion region;
  final int count;
  final VoidCallback onTap;

  String get _label {
    switch (region) {
      case ExamRegion.us:
        return '🇺🇸 US';
      case ExamRegion.uk:
        return '🇬🇧 UK';
      case ExamRegion.africa:
        return '🌍 Africa';
      case ExamRegion.india:
        return '🇮🇳 India';
      case ExamRegion.europe:
        return '🇪🇺 Europe';
      case ExamRegion.latinAmerica:
        return '🌎 Latin America';
      case ExamRegion.china:
        return '🇨🇳 China';
      case ExamRegion.global:
        return '🌐 Global';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: WittSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: WittSpacing.md,
            vertical: WittSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: WittColors.surfaceVariant,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: WittColors.outline),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$count exams',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: WittColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Featured exam tile ────────────────────────────────────────────────────

class _FeaturedExamTile extends StatelessWidget {
  const _FeaturedExamTile({
    required this.exam,
    required this.isAdded,
    required this.onTap,
    required this.onAdd,
  });

  final Exam exam;
  final bool isAdded;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WittSpacing.lg,
        0,
        WittSpacing.lg,
        WittSpacing.sm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WittSpacing.sm),
        child: Container(
          padding: const EdgeInsets.all(WittSpacing.md),
          decoration: BoxDecoration(
            color: WittColors.surfaceVariant,
            borderRadius: BorderRadius.circular(WittSpacing.sm),
            border: Border.all(color: WittColors.outline),
          ),
          child: Row(
            children: [
              Text(exam.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: WittSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exam.purpose,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: WittColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _PillTag(label: exam.region.name.toUpperCase()),
                        const SizedBox(width: 4),
                        _PillTag(label: '${exam.totalQuestions} Qs'),
                        const SizedBox(width: 4),
                        _PillTag(label: '${exam.freeQuestionCount} free'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: WittSpacing.sm),
              isAdded
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: WittSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: WittColors.successContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check,
                            size: 12,
                            color: WittColors.success,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Added',
                            style: TextStyle(
                              fontSize: 11,
                              color: WittColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GestureDetector(
                      onTap: onAdd,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: WittSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: WittColors.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add,
                              size: 12,
                              color: WittColors.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Add',
                              style: TextStyle(
                                fontSize: 11,
                                color: WittColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  const _PillTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: WittColors.outline.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: WittColors.textTertiary,
          fontSize: 10,
        ),
      ),
    );
  }
}
