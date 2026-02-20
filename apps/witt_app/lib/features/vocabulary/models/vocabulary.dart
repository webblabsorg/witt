import 'package:flutter/foundation.dart';

enum WordDifficulty { beginner, intermediate, advanced, expert }

enum PartOfSpeech {
  noun,
  verb,
  adjective,
  adverb,
  pronoun,
  preposition,
  conjunction,
  interjection,
  article,
}

@immutable
class WordDefinition {
  const WordDefinition({
    required this.partOfSpeech,
    required this.definition,
    this.example,
    this.synonyms = const [],
    this.antonyms = const [],
  });

  final PartOfSpeech partOfSpeech;
  final String definition;
  final String? example;
  final List<String> synonyms;
  final List<String> antonyms;

  factory WordDefinition.fromJson(Map<String, dynamic> json) => WordDefinition(
        partOfSpeech: PartOfSpeech.values.firstWhere(
          (e) => e.name == json['part_of_speech'],
          orElse: () => PartOfSpeech.noun,
        ),
        definition: json['definition'] as String,
        example: json['example'] as String?,
        synonyms: List<String>.from(json['synonyms'] ?? []),
        antonyms: List<String>.from(json['antonyms'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'part_of_speech': partOfSpeech.name,
        'definition': definition,
        if (example != null) 'example': example,
        'synonyms': synonyms,
        'antonyms': antonyms,
      };
}

@immutable
class VocabWord {
  const VocabWord({
    required this.id,
    required this.word,
    required this.definitions,
    this.pronunciation,
    this.audioUrl,
    this.imageUrl,
    this.difficulty = WordDifficulty.intermediate,
    this.frequency = 0,
    this.etymology,
    this.tags = const [],
    this.isSaved = false,
    this.isWordOfDay = false,
    this.savedAt,
  });

  final String id;
  final String word;
  final List<WordDefinition> definitions;
  final String? pronunciation;
  final String? audioUrl;
  final String? imageUrl;
  final WordDifficulty difficulty;
  final int frequency;
  final String? etymology;
  final List<String> tags;
  final bool isSaved;
  final bool isWordOfDay;
  final DateTime? savedAt;

  String get primaryDefinition =>
      definitions.isNotEmpty ? definitions.first.definition : '';

  String get primaryPartOfSpeech =>
      definitions.isNotEmpty ? definitions.first.partOfSpeech.name : '';

  factory VocabWord.fromJson(Map<String, dynamic> json) => VocabWord(
        id: json['id'] as String,
        word: json['word'] as String,
        definitions: (json['definitions'] as List<dynamic>? ?? [])
            .map((d) => WordDefinition.fromJson(d as Map<String, dynamic>))
            .toList(),
        pronunciation: json['pronunciation'] as String?,
        audioUrl: json['audio_url'] as String?,
        imageUrl: json['image_url'] as String?,
        difficulty: WordDifficulty.values.firstWhere(
          (e) => e.name == json['difficulty'],
          orElse: () => WordDifficulty.intermediate,
        ),
        frequency: json['frequency'] as int? ?? 0,
        etymology: json['etymology'] as String?,
        tags: List<String>.from(json['tags'] ?? []),
        isSaved: json['is_saved'] as bool? ?? false,
        isWordOfDay: json['is_word_of_day'] as bool? ?? false,
        savedAt: json['saved_at'] != null
            ? DateTime.parse(json['saved_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'definitions': definitions.map((d) => d.toJson()).toList(),
        if (pronunciation != null) 'pronunciation': pronunciation,
        if (audioUrl != null) 'audio_url': audioUrl,
        if (imageUrl != null) 'image_url': imageUrl,
        'difficulty': difficulty.name,
        'frequency': frequency,
        if (etymology != null) 'etymology': etymology,
        'tags': tags,
        'is_saved': isSaved,
        'is_word_of_day': isWordOfDay,
        if (savedAt != null) 'saved_at': savedAt!.toIso8601String(),
      };

  VocabWord copyWith({
    String? id,
    String? word,
    List<WordDefinition>? definitions,
    String? pronunciation,
    String? audioUrl,
    String? imageUrl,
    WordDifficulty? difficulty,
    int? frequency,
    String? etymology,
    List<String>? tags,
    bool? isSaved,
    bool? isWordOfDay,
    DateTime? savedAt,
  }) =>
      VocabWord(
        id: id ?? this.id,
        word: word ?? this.word,
        definitions: definitions ?? this.definitions,
        pronunciation: pronunciation ?? this.pronunciation,
        audioUrl: audioUrl ?? this.audioUrl,
        imageUrl: imageUrl ?? this.imageUrl,
        difficulty: difficulty ?? this.difficulty,
        frequency: frequency ?? this.frequency,
        etymology: etymology ?? this.etymology,
        tags: tags ?? this.tags,
        isSaved: isSaved ?? this.isSaved,
        isWordOfDay: isWordOfDay ?? this.isWordOfDay,
        savedAt: savedAt ?? this.savedAt,
      );
}

@immutable
class VocabList {
  const VocabList({
    required this.id,
    required this.name,
    required this.userId,
    this.description = '',
    this.emoji = '📝',
    this.examId,
    this.subject,
    this.wordIds = const [],
    this.isPublic = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String userId;
  final String description;
  final String emoji;
  final String? examId;
  final String? subject;
  final List<String> wordIds;
  final bool isPublic;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get wordCount => wordIds.length;

  factory VocabList.fromJson(Map<String, dynamic> json) => VocabList(
        id: json['id'] as String,
        name: json['name'] as String,
        userId: json['user_id'] as String,
        description: json['description'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '📝',
        examId: json['exam_id'] as String?,
        subject: json['subject'] as String?,
        wordIds: List<String>.from(json['word_ids'] ?? []),
        isPublic: json['is_public'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'user_id': userId,
        'description': description,
        'emoji': emoji,
        if (examId != null) 'exam_id': examId,
        if (subject != null) 'subject': subject,
        'word_ids': wordIds,
        'is_public': isPublic,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  VocabList copyWith({
    String? id,
    String? name,
    String? userId,
    String? description,
    String? emoji,
    String? examId,
    String? subject,
    List<String>? wordIds,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      VocabList(
        id: id ?? this.id,
        name: name ?? this.name,
        userId: userId ?? this.userId,
        description: description ?? this.description,
        emoji: emoji ?? this.emoji,
        examId: examId ?? this.examId,
        subject: subject ?? this.subject,
        wordIds: wordIds ?? this.wordIds,
        isPublic: isPublic ?? this.isPublic,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
