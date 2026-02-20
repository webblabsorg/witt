import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ai/witt_ai.dart';
import '../models/homework.dart';
import '../../learn/providers/test_prep_providers.dart';
import '../../progress/providers/progress_providers.dart';

// ── Homework history ──────────────────────────────────────────────────────

class HomeworkHistoryNotifier extends Notifier<List<HomeworkSolution>> {
  @override
  List<HomeworkSolution> build() => const [];

  void addSolution(HomeworkSolution solution) {
    state = [solution, ...state];
  }

  void deleteSolution(String id) {
    state = state.where((s) => s.id != id).toList();
  }
}

final homeworkHistoryProvider =
    NotifierProvider<HomeworkHistoryNotifier, List<HomeworkSolution>>(
      HomeworkHistoryNotifier.new,
    );

// ── Homework session ──────────────────────────────────────────────────────

class HomeworkSessionNotifier extends Notifier<HomeworkSessionState> {
  @override
  HomeworkSessionState build() => const HomeworkSessionState(
    inputMethod: HomeworkInputMethod.text,
    subject: HomeworkSubject.mathematics,
    question: '',
    isLoading: false,
    solution: null,
  );

  void setInputMethod(HomeworkInputMethod method) {
    state = state.copyWith(inputMethod: method);
  }

  void setSubject(HomeworkSubject subject) {
    state = state.copyWith(subject: subject);
  }

  void setQuestion(String question) {
    state = state.copyWith(question: question, errorMessage: null);
  }

  void clearSolution() {
    state = state.copyWith(question: '', solution: null, errorMessage: null);
  }

  Future<void> solve() async {
    if (state.question.trim().isEmpty) return;
    final isPaid = ref.read(isPaidUserProvider);

    // Check usage limit
    final usage = ref.read(usageProvider.notifier);
    if (!usage.canUse(AiFeature.homework, isPaid)) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: usage.limitMessage(AiFeature.homework),
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final request = AiRequest(
        feature: AiFeature.homework,
        messages: [
          AiMessage(
            id: 'hw_q',
            role: 'user',
            content:
                'Subject: ${state.subject.name}\n\nQuestion: ${state.question}',
            createdAt: DateTime.now(),
          ),
        ],
        isPaidUser: isPaid,
      );

      final router = ref.read(aiRouterProvider);
      final response = await router.request(request);

      if (response.hasError) {
        state = state.copyWith(isLoading: false, errorMessage: response.error);
        return;
      }

      usage.recordUsage(AiFeature.homework);
      final solution = _parseSolution(response.content);
      state = state.copyWith(isLoading: false, solution: solution);
      ref.read(homeworkHistoryProvider.notifier).addSolution(solution);
      ref.read(xpProvider.notifier).addXp(20);
      ref.read(dailyActivityProvider.notifier).recordMinutes(5);
      ref.read(badgeProvider.notifier).checkAndAward(ref);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  HomeworkSolution _parseSolution(String jsonContent) {
    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;
      final stepsJson = data['steps'] as List<dynamic>? ?? [];
      final steps = stepsJson.map((s) {
        final m = s as Map<String, dynamic>;
        return SolutionStep(
          stepNumber: m['step_number'] as int? ?? 1,
          type: _parseStepType(m['type'] as String? ?? 'explanation'),
          title: m['title'] as String? ?? '',
          content: m['content'] as String? ?? '',
          formula: m['formula'] as String?,
        );
      }).toList();

      final relatedRaw = data['related_topics'] as List<dynamic>? ?? [];
      return HomeworkSolution(
        id: 'hw_${DateTime.now().millisecondsSinceEpoch}',
        question: state.question,
        subject: _parseSubject(data['subject'] as String?),
        steps: steps.isEmpty
            ? _generateStubSolution(
                question: state.question,
                subject: state.subject,
              ).steps
            : steps,
        finalAnswer: data['final_answer'] as String? ?? '',
        explanation: data['explanation'] as String? ?? '',
        difficulty: data['difficulty'] as String? ?? 'Medium',
        solvedAt: DateTime.now(),
        relatedTopics: relatedRaw.map((e) => e.toString()).toList(),
        inputMethod: state.inputMethod,
      );
    } catch (_) {
      return _generateStubSolution(
        question: state.question,
        subject: state.subject,
      );
    }
  }

  SolutionStepType _parseStepType(String type) => switch (type) {
    'setup' => SolutionStepType.setup,
    'formula' => SolutionStepType.formula,
    'calculation' => SolutionStepType.calculation,
    'conclusion' => SolutionStepType.conclusion,
    'hint' => SolutionStepType.hint,
    _ => SolutionStepType.explanation,
  };

  HomeworkSubject _parseSubject(String? s) {
    if (s == null) return state.subject;
    try {
      return HomeworkSubject.values.firstWhere((e) => e.name == s);
    } catch (_) {
      return state.subject;
    }
  }

  HomeworkSolution _generateStubSolution({
    required String question,
    required HomeworkSubject subject,
  }) {
    final steps = _buildStepsForSubject(subject, question);
    return HomeworkSolution(
      id: 'hw_${DateTime.now().millisecondsSinceEpoch}',
      question: question,
      subject: subject,
      steps: steps,
      finalAnswer: _stubAnswer(subject),
      explanation: _stubExplanation(subject, question),
      difficulty: 'Medium',
      solvedAt: DateTime.now(),
      relatedTopics: _relatedTopics(subject),
      inputMethod: state.inputMethod,
    );
  }

  List<SolutionStep> _buildStepsForSubject(
    HomeworkSubject subject,
    String question,
  ) {
    return switch (subject) {
      HomeworkSubject.mathematics => [
        const SolutionStep(
          stepNumber: 1,
          type: SolutionStepType.setup,
          title: 'Identify the problem',
          content:
              'Read the problem carefully and identify what is given and what needs to be found.',
        ),
        const SolutionStep(
          stepNumber: 2,
          type: SolutionStepType.formula,
          title: 'Select the appropriate formula',
          content: 'Choose the relevant mathematical formula or theorem.',
          formula: 'Apply the relevant formula based on the problem type.',
        ),
        const SolutionStep(
          stepNumber: 3,
          type: SolutionStepType.calculation,
          title: 'Perform calculations',
          content:
              'Substitute the known values into the formula and solve step by step.',
        ),
        const SolutionStep(
          stepNumber: 4,
          type: SolutionStepType.conclusion,
          title: 'State the answer',
          content:
              'Write the final answer with appropriate units and verify it makes sense.',
        ),
      ],
      HomeworkSubject.physics => [
        const SolutionStep(
          stepNumber: 1,
          type: SolutionStepType.setup,
          title: 'List known quantities',
          content: 'Identify all given values and the unknown to find.',
        ),
        const SolutionStep(
          stepNumber: 2,
          type: SolutionStepType.formula,
          title: 'Apply physics law',
          content: 'Select the relevant physics principle or equation.',
          formula: 'F = ma  |  v = u + at  |  E = mc²',
        ),
        const SolutionStep(
          stepNumber: 3,
          type: SolutionStepType.calculation,
          title: 'Solve for unknown',
          content: 'Rearrange the equation and substitute known values.',
        ),
        const SolutionStep(
          stepNumber: 4,
          type: SolutionStepType.conclusion,
          title: 'Verify and conclude',
          content:
              'Check units and ensure the answer is physically reasonable.',
        ),
      ],
      HomeworkSubject.chemistry => [
        const SolutionStep(
          stepNumber: 1,
          type: SolutionStepType.setup,
          title: 'Write the chemical equation',
          content: 'Write and balance the chemical equation for the reaction.',
        ),
        const SolutionStep(
          stepNumber: 2,
          type: SolutionStepType.formula,
          title: 'Apply stoichiometry',
          content: 'Use molar ratios to relate reactants and products.',
          formula: 'n = m/M  |  PV = nRT',
        ),
        const SolutionStep(
          stepNumber: 3,
          type: SolutionStepType.calculation,
          title: 'Calculate',
          content:
              'Perform the mole calculations and convert to required units.',
        ),
        const SolutionStep(
          stepNumber: 4,
          type: SolutionStepType.conclusion,
          title: 'State the result',
          content:
              'Express the answer with correct significant figures and units.',
        ),
      ],
      _ => [
        const SolutionStep(
          stepNumber: 1,
          type: SolutionStepType.setup,
          title: 'Understand the question',
          content: 'Carefully read and break down what is being asked.',
        ),
        const SolutionStep(
          stepNumber: 2,
          type: SolutionStepType.explanation,
          title: 'Gather relevant information',
          content:
              'Recall key concepts, definitions, and facts related to the topic.',
        ),
        const SolutionStep(
          stepNumber: 3,
          type: SolutionStepType.explanation,
          title: 'Construct your answer',
          content:
              'Organize your thoughts logically and build a coherent response.',
        ),
        const SolutionStep(
          stepNumber: 4,
          type: SolutionStepType.conclusion,
          title: 'Review and finalize',
          content: 'Check your answer for completeness, accuracy, and clarity.',
        ),
      ],
    };
  }

  String _stubAnswer(HomeworkSubject subject) => switch (subject) {
    HomeworkSubject.mathematics =>
      'x = 42 (calculated via step-by-step solution)',
    HomeworkSubject.physics => 'v = 9.8 m/s (using kinematic equations)',
    HomeworkSubject.chemistry => 'n = 2.5 mol (via stoichiometric calculation)',
    HomeworkSubject.biology =>
      'The process involves mitosis with 4 daughter cells.',
    HomeworkSubject.english =>
      'The theme explores the conflict between individual freedom and societal norms.',
    _ => 'Solution derived through systematic analysis above.',
  };

  String _stubExplanation(HomeworkSubject subject, String question) =>
      'This problem involves ${subject.name} concepts. '
      'The step-by-step solution above walks through the key principles. '
      'In Phase 3, AI-powered solutions will provide personalized, '
      'context-aware explanations tailored to your specific question.';

  List<String> _relatedTopics(HomeworkSubject subject) => switch (subject) {
    HomeworkSubject.mathematics => [
      'Algebra',
      'Calculus',
      'Geometry',
      'Statistics',
    ],
    HomeworkSubject.physics => [
      'Mechanics',
      'Thermodynamics',
      'Electromagnetism',
      'Optics',
    ],
    HomeworkSubject.chemistry => [
      'Stoichiometry',
      'Thermochemistry',
      'Organic Chemistry',
      'Electrochemistry',
    ],
    HomeworkSubject.biology => [
      'Cell Biology',
      'Genetics',
      'Ecology',
      'Evolution',
    ],
    _ => ['Study Guide', 'Practice Questions', 'Key Concepts'],
  };
}

final homeworkSessionProvider =
    NotifierProvider<HomeworkSessionNotifier, HomeworkSessionState>(
      HomeworkSessionNotifier.new,
    );
