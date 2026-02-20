import 'package:flutter/foundation.dart';

enum HomeworkInputMethod {
  text,
  camera,
  upload,
  voice,
}

enum HomeworkSubject {
  mathematics,
  physics,
  chemistry,
  biology,
  english,
  history,
  geography,
  computerScience,
  economics,
  other,
}

enum SolutionStepType {
  setup,
  formula,
  calculation,
  explanation,
  conclusion,
  hint,
}

@immutable
class SolutionStep {
  const SolutionStep({
    required this.stepNumber,
    required this.type,
    required this.title,
    required this.content,
    this.formula,
    this.imageUrl,
  });

  final int stepNumber;
  final SolutionStepType type;
  final String title;
  final String content;
  final String? formula;
  final String? imageUrl;
}

@immutable
class HomeworkSolution {
  const HomeworkSolution({
    required this.id,
    required this.question,
    required this.subject,
    required this.steps,
    required this.finalAnswer,
    required this.explanation,
    required this.difficulty,
    required this.solvedAt,
    this.relatedTopics = const [],
    this.practiceQuestionIds = const [],
    this.inputMethod = HomeworkInputMethod.text,
  });

  final String id;
  final String question;
  final HomeworkSubject subject;
  final List<SolutionStep> steps;
  final String finalAnswer;
  final String explanation;
  final String difficulty;
  final DateTime solvedAt;
  final List<String> relatedTopics;
  final List<String> practiceQuestionIds;
  final HomeworkInputMethod inputMethod;
}

class HomeworkSessionState {
  const HomeworkSessionState({
    required this.inputMethod,
    required this.subject,
    required this.question,
    required this.isLoading,
    required this.solution,
    this.imageBytes,
    this.errorMessage,
  });

  final HomeworkInputMethod inputMethod;
  final HomeworkSubject subject;
  final String question;
  final bool isLoading;
  final HomeworkSolution? solution;
  final List<int>? imageBytes;
  final String? errorMessage;

  HomeworkSessionState copyWith({
    HomeworkInputMethod? inputMethod,
    HomeworkSubject? subject,
    String? question,
    bool? isLoading,
    HomeworkSolution? solution,
    List<int>? imageBytes,
    String? errorMessage,
  }) =>
      HomeworkSessionState(
        inputMethod: inputMethod ?? this.inputMethod,
        subject: subject ?? this.subject,
        question: question ?? this.question,
        isLoading: isLoading ?? this.isLoading,
        solution: solution ?? this.solution,
        imageBytes: imageBytes ?? this.imageBytes,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}
