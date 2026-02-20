import 'package:flutter/foundation.dart';

enum QuestionType {
  mcq,
  multiSelect,
  trueFalse,
  fillBlank,
  shortAnswer,
  essay,
  passageBased,
  dataInterpretation,
  quantitativeComparison,
  sentenceCompletion,
  errorIdentification,
}

enum DifficultyLevel { easy, medium, hard, expert }

@immutable
class QuestionOption {
  const QuestionOption({
    required this.id,
    required this.text,
    this.imageUrl,
  });

  final String id;
  final String text;
  final String? imageUrl;

  factory QuestionOption.fromJson(Map<String, dynamic> json) => QuestionOption(
        id: json['id'] as String,
        text: json['text'] as String,
        imageUrl: json['image_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        if (imageUrl != null) 'image_url': imageUrl,
      };
}

@immutable
class Question {
  const Question({
    required this.id,
    required this.examId,
    required this.sectionId,
    required this.type,
    required this.text,
    required this.correctAnswerIds,
    required this.difficulty,
    required this.topic,
    required this.estimatedTimeSeconds,
    required this.explanation,
    this.options = const [],
    this.passageText,
    this.imageUrl,
    this.audioUrl,
    this.isPreGenerated = true,
    this.tags = const [],
  });

  final String id;
  final String examId;
  final String sectionId;
  final QuestionType type;
  final String text;
  final List<QuestionOption> options;
  final List<String> correctAnswerIds;
  final DifficultyLevel difficulty;
  final String topic;
  final int estimatedTimeSeconds;
  final String explanation;
  final String? passageText;
  final String? imageUrl;
  final String? audioUrl;
  final bool isPreGenerated;
  final List<String> tags;

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as String,
        examId: json['exam_id'] as String,
        sectionId: json['section_id'] as String,
        type: QuestionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => QuestionType.mcq,
        ),
        text: json['text'] as String,
        options: (json['options'] as List<dynamic>? ?? [])
            .map((o) => QuestionOption.fromJson(o as Map<String, dynamic>))
            .toList(),
        correctAnswerIds: List<String>.from(json['correct_answer_ids'] ?? []),
        difficulty: DifficultyLevel.values.firstWhere(
          (e) => e.name == json['difficulty'],
          orElse: () => DifficultyLevel.medium,
        ),
        topic: json['topic'] as String,
        estimatedTimeSeconds: json['estimated_time_seconds'] as int? ?? 60,
        explanation: json['explanation'] as String? ?? '',
        passageText: json['passage_text'] as String?,
        imageUrl: json['image_url'] as String?,
        audioUrl: json['audio_url'] as String?,
        isPreGenerated: json['is_pre_generated'] as bool? ?? true,
        tags: List<String>.from(json['tags'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'exam_id': examId,
        'section_id': sectionId,
        'type': type.name,
        'text': text,
        'options': options.map((o) => o.toJson()).toList(),
        'correct_answer_ids': correctAnswerIds,
        'difficulty': difficulty.name,
        'topic': topic,
        'estimated_time_seconds': estimatedTimeSeconds,
        'explanation': explanation,
        if (passageText != null) 'passage_text': passageText,
        if (imageUrl != null) 'image_url': imageUrl,
        if (audioUrl != null) 'audio_url': audioUrl,
        'is_pre_generated': isPreGenerated,
        'tags': tags,
      };
}

@immutable
class QuestionAttempt {
  const QuestionAttempt({
    required this.id,
    required this.questionId,
    required this.examId,
    required this.userId,
    required this.selectedAnswerIds,
    required this.isCorrect,
    required this.timeSpentSeconds,
    required this.attemptedAt,
    this.sessionId,
    this.textAnswer,
  });

  final String id;
  final String questionId;
  final String examId;
  final String userId;
  final List<String> selectedAnswerIds;
  final bool isCorrect;
  final int timeSpentSeconds;
  final DateTime attemptedAt;
  final String? sessionId;
  final String? textAnswer;

  factory QuestionAttempt.fromJson(Map<String, dynamic> json) =>
      QuestionAttempt(
        id: json['id'] as String,
        questionId: json['question_id'] as String,
        examId: json['exam_id'] as String,
        userId: json['user_id'] as String,
        selectedAnswerIds:
            List<String>.from(json['selected_answer_ids'] ?? []),
        isCorrect: json['is_correct'] as bool,
        timeSpentSeconds: json['time_spent_seconds'] as int,
        attemptedAt: DateTime.parse(json['attempted_at'] as String),
        sessionId: json['session_id'] as String?,
        textAnswer: json['text_answer'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'question_id': questionId,
        'exam_id': examId,
        'user_id': userId,
        'selected_answer_ids': selectedAnswerIds,
        'is_correct': isCorrect,
        'time_spent_seconds': timeSpentSeconds,
        'attempted_at': attemptedAt.toIso8601String(),
        if (sessionId != null) 'session_id': sessionId,
        if (textAnswer != null) 'text_answer': textAnswer,
      };
}

@immutable
class PracticeSession {
  const PracticeSession({
    required this.id,
    required this.examId,
    required this.userId,
    required this.attempts,
    required this.startedAt,
    required this.completedAt,
    required this.topic,
    required this.xpEarned,
  });

  final String id;
  final String examId;
  final String userId;
  final List<QuestionAttempt> attempts;
  final DateTime startedAt;
  final DateTime completedAt;
  final String topic;
  final int xpEarned;

  int get totalQuestions => attempts.length;
  int get correctCount => attempts.where((a) => a.isCorrect).length;
  double get accuracy =>
      totalQuestions == 0 ? 0 : correctCount / totalQuestions;
  int get totalTimeSeconds =>
      attempts.fold(0, (sum, a) => sum + a.timeSpentSeconds);

  Map<String, double> get accuracyByTopic {
    final Map<String, List<bool>> byTopic = {};
    return byTopic.map((k, v) => MapEntry(
          k,
          v.isEmpty ? 0 : v.where((b) => b).length / v.length,
        ));
  }
}
