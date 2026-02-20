import 'package:flutter/foundation.dart';

// ── Card types ────────────────────────────────────────────────────────────

enum FlashcardType {
  basic,        // Front / Back
  reversed,     // Back / Front (auto-generates reverse card)
  cloze,        // Fill-in-the-blank: "The capital of France is {{Paris}}"
  imageOcclusion, // Image with hidden regions
  typed,        // User types the answer
}

// ── Study modes ───────────────────────────────────────────────────────────

enum StudyMode {
  flashcard,  // Classic flip cards
  learn,      // Guided learn with multiple rounds
  write,      // Type the answer
  match,      // Match pairs game
  test,       // Auto-generated test from deck
}

// ── SM-2 rating ───────────────────────────────────────────────────────────

enum Sm2Rating {
  again,  // 0 — complete blackout
  hard,   // 1 — significant difficulty
  good,   // 2 — correct with hesitation
  easy,   // 3 — perfect response
}

// ── Flashcard model ───────────────────────────────────────────────────────

@immutable
class Flashcard {
  const Flashcard({
    required this.id,
    required this.deckId,
    required this.type,
    required this.front,
    required this.back,
    this.hint,
    this.imageUrl,
    this.audioUrl,
    this.clozeText,
    this.tags = const [],
    // SM-2 fields
    this.easeFactor = 2.5,
    this.interval = 1,
    this.repetitions = 0,
    this.nextReviewAt,
    this.lastReviewedAt,
    this.totalReviews = 0,
    this.correctReviews = 0,
    this.createdAt,
  });

  final String id;
  final String deckId;
  final FlashcardType type;
  final String front;
  final String back;
  final String? hint;
  final String? imageUrl;
  final String? audioUrl;
  final String? clozeText;
  final List<String> tags;

  // SM-2 scheduling fields
  final double easeFactor;
  final int interval;       // days until next review
  final int repetitions;    // consecutive correct answers
  final DateTime? nextReviewAt;
  final DateTime? lastReviewedAt;
  final int totalReviews;
  final int correctReviews;
  final DateTime? createdAt;

  bool get isDue {
    if (nextReviewAt == null) return true;
    return DateTime.now().isAfter(nextReviewAt!);
  }

  double get retentionRate =>
      totalReviews == 0 ? 0 : correctReviews / totalReviews;

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
        id: json['id'] as String,
        deckId: json['deck_id'] as String,
        type: FlashcardType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => FlashcardType.basic,
        ),
        front: json['front'] as String,
        back: json['back'] as String,
        hint: json['hint'] as String?,
        imageUrl: json['image_url'] as String?,
        audioUrl: json['audio_url'] as String?,
        clozeText: json['cloze_text'] as String?,
        tags: List<String>.from(json['tags'] ?? []),
        easeFactor: (json['ease_factor'] as num?)?.toDouble() ?? 2.5,
        interval: json['interval'] as int? ?? 1,
        repetitions: json['repetitions'] as int? ?? 0,
        nextReviewAt: json['next_review_at'] != null
            ? DateTime.parse(json['next_review_at'] as String)
            : null,
        lastReviewedAt: json['last_reviewed_at'] != null
            ? DateTime.parse(json['last_reviewed_at'] as String)
            : null,
        totalReviews: json['total_reviews'] as int? ?? 0,
        correctReviews: json['correct_reviews'] as int? ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'deck_id': deckId,
        'type': type.name,
        'front': front,
        'back': back,
        if (hint != null) 'hint': hint,
        if (imageUrl != null) 'image_url': imageUrl,
        if (audioUrl != null) 'audio_url': audioUrl,
        if (clozeText != null) 'cloze_text': clozeText,
        'tags': tags,
        'ease_factor': easeFactor,
        'interval': interval,
        'repetitions': repetitions,
        if (nextReviewAt != null)
          'next_review_at': nextReviewAt!.toIso8601String(),
        if (lastReviewedAt != null)
          'last_reviewed_at': lastReviewedAt!.toIso8601String(),
        'total_reviews': totalReviews,
        'correct_reviews': correctReviews,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  Flashcard copyWith({
    String? id,
    String? deckId,
    FlashcardType? type,
    String? front,
    String? back,
    String? hint,
    String? imageUrl,
    String? audioUrl,
    String? clozeText,
    List<String>? tags,
    double? easeFactor,
    int? interval,
    int? repetitions,
    DateTime? nextReviewAt,
    DateTime? lastReviewedAt,
    int? totalReviews,
    int? correctReviews,
    DateTime? createdAt,
  }) =>
      Flashcard(
        id: id ?? this.id,
        deckId: deckId ?? this.deckId,
        type: type ?? this.type,
        front: front ?? this.front,
        back: back ?? this.back,
        hint: hint ?? this.hint,
        imageUrl: imageUrl ?? this.imageUrl,
        audioUrl: audioUrl ?? this.audioUrl,
        clozeText: clozeText ?? this.clozeText,
        tags: tags ?? this.tags,
        easeFactor: easeFactor ?? this.easeFactor,
        interval: interval ?? this.interval,
        repetitions: repetitions ?? this.repetitions,
        nextReviewAt: nextReviewAt ?? this.nextReviewAt,
        lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
        totalReviews: totalReviews ?? this.totalReviews,
        correctReviews: correctReviews ?? this.correctReviews,
        createdAt: createdAt ?? this.createdAt,
      );
}

// ── Deck model ────────────────────────────────────────────────────────────

@immutable
class FlashcardDeck {
  const FlashcardDeck({
    required this.id,
    required this.name,
    required this.userId,
    this.description = '',
    this.emoji = '📚',
    this.color = 0xFF4F46E5,
    this.examId,
    this.subject,
    this.tags = const [],
    this.cardCount = 0,
    this.dueCount = 0,
    this.newCount = 0,
    this.isPublic = false,
    this.isOfflineCached = false,
    this.createdAt,
    this.lastStudiedAt,
  });

  final String id;
  final String name;
  final String userId;
  final String description;
  final String emoji;
  final int color;
  final String? examId;
  final String? subject;
  final List<String> tags;
  final int cardCount;
  final int dueCount;
  final int newCount;
  final bool isPublic;
  final bool isOfflineCached;
  final DateTime? createdAt;
  final DateTime? lastStudiedAt;

  factory FlashcardDeck.fromJson(Map<String, dynamic> json) => FlashcardDeck(
        id: json['id'] as String,
        name: json['name'] as String,
        userId: json['user_id'] as String,
        description: json['description'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '📚',
        color: json['color'] as int? ?? 0xFF4F46E5,
        examId: json['exam_id'] as String?,
        subject: json['subject'] as String?,
        tags: List<String>.from(json['tags'] ?? []),
        cardCount: json['card_count'] as int? ?? 0,
        dueCount: json['due_count'] as int? ?? 0,
        newCount: json['new_count'] as int? ?? 0,
        isPublic: json['is_public'] as bool? ?? false,
        isOfflineCached: json['is_offline_cached'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        lastStudiedAt: json['last_studied_at'] != null
            ? DateTime.parse(json['last_studied_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'user_id': userId,
        'description': description,
        'emoji': emoji,
        'color': color,
        if (examId != null) 'exam_id': examId,
        if (subject != null) 'subject': subject,
        'tags': tags,
        'card_count': cardCount,
        'due_count': dueCount,
        'new_count': newCount,
        'is_public': isPublic,
        'is_offline_cached': isOfflineCached,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (lastStudiedAt != null)
          'last_studied_at': lastStudiedAt!.toIso8601String(),
      };

  FlashcardDeck copyWith({
    String? id,
    String? name,
    String? userId,
    String? description,
    String? emoji,
    int? color,
    String? examId,
    String? subject,
    List<String>? tags,
    int? cardCount,
    int? dueCount,
    int? newCount,
    bool? isPublic,
    bool? isOfflineCached,
    DateTime? createdAt,
    DateTime? lastStudiedAt,
  }) =>
      FlashcardDeck(
        id: id ?? this.id,
        name: name ?? this.name,
        userId: userId ?? this.userId,
        description: description ?? this.description,
        emoji: emoji ?? this.emoji,
        color: color ?? this.color,
        examId: examId ?? this.examId,
        subject: subject ?? this.subject,
        tags: tags ?? this.tags,
        cardCount: cardCount ?? this.cardCount,
        dueCount: dueCount ?? this.dueCount,
        newCount: newCount ?? this.newCount,
        isPublic: isPublic ?? this.isPublic,
        isOfflineCached: isOfflineCached ?? this.isOfflineCached,
        createdAt: createdAt ?? this.createdAt,
        lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
      );
}

// ── Study session record ──────────────────────────────────────────────────

@immutable
class FlashcardStudySession {
  const FlashcardStudySession({
    required this.id,
    required this.deckId,
    required this.userId,
    required this.mode,
    required this.cardsStudied,
    required this.correctCount,
    required this.againCount,
    required this.hardCount,
    required this.goodCount,
    required this.easyCount,
    required this.totalTimeSeconds,
    required this.startedAt,
    required this.completedAt,
  });

  final String id;
  final String deckId;
  final String userId;
  final StudyMode mode;
  final int cardsStudied;
  final int correctCount;
  final int againCount;
  final int hardCount;
  final int goodCount;
  final int easyCount;
  final int totalTimeSeconds;
  final DateTime startedAt;
  final DateTime completedAt;

  double get accuracy =>
      cardsStudied == 0 ? 0 : correctCount / cardsStudied;
  int get xpEarned =>
      (correctCount * 5 + easyCount * 3 + goodCount * 2).clamp(0, 500);
}
