import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ai/witt_ai.dart';
import 'package:witt_ui/witt_ui.dart';
import '../models/exam.dart';
import '../models/question.dart';
import '../providers/exam_providers.dart';
import '../providers/test_prep_providers.dart';
import 'question_screen.dart';
import 'topic_drill_screen.dart';

class ExamHubScreen extends ConsumerWidget {
  const ExamHubScreen({super.key, required this.examId});
  final String examId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exam = ref.watch(examByIdProvider(examId));
    if (exam == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exam')),
        body: const Center(child: Text('Exam not found')),
      );
    }

    final proficiency = ref.watch(
      userProficiencyProvider.select((map) => map[examId]),
    );
    final readiness = proficiency != null
        ? (proficiency.overallScore * 100).round()
        : 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [WittColors.primary, WittColors.primaryDark],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      WittSpacing.lg,
                      56,
                      WittSpacing.lg,
                      WittSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exam.emoji, style: const TextStyle(fontSize: 36)),
                        const SizedBox(height: WittSpacing.xs),
                        Text(
                          exam.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          exam.purpose,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              title: Text(exam.name),
              collapseMode: CollapseMode.parallax,
            ),
          ),

          // ── Readiness card ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(WittSpacing.lg),
              child: _ReadinessCard(
                readiness: readiness,
                questionsAttempted: proficiency?.questionsAttempted ?? 0,
                freeQuestionCount: exam.freeQuestionCount,
              ),
            ),
          ),

          // ── Section header ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                WittSpacing.lg,
                0,
                WittSpacing.lg,
                WittSpacing.sm,
              ),
              child: Text(
                'Practice by Section',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),

          // ── Section tiles ────────────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final section = exam.sections[index];
              final topicAcc = proficiency?.topicScores ?? {};
              return _SectionTile(
                exam: exam,
                section: section,
                topicAccuracies: topicAcc,
                onTap: () => _startTopicDrill(context, exam, section),
              );
            }, childCount: exam.sections.length),
          ),

          // ── Quick actions ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(WittSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: WittSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.quiz_outlined,
                          label: 'Full Mock Test',
                          subtitle:
                              '${exam.totalQuestions} Qs · ${exam.totalTimeMinutes}m',
                          color: WittColors.accent,
                          onTap: () => _startMockTest(context, exam),
                        ),
                      ),
                      const SizedBox(width: WittSpacing.sm),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.bookmark_outline,
                          label: 'Bookmarked Qs',
                          subtitle: 'Review saved questions',
                          color: WittColors.secondary,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: WittSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.history,
                          label: 'Question History',
                          subtitle:
                              '${proficiency?.questionsAttempted ?? 0} attempted',
                          color: WittColors.primary,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: WittSpacing.sm),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.analytics_outlined,
                          label: 'Analytics',
                          subtitle: 'Topic mastery heatmap',
                          color: WittColors.success,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: WittSpacing.sm),
                  _ActionCard(
                    icon: Icons.auto_awesome,
                    label: 'AI Generate Questions',
                    subtitle: 'Claude creates custom practice Qs',
                    color: WittColors.secondary,
                    onTap: () => _generateAiQuestions(context, ref, exam),
                    fullWidth: true,
                  ),
                ],
              ),
            ),
          ),

          // ── Exam info ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                WittSpacing.lg,
                0,
                WittSpacing.lg,
                WittSpacing.xl,
              ),
              child: _ExamInfoCard(exam: exam),
            ),
          ),
        ],
      ),
    );
  }

  void _startTopicDrill(BuildContext context, Exam exam, ExamSection section) {
    final topic = section.topics.isNotEmpty
        ? section.topics.first
        : section.name;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TopicDrillScreen(
          examId: exam.id,
          sectionId: section.id,
          sectionName: section.name,
          topic: topic,
        ),
      ),
    );
  }

  void _startMockTest(BuildContext context, Exam exam) {
    final allQuestions = exam.sections
        .expand((s) => _buildSampleQuestions(exam, s, count: 5))
        .toList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuestionScreen(
          examId: exam.id,
          sectionName: 'Full Mock Test',
          questions: allQuestions,
        ),
      ),
    );
  }

  Future<void> _generateAiQuestions(
    BuildContext context,
    WidgetRef ref,
    Exam exam,
  ) async {
    final isPaid = ref.read(isPaidUserProvider);
    final usage = ref.read(usageProvider.notifier);

    if (!isPaid) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'AI exam question generation is available on paid plans only.',
            ),
          ),
        );
        context.push('/onboarding/paywall');
      }
      return;
    }

    if (!usage.canUse(AiFeature.examGenerate, isPaid)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(usage.limitMessage(AiFeature.examGenerate)),
            backgroundColor: WittColors.error,
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generating ${exam.name} questions with Claude…'),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    final sectionNames = exam.sections.map((s) => s.name).take(3).join(', ');
    final request = AiRequest(
      feature: AiFeature.examGenerate,
      messages: [
        AiMessage(
          id: 'exam_gen',
          role: 'user',
          content:
              'Generate 10 practice questions for ${exam.name} exam. '
              'Cover these sections: $sectionNames. '
              'Mix difficulty levels. Include MCQ and true/false.',
          createdAt: DateTime.now(),
        ),
      ],
      isPaidUser: isPaid,
    );

    final router = ref.read(aiRouterProvider);
    final response = await router.request(request);

    if (!context.mounted) return;

    if (response.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error ?? 'Generation failed'),
          backgroundColor: WittColors.error,
        ),
      );
      return;
    }

    usage.recordUsage(AiFeature.examGenerate);
    final questions = _parseAiExamQuestions(response.content, exam);

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not parse questions. Try again.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuestionScreen(
          examId: exam.id,
          sectionName: 'AI Practice — ${exam.name}',
          questions: questions,
        ),
      ),
    );
  }

  List<Question> _parseAiExamQuestions(String jsonContent, Exam exam) {
    try {
      final raw = jsonDecode(jsonContent);
      final list = raw is List ? raw : (raw as Map)['questions'] as List? ?? [];
      return list.asMap().entries.map((entry) {
        final i = entry.key;
        final q = entry.value as Map<String, dynamic>;
        final optionsRaw = q['options'] as List<dynamic>? ?? [];
        final options = optionsRaw.map((o) {
          final om = o as Map<String, dynamic>;
          return QuestionOption(
            id: om['id'] as String? ?? 'opt_$i',
            text: om['text'] as String? ?? '',
          );
        }).toList();
        final correctRaw = q['correct_answer_ids'] as List<dynamic>? ?? [];
        return Question(
          id: 'ai_exam_${exam.id}_${DateTime.now().millisecondsSinceEpoch}_$i',
          examId: exam.id,
          sectionId: q['section_id'] as String? ?? 'ai',
          type: _parseQType(q['type'] as String? ?? 'mcq'),
          text: q['text'] as String? ?? '',
          options: options,
          correctAnswerIds: correctRaw.map((e) => e.toString()).toList(),
          difficulty: _parseDifficulty(q['difficulty'] as String? ?? 'medium'),
          topic: q['topic'] as String? ?? exam.name,
          estimatedTimeSeconds: 60,
          explanation: q['explanation'] as String? ?? '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  QuestionType _parseQType(String t) => switch (t) {
    'trueFalse' => QuestionType.trueFalse,
    'fillBlank' => QuestionType.fillBlank,
    'multiSelect' => QuestionType.multiSelect,
    _ => QuestionType.mcq,
  };

  DifficultyLevel _parseDifficulty(String d) => switch (d) {
    'easy' => DifficultyLevel.easy,
    'hard' => DifficultyLevel.hard,
    'expert' => DifficultyLevel.expert,
    _ => DifficultyLevel.medium,
  };

  List<Question> _buildSampleQuestions(
    Exam exam,
    ExamSection section, {
    required int count,
  }) {
    return List.generate(count, (i) {
      final topic = section.topics.isNotEmpty
          ? section.topics[i % section.topics.length]
          : section.name;
      return Question(
        id: '${exam.id}_${section.id}_sample_$i',
        examId: exam.id,
        sectionId: section.id,
        type: QuestionType.mcq,
        text:
            'Sample ${exam.name} question ${i + 1} on $topic. This is a placeholder question that will be replaced by AI-generated or pre-generated content from the database.',
        options: const [
          QuestionOption(id: 'a', text: 'Answer choice A'),
          QuestionOption(id: 'b', text: 'Answer choice B'),
          QuestionOption(id: 'c', text: 'Answer choice C'),
          QuestionOption(id: 'd', text: 'Answer choice D'),
        ],
        correctAnswerIds: const ['a'],
        difficulty: DifficultyLevel.medium,
        topic: topic,
        estimatedTimeSeconds: 60,
        explanation:
            'This is the explanation for why answer A is correct. In a real question, this would contain a detailed step-by-step explanation.',
      );
    });
  }
}

// ── Readiness card ────────────────────────────────────────────────────────

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({
    required this.readiness,
    required this.questionsAttempted,
    required this.freeQuestionCount,
  });

  final int readiness;
  final int questionsAttempted;
  final int freeQuestionCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = readiness >= 70
        ? WittColors.success
        : readiness >= 40
        ? WittColors.secondary
        : WittColors.error;

    return Container(
      padding: const EdgeInsets.all(WittSpacing.md),
      decoration: BoxDecoration(
        color: WittColors.surfaceVariant,
        borderRadius: BorderRadius.circular(WittSpacing.md),
        border: Border.all(color: WittColors.outline),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: readiness / 100,
                  backgroundColor: WittColors.outline,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeWidth: 6,
                ),
                Text(
                  '$readiness%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: WittSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Readiness',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$questionsAttempted questions attempted',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: WittColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  questionsAttempted == 0
                      ? 'Start practicing to track your progress'
                      : 'Keep going — you\'re building momentum!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: WittColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section tile ──────────────────────────────────────────────────────────

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.exam,
    required this.section,
    required this.topicAccuracies,
    required this.onTap,
  });

  final Exam exam;
  final ExamSection section;
  final Map<String, double> topicAccuracies;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topicCount = section.topics.length;

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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: WittColors.primaryContainer,
                  borderRadius: BorderRadius.circular(WittSpacing.xs),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: WittColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: WittSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${section.questionCount} Qs · ${section.timeLimitMinutes}m'
                      '${topicCount > 0 ? ' · $topicCount topics' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: WittColors.textSecondary,
                      ),
                    ),
                    if (section.topics.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: section.topics
                            .take(3)
                            .map((t) => _TopicChip(topic: t))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: WittColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.topic});
  final String topic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: WittColors.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        topic,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: WittColors.primary,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ── Action card ───────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WittSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(WittSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(WittSpacing.sm),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: WittSpacing.sm),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: WittColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Exam info card ────────────────────────────────────────────────────────

class _ExamInfoCard extends StatelessWidget {
  const _ExamInfoCard({required this.exam});
  final Exam exam;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(WittSpacing.md),
      decoration: BoxDecoration(
        color: WittColors.surfaceVariant,
        borderRadius: BorderRadius.circular(WittSpacing.sm),
        border: Border.all(color: WittColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exam Details',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: WittSpacing.sm),
          _InfoRow(label: 'Full Name', value: exam.fullName),
          _InfoRow(label: 'Total Questions', value: '${exam.totalQuestions}'),
          _InfoRow(
            label: 'Total Time',
            value: '${exam.totalTimeMinutes} minutes',
          ),
          _InfoRow(
            label: 'Score Range',
            value: '${exam.minScore.toInt()} – ${exam.maxScore.toInt()}',
          ),
          _InfoRow(label: 'Sections', value: '${exam.sections.length}'),
          if (exam.hasNegativeMarking)
            _InfoRow(
              label: 'Negative Marking',
              value: '-${exam.negativeMarkPenalty} per wrong',
            ),
          _InfoRow(
            label: 'Free Questions',
            value: '${exam.freeQuestionCount} included',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: WittColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
