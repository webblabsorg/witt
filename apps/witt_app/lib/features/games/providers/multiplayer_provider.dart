/// Supabase Realtime multiplayer matchmaking provider.
///
/// Flow:
///   1. Player calls [findMatch] → inserts a row into `multiplayer_queue`
///      and subscribes to the Realtime channel for that game type.
///   2. When a second player joins, the server (or the first client) creates
///      a `multiplayer_sessions` row and broadcasts the session ID.
///   3. Both clients receive the session ID and transition to [MultiplayerStatus.inGame].
///   4. [cancelSearch] removes the queue row and unsubscribes.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/game_models.dart';

// ── State ─────────────────────────────────────────────────────────────────

class MultiplayerState {
  const MultiplayerState({
    this.status = MultiplayerStatus.offline,
    this.sessionId,
    this.opponentId,
    this.gameId,
    this.error,
  });

  final MultiplayerStatus status;
  final String? sessionId;
  final String? opponentId;
  final String? gameId;
  final String? error;

  MultiplayerState copyWith({
    MultiplayerStatus? status,
    String? sessionId,
    String? opponentId,
    String? gameId,
    String? error,
  }) =>
      MultiplayerState(
        status: status ?? this.status,
        sessionId: sessionId ?? this.sessionId,
        opponentId: opponentId ?? this.opponentId,
        gameId: gameId ?? this.gameId,
        error: error ?? this.error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────

class MultiplayerNotifier extends Notifier<MultiplayerState> {
  RealtimeChannel? _channel;
  String? _queueRowId;

  @override
  MultiplayerState build() => const MultiplayerState();

  SupabaseClient get _db => Supabase.instance.client;
  String? get _userId => _db.auth.currentUser?.id;

  /// Join the matchmaking queue for [gameId] and listen for a match.
  Future<void> findMatch(String gameId) async {
    final uid = _userId;
    if (uid == null) return;

    state = state.copyWith(
      status: MultiplayerStatus.searching,
      gameId: gameId,
      error: null,
    );

    try {
      // Insert into queue
      final row = await _db
          .from('multiplayer_queue')
          .insert({'user_id': uid, 'game_id': gameId})
          .select()
          .single();
      _queueRowId = row['id'] as String;

      // Subscribe to Realtime channel for this game type
      _channel = _db
          .channel('multiplayer:$gameId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'multiplayer_sessions',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'game_id',
              value: gameId,
            ),
            callback: (payload) => _onSessionCreated(payload, uid),
          )
          .subscribe();

      state = state.copyWith(status: MultiplayerStatus.inLobby);
    } catch (e) {
      state = state.copyWith(
        status: MultiplayerStatus.offline,
        error: 'Matchmaking failed: $e',
      );
    }
  }

  void _onSessionCreated(PostgresChangePayload payload, String myUid) {
    final record = payload.newRecord;
    final p1 = record['player1_id'] as String?;
    final p2 = record['player2_id'] as String?;

    // Only react if this session involves us
    if (p1 != myUid && p2 != myUid) return;

    final opponentId = p1 == myUid ? p2 : p1;
    final sessionId = record['id'] as String?;

    state = state.copyWith(
      status: MultiplayerStatus.inGame,
      sessionId: sessionId,
      opponentId: opponentId,
    );
  }

  /// Cancel matchmaking and clean up.
  Future<void> cancelSearch() async {
    await _channel?.unsubscribe();
    _channel = null;

    if (_queueRowId != null) {
      await _db
          .from('multiplayer_queue')
          .delete()
          .eq('id', _queueRowId!);
      _queueRowId = null;
    }

    state = const MultiplayerState();
  }

  /// End the current game session.
  Future<void> endSession() async {
    await _channel?.unsubscribe();
    _channel = null;
    state = const MultiplayerState();
  }
}

final multiplayerProvider =
    NotifierProvider<MultiplayerNotifier, MultiplayerState>(
  MultiplayerNotifier.new,
);

/// Convenience: current status only (replaces old StateProvider).
final multiplayerStatusProvider = Provider<MultiplayerStatus>((ref) {
  return ref.watch(multiplayerProvider).status;
});
