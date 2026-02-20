import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ai/witt_ai.dart';
import '../models/note.dart';
import 'notes_providers.dart';
import '../../learn/providers/test_prep_providers.dart';

// ── AI Note Summary ───────────────────────────────────────────────────────

class NoteSummary {
  const NoteSummary({
    required this.noteId,
    required this.title,
    required this.summary,
    required this.keyPoints,
    required this.definitions,
    required this.actionItems,
    required this.generatedAt,
  });

  final String noteId;
  final String title;
  final String summary;
  final List<String> keyPoints;
  final List<Map<String, String>> definitions;
  final List<String> actionItems;
  final DateTime generatedAt;
}

enum AiNoteSummaryStatus { idle, loading, done, error, limited }

class AiNoteSummaryState {
  const AiNoteSummaryState({
    required this.status,
    this.summary,
    this.errorMessage,
  });
  final AiNoteSummaryStatus status;
  final NoteSummary? summary;
  final String? errorMessage;

  AiNoteSummaryState copyWith({
    AiNoteSummaryStatus? status,
    NoteSummary? summary,
    String? errorMessage,
  }) =>
      AiNoteSummaryState(
        status: status ?? this.status,
        summary: summary ?? this.summary,
        errorMessage: errorMessage,
      );

  static const initial = AiNoteSummaryState(status: AiNoteSummaryStatus.idle);
}

class AiNoteSummaryNotifier
    extends FamilyNotifier<AiNoteSummaryState, String> {
  @override
  AiNoteSummaryState build(String noteId) => AiNoteSummaryState.initial;

  Future<void> summarize() async {
    final note = ref.read(noteByIdProvider(arg));
    if (note == null) return;

    final isPaid = ref.read(isPaidUserProvider);
    final usage = ref.read(usageProvider.notifier);

    if (!usage.canUse(AiFeature.summarize, isPaid)) {
      state = state.copyWith(
        status: AiNoteSummaryStatus.limited,
        errorMessage: usage.limitMessage(AiFeature.summarize),
      );
      return;
    }

    state = state.copyWith(status: AiNoteSummaryStatus.loading);

    try {
      final request = AiRequest(
        feature: AiFeature.summarize,
        messages: [
          AiMessage(
            id: 'note_sum',
            role: 'user',
            content: 'Title: ${note.title}\n\n${note.content}',
            createdAt: DateTime.now(),
          ),
        ],
        isPaidUser: isPaid,
      );

      final router = ref.read(aiRouterProvider);
      final response = await router.request(request);

      if (response.hasError) {
        state = state.copyWith(
          status: AiNoteSummaryStatus.error,
          errorMessage: response.error,
        );
        return;
      }

      usage.recordUsage(AiFeature.summarize);
      final summary = _parseSummary(response.content, note);
      state = state.copyWith(
        status: AiNoteSummaryStatus.done,
        summary: summary,
      );
    } catch (e) {
      state = state.copyWith(
        status: AiNoteSummaryStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  NoteSummary _parseSummary(String jsonContent, Note note) {
    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;
      final keyPointsRaw = data['key_points'] as List<dynamic>? ?? [];
      final defsRaw = data['definitions'] as List<dynamic>? ?? [];
      final actionsRaw = data['action_items'] as List<dynamic>? ?? [];

      return NoteSummary(
        noteId: note.id,
        title: data['title'] as String? ?? note.title,
        summary: data['summary'] as String? ?? '',
        keyPoints: keyPointsRaw.map((e) => e.toString()).toList(),
        definitions: defsRaw.map((d) {
          final m = d as Map<String, dynamic>;
          return {
            'term': m['term'] as String? ?? '',
            'definition': m['definition'] as String? ?? '',
          };
        }).toList(),
        actionItems: actionsRaw.map((e) => e.toString()).toList(),
        generatedAt: DateTime.now(),
      );
    } catch (_) {
      return NoteSummary(
        noteId: note.id,
        title: note.title,
        summary: 'Summary could not be parsed. Please try again.',
        keyPoints: const [],
        definitions: const [],
        actionItems: const [],
        generatedAt: DateTime.now(),
      );
    }
  }

  void reset() => state = AiNoteSummaryState.initial;
}

final aiNoteSummaryProvider = NotifierProviderFamily<AiNoteSummaryNotifier,
    AiNoteSummaryState, String>(AiNoteSummaryNotifier.new);
