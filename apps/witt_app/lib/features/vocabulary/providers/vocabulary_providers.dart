import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vocabulary.dart';
import '../../flashcards/models/flashcard.dart';

// ── Free tier limits ──────────────────────────────────────────────────────

const int freeVocabListLimit = 3;
const int freeWordsPerListLimit = 25;

// ── Word of the Day ───────────────────────────────────────────────────────

final wordOfDayProvider = Provider<VocabWord>((ref) => _wordOfDay);

// ── Dictionary search ─────────────────────────────────────────────────────

class DictionarySearchNotifier extends Notifier<DictionarySearchState> {
  @override
  DictionarySearchState build() => const DictionarySearchState(
    query: '',
    results: [],
    isLoading: false,
    currentWord: null,
  );

  void search(String query) {
    if (query.trim().isEmpty) {
      state = state.copyWith(query: '', results: [], currentWord: null);
      return;
    }
    state = state.copyWith(query: query, isLoading: true);

    // Phase 2: stub — search local dictionary
    final results = _localDictionary
        .where((w) => w.word.toLowerCase().contains(query.toLowerCase()))
        .toList();

    state = state.copyWith(
      results: results,
      isLoading: false,
      currentWord: results.isNotEmpty ? results.first : null,
    );
  }

  void selectWord(VocabWord word) {
    state = state.copyWith(currentWord: word);
  }

  void clear() {
    state = const DictionarySearchState(
      query: '',
      results: [],
      isLoading: false,
      currentWord: null,
    );
  }
}

class DictionarySearchState {
  const DictionarySearchState({
    required this.query,
    required this.results,
    required this.isLoading,
    required this.currentWord,
  });

  final String query;
  final List<VocabWord> results;
  final bool isLoading;
  final VocabWord? currentWord;

  DictionarySearchState copyWith({
    String? query,
    List<VocabWord>? results,
    bool? isLoading,
    VocabWord? currentWord,
  }) => DictionarySearchState(
    query: query ?? this.query,
    results: results ?? this.results,
    isLoading: isLoading ?? this.isLoading,
    currentWord: currentWord ?? this.currentWord,
  );
}

final dictionarySearchProvider =
    NotifierProvider<DictionarySearchNotifier, DictionarySearchState>(
      DictionarySearchNotifier.new,
    );

// ── Saved words ───────────────────────────────────────────────────────────

class SavedWordsNotifier extends Notifier<List<VocabWord>> {
  @override
  List<VocabWord> build() => [];

  void saveWord(VocabWord word) {
    if (state.any((w) => w.id == word.id)) return;
    state = [word.copyWith(isSaved: true, savedAt: DateTime.now()), ...state];
  }

  void removeWord(String wordId) {
    state = state.where((w) => w.id != wordId).toList();
  }

  bool isSaved(String wordId) => state.any((w) => w.id == wordId);

  /// Auto-generate flashcards from saved words.
  List<Flashcard> generateFlashcards({
    required String deckId,
    required List<String> wordIds,
  }) {
    final words = state.where((w) => wordIds.contains(w.id)).toList();
    return words
        .map(
          (w) => Flashcard(
            id: 'vocab_${w.id}_${DateTime.now().millisecondsSinceEpoch}',
            deckId: deckId,
            type: FlashcardType.basic,
            front: w.word,
            back: w.primaryDefinition,
            hint:
                w.definitions.isNotEmpty && w.definitions.first.example != null
                ? w.definitions.first.example
                : null,
            tags: ['vocabulary', ...w.tags],
            createdAt: DateTime.now(),
          ),
        )
        .toList();
  }
}

final savedWordsProvider =
    NotifierProvider<SavedWordsNotifier, List<VocabWord>>(
      SavedWordsNotifier.new,
    );

// ── Vocab lists ───────────────────────────────────────────────────────────

class VocabListNotifier extends Notifier<List<VocabList>> {
  @override
  List<VocabList> build() => [];

  void createList(VocabList list) {
    state = [list, ...state];
  }

  void updateList(VocabList updated) {
    state = state.map((l) => l.id == updated.id ? updated : l).toList();
  }

  void deleteList(String id) {
    state = state.where((l) => l.id != id).toList();
  }

  void addWordToList(String listId, String wordId) {
    state = state.map((l) {
      if (l.id == listId && !l.wordIds.contains(wordId)) {
        return l.copyWith(wordIds: [...l.wordIds, wordId]);
      }
      return l;
    }).toList();
  }

  void removeWordFromList(String listId, String wordId) {
    state = state.map((l) {
      if (l.id == listId) {
        return l.copyWith(
          wordIds: l.wordIds.where((id) => id != wordId).toList(),
        );
      }
      return l;
    }).toList();
  }

  bool canCreateList(bool isPaidUser) {
    if (isPaidUser) return true;
    return state.length < freeVocabListLimit;
  }
}

final vocabListProvider = NotifierProvider<VocabListNotifier, List<VocabList>>(
  VocabListNotifier.new,
);

// ── Auto-flashcard generation ─────────────────────────────────────────────

final autoFlashcardGenProvider = Provider.family<List<Flashcard>, String>((
  ref,
  listId,
) {
  final list = ref
      .watch(vocabListProvider)
      .cast<VocabList?>()
      .firstWhere((l) => l?.id == listId, orElse: () => null);
  if (list == null) return const [];
  final savedWords = ref.watch(savedWordsProvider);
  return savedWords
      .where((w) => list.wordIds.contains(w.id))
      .map(
        (w) => Flashcard(
          id: 'auto_${w.id}',
          deckId: 'auto_$listId',
          type: FlashcardType.basic,
          front: w.word,
          back: w.primaryDefinition,
          hint: w.definitions.isNotEmpty ? w.definitions.first.example : null,
          tags: ['auto-generated', 'vocabulary'],
          createdAt: DateTime.now(),
        ),
      )
      .toList();
});

// ── Sample data ───────────────────────────────────────────────────────────

final VocabWord _wordOfDay = VocabWord(
  id: 'wod_today',
  word: 'Perspicacious',
  definitions: const [
    WordDefinition(
      partOfSpeech: PartOfSpeech.adjective,
      definition: 'Having a ready insight into things; shrewd and discerning.',
      example: 'A perspicacious observer would have noticed the subtle clues.',
      synonyms: ['shrewd', 'astute', 'discerning', 'perceptive'],
      antonyms: ['obtuse', 'imperceptive', 'unperceptive'],
    ),
  ],
  pronunciation: '/ˌpɜːspɪˈkeɪʃəs/',
  difficulty: WordDifficulty.advanced,
  frequency: 1200,
  etymology:
      'From Latin perspicax (sharp-sighted), from perspicere (to see through).',
  tags: const ['SAT', 'GRE', 'Academic'],
  isWordOfDay: true,
);

final List<VocabWord> _localDictionary = [
  _wordOfDay,
  VocabWord(
    id: 'word_ephemeral',
    word: 'Ephemeral',
    definitions: const [
      WordDefinition(
        partOfSpeech: PartOfSpeech.adjective,
        definition: 'Lasting for a very short time.',
        example: 'The ephemeral beauty of cherry blossoms.',
        synonyms: ['transient', 'fleeting', 'momentary', 'brief'],
        antonyms: ['permanent', 'lasting', 'enduring'],
      ),
    ],
    pronunciation: '/ɪˈfem(ə)r(ə)l/',
    difficulty: WordDifficulty.intermediate,
    frequency: 3500,
    tags: const ['SAT', 'GRE'],
  ),
  VocabWord(
    id: 'word_ubiquitous',
    word: 'Ubiquitous',
    definitions: const [
      WordDefinition(
        partOfSpeech: PartOfSpeech.adjective,
        definition: 'Present, appearing, or found everywhere.',
        example: 'Mobile phones are now ubiquitous in modern society.',
        synonyms: ['omnipresent', 'pervasive', 'universal'],
        antonyms: ['rare', 'scarce', 'uncommon'],
      ),
    ],
    pronunciation: '/juːˈbɪkwɪtəs/',
    difficulty: WordDifficulty.intermediate,
    frequency: 5200,
    tags: const ['SAT', 'GRE', 'IELTS'],
  ),
  VocabWord(
    id: 'word_ameliorate',
    word: 'Ameliorate',
    definitions: const [
      WordDefinition(
        partOfSpeech: PartOfSpeech.verb,
        definition: 'Make (something bad or unsatisfactory) better.',
        example:
            'The new policy was designed to ameliorate the housing crisis.',
        synonyms: ['improve', 'better', 'enhance', 'alleviate'],
        antonyms: ['worsen', 'aggravate', 'exacerbate'],
      ),
    ],
    pronunciation: '/əˈmiːlɪəreɪt/',
    difficulty: WordDifficulty.advanced,
    frequency: 1800,
    tags: const ['SAT', 'GRE'],
  ),
  VocabWord(
    id: 'word_verbose',
    word: 'Verbose',
    definitions: const [
      WordDefinition(
        partOfSpeech: PartOfSpeech.adjective,
        definition: 'Using or expressed in more words than are needed.',
        example: 'The verbose report could have been summarised in one page.',
        synonyms: ['wordy', 'long-winded', 'prolix', 'garrulous'],
        antonyms: ['concise', 'succinct', 'terse', 'brief'],
      ),
    ],
    pronunciation: '/vɜːˈbəʊs/',
    difficulty: WordDifficulty.intermediate,
    frequency: 2900,
    tags: const ['SAT', 'IELTS', 'TOEFL'],
  ),
];

