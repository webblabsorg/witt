import 'package:flutter/foundation.dart';

enum NoteFormat { plainText, markdown, richText }

enum NoteTemplate {
  blank,
  cornell,
  outline,
  mindMap,
  studyGuide,
  flashcardGen,
}

@immutable
class NoteTag {
  const NoteTag({required this.id, required this.name, required this.color});
  final String id;
  final String name;
  final int color;

  factory NoteTag.fromJson(Map<String, dynamic> json) => NoteTag(
        id: json['id'] as String,
        name: json['name'] as String,
        color: json['color'] as int? ?? 0xFF4F46E5,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'color': color};
}

@immutable
class Note {
  const Note({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.format,
    this.template = NoteTemplate.blank,
    this.examId,
    this.subject,
    this.tags = const [],
    this.wordCount = 0,
    this.isPinned = false,
    this.isArchived = false,
    this.isFavorite = false,
    this.isOfflineCached = false,
    this.createdAt,
    this.updatedAt,
    this.lastExportedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String content;
  final NoteFormat format;
  final NoteTemplate template;
  final String? examId;
  final String? subject;
  final List<NoteTag> tags;
  final int wordCount;
  final bool isPinned;
  final bool isArchived;
  final bool isFavorite;
  final bool isOfflineCached;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastExportedAt;

  int get estimatedReadMinutes => (wordCount / 200).ceil().clamp(1, 60);

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        format: NoteFormat.values.firstWhere(
          (e) => e.name == json['format'],
          orElse: () => NoteFormat.richText,
        ),
        template: NoteTemplate.values.firstWhere(
          (e) => e.name == json['template'],
          orElse: () => NoteTemplate.blank,
        ),
        examId: json['exam_id'] as String?,
        subject: json['subject'] as String?,
        tags: (json['tags'] as List<dynamic>? ?? [])
            .map((t) => NoteTag.fromJson(t as Map<String, dynamic>))
            .toList(),
        wordCount: json['word_count'] as int? ?? 0,
        isPinned: json['is_pinned'] as bool? ?? false,
        isArchived: json['is_archived'] as bool? ?? false,
        isFavorite: json['is_favorite'] as bool? ?? false,
        isOfflineCached: json['is_offline_cached'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
        lastExportedAt: json['last_exported_at'] != null
            ? DateTime.parse(json['last_exported_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'content': content,
        'format': format.name,
        'template': template.name,
        if (examId != null) 'exam_id': examId,
        if (subject != null) 'subject': subject,
        'tags': tags.map((t) => t.toJson()).toList(),
        'word_count': wordCount,
        'is_pinned': isPinned,
        'is_archived': isArchived,
        'is_favorite': isFavorite,
        'is_offline_cached': isOfflineCached,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
        if (lastExportedAt != null)
          'last_exported_at': lastExportedAt!.toIso8601String(),
      };

  Note copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    NoteFormat? format,
    NoteTemplate? template,
    String? examId,
    String? subject,
    List<NoteTag>? tags,
    int? wordCount,
    bool? isPinned,
    bool? isArchived,
    bool? isFavorite,
    bool? isOfflineCached,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastExportedAt,
  }) =>
      Note(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        content: content ?? this.content,
        format: format ?? this.format,
        template: template ?? this.template,
        examId: examId ?? this.examId,
        subject: subject ?? this.subject,
        tags: tags ?? this.tags,
        wordCount: wordCount ?? this.wordCount,
        isPinned: isPinned ?? this.isPinned,
        isArchived: isArchived ?? this.isArchived,
        isFavorite: isFavorite ?? this.isFavorite,
        isOfflineCached: isOfflineCached ?? this.isOfflineCached,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastExportedAt: lastExportedAt ?? this.lastExportedAt,
      );
}
