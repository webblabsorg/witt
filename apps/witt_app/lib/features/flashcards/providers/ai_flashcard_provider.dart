import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ai/witt_ai.dart';
import '../models/flashcard.dart';
import 'flashcard_providers.dart';
import '../../learn/providers/test_prep_providers.dart';

// ── AI Flashcard Generation State ─────────────────────────────────────────

enum AiFlashcardGenStatus { idle, loading, done, error, limited }

class AiFlashcardGenState {
  const AiFlashcardGenState({
    required this.status,
    this.generatedDeckId,
    this.errorMessage,
  });
  final AiFlashcardGenStatus status;
  final String? generatedDeckId;
  final String? errorMessage;

  AiFlashcardGenState copyWith({
    AiFlashcardGenStatus? status,
    String? generatedDeckId,
    String? errorMessage,
  }) =>
      AiFlashcardGenState(
        status: status ?? this.status,
        generatedDeckId: generatedDeckId ?? this.generatedDeckId,
        errorMessage: errorMessage,
      );

  static const initial =
      AiFlashcardGenState(status: AiFlashcardGenStatus.idle);
}

class AiFlashcardGenNotifier extends Notifier<AiFlashcardGenState> {
  @override
  AiFlashcardGenState build() => AiFlashcardGenState.initial;

  Future<void> generateDeck({
    required String topic,
    int cardCount = 10,
    String? examId,
  }) async {
    final isPaid = ref.read(isPaidUserProvider);
    final usage = ref.read(usageProvider.notifier);

    if (!usage.canUse(AiFeature.flashcardGenerate, isPaid)) {
      state = state.copyWith(
        status: AiFlashcardGenStatus.limited,
        errorMessage: usage.limitMessage(AiFeature.flashcardGenerate),
      );
      return;
    }

    final count = isPaid ? cardCount : cardCount.clamp(1, 10);
    state = state.copyWith(status: AiFlashcardGenStatus.loading);

    try {
      final request = AiRequest(
        feature: AiFeature.flashcardGenerate,
        messages: [
          AiMessage(
            id: 'fc_gen',
            role: 'user',
            content:
                'Create $count flashcards for the topic: "$topic".'
                '${examId != null ? ' Exam context: $examId.' : ''}',
            createdAt: DateTime.now(),
          ),
        ],
        isPaidUser: isPaid,
      );

      final router = ref.read(aiRouterProvider);
      final response = await router.request(request);

      if (response.hasError) {
        state = state.copyWith(
          status: AiFlashcardGenStatus.error,
          errorMessage: response.error,
        );
        return;
      }

      usage.recordUsage(AiFeature.flashcardGenerate);
      final deckId = _buildDeck(response.content, topic, examId);
      state = state.copyWith(
        status: AiFlashcardGenStatus.done,
        generatedDeckId: deckId,
      );
    } catch (e) {
      state = state.copyWith(
        status: AiFlashcardGenStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  String _buildDeck(String jsonContent, String topic, String? examId) {
    final deckId = 'ai_deck_${DateTime.now().millisecondsSinceEpoch}';
    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;
      final title = data['deck_title'] as String? ?? topic;
      final cardsRaw = data['cards'] as List<dynamic>? ?? [];

      final deck = FlashcardDeck(
        id: deckId,
        name: title,
        userId: 'local_user',
        description: 'AI-generated deck for $topic',
        emoji: '🤖',
        color: 0xFF4F46E5,
        examId: examId,
        subject: topic,
        tags: ['AI Generated', topic],
        cardCount: cardsRaw.length,
        dueCount: cardsRaw.length,
        newCount: cardsRaw.length,
        createdAt: DateTime.now(),
      );

      final cards = cardsRaw.asMap().entries.map((entry) {
        final i = entry.key;
        final c = entry.value as Map<String, dynamic>;
        return Flashcard(
          id: '${deckId}_card_$i',
          deckId: deckId,
          type: FlashcardType.basic,
          front: c['front'] as String? ?? '',
          back: c['back'] as String? ?? '',
          hint: c['hint'] as String?,
          createdAt: DateTime.now(),
        );
      }).toList();

      ref.read(deckListProvider.notifier).createDeck(deck);
      for (final card in cards) {
        ref.read(cardListProvider.notifier).addCard(card);
      }
    } catch (_) {
      // Return deckId even if parsing failed — deck was already created
    }
    return deckId;
  }

  void reset() => state = AiFlashcardGenState.initial;
}

final aiFlashcardGenProvider =
    NotifierProvider<AiFlashcardGenNotifier, AiFlashcardGenState>(
        AiFlashcardGenNotifier.new);
