import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flashcard.dart';
import '../services/sm2_algorithm.dart';
import '../../progress/providers/progress_providers.dart';

// ── Deck CRUD ─────────────────────────────────────────────────────────────

class DeckListNotifier extends Notifier<List<FlashcardDeck>> {
  @override
  List<FlashcardDeck> build() => [];

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
  Map<String, List<Flashcard>> build() => {};

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

