import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ai/witt_ai.dart';
import '../models/sage_models.dart';
import '../../learn/providers/test_prep_providers.dart';

// ── Conversation history (last 5 for free, unlimited for paid) ────────────

class SageHistoryNotifier extends Notifier<List<SageConversation>> {
  @override
  List<SageConversation> build() => [];

  void add(SageConversation conv) {
    final isPaid = ref.read(isPaidUserProvider);
    final limit = isPaid ? 999 : 5;
    final updated = [conv, ...state];
    state = updated.length > limit ? updated.sublist(0, limit) : updated;
  }

  void update(SageConversation conv) {
    state = [
      for (final c in state)
        if (c.id == conv.id) conv else c,
    ];
  }

  void delete(String id) {
    state = state.where((c) => c.id != id).toList();
  }
}

final sageHistoryProvider =
    NotifierProvider<SageHistoryNotifier, List<SageConversation>>(
        SageHistoryNotifier.new);

// ── Active session ────────────────────────────────────────────────────────

class SageSessionNotifier extends Notifier<SageSessionState> {
  @override
  SageSessionState build() => SageSessionState.initial();

  void setMode(SageMode mode) {
    state = state.copyWith(mode: mode);
  }

  void newConversation() {
    // Save current if it has messages
    if (state.conversation.messages.isNotEmpty) {
      ref.read(sageHistoryProvider.notifier).add(state.conversation);
    }
    state = SageSessionState.initial();
  }

  void loadConversation(SageConversation conv) {
    state = state.copyWith(conversation: conv, mode: conv.mode);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isStreaming) return;

    final isPaid = ref.read(isPaidUserProvider);

    // Check usage limits
    final usage = ref.read(usageProvider.notifier);
    if (!usage.canUse(AiFeature.sageChat, isPaid)) {
      state = state.copyWith(
        limitMessage: usage.limitMessage(AiFeature.sageChat),
      );
      return;
    }

    // Append user message
    final userMsg = AiMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: text.trim(),
      createdAt: DateTime.now(),
    );

    final updatedConv = state.conversation.copyWith(
      messages: [...state.conversation.messages, userMsg],
      updatedAt: DateTime.now(),
      title: state.conversation.messages.isEmpty
          ? _titleFromText(text)
          : state.conversation.title,
    );

    // Add streaming placeholder
    final streamingId = 'msg_stream_${DateTime.now().millisecondsSinceEpoch}';
    state = state.copyWith(
      conversation: updatedConv,
      isStreaming: true,
      streamingContent: '',
      error: null,
      limitMessage: null,
    );

    // Build context window (4 msgs for free, full for paid)
    final contextLimit = isPaid ? 999 : 4;
    final contextMessages = updatedConv.messages
        .where((m) => m.role != 'system')
        .toList()
        .reversed
        .take(contextLimit)
        .toList()
        .reversed
        .toList();

    final systemPrompt = _systemPromptForMode(state.mode);

    final request = AiRequest(
      feature: AiFeature.sageChat,
      messages: contextMessages,
      isPaidUser: isPaid,
      systemPrompt: systemPrompt,
      maxTokens: isPaid ? 2048 : 700,
      stream: true,
    );

    String accumulated = '';

    try {
      final router = ref.read(aiRouterProvider);
      await for (final token in router.stream(request)) {
        accumulated += token;
        state = state.copyWith(streamingContent: accumulated);
      }

      // Record usage
      usage.recordUsage(AiFeature.sageChat);

      // Commit streamed message
      final assistantMsg = AiMessage(
        id: streamingId,
        role: 'assistant',
        content: accumulated,
        createdAt: DateTime.now(),
      );

      final finalConv = state.conversation.copyWith(
        messages: [...state.conversation.messages, assistantMsg],
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(
        conversation: finalConv,
        isStreaming: false,
        streamingContent: '',
      );

      // Persist to history
      ref.read(sageHistoryProvider.notifier).update(finalConv);
      if (!ref
          .read(sageHistoryProvider)
          .any((c) => c.id == finalConv.id)) {
        ref.read(sageHistoryProvider.notifier).add(finalConv);
      }
    } catch (e) {
      state = state.copyWith(
        isStreaming: false,
        streamingContent: '',
        error: e.toString(),
      );
    }
  }

  String _titleFromText(String text) {
    final words = text.trim().split(' ');
    return words.take(6).join(' ') + (words.length > 6 ? '…' : '');
  }

  String _systemPromptForMode(SageMode mode) => switch (mode) {
        SageMode.chat =>
          'You are Sage, an expert AI study companion for Witt. Help students learn effectively. Be concise, clear, and encouraging.',
        SageMode.explain =>
          'You are Sage. Explain concepts clearly with examples, analogies, and step-by-step breakdowns. Use markdown formatting.',
        SageMode.homework =>
          'You are Sage. Help students understand their homework by walking through problems step by step. Never just give the answer — guide them to understand.',
        SageMode.quiz =>
          'You are Sage. Generate interactive quiz questions based on the student\'s topic. After each answer, provide feedback and explanation.',
        SageMode.planning =>
          'You are Sage. Help students create effective study plans. Ask about their exam dates, available time, and weak areas. Generate structured, realistic plans.',
        SageMode.flashcardGen =>
          'You are Sage. Generate flashcard decks from the provided topic or text. Format each card clearly with a term/question on the front and definition/answer on the back.',
        SageMode.lectureSummary =>
          'You are Sage. Summarize lecture content into structured notes with headings, key points, definitions, and action items.',
      };
}

final sageSessionProvider =
    NotifierProvider<SageSessionNotifier, SageSessionState>(
        SageSessionNotifier.new);

// ── Remaining messages badge ──────────────────────────────────────────────

final sageRemainingMessagesProvider = Provider<int?>((ref) {
  final isPaid = ref.watch(isPaidUserProvider);
  if (isPaid) return null; // unlimited
  final usage = ref.watch(usageProvider);
  return (10 - usage.dailyMessages).clamp(0, 10);
});
