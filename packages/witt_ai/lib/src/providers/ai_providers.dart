import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_models.dart';
import '../router/ai_router.dart';

// ── AiRouter singleton ────────────────────────────────────────────────────

/// Override this in the app with real Supabase credentials.
final aiRouterProvider = Provider<AiRouter>((ref) {
  // Credentials injected at app startup via ProviderScope overrides.
  throw UnimplementedError(
      'aiRouterProvider must be overridden with real credentials');
});

// ── Usage tracking ────────────────────────────────────────────────────────

class UsageNotifier extends Notifier<UsageRecord> {
  @override
  UsageRecord build() => UsageRecord.empty;

  bool canUse(AiFeature feature, bool isPaidUser) {
    if (isPaidUser) return true;
    _maybeResetDaily();
    return state.canUseFeature(feature);
  }

  String limitMessage(AiFeature feature) => state.limitMessage(feature);

  void recordUsage(AiFeature feature) {
    _maybeResetDaily();
    state = state.increment(feature);
  }

  void _maybeResetDaily() {
    final now = DateTime.now().toUtc();
    final last = state.lastResetDate;
    final sameDay = now.year == last.year &&
        now.month == last.month &&
        now.day == last.day;
    if (!sameDay) {
      state = UsageRecord(
        dailyMessages: 0,
        monthlyMessages: _shouldResetMonthly(now, last)
            ? 0
            : state.monthlyMessages,
        dailyHomework: 0,
        dailyQuizGens: 0,
        dailyFlashcardGens: 0,
        dailySummarizations: 0,
        dailyAttachments: 0,
        lastResetDate: now,
      );
    }
  }

  bool _shouldResetMonthly(DateTime now, DateTime last) =>
      now.year > last.year || now.month > last.month;
}

final usageProvider =
    NotifierProvider<UsageNotifier, UsageRecord>(UsageNotifier.new);

// ── Convenience: make an AI request with usage enforcement ────────────────

/// Returns the response content, or throws [AiLimitException] if over limit.
Future<AiResponse> makeAiRequest({
  required Ref ref,
  required AiRequest request,
  required bool isPaidUser,
}) async {
  final usage = ref.read(usageProvider.notifier);
  if (!usage.canUse(request.feature, isPaidUser)) {
    throw AiLimitException(usage.limitMessage(request.feature));
  }
  final router = ref.read(aiRouterProvider);
  final response = await router.request(request);
  if (!response.hasError) {
    usage.recordUsage(request.feature);
  }
  return response;
}

/// Returns a stream of delta tokens, enforcing usage limits.
Stream<String> makeAiStream({
  required Ref ref,
  required AiRequest request,
  required bool isPaidUser,
}) async* {
  final usage = ref.read(usageProvider.notifier);
  if (!usage.canUse(request.feature, isPaidUser)) {
    throw AiLimitException(usage.limitMessage(request.feature));
  }
  final router = ref.read(aiRouterProvider);
  bool recorded = false;
  await for (final token in router.stream(request)) {
    if (!recorded) {
      usage.recordUsage(request.feature);
      recorded = true;
    }
    yield token;
  }
}

class AiLimitException implements Exception {
  const AiLimitException(this.message);
  final String message;
  @override
  String toString() => message;
}
