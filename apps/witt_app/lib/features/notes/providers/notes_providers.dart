import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note.dart';

// ── Note CRUD ─────────────────────────────────────────────────────────────

class NoteListNotifier extends Notifier<List<Note>> {
  static const int freeNoteLimit = 10;
  static const int freeWordLimit = 2000;

  @override
  List<Note> build() => _sampleNotes;

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

// ── Sample data ───────────────────────────────────────────────────────────

final List<Note> _sampleNotes = [
  Note(
    id: 'note_1',
    userId: 'local_user',
    title: 'SAT Math — Key Formulas',
    content: '''# SAT Math Key Formulas

## Algebra
- Quadratic formula: x = (-b ± √(b²-4ac)) / 2a
- Slope: m = (y₂-y₁)/(x₂-x₁)
- Distance: d = √((x₂-x₁)² + (y₂-y₁)²)

## Geometry
- Circle area: A = πr²
- Cylinder volume: V = πr²h
- Pythagorean theorem: a² + b² = c²

## Statistics
- Mean = sum / count
- Median = middle value
- Mode = most frequent value''',
    format: NoteFormat.markdown,
    template: NoteTemplate.studyGuide,
    examId: 'sat',
    subject: 'Mathematics',
    wordCount: 87,
    isPinned: true,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  Note(
    id: 'note_2',
    userId: 'local_user',
    title: 'WAEC Biology — Cell Structure',
    content: '''# Cell Structure Notes

## Animal Cell Organelles
- **Nucleus**: Controls cell activities, contains DNA
- **Mitochondria**: ATP production (powerhouse)
- **Ribosomes**: Protein synthesis
- **Endoplasmic Reticulum**: Transport network
- **Golgi Apparatus**: Packaging and secretion

## Plant Cell (additional)
- **Cell Wall**: Rigid structure, cellulose
- **Chloroplasts**: Photosynthesis
- **Large Vacuole**: Water storage and support

## Key Differences
| Feature | Animal | Plant |
|---------|--------|-------|
| Cell wall | No | Yes |
| Chloroplasts | No | Yes |
| Vacuole | Small | Large |''',
    format: NoteFormat.markdown,
    template: NoteTemplate.cornell,
    examId: 'waec',
    subject: 'Biology',
    wordCount: 112,
    isFavorite: true,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  Note(
    id: 'note_3',
    userId: 'local_user',
    title: "JEE Physics — Newton's Laws",
    content: '''# Newton's Laws of Motion

## First Law (Inertia)
An object at rest stays at rest, and an object in motion stays in motion, unless acted upon by an external force.

## Second Law
F = ma
Force = mass × acceleration

## Third Law
For every action, there is an equal and opposite reaction.

## Applications
- Rocket propulsion (3rd law)
- Car braking (1st law)
- Weight on a scale (2nd law)''',
    format: NoteFormat.markdown,
    examId: 'jee_main',
    subject: 'Physics',
    wordCount: 89,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
  ),
];
