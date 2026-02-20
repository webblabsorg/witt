import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/content_pack.dart';

// ── Offline sync status ───────────────────────────────────────────────────

class OfflineSyncNotifier extends Notifier<OfflineSyncStatus> {
  @override
  OfflineSyncStatus build() => OfflineSyncStatus(
        isOnline: true,
        lastSyncedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        pendingUploads: 2,
        isSyncing: false,
      );

  void setOnline(bool online) {
    state = state.copyWith(isOnline: online);
  }

  Future<void> sync() async {
    if (!state.isOnline || state.isSyncing) return;
    state = state.copyWith(isSyncing: true);
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(
      isSyncing: false,
      lastSyncedAt: DateTime.now(),
      pendingUploads: 0,
    );
  }
}

final offlineSyncProvider =
    NotifierProvider<OfflineSyncNotifier, OfflineSyncStatus>(
        OfflineSyncNotifier.new);

// ── Content packs ─────────────────────────────────────────────────────────

class ContentPacksNotifier extends Notifier<List<ContentPack>> {
  @override
  List<ContentPack> build() => _catalogPacks;

  Future<void> downloadPack(String packId) async {
    _setPack(packId, (p) => p.copyWith(
          status: ContentPackStatus.downloading,
          downloadProgress: 0.0,
        ));

    // Simulate download progress
    for (var i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      _setPack(packId, (p) => p.copyWith(
            downloadProgress: i / 10.0,
          ));
    }

    _setPack(packId, (p) => p.copyWith(
          status: ContentPackStatus.downloaded,
          downloadProgress: 1.0,
          downloadedAt: DateTime.now(),
        ));
  }

  void deletePack(String packId) {
    _setPack(packId, (p) => p.copyWith(
          status: ContentPackStatus.available,
          downloadProgress: 0.0,
          downloadedAt: null,
        ));
  }

  void _setPack(String packId, ContentPack Function(ContentPack) update) {
    state = state.map((p) => p.id == packId ? update(p) : p).toList();
  }

  List<ContentPack> get downloadedPacks =>
      state.where((p) => p.isDownloaded).toList();

  int get totalDownloadedBytes => downloadedPacks.fold(0, (s, p) => s + p.sizeBytes);
}

final contentPacksProvider =
    NotifierProvider<ContentPacksNotifier, List<ContentPack>>(
        ContentPacksNotifier.new);

final downloadedPacksProvider = Provider<List<ContentPack>>((ref) {
  return ref.watch(contentPacksProvider).where((p) => p.isDownloaded).toList();
});

final totalStorageUsedProvider = Provider<int>((ref) {
  return ref
      .watch(contentPacksProvider)
      .where((p) => p.isDownloaded)
      .fold(0, (s, p) => s + p.sizeBytes);
});

// ── Sample catalog ────────────────────────────────────────────────────────

final List<ContentPack> _catalogPacks = [
  const ContentPack(
    id: 'pack_sat_math',
    examId: 'sat',
    examName: 'SAT',
    examEmoji: '📐',
    title: 'SAT Math — Full Pack',
    description: '800+ practice questions covering all SAT Math topics including algebra, geometry, and data analysis.',
    category: ContentPackCategory.practiceTests,
    sizeBytes: 4 * 1024 * 1024,
    version: '2.1',
    questionCount: 820,
    status: ContentPackStatus.downloaded,
  ),
  const ContentPack(
    id: 'pack_sat_verbal',
    examId: 'sat',
    examName: 'SAT',
    examEmoji: '📐',
    title: 'SAT Reading & Writing',
    description: 'Comprehensive reading comprehension and writing practice for the SAT verbal sections.',
    category: ContentPackCategory.practiceTests,
    sizeBytes: 3 * 1024 * 1024,
    version: '2.0',
    questionCount: 650,
    status: ContentPackStatus.available,
  ),
  const ContentPack(
    id: 'pack_gre_verbal',
    examId: 'gre',
    examName: 'GRE',
    examEmoji: '🎓',
    title: 'GRE Verbal Mastery',
    description: 'High-frequency GRE vocabulary, text completion, and reading comprehension questions.',
    category: ContentPackCategory.vocabulary,
    sizeBytes: 2 * 1024 * 1024,
    version: '1.5',
    questionCount: 400,
    status: ContentPackStatus.available,
  ),
  const ContentPack(
    id: 'pack_gre_quant',
    examId: 'gre',
    examName: 'GRE',
    examEmoji: '🎓',
    title: 'GRE Quantitative Reasoning',
    description: 'Full coverage of GRE quant topics: arithmetic, algebra, geometry, and data interpretation.',
    category: ContentPackCategory.practiceTests,
    sizeBytes: 3500 * 1024,
    version: '1.8',
    questionCount: 500,
    status: ContentPackStatus.updateAvailable,
    isPremium: true,
  ),
  const ContentPack(
    id: 'pack_ielts_vocab',
    examId: 'ielts',
    examName: 'IELTS',
    examEmoji: '🌍',
    title: 'IELTS Academic Vocabulary',
    description: 'Essential academic word list and topic-based vocabulary for IELTS Academic band 7+.',
    category: ContentPackCategory.vocabulary,
    sizeBytes: 1500 * 1024,
    version: '1.2',
    questionCount: 300,
    status: ContentPackStatus.available,
  ),
  const ContentPack(
    id: 'pack_toefl_listening',
    examId: 'toefl',
    examName: 'TOEFL',
    examEmoji: '🎧',
    title: 'TOEFL Listening Practice',
    description: 'Transcripts and comprehension questions for TOEFL listening section preparation.',
    category: ContentPackCategory.studyGuides,
    sizeBytes: 5 * 1024 * 1024,
    version: '1.0',
    questionCount: 200,
    status: ContentPackStatus.available,
    isPremium: true,
  ),
  const ContentPack(
    id: 'pack_sat_flashcards',
    examId: 'sat',
    examName: 'SAT',
    examEmoji: '📐',
    title: 'SAT Vocabulary Flashcards',
    description: '500 high-frequency SAT words with definitions, examples, and memory aids.',
    category: ContentPackCategory.flashcards,
    sizeBytes: 800 * 1024,
    version: '3.0',
    questionCount: 500,
    status: ContentPackStatus.available,
  ),
  const ContentPack(
    id: 'pack_gmat_cr',
    examId: 'gmat',
    examName: 'GMAT',
    examEmoji: '💼',
    title: 'GMAT Critical Reasoning',
    description: 'Structured approach to GMAT Critical Reasoning with 300+ practice questions.',
    category: ContentPackCategory.practiceTests,
    sizeBytes: 2500 * 1024,
    version: '2.2',
    questionCount: 320,
    status: ContentPackStatus.available,
    isPremium: true,
  ),
];
