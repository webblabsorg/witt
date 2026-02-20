import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_monetization/witt_monetization.dart';
import '../models/game_models.dart';
import '../../../core/persistence/hive_boxes.dart';
import '../../../core/analytics/analytics.dart';

// ── All 9 games catalog ───────────────────────────────────────────────────

const allGames = [
  GameDefinition(
    id: 'word_duel',
    title: 'Word Duel',
    description: 'Battle opponents with vocabulary knowledge',
    emoji: '⚔️',
    category: GameCategory.wordGames,
    color: Color(0xFF7C3AED),
    isPaidOnly: false,
    supportsMultiplayer: true,
  ),
  GameDefinition(
    id: 'quiz_royale',
    title: 'Quiz Royale',
    description: 'Last student standing wins',
    emoji: '🏆',
    category: GameCategory.generalKnowledge,
    color: Color(0xFFD97706),
    isPaidOnly: false,
    supportsMultiplayer: true,
  ),
  GameDefinition(
    id: 'equation_rush',
    title: 'Equation Rush',
    description: 'Solve equations faster than your opponent',
    emoji: '⚡',
    category: GameCategory.mathGames,
    color: Color(0xFF0891B2),
    isPaidOnly: false,
    supportsMultiplayer: true,
  ),
  GameDefinition(
    id: 'fact_or_fiction',
    title: 'Fact or Fiction',
    description: 'True or false — but faster than ever',
    emoji: '🎯',
    category: GameCategory.generalKnowledge,
    color: Color(0xFF059669),
    isPaidOnly: false,
    supportsMultiplayer: false,
  ),
  GameDefinition(
    id: 'crossword_builder',
    title: 'Crossword Builder',
    description: 'Build crosswords from your study topics',
    emoji: '🔤',
    category: GameCategory.wordGames,
    color: Color(0xFFDB2777),
    isPaidOnly: true,
    supportsMultiplayer: false,
  ),
  GameDefinition(
    id: 'memory_match',
    title: 'Memory Match',
    description: 'Match concepts to definitions at speed',
    emoji: '🃏',
    category: GameCategory.memory,
    color: Color(0xFF7C3AED),
    isPaidOnly: false,
    supportsMultiplayer: false,
  ),
  GameDefinition(
    id: 'timeline_challenge',
    title: 'Timeline Challenge',
    description: 'Arrange historical events in order',
    emoji: '📅',
    category: GameCategory.generalKnowledge,
    color: Color(0xFFB45309),
    isPaidOnly: true,
    supportsMultiplayer: false,
  ),
  GameDefinition(
    id: 'spelling_bee',
    title: 'Spelling Bee',
    description: 'Spell your way to the top',
    emoji: '🐝',
    category: GameCategory.wordGames,
    color: Color(0xFFF59E0B),
    isPaidOnly: false,
    supportsMultiplayer: true,
  ),
  GameDefinition(
    id: 'subject_boss',
    title: 'Subject Boss Battles',
    description: 'Defeat the boss with subject mastery',
    emoji: '👾',
    category: GameCategory.challenge,
    color: Color(0xFFDC2626),
    isPaidOnly: true,
    supportsMultiplayer: false,
  ),
];

// ── Brain challenges ──────────────────────────────────────────────────────

final _brainChallenges = [
  const BrainChallenge(
    id: 'bc_daily',
    title: 'Daily Logic Puzzle',
    description: 'A new logic puzzle every day. Solve it to keep your streak!',
    category: 'Logic',
    difficulty: GameDifficulty.medium,
    xpReward: 50,
    isDaily: true,
  ),
  const BrainChallenge(
    id: 'bc1',
    title: 'Number Sequence',
    description: 'Find the pattern and complete the sequence.',
    category: 'Math',
    difficulty: GameDifficulty.easy,
    xpReward: 20,
  ),
  const BrainChallenge(
    id: 'bc2',
    title: 'Word Analogy',
    description: 'Complete the analogy: Doctor : Hospital :: Teacher : ?',
    category: 'Verbal',
    difficulty: GameDifficulty.easy,
    xpReward: 20,
  ),
  const BrainChallenge(
    id: 'bc3',
    title: 'Spatial Reasoning',
    description: 'Which shape completes the pattern?',
    category: 'Spatial',
    difficulty: GameDifficulty.hard,
    xpReward: 40,
  ),
  const BrainChallenge(
    id: 'bc4',
    title: 'Critical Thinking',
    description: 'Evaluate the argument and identify the flaw.',
    category: 'Logic',
    difficulty: GameDifficulty.hard,
    xpReward: 40,
  ),
];

// ── Leaderboard data ──────────────────────────────────────────────────────

final _globalLeaderboard = [
  const LeaderboardEntry(
    rank: 1,
    userId: 'u1',
    name: 'Priya Sharma',
    avatarInitials: 'PS',
    score: 98450,
    country: '🇮🇳',
  ),
  const LeaderboardEntry(
    rank: 2,
    userId: 'u2',
    name: 'Kwame Mensah',
    avatarInitials: 'KM',
    score: 94200,
    country: '🇬🇭',
  ),
  const LeaderboardEntry(
    rank: 3,
    userId: 'u3',
    name: 'Sofia Reyes',
    avatarInitials: 'SR',
    score: 91800,
    country: '🇲🇽',
  ),
  const LeaderboardEntry(
    rank: 4,
    userId: 'u4',
    name: 'Aditya Kumar',
    avatarInitials: 'AK',
    score: 87300,
    country: '🇮🇳',
  ),
  const LeaderboardEntry(
    rank: 5,
    userId: 'u5',
    name: 'Amara Osei',
    avatarInitials: 'AO',
    score: 82100,
    country: '🇬🇭',
  ),
  const LeaderboardEntry(
    rank: 342,
    userId: 'me',
    name: 'You',
    avatarInitials: 'ME',
    score: 12400,
    country: '🌍',
    isCurrentUser: true,
  ),
];

// ── Providers ─────────────────────────────────────────────────────────────

final gamesProvider = Provider<List<GameDefinition>>((ref) {
  final isPaid = ref.watch(isPaidProvider);
  if (isPaid) return allGames;
  return allGames; // all visible; isPaidOnly gates launch, not visibility
});

final brainChallengesProvider =
    NotifierProvider<BrainChallengesNotifier, List<BrainChallenge>>(
      BrainChallengesNotifier.new,
    );

class BrainChallengesNotifier extends Notifier<List<BrainChallenge>> {
  @override
  List<BrainChallenge> build() {
    final completedIds = Set<String>.from(
      gamesBox.get(kKeyCompletedChallengeIds, defaultValue: <String>[]) as List,
    );
    return _brainChallenges
        .map((c) => c.copyWith(isCompleted: completedIds.contains(c.id)))
        .toList();
  }

  void complete(String id) {
    final challenge = state.firstWhere((c) => c.id == id);
    state = state
        .map((c) => c.id == id ? c.copyWith(isCompleted: true) : c)
        .toList();
    final completedIds = state
        .where((c) => c.isCompleted)
        .map((c) => c.id)
        .toList();
    gamesBox.put(kKeyCompletedChallengeIds, completedIds);
    Analytics.completeChallenge(id, challenge.xpReward);
  }
}

final leaderboardProvider = Provider<List<LeaderboardEntry>>(
  (_) => _globalLeaderboard,
);

// ── Daily games played counter (free: 3/day, Hive-backed) ────────────────

int _todayGamesPlayed() {
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final lastReset =
      gamesBox.get(kKeyGamesLastResetDate, defaultValue: '') as String;
  if (lastReset != today) {
    gamesBox.put(kKeyGamesLastResetDate, today);
    gamesBox.put(kKeyGamesPlayedToday, 0);
    return 0;
  }
  return gamesBox.get(kKeyGamesPlayedToday, defaultValue: 0) as int;
}

final gamesPlayedTodayProvider = StateProvider<int>((_) => _todayGamesPlayed());

final canPlayGameProvider = Provider<bool>((ref) {
  final isPaid = ref.watch(isPaidProvider);
  if (isPaid) return true;
  final played = ref.watch(gamesPlayedTodayProvider);
  return played < 3;
});

// ── Multiplayer status ────────────────────────────────────────────────────

final multiplayerStatusProvider = StateProvider<MultiplayerStatus>(
  (_) => MultiplayerStatus.offline,
);

// ── Active game session ───────────────────────────────────────────────────

class GameSessionNotifier extends Notifier<GameSessionState?> {
  Timer? _timer;

  @override
  GameSessionState? build() => null;

  void startGame(String gameId) {
    _timer?.cancel();
    final game = allGames.firstWhere(
      (g) => g.id == gameId,
      orElse: () => allGames.first,
    );
    Analytics.launchGame(gameId, game.title, game.isPaidOnly);
    state = GameSessionState(
      gameId: gameId,
      score: 0,
      questionIndex: 0,
      totalQuestions: 10,
      timeRemainingSeconds: 60,
      currentQuestion: _sampleQuestion(gameId, 0),
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = state;
      if (s == null || s.isComplete) {
        _timer?.cancel();
        return;
      }
      if (s.timeRemainingSeconds <= 1) {
        _timer?.cancel();
        state = s.copyWith(isComplete: true);
      } else {
        state = s.copyWith(timeRemainingSeconds: s.timeRemainingSeconds - 1);
      }
    });
  }

  void answer(String answer) {
    final s = state;
    if (s == null || s.isComplete) return;
    final correct = answer == 'A'; // simplified: first option always correct
    final newScore = correct ? s.score + 10 : s.score;
    final nextIndex = s.questionIndex + 1;
    final done = nextIndex >= s.totalQuestions;
    if (done) _timer?.cancel();
    state = s.copyWith(
      score: newScore,
      questionIndex: nextIndex,
      isComplete: done,
      selectedAnswer: answer,
      isCorrect: correct,
      currentQuestion: done ? null : _sampleQuestion(s.gameId, nextIndex),
    );
  }

  void endGame() {
    final s = state;
    if (s != null) {
      Analytics.completeGame(s.gameId, s.score, s.isComplete);
    }
    _timer?.cancel();
    state = null;
  }

  String _sampleQuestion(String gameId, int index) {
    final questions = switch (gameId) {
      'word_duel' => [
        'What is the meaning of "Ephemeral"?',
        'Which word means "to make amends"?',
        'Define "Ubiquitous"',
      ],
      'equation_rush' => [
        'Solve: 3x + 7 = 22',
        'What is √144?',
        'Simplify: 2(x + 3) = 14',
      ],
      'fact_or_fiction' => [
        'The Great Wall of China is visible from space.',
        'Humans use only 10% of their brains.',
        'Lightning never strikes the same place twice.',
      ],
      _ => [
        'Which planet is closest to the Sun?',
        'What is the capital of France?',
        'Who wrote Romeo and Juliet?',
      ],
    };
    return questions[index % questions.length];
  }
}

final gameSessionProvider =
    NotifierProvider<GameSessionNotifier, GameSessionState?>(
      GameSessionNotifier.new,
    );
