import 'package:flutter/material.dart';

// ── Enums ─────────────────────────────────────────────────────────────────

enum GameCategory { wordGames, mathGames, generalKnowledge, memory, challenge }

enum GameDifficulty { easy, medium, hard }

enum MultiplayerStatus { offline, searching, inLobby, inGame }

// ── Game definition ───────────────────────────────────────────────────────

@immutable
class GameDefinition {
  const GameDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    required this.color,
    required this.isPaidOnly,
    required this.supportsMultiplayer,
    this.dailyLimit = 3,
  });

  final String id;
  final String title;
  final String description;
  final String emoji;
  final GameCategory category;
  final Color color;
  final bool isPaidOnly;
  final bool supportsMultiplayer;
  final int dailyLimit;
}

// ── Brain challenge ───────────────────────────────────────────────────────

@immutable
class BrainChallenge {
  const BrainChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.xpReward,
    this.isCompleted = false,
    this.isDaily = false,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final GameDifficulty difficulty;
  final int xpReward;
  final bool isCompleted;
  final bool isDaily;

  BrainChallenge copyWith({bool? isCompleted}) => BrainChallenge(
    id: id,
    title: title,
    description: description,
    category: category,
    difficulty: difficulty,
    xpReward: xpReward,
    isCompleted: isCompleted ?? this.isCompleted,
    isDaily: isDaily,
  );
}

// ── Leaderboard entry ─────────────────────────────────────────────────────

@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.avatarInitials,
    required this.score,
    required this.country,
    this.isCurrentUser = false,
  });

  final int rank;
  final String userId;
  final String name;
  final String avatarInitials;
  final int score;
  final String country;
  final bool isCurrentUser;
}

// ── Game session state ────────────────────────────────────────────────────

@immutable
class GameSessionState {
  const GameSessionState({
    required this.gameId,
    required this.score,
    required this.questionIndex,
    required this.totalQuestions,
    required this.timeRemainingSeconds,
    this.isComplete = false,
    this.currentQuestion,
    this.selectedAnswer,
    this.isCorrect,
  });

  final String gameId;
  final int score;
  final int questionIndex;
  final int totalQuestions;
  final int timeRemainingSeconds;
  final bool isComplete;
  final String? currentQuestion;
  final String? selectedAnswer;
  final bool? isCorrect;

  GameSessionState copyWith({
    int? score,
    int? questionIndex,
    int? timeRemainingSeconds,
    bool? isComplete,
    String? currentQuestion,
    String? selectedAnswer,
    bool? isCorrect,
  }) => GameSessionState(
    gameId: gameId,
    score: score ?? this.score,
    questionIndex: questionIndex ?? this.questionIndex,
    totalQuestions: totalQuestions,
    timeRemainingSeconds: timeRemainingSeconds ?? this.timeRemainingSeconds,
    isComplete: isComplete ?? this.isComplete,
    currentQuestion: currentQuestion ?? this.currentQuestion,
    selectedAnswer: selectedAnswer ?? this.selectedAnswer,
    isCorrect: isCorrect ?? this.isCorrect,
  );
}
