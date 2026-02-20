import '../models/flashcard.dart';

/// SM-2 Spaced Repetition Algorithm
///
/// Based on the original SuperMemo SM-2 algorithm by Piotr Woźniak.
/// Reference: https://www.supermemo.com/en/archives1990-2015/english/ol/sm2
///
/// Rating scale:
///   again (0) — complete blackout
///   hard  (1) — significant difficulty
///   good  (2) — correct with hesitation
///   easy  (3) — perfect response
class Sm2Algorithm {
  static const double _minEaseFactor = 1.3;
  static const double _maxEaseFactor = 2.5;

  /// Apply an SM-2 review to a flashcard and return the updated card.
  static Flashcard review({
    required Flashcard card,
    required Sm2Rating rating,
    required DateTime reviewedAt,
  }) {
    final q = _ratingToQ(rating);
    final isCorrect = q >= 2;

    double newEaseFactor;
    int newInterval;
    int newRepetitions;

    if (isCorrect) {
      // Correct response — advance the schedule
      newRepetitions = card.repetitions + 1;
      newEaseFactor = (card.easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)))
          .clamp(_minEaseFactor, _maxEaseFactor);

      if (card.repetitions == 0) {
        newInterval = 1;
      } else if (card.repetitions == 1) {
        newInterval = 6;
      } else {
        newInterval = (card.interval * newEaseFactor).round();
      }
    } else {
      // Incorrect response — reset to beginning
      newRepetitions = 0;
      newEaseFactor = (card.easeFactor - 0.2).clamp(_minEaseFactor, _maxEaseFactor);
      newInterval = 1;
    }

    // Apply fuzz factor (±5% of interval) to avoid review clustering
    final fuzz = (newInterval * 0.05).round().clamp(1, 3);
    final fuzzedInterval = newInterval + (reviewedAt.millisecond % (fuzz * 2 + 1)) - fuzz;
    final finalInterval = fuzzedInterval.clamp(1, 365);

    final nextReview = reviewedAt.add(Duration(days: finalInterval));

    return card.copyWith(
      easeFactor: newEaseFactor,
      interval: finalInterval,
      repetitions: newRepetitions,
      nextReviewAt: nextReview,
      lastReviewedAt: reviewedAt,
      totalReviews: card.totalReviews + 1,
      correctReviews: card.correctReviews + (isCorrect ? 1 : 0),
    );
  }

  /// Returns the next review date without modifying the card.
  static DateTime previewNextReview({
    required Flashcard card,
    required Sm2Rating rating,
  }) {
    final reviewed = review(card: card, rating: rating, reviewedAt: DateTime.now());
    return reviewed.nextReviewAt ?? DateTime.now().add(const Duration(days: 1));
  }

  /// Returns a human-readable label for the next review interval.
  static String intervalLabel(Sm2Rating rating, Flashcard card) {
    final next = previewNextReview(card: card, rating: rating);
    final days = next.difference(DateTime.now()).inDays;
    if (days == 0) return 'Again';
    if (days == 1) return '1 day';
    if (days < 7) return '$days days';
    if (days < 14) return '1 week';
    if (days < 30) return '${(days / 7).round()} weeks';
    if (days < 365) return '${(days / 30).round()} months';
    return '${(days / 365).round()} years';
  }

  /// Sort cards into study buckets for a session.
  static StudyQueue buildQueue({
    required List<Flashcard> cards,
    required int newCardsPerSession,
    required int reviewCardsPerSession,
  }) {
    final now = DateTime.now();

    final dueCards = cards
        .where((c) => c.repetitions > 0 && c.isDue)
        .toList()
      ..sort((a, b) => (a.nextReviewAt ?? now).compareTo(b.nextReviewAt ?? now));

    final newCards = cards
        .where((c) => c.repetitions == 0 && c.nextReviewAt == null)
        .take(newCardsPerSession)
        .toList();

    final reviewCards = dueCards.take(reviewCardsPerSession).toList();

    // Interleave new and review cards
    final queue = <Flashcard>[];
    int ni = 0, ri = 0;
    while (ni < newCards.length || ri < reviewCards.length) {
      if (ri < reviewCards.length) queue.add(reviewCards[ri++]);
      if (ri < reviewCards.length) queue.add(reviewCards[ri++]);
      if (ni < newCards.length) queue.add(newCards[ni++]);
    }

    return StudyQueue(
      cards: queue,
      newCount: newCards.length,
      reviewCount: reviewCards.length,
      totalDue: dueCards.length,
    );
  }

  static int _ratingToQ(Sm2Rating rating) {
    return switch (rating) {
      Sm2Rating.again => 0,
      Sm2Rating.hard => 1,
      Sm2Rating.good => 3,
      Sm2Rating.easy => 5,
    };
  }
}

class StudyQueue {
  const StudyQueue({
    required this.cards,
    required this.newCount,
    required this.reviewCount,
    required this.totalDue,
  });

  final List<Flashcard> cards;
  final int newCount;
  final int reviewCount;
  final int totalDue;

  bool get isEmpty => cards.isEmpty;
  int get total => cards.length;
}
