import 'package:flutter/foundation.dart';

enum AiProvider { groq, openai, claude }

enum AiFeature {
  sageChat,
  examGenerate,
  homework,
  quizGenerate,
  flashcardGenerate,
  summarize,
  transcribe,
  tts,
}

enum SageMode {
  chat,
  explain,
  homework,
  quiz,
  planning,
  flashcardGen,
  lectureSummary,
}

@immutable
class AiMessage {
  const AiMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isStreaming = false,
  });

  final String id;
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  final DateTime createdAt;
  final bool isStreaming;

  AiMessage copyWith({
    String? id,
    String? role,
    String? content,
    DateTime? createdAt,
    bool? isStreaming,
  }) => AiMessage(
    id: id ?? this.id,
    role: role ?? this.role,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
    isStreaming: isStreaming ?? this.isStreaming,
  );

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

@immutable
class AiRequest {
  const AiRequest({
    required this.feature,
    required this.messages,
    required this.isPaidUser,
    this.examId,
    this.systemPrompt,
    this.maxTokens,
    this.stream = false,
  });

  final AiFeature feature;
  final List<AiMessage> messages;
  final bool isPaidUser;
  final String? examId;
  final String? systemPrompt;
  final int? maxTokens;
  final bool stream;

  AiProvider get resolvedProvider {
    if (feature == AiFeature.examGenerate) return AiProvider.claude;
    if (feature == AiFeature.transcribe || feature == AiFeature.tts) {
      return AiProvider.openai;
    }
    return isPaidUser ? AiProvider.openai : AiProvider.groq;
  }

  String get edgeFunctionSlug => switch (feature) {
    AiFeature.sageChat => 'ai-chat',
    AiFeature.examGenerate => 'ai-exam-generate',
    AiFeature.homework => 'ai-homework',
    AiFeature.quizGenerate => 'ai-quiz-generate',
    AiFeature.flashcardGenerate => 'ai-flashcard-generate',
    AiFeature.summarize => 'ai-summarize',
    AiFeature.transcribe => 'ai-transcribe',
    AiFeature.tts => 'ai-tts',
  };
}

@immutable
class AiResponse {
  const AiResponse({
    required this.content,
    required this.provider,
    required this.feature,
    required this.tokensUsed,
    this.error,
  });

  final String content;
  final AiProvider provider;
  final AiFeature feature;
  final int tokensUsed;
  final String? error;

  bool get hasError => error != null;
}

@immutable
class UsageRecord {
  const UsageRecord({
    required this.dailyMessages,
    required this.monthlyMessages,
    required this.dailyHomework,
    required this.dailyQuizGens,
    required this.dailyFlashcardGens,
    required this.dailySummarizations,
    required this.dailyAttachments,
    required this.lastResetDate,
  });

  final int dailyMessages;
  final int monthlyMessages;
  final int dailyHomework;
  final int dailyQuizGens;
  final int dailyFlashcardGens;
  final int dailySummarizations;
  final int dailyAttachments;
  final DateTime lastResetDate;

  static final _epoch = DateTime.utc(2000);

  static final UsageRecord empty = UsageRecord(
    dailyMessages: 0,
    monthlyMessages: 0,
    dailyHomework: 0,
    dailyQuizGens: 0,
    dailyFlashcardGens: 0,
    dailySummarizations: 0,
    dailyAttachments: 0,
    lastResetDate: _epoch,
  );

  bool canUseFeature(AiFeature feature) => switch (feature) {
    AiFeature.sageChat => dailyMessages < 10 && monthlyMessages < 300,
    AiFeature.homework => dailyHomework < 5,
    AiFeature.quizGenerate => dailyQuizGens < 1,
    AiFeature.flashcardGenerate => dailyFlashcardGens < 1,
    AiFeature.summarize => dailySummarizations < 3,
    AiFeature.transcribe => false, // paid only
    AiFeature.tts => false, // paid only
    AiFeature.examGenerate => false, // paid only
  };

  String limitMessage(AiFeature feature) => switch (feature) {
    AiFeature.sageChat =>
      dailyMessages >= 10
          ? "You've used all 10 messages today. Upgrade to Premium for unlimited access."
          : "You've reached your monthly message limit. Upgrade to Premium.",
    AiFeature.homework =>
      "You've used all 5 homework solves today. Upgrade for unlimited.",
    AiFeature.quizGenerate =>
      "You've used your 1 free quiz generation today. Upgrade for unlimited.",
    AiFeature.flashcardGenerate =>
      "You've used your 1 free flashcard generation today. Upgrade for unlimited.",
    AiFeature.summarize =>
      "You've used all 3 free summarizations today. Upgrade for unlimited.",
    AiFeature.transcribe =>
      "Lecture transcription requires Premium. Upgrade to unlock.",
    AiFeature.tts => "Text-to-speech requires Premium. Upgrade to unlock.",
    AiFeature.examGenerate =>
      'AI exam question generation requires Premium. Upgrade to unlock.',
  };

  UsageRecord increment(AiFeature feature) {
    return UsageRecord(
      dailyMessages: feature == AiFeature.sageChat
          ? dailyMessages + 1
          : dailyMessages,
      monthlyMessages: feature == AiFeature.sageChat
          ? monthlyMessages + 1
          : monthlyMessages,
      dailyHomework: feature == AiFeature.homework
          ? dailyHomework + 1
          : dailyHomework,
      dailyQuizGens: feature == AiFeature.quizGenerate
          ? dailyQuizGens + 1
          : dailyQuizGens,
      dailyFlashcardGens: feature == AiFeature.flashcardGenerate
          ? dailyFlashcardGens + 1
          : dailyFlashcardGens,
      dailySummarizations: feature == AiFeature.summarize
          ? dailySummarizations + 1
          : dailySummarizations,
      dailyAttachments: dailyAttachments,
      lastResetDate: lastResetDate,
    );
  }
}
