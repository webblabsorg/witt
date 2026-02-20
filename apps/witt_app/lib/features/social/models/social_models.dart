import 'package:flutter/foundation.dart';

// ── Enums ─────────────────────────────────────────────────────────────────

enum PostType { text, image, question, poll, resource }

enum GroupRole { member, moderator, admin }

enum FriendStatus { none, pending, accepted, blocked }

// ── Feed Post ─────────────────────────────────────────────────────────────

@immutable
class SocialPost {
  const SocialPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.type,
    required this.likes,
    required this.commentCount,
    required this.createdAt,
    this.imageUrl,
    this.groupId,
    this.groupName,
    this.isLiked = false,
    this.tags = const [],
  });

  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final PostType type;
  final int likes;
  final int commentCount;
  final DateTime createdAt;
  final String? imageUrl;
  final String? groupId;
  final String? groupName;
  final bool isLiked;
  final List<String> tags;

  SocialPost copyWith({
    bool? isLiked,
    int? likes,
    int? commentCount,
  }) =>
      SocialPost(
        id: id,
        authorId: authorId,
        authorName: authorName,
        authorAvatar: authorAvatar,
        content: content,
        type: type,
        likes: likes ?? this.likes,
        commentCount: commentCount ?? this.commentCount,
        createdAt: createdAt,
        imageUrl: imageUrl,
        groupId: groupId,
        groupName: groupName,
        isLiked: isLiked ?? this.isLiked,
        tags: tags,
      );
}

// ── Study Group ───────────────────────────────────────────────────────────

@immutable
class StudyGroup {
  const StudyGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.subject,
    required this.examTag,
    required this.isPublic,
    this.coverEmoji = '📚',
    this.role,
    this.isJoined = false,
  });

  final String id;
  final String name;
  final String description;
  final int memberCount;
  final String subject;
  final String examTag;
  final bool isPublic;
  final String coverEmoji;
  final GroupRole? role;
  final bool isJoined;

  StudyGroup copyWith({bool? isJoined, GroupRole? role}) => StudyGroup(
        id: id,
        name: name,
        description: description,
        memberCount: memberCount,
        subject: subject,
        examTag: examTag,
        isPublic: isPublic,
        coverEmoji: coverEmoji,
        role: role ?? this.role,
        isJoined: isJoined ?? this.isJoined,
      );
}

// ── Forum Question ────────────────────────────────────────────────────────

@immutable
class ForumQuestion {
  const ForumQuestion({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.title,
    required this.body,
    required this.votes,
    required this.answerCount,
    required this.createdAt,
    required this.tags,
    this.isAnswered = false,
    this.isUpvoted = false,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String title;
  final String body;
  final int votes;
  final int answerCount;
  final DateTime createdAt;
  final List<String> tags;
  final bool isAnswered;
  final bool isUpvoted;

  ForumQuestion copyWith({bool? isUpvoted, int? votes}) => ForumQuestion(
        id: id,
        authorId: authorId,
        authorName: authorName,
        authorAvatar: authorAvatar,
        title: title,
        body: body,
        votes: votes ?? this.votes,
        answerCount: answerCount,
        createdAt: createdAt,
        tags: tags,
        isAnswered: isAnswered,
        isUpvoted: isUpvoted ?? this.isUpvoted,
      );
}

// ── Marketplace Deck ──────────────────────────────────────────────────────

@immutable
class MarketplaceDeck {
  const MarketplaceDeck({
    required this.id,
    required this.title,
    required this.authorName,
    required this.authorAvatar,
    required this.cardCount,
    required this.downloads,
    required this.rating,
    required this.subject,
    required this.examTag,
    this.isPremium = false,
    this.priceUsd,
  });

  final String id;
  final String title;
  final String authorName;
  final String authorAvatar;
  final int cardCount;
  final int downloads;
  final double rating;
  final String subject;
  final String examTag;
  final bool isPremium;
  final double? priceUsd;
}

// ── Friend ────────────────────────────────────────────────────────────────

@immutable
class Friend {
  const Friend({
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.status,
    this.xp = 0,
    this.streak = 0,
  });

  final String userId;
  final String name;
  final String avatarUrl;
  final FriendStatus status;
  final int xp;
  final int streak;
}
