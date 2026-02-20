import 'package:flutter/foundation.dart';

enum ContentPackStatus {
  available,
  downloading,
  downloaded,
  updateAvailable,
  error,
}

enum ContentPackCategory {
  examPrep,
  vocabulary,
  flashcards,
  practiceTests,
  studyGuides,
}

@immutable
class ContentPack {
  const ContentPack({
    required this.id,
    required this.examId,
    required this.examName,
    required this.examEmoji,
    required this.title,
    required this.description,
    required this.category,
    required this.sizeBytes,
    required this.version,
    required this.questionCount,
    required this.status,
    this.downloadedAt,
    this.downloadProgress = 0.0,
    this.isPremium = false,
  });

  final String id;
  final String examId;
  final String examName;
  final String examEmoji;
  final String title;
  final String description;
  final ContentPackCategory category;
  final int sizeBytes;
  final String version;
  final int questionCount;
  final ContentPackStatus status;
  final DateTime? downloadedAt;
  final double downloadProgress;
  final bool isPremium;

  String get sizeLabel {
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isDownloaded => status == ContentPackStatus.downloaded;
  bool get isDownloading => status == ContentPackStatus.downloading;

  ContentPack copyWith({
    String? id,
    String? examId,
    String? examName,
    String? examEmoji,
    String? title,
    String? description,
    ContentPackCategory? category,
    int? sizeBytes,
    String? version,
    int? questionCount,
    ContentPackStatus? status,
    DateTime? downloadedAt,
    double? downloadProgress,
    bool? isPremium,
  }) =>
      ContentPack(
        id: id ?? this.id,
        examId: examId ?? this.examId,
        examName: examName ?? this.examName,
        examEmoji: examEmoji ?? this.examEmoji,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        version: version ?? this.version,
        questionCount: questionCount ?? this.questionCount,
        status: status ?? this.status,
        downloadedAt: downloadedAt ?? this.downloadedAt,
        downloadProgress: downloadProgress ?? this.downloadProgress,
        isPremium: isPremium ?? this.isPremium,
      );
}

@immutable
class OfflineSyncStatus {
  const OfflineSyncStatus({
    required this.isOnline,
    required this.lastSyncedAt,
    required this.pendingUploads,
    required this.isSyncing,
  });

  final bool isOnline;
  final DateTime? lastSyncedAt;
  final int pendingUploads;
  final bool isSyncing;

  OfflineSyncStatus copyWith({
    bool? isOnline,
    DateTime? lastSyncedAt,
    int? pendingUploads,
    bool? isSyncing,
  }) =>
      OfflineSyncStatus(
        isOnline: isOnline ?? this.isOnline,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        pendingUploads: pendingUploads ?? this.pendingUploads,
        isSyncing: isSyncing ?? this.isSyncing,
      );
}
