import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note.dart';

// ── Note CRUD ─────────────────────────────────────────────────────────────

class NoteListNotifier extends Notifier<List<Note>> {
  static const int freeNoteLimit = 10;
  static const int freeWordLimit = 2000;

  @override
  List<Note> build() => [];

  void createNote(Note note) {
    state = [note, ...state];
  }

  void updateNote(Note updated) {
    state = state.map((n) => n.id == updated.id ? updated : n).toList();
  }

  void deleteNote(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  void togglePin(String id) {
    state = state.map((n) {
      if (n.id == id) return n.copyWith(isPinned: !n.isPinned);
      return n;
    }).toList();
  }

  void toggleFavorite(String id) {
    state = state.map((n) {
      if (n.id == id) return n.copyWith(isFavorite: !n.isFavorite);
      return n;
    }).toList();
  }

  void archiveNote(String id) {
    state = state.map((n) {
      if (n.id == id) return n.copyWith(isArchived: true);
      return n;
    }).toList();
  }

  bool canCreateNote(bool isPaidUser) {
    if (isPaidUser) return true;
    final activeNotes = state.where((n) => !n.isArchived).length;
    return activeNotes < freeNoteLimit;
  }

  bool canAddWords(String noteId, int newWordCount, bool isPaidUser) {
    if (isPaidUser) return true;
    final note = state.cast<Note?>().firstWhere(
      (n) => n?.id == noteId,
      orElse: () => null,
    );
    if (note == null) return true;
    return note.wordCount + newWordCount <= freeWordLimit;
  }

  Note? getNote(String id) {
    try {
      return state.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }
}

final noteListProvider = NotifierProvider<NoteListNotifier, List<Note>>(
  NoteListNotifier.new,
);

final noteByIdProvider = Provider.family<Note?, String>((ref, id) {
  return ref
      .watch(noteListProvider)
      .cast<Note?>()
      .firstWhere((n) => n?.id == id, orElse: () => null);
});

final pinnedNotesProvider = Provider<List<Note>>((ref) {
  return ref
      .watch(noteListProvider)
      .where((n) => n.isPinned && !n.isArchived)
      .toList();
});

final activeNotesProvider = Provider<List<Note>>((ref) {
  return ref.watch(noteListProvider).where((n) => !n.isArchived).toList();
});

// ── Note editor state ─────────────────────────────────────────────────────

class NoteEditorState {
  const NoteEditorState({
    required this.noteId,
    required this.title,
    required this.content,
    required this.format,
    required this.isDirty,
    required this.isSaving,
    required this.wordCount,
    this.lastSavedAt,
  });

  final String noteId;
  final String title;
  final String content;
  final NoteFormat format;
  final bool isDirty;
  final bool isSaving;
  final int wordCount;
  final DateTime? lastSavedAt;

  NoteEditorState copyWith({
    String? noteId,
    String? title,
    String? content,
    NoteFormat? format,
    bool? isDirty,
    bool? isSaving,
    int? wordCount,
    DateTime? lastSavedAt,
  }) => NoteEditorState(
    noteId: noteId ?? this.noteId,
    title: title ?? this.title,
    content: content ?? this.content,
    format: format ?? this.format,
    isDirty: isDirty ?? this.isDirty,
    isSaving: isSaving ?? this.isSaving,
    wordCount: wordCount ?? this.wordCount,
    lastSavedAt: lastSavedAt ?? this.lastSavedAt,
  );
}

class NoteEditorNotifier extends FamilyNotifier<NoteEditorState?, String> {
  @override
  NoteEditorState? build(String noteId) {
    final note = ref.read(noteListProvider.notifier).getNote(noteId);
    if (note == null) return null;
    return NoteEditorState(
      noteId: noteId,
      title: note.title,
      content: note.content,
      format: note.format,
      isDirty: false,
      isSaving: false,
      wordCount: note.wordCount,
    );
  }

  void updateTitle(String title) {
    final s = state;
    if (s == null) return;
    state = s.copyWith(title: title, isDirty: true);
  }

  void updateContent(String content) {
    final s = state;
    if (s == null) return;
    final words = content.trim().isEmpty
        ? 0
        : content.trim().split(RegExp(r'\s+')).length;
    state = s.copyWith(content: content, isDirty: true, wordCount: words);
  }

  void save() {
    final s = state;
    if (s == null || !s.isDirty) return;
    state = s.copyWith(isSaving: true);

    final existing = ref.read(noteListProvider.notifier).getNote(s.noteId);
    if (existing != null) {
      ref
          .read(noteListProvider.notifier)
          .updateNote(
            existing.copyWith(
              title: s.title,
              content: s.content,
              wordCount: s.wordCount,
              updatedAt: DateTime.now(),
            ),
          );
    }

    state = s.copyWith(
      isDirty: false,
      isSaving: false,
      lastSavedAt: DateTime.now(),
    );
  }
}

final noteEditorProvider =
    NotifierProviderFamily<NoteEditorNotifier, NoteEditorState?, String>(
      NoteEditorNotifier.new,
    );
