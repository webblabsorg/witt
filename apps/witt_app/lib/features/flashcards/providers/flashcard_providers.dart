import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flashcard.dart';
import '../services/sm2_algorithm.dart';
import '../../progress/providers/progress_providers.dart';

// ── Deck CRUD ─────────────────────────────────────────────────────────────

class DeckListNotifier extends Notifier<List<FlashcardDeck>> {
  @override
  List<FlashcardDeck> build() => _sampleDecks;

  void createDeck(FlashcardDeck deck) {
    state = [deck, ...state];
  }

  void updateDeck(FlashcardDeck updated) {
    state = state.map((d) => d.id == updated.id ? updated : d).toList();
  }

  void deleteDeck(String deckId) {
    state = state.where((d) => d.id != deckId).toList();
  }

  FlashcardDeck? getDeck(String id) {
    try {
      return state.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}

final deckListProvider =
    NotifierProvider<DeckListNotifier, List<FlashcardDeck>>(
      DeckListNotifier.new,
    );

final deckByIdProvider = Provider.family<FlashcardDeck?, String>((ref, id) {
  return ref
      .watch(deckListProvider)
      .cast<FlashcardDeck?>()
      .firstWhere((d) => d?.id == id, orElse: () => null);
});

// ── Card CRUD ─────────────────────────────────────────────────────────────

class CardListNotifier extends Notifier<Map<String, List<Flashcard>>> {
  @override
  Map<String, List<Flashcard>> build() => _sampleCards;

  List<Flashcard> cardsForDeck(String deckId) => state[deckId] ?? const [];

  void addCard(Flashcard card) {
    final current = List<Flashcard>.from(state[card.deckId] ?? []);
    current.add(card);
    state = {...state, card.deckId: current};
    _updateDeckCounts(card.deckId);
  }

  void updateCard(Flashcard updated) {
    final current = List<Flashcard>.from(state[updated.deckId] ?? []);
    final idx = current.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      current[idx] = updated;
      state = {...state, updated.deckId: current};
      _updateDeckCounts(updated.deckId);
    }
  }

  void deleteCard(String deckId, String cardId) {
    final current = List<Flashcard>.from(state[deckId] ?? []);
    current.removeWhere((c) => c.id == cardId);
    state = {...state, deckId: current};
    _updateDeckCounts(deckId);
  }

  void applyReview({
    required String deckId,
    required String cardId,
    required Sm2Rating rating,
  }) {
    final cards = List<Flashcard>.from(state[deckId] ?? []);
    final idx = cards.indexWhere((c) => c.id == cardId);
    if (idx == -1) return;

    final updated = Sm2Algorithm.review(
      card: cards[idx],
      rating: rating,
      reviewedAt: DateTime.now(),
    );
    cards[idx] = updated;
    state = {...state, deckId: cards};
    _updateDeckCounts(deckId);
  }

  void _updateDeckCounts(String deckId) {
    // Notify deck list to refresh counts
  }

  /// Import cards from CSV/TSV string.
  /// Expected format: front\tback[\thint]
  List<Flashcard> importFromCsv({
    required String deckId,
    required String content,
    String delimiter = '\t',
  }) {
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty);
    final imported = <Flashcard>[];
    int i = 0;
    for (final line in lines) {
      final parts = line.split(delimiter);
      if (parts.length < 2) continue;
      final card = Flashcard(
        id: '${deckId}_import_${DateTime.now().millisecondsSinceEpoch}_$i',
        deckId: deckId,
        type: FlashcardType.basic,
        front: parts[0].trim(),
        back: parts[1].trim(),
        hint: parts.length > 2 ? parts[2].trim() : null,
        createdAt: DateTime.now(),
      );
      imported.add(card);
      i++;
    }
    final current = List<Flashcard>.from(state[deckId] ?? []);
    current.addAll(imported);
    state = {...state, deckId: current};
    return imported;
  }

  /// Export cards to TSV string.
  String exportToCsv(String deckId, {String delimiter = '\t'}) {
    final cards = state[deckId] ?? [];
    return cards
        .map((c) => [c.front, c.back, c.hint ?? ''].join(delimiter))
        .join('\n');
  }
}

final cardListProvider =
    NotifierProvider<CardListNotifier, Map<String, List<Flashcard>>>(
      CardListNotifier.new,
    );

final cardsForDeckProvider = Provider.family<List<Flashcard>, String>((
  ref,
  deckId,
) {
  return ref.watch(cardListProvider)[deckId] ?? const [];
});

final dueCardsForDeckProvider = Provider.family<List<Flashcard>, String>((
  ref,
  deckId,
) {
  return (ref.watch(cardListProvider)[deckId] ?? [])
      .where((c) => c.isDue)
      .toList();
});

// ── Study session state ───────────────────────────────────────────────────

enum StudySessionStatus { idle, active, complete }

class StudySessionState {
  const StudySessionState({
    required this.deckId,
    required this.mode,
    required this.status,
    required this.queue,
    required this.currentIndex,
    required this.isFlipped,
    required this.ratings,
    required this.startedAt,
    this.typedAnswer = '',
    this.matchPairs = const [],
    this.matchSelected,
    this.matchCompleted = const [],
  });

  final String deckId;
  final StudyMode mode;
  final StudySessionStatus status;
  final List<Flashcard> queue;
  final int currentIndex;
  final bool isFlipped;
  final List<Sm2Rating> ratings;
  final DateTime startedAt;
  final String typedAnswer;
  final List<MatchPair> matchPairs;
  final String? matchSelected;
  final List<String> matchCompleted;

  Flashcard? get currentCard =>
      currentIndex < queue.length ? queue[currentIndex] : null;

  bool get isLast => currentIndex + 1 >= queue.length;
  int get correctCount =>
      ratings.where((r) => r == Sm2Rating.good || r == Sm2Rating.easy).length;
  int get totalTimeSeconds => DateTime.now().difference(startedAt).inSeconds;

  StudySessionState copyWith({
    String? deckId,
    StudyMode? mode,
    StudySessionStatus? status,
    List<Flashcard>? queue,
    int? currentIndex,
    bool? isFlipped,
    List<Sm2Rating>? ratings,
    DateTime? startedAt,
    String? typedAnswer,
    List<MatchPair>? matchPairs,
    String? matchSelected,
    List<String>? matchCompleted,
  }) => StudySessionState(
    deckId: deckId ?? this.deckId,
    mode: mode ?? this.mode,
    status: status ?? this.status,
    queue: queue ?? this.queue,
    currentIndex: currentIndex ?? this.currentIndex,
    isFlipped: isFlipped ?? this.isFlipped,
    ratings: ratings ?? this.ratings,
    startedAt: startedAt ?? this.startedAt,
    typedAnswer: typedAnswer ?? this.typedAnswer,
    matchPairs: matchPairs ?? this.matchPairs,
    matchSelected: matchSelected ?? this.matchSelected,
    matchCompleted: matchCompleted ?? this.matchCompleted,
  );
}

class MatchPair {
  const MatchPair({
    required this.id,
    required this.front,
    required this.back,
    required this.isMatched,
  });
  final String id;
  final String front;
  final String back;
  final bool isMatched;
}

class StudySessionNotifier extends Notifier<StudySessionState?> {
  @override
  StudySessionState? build() => null;

  void startSession({
    required String deckId,
    required StudyMode mode,
    required List<Flashcard> cards,
    int newCardsPerSession = 20,
    int reviewCardsPerSession = 100,
  }) {
    final studyQueue = Sm2Algorithm.buildQueue(
      cards: cards,
      newCardsPerSession: newCardsPerSession,
      reviewCardsPerSession: reviewCardsPerSession,
    );

    List<Flashcard> queue;
    if (mode == StudyMode.flashcard || mode == StudyMode.learn) {
      queue = studyQueue.isEmpty ? cards.take(20).toList() : studyQueue.cards;
    } else {
      queue = cards.take(20).toList();
    }

    if (queue.isEmpty) return;

    List<MatchPair> matchPairs = [];
    if (mode == StudyMode.match) {
      matchPairs = queue
          .take(6)
          .map(
            (c) => MatchPair(
              id: c.id,
              front: c.front,
              back: c.back,
              isMatched: false,
            ),
          )
          .toList();
    }

    state = StudySessionState(
      deckId: deckId,
      mode: mode,
      status: StudySessionStatus.active,
      queue: queue,
      currentIndex: 0,
      isFlipped: false,
      ratings: const [],
      startedAt: DateTime.now(),
      matchPairs: matchPairs,
    );
  }

  void flip() {
    final s = state;
    if (s == null) return;
    state = s.copyWith(isFlipped: !s.isFlipped);
  }

  void rate(Sm2Rating rating) {
    final s = state;
    if (s == null || s.currentCard == null) return;

    // Apply SM-2 review
    ref
        .read(cardListProvider.notifier)
        .applyReview(
          deckId: s.deckId,
          cardId: s.currentCard!.id,
          rating: rating,
        );

    // Progress instrumentation
    ref.read(dailyActivityProvider.notifier).recordFlashcard();
    if (rating == Sm2Rating.good || rating == Sm2Rating.easy) {
      ref.read(xpProvider.notifier).addXp(5);
    }

    final newRatings = [...s.ratings, rating];

    if (s.isLast) {
      state = s.copyWith(
        ratings: newRatings,
        status: StudySessionStatus.complete,
      );
      ref.read(badgeProvider.notifier).checkAndAward(ref);
    } else {
      state = s.copyWith(
        currentIndex: s.currentIndex + 1,
        isFlipped: false,
        ratings: newRatings,
        typedAnswer: '',
      );
    }
  }

  void updateTypedAnswer(String answer) {
    final s = state;
    if (s == null) return;
    state = s.copyWith(typedAnswer: answer);
  }

  void submitTypedAnswer() {
    final s = state;
    if (s == null || s.currentCard == null) return;
    final correct =
        s.typedAnswer.trim().toLowerCase() ==
        s.currentCard!.back.trim().toLowerCase();
    rate(correct ? Sm2Rating.good : Sm2Rating.again);
  }

  void selectMatchItem(String id) {
    final s = state;
    if (s == null) return;

    if (s.matchSelected == null) {
      state = s.copyWith(matchSelected: id);
      return;
    }

    // Check if it's a matching pair
    final first = s.matchPairs.firstWhere(
      (p) => p.id == s.matchSelected || '${p.id}_back' == s.matchSelected,
      orElse: () =>
          const MatchPair(id: '', front: '', back: '', isMatched: false),
    );
    final second = s.matchPairs.firstWhere(
      (p) => p.id == id || '${p.id}_back' == id,
      orElse: () =>
          const MatchPair(id: '', front: '', back: '', isMatched: false),
    );

    if (first.id.isNotEmpty && second.id.isNotEmpty && first.id == second.id) {
      final completed = [...s.matchCompleted, first.id];
      final allDone = completed.length >= s.matchPairs.length;
      state = s.copyWith(
        matchSelected: null,
        matchCompleted: completed,
        status: allDone ? StudySessionStatus.complete : null,
      );
    } else {
      state = s.copyWith(matchSelected: null);
    }
  }

  void endSession() {
    state = null;
  }
}

final studySessionProvider =
    NotifierProvider<StudySessionNotifier, StudySessionState?>(
      StudySessionNotifier.new,
    );

// ── Sample data ───────────────────────────────────────────────────────────

final List<FlashcardDeck> _sampleDecks = [
  FlashcardDeck(
    id: 'deck_sat_vocab',
    name: 'SAT Vocabulary',
    userId: 'local_user',
    description: 'Essential SAT vocabulary words',
    emoji: '📖',
    color: 0xFF4F46E5,
    examId: 'sat',
    subject: 'English',
    tags: const ['SAT', 'Vocabulary', 'English'],
    cardCount: 5,
    dueCount: 3,
    newCount: 2,
    createdAt: DateTime.now().subtract(const Duration(days: 7)),
    lastStudiedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  FlashcardDeck(
    id: 'deck_waec_bio',
    name: 'WAEC Biology',
    userId: 'local_user',
    description: 'WAEC Biology key concepts',
    emoji: '🧬',
    color: 0xFF10B981,
    examId: 'waec',
    subject: 'Biology',
    tags: const ['WAEC', 'Biology', 'Science'],
    cardCount: 4,
    dueCount: 2,
    newCount: 2,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  FlashcardDeck(
    id: 'deck_jee_physics',
    name: 'JEE Physics Formulas',
    userId: 'local_user',
    description: 'Key physics formulas for JEE',
    emoji: '⚡',
    color: 0xFFF59E0B,
    examId: 'jee_main',
    subject: 'Physics',
    tags: const ['JEE', 'Physics', 'Formulas'],
    cardCount: 4,
    dueCount: 1,
    newCount: 3,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
];

final Map<String, List<Flashcard>> _sampleCards = {
  'deck_sat_vocab': [
    Flashcard(
      id: 'card_1',
      deckId: 'deck_sat_vocab',
      type: FlashcardType.basic,
      front: 'Ephemeral',
      back: 'Lasting for a very short time',
      hint: 'Think: "ephemera" — things that exist briefly',
      tags: const ['SAT', 'Vocabulary'],
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    Flashcard(
      id: 'card_2',
      deckId: 'deck_sat_vocab',
      type: FlashcardType.basic,
      front: 'Ubiquitous',
      back: 'Present, appearing, or found everywhere',
      hint: 'Think: "everywhere at once"',
      tags: const ['SAT', 'Vocabulary'],
      easeFactor: 2.3,
      interval: 3,
      repetitions: 2,
      nextReviewAt: DateTime.now().subtract(const Duration(hours: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    Flashcard(
      id: 'card_3',
      deckId: 'deck_sat_vocab',
      type: FlashcardType.cloze,
      front: 'The politician\'s {{verbose}} speech lasted three hours.',
      back: 'verbose — using more words than needed',
      clozeText: 'The politician\'s _____ speech lasted three hours.',
      tags: const ['SAT', 'Vocabulary'],
      easeFactor: 2.1,
      interval: 1,
      repetitions: 1,
      nextReviewAt: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    Flashcard(
      id: 'card_4',
      deckId: 'deck_sat_vocab',
      type: FlashcardType.basic,
      front: 'Ameliorate',
      back: 'Make (something bad or unsatisfactory) better',
      hint: 'Similar to "improve" or "alleviate"',
      tags: const ['SAT', 'Vocabulary'],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Flashcard(
      id: 'card_5',
      deckId: 'deck_sat_vocab',
      type: FlashcardType.basic,
      front: 'Perfidious',
      back: 'Deceitful and untrustworthy',
      hint: 'Think: "perfidy" — betrayal',
      tags: const ['SAT', 'Vocabulary'],
      easeFactor: 2.6,
      interval: 7,
      repetitions: 3,
      nextReviewAt: DateTime.now().add(const Duration(days: 4)),
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ],
  'deck_waec_bio': [
    Flashcard(
      id: 'card_bio_1',
      deckId: 'deck_waec_bio',
      type: FlashcardType.basic,
      front: 'What is osmosis?',
      back:
          'The movement of water molecules through a semi-permeable membrane from a region of lower solute concentration to higher solute concentration.',
      tags: const ['WAEC', 'Biology', 'Cell Biology'],
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Flashcard(
      id: 'card_bio_2',
      deckId: 'deck_waec_bio',
      type: FlashcardType.basic,
      front: 'Define photosynthesis',
      back:
          'The process by which green plants use sunlight, water, and CO₂ to produce glucose and oxygen. Equation: 6CO₂ + 6H₂O + light → C₆H₁₂O₆ + 6O₂',
      tags: const ['WAEC', 'Biology', 'Plant Biology'],
      easeFactor: 2.4,
      interval: 2,
      repetitions: 1,
      nextReviewAt: DateTime.now().subtract(const Duration(hours: 5)),
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Flashcard(
      id: 'card_bio_3',
      deckId: 'deck_waec_bio',
      type: FlashcardType.basic,
      front: 'What is the function of mitochondria?',
      back:
          'The powerhouse of the cell — produces ATP through cellular respiration.',
      tags: const ['WAEC', 'Biology', 'Cell Biology'],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Flashcard(
      id: 'card_bio_4',
      deckId: 'deck_waec_bio',
      type: FlashcardType.basic,
      front: 'Difference between mitosis and meiosis',
      back:
          'Mitosis: produces 2 identical diploid cells (growth/repair). Meiosis: produces 4 haploid cells (sexual reproduction).',
      tags: const ['WAEC', 'Biology', 'Genetics'],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ],
  'deck_jee_physics': [
    Flashcard(
      id: 'card_phy_1',
      deckId: 'deck_jee_physics',
      type: FlashcardType.basic,
      front: 'Newton\'s Second Law',
      back: 'F = ma\nForce equals mass times acceleration.',
      tags: const ['JEE', 'Physics', 'Mechanics'],
      easeFactor: 2.7,
      interval: 14,
      repetitions: 4,
      nextReviewAt: DateTime.now().subtract(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Flashcard(
      id: 'card_phy_2',
      deckId: 'deck_jee_physics',
      type: FlashcardType.basic,
      front: 'Kinetic Energy formula',
      back: 'KE = ½mv²\nwhere m = mass, v = velocity',
      tags: const ['JEE', 'Physics', 'Energy'],
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    Flashcard(
      id: 'card_phy_3',
      deckId: 'deck_jee_physics',
      type: FlashcardType.basic,
      front: 'Ohm\'s Law',
      back: 'V = IR\nVoltage = Current × Resistance',
      tags: const ['JEE', 'Physics', 'Electricity'],
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Flashcard(
      id: 'card_phy_4',
      deckId: 'deck_jee_physics',
      type: FlashcardType.basic,
      front: 'Coulomb\'s Law',
      back: 'F = kq₁q₂/r²\nElectrostatic force between two charges',
      tags: const ['JEE', 'Physics', 'Electrostatics'],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ],
};
