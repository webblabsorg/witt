import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:witt_monetization/witt_monetization.dart';
import '../models/social_models.dart';
import '../../../core/persistence/hive_boxes.dart';
import '../../../core/analytics/analytics.dart';
import '../../../core/notifications/notification_service.dart';

// ── Sample data ───────────────────────────────────────────────────────────

final _samplePosts = [
  SocialPost(
    id: 'p1',
    authorId: 'u1',
    authorName: 'Amara Osei',
    authorAvatar: 'AO',
    content:
        'Just scored 1480 on my SAT practice test! The AI-generated questions really helped me focus on weak areas. Who else is prepping for SAT 2026? 🎯',
    type: PostType.text,
    likes: 47,
    commentCount: 12,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    tags: ['SAT', 'TestPrep'],
  ),
  SocialPost(
    id: 'p2',
    authorId: 'u2',
    authorName: 'Priya Sharma',
    authorAvatar: 'PS',
    content:
        'Sharing my GRE Vocabulary deck — 500 high-frequency words with mnemonics. Free to download in the Marketplace! 📚',
    type: PostType.resource,
    likes: 134,
    commentCount: 28,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    tags: ['GRE', 'Vocabulary', 'Flashcards'],
  ),
  SocialPost(
    id: 'p3',
    authorId: 'u3',
    authorName: 'Kwame Mensah',
    authorAvatar: 'KM',
    content:
        'Quick tip for WAEC Chemistry: focus on organic reactions and periodic trends. They come up every year. Good luck to everyone writing next month! 🧪',
    type: PostType.text,
    likes: 89,
    commentCount: 19,
    createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    groupId: 'g2',
    groupName: 'WAEC Science Squad',
    tags: ['WAEC', 'Chemistry'],
  ),
  SocialPost(
    id: 'p4',
    authorId: 'u4',
    authorName: 'Sofia Reyes',
    authorAvatar: 'SR',
    content:
        'Does anyone have good resources for IELTS Writing Task 2? I keep struggling with coherence and cohesion. Any tips? 🙏',
    type: PostType.question,
    likes: 23,
    commentCount: 41,
    createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    tags: ['IELTS', 'Writing'],
  ),
  SocialPost(
    id: 'p5',
    authorId: 'u5',
    authorName: 'Aditya Kumar',
    authorAvatar: 'AK',
    content:
        'Study streak: 30 days! 🔥 Consistency is everything. Even 20 minutes a day adds up. Keep going everyone!',
    type: PostType.text,
    likes: 201,
    commentCount: 34,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    tags: ['Motivation', 'Streak'],
  ),
];

final _sampleGroups = [
  const StudyGroup(
    id: 'g1',
    name: 'SAT Math Masters',
    description:
        'Daily practice problems, tips, and peer support for SAT Math.',
    memberCount: 1247,
    subject: 'Mathematics',
    examTag: 'SAT',
    isPublic: true,
    coverEmoji: '📐',
    isJoined: true,
    role: GroupRole.member,
  ),
  const StudyGroup(
    id: 'g2',
    name: 'WAEC Science Squad',
    description:
        'Physics, Chemistry, Biology — all WAEC science subjects covered.',
    memberCount: 892,
    subject: 'Science',
    examTag: 'WAEC',
    isPublic: true,
    coverEmoji: '🧪',
  ),
  const StudyGroup(
    id: 'g3',
    name: 'GRE Verbal Prep',
    description:
        'Vocabulary, reading comprehension, and text completion strategies.',
    memberCount: 634,
    subject: 'English',
    examTag: 'GRE',
    isPublic: true,
    coverEmoji: '📖',
  ),
  const StudyGroup(
    id: 'g4',
    name: 'IELTS Writing Workshop',
    description: 'Essay feedback, band score tips, and writing practice.',
    memberCount: 445,
    subject: 'English',
    examTag: 'IELTS',
    isPublic: true,
    coverEmoji: '✍️',
  ),
  const StudyGroup(
    id: 'g5',
    name: 'JAMB 2026 Prep',
    description: 'All subjects, past questions, and study schedules for JAMB.',
    memberCount: 2103,
    subject: 'General',
    examTag: 'JAMB',
    isPublic: true,
    coverEmoji: '🎓',
    isJoined: true,
    role: GroupRole.member,
  ),
];

final _sampleQuestions = [
  ForumQuestion(
    id: 'q1',
    authorId: 'u6',
    authorName: 'Fatima Al-Hassan',
    authorAvatar: 'FA',
    title: 'How do I approach SAT Evidence-Based Reading passages?',
    body:
        'I always run out of time on the reading section. Should I read the passage first or go straight to the questions?',
    votes: 34,
    answerCount: 8,
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    tags: ['SAT', 'Reading', 'Strategy'],
    isAnswered: true,
  ),
  ForumQuestion(
    id: 'q2',
    authorId: 'u7',
    authorName: 'Liam O\'Brien',
    authorAvatar: 'LO',
    title: 'GRE Quant — is a calculator allowed?',
    body:
        'I\'ve seen conflicting information online. Can someone clarify what tools are available during the GRE Quant section?',
    votes: 21,
    answerCount: 5,
    createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    tags: ['GRE', 'Quant'],
    isAnswered: true,
  ),
  ForumQuestion(
    id: 'q3',
    authorId: 'u8',
    authorName: 'Yuki Tanaka',
    authorAvatar: 'YT',
    title: 'Best strategy for IELTS Listening Section 4?',
    body:
        'Section 4 is a monologue and I find it the hardest. Any tips for note-taking and predicting answers?',
    votes: 15,
    answerCount: 3,
    createdAt: DateTime.now().subtract(const Duration(hours: 10)),
    tags: ['IELTS', 'Listening'],
    isAnswered: false,
  ),
  ForumQuestion(
    id: 'q4',
    authorId: 'u9',
    authorName: 'Chidi Okafor',
    authorAvatar: 'CO',
    title: 'WAEC Biology — how many past questions should I practice?',
    body:
        'I have 10 years of past questions. Is that enough or should I go further back? What\'s the pattern?',
    votes: 28,
    answerCount: 11,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    tags: ['WAEC', 'Biology'],
    isAnswered: true,
  ),
];

final _sampleDecks = [
  const MarketplaceDeck(
    id: 'd1',
    title: 'SAT Vocabulary — 1000 Essential Words',
    authorName: 'Priya Sharma',
    authorAvatar: 'PS',
    cardCount: 1000,
    downloads: 8432,
    rating: 4.8,
    subject: 'English',
    examTag: 'SAT',
  ),
  const MarketplaceDeck(
    id: 'd2',
    title: 'GRE Math Formulas & Concepts',
    authorName: 'Aditya Kumar',
    authorAvatar: 'AK',
    cardCount: 250,
    downloads: 5201,
    rating: 4.7,
    subject: 'Mathematics',
    examTag: 'GRE',
  ),
  const MarketplaceDeck(
    id: 'd3',
    title: 'IELTS Academic Word List',
    authorName: 'Sofia Reyes',
    authorAvatar: 'SR',
    cardCount: 570,
    downloads: 3890,
    rating: 4.6,
    subject: 'English',
    examTag: 'IELTS',
    isPremium: true,
    priceUsd: 2.99,
  ),
  const MarketplaceDeck(
    id: 'd4',
    title: 'WAEC Chemistry — Organic Reactions',
    authorName: 'Kwame Mensah',
    authorAvatar: 'KM',
    cardCount: 180,
    downloads: 2140,
    rating: 4.5,
    subject: 'Chemistry',
    examTag: 'WAEC',
  ),
];

final _sampleFriends = [
  const Friend(
    userId: 'u1',
    name: 'Amara Osei',
    avatarUrl: 'AO',
    status: FriendStatus.accepted,
    xp: 4200,
    streak: 15,
  ),
  const Friend(
    userId: 'u2',
    name: 'Priya Sharma',
    avatarUrl: 'PS',
    status: FriendStatus.accepted,
    xp: 7800,
    streak: 42,
  ),
  const Friend(
    userId: 'u10',
    name: 'James Okonkwo',
    avatarUrl: 'JO',
    status: FriendStatus.pending,
    xp: 1200,
    streak: 3,
  ),
];

// ── Feed Notifier ─────────────────────────────────────────────────────────

class FeedNotifier extends Notifier<List<SocialPost>> {
  @override
  List<SocialPost> build() {
    // Restore liked state from Hive
    final likedIds = Set<String>.from(
      socialBox.get(kKeyLikedPostIds, defaultValue: <String>[]) as List,
    );
    return _samplePosts
        .map((p) => p.copyWith(isLiked: likedIds.contains(p.id)))
        .toList();
  }

  void toggleLike(String postId) {
    state = state.map((p) {
      if (p.id != postId) return p;
      return p.copyWith(
        isLiked: !p.isLiked,
        likes: p.isLiked ? p.likes - 1 : p.likes + 1,
      );
    }).toList();
    // Persist liked set
    final likedIds = state.where((p) => p.isLiked).map((p) => p.id).toList();
    socialBox.put(kKeyLikedPostIds, likedIds);
    final liked = state.firstWhere((p) => p.id == postId).isLiked;
    Analytics.likePost(postId, liked);
  }

  void reportPost(String postId) {
    state = state.map((p) {
      if (p.id != postId) return p;
      return p.copyWith(isReported: true);
    }).toList();
    Analytics.reportContent('feed_post', postId, 'inappropriate');
  }

  Future<void> addPost(String content, List<String> tags) async {
    final post = SocialPost(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      authorId: 'me',
      authorName: 'You',
      authorAvatar: 'ME',
      content: content,
      type: PostType.text,
      likes: 0,
      commentCount: 0,
      createdAt: DateTime.now(),
      tags: tags,
    );
    state = [post, ...state];
    Analytics.createPost(post.type.name, tags);

    // Optimistic local counter update
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastReset =
        socialBox.get(kKeySocialLastResetDate, defaultValue: '') as String;
    final count = lastReset == today
        ? (socialBox.get(kKeyPostsToday, defaultValue: 0) as int)
        : 0;
    socialBox.put(kKeySocialLastResetDate, today);
    socialBox.put(kKeyPostsToday, count + 1);

    // Server-authoritative: call record_social_post RPC
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      try {
        await Supabase.instance.client.rpc(
          'record_social_post',
          params: {'p_user_id': uid},
        );
        // Notify group members if this post is tagged to a group
        if (tags.isNotEmpty) {
          final memberIds = await NotificationService.resolveGroupMemberIds(
            tags.first,
          );
          // Exclude the poster themselves
          final uid2 = Supabase.instance.client.auth.currentUser?.id;
          final recipients = memberIds.where((id) => id != uid2).toList();
          await NotificationService.notifyGroupPost(
            memberUserIds: recipients,
            groupName: tags.first,
            authorName: 'You',
          );
        }
      } on PostgrestException catch (e) {
        if (e.message.contains('post_limit_exceeded')) {
          // Roll back the optimistic post and local counter
          state = state.where((p) => p.id != post.id).toList();
          socialBox.put(kKeyPostsToday, count);
        }
        // Other errors: non-fatal, post stays visible locally
      } catch (_) {
        // Network error: non-fatal
      }
    }
  }
}

final feedProvider = NotifierProvider<FeedNotifier, List<SocialPost>>(
  FeedNotifier.new,
);

// ── Groups Notifier ───────────────────────────────────────────────────────

class GroupsNotifier extends Notifier<List<StudyGroup>> {
  @override
  List<StudyGroup> build() {
    // Restore joined state from Hive
    final joinedIds = Set<String>.from(
      socialBox.get(kKeyJoinedGroupIds, defaultValue: <String>[]) as List,
    );
    return _sampleGroups.map((g) {
      final joined = joinedIds.contains(g.id);
      return g.copyWith(
        isJoined: joined,
        role: joined ? GroupRole.member : null,
      );
    }).toList();
  }

  int get joinedCount => state.where((g) => g.isJoined).length;

  bool canJoin(bool isPaid) {
    if (isPaid) return true;
    return joinedCount < 2;
  }

  void toggleJoin(String groupId, bool isPaid) {
    final group = state.firstWhere((g) => g.id == groupId);
    if (!group.isJoined && !canJoin(isPaid)) return;
    state = state.map((g) {
      if (g.id != groupId) return g;
      return g.copyWith(
        isJoined: !g.isJoined,
        role: !g.isJoined ? GroupRole.member : null,
      );
    }).toList();
    // Persist joined IDs
    final joinedIds = state.where((g) => g.isJoined).map((g) => g.id).toList();
    socialBox.put(kKeyJoinedGroupIds, joinedIds);
    final nowJoined = state.firstWhere((g) => g.id == groupId).isJoined;
    if (nowJoined) {
      Analytics.joinGroup(groupId, group.name);
    } else {
      Analytics.leaveGroup(groupId);
    }
  }
}

final groupsProvider = NotifierProvider<GroupsNotifier, List<StudyGroup>>(
  GroupsNotifier.new,
);

// ── Forum Notifier ────────────────────────────────────────────────────────

class ForumNotifier extends Notifier<List<ForumQuestion>> {
  @override
  List<ForumQuestion> build() => _sampleQuestions;

  void toggleUpvote(String questionId) {
    state = state.map((q) {
      if (q.id != questionId) return q;
      return q.copyWith(
        isUpvoted: !q.isUpvoted,
        votes: q.isUpvoted ? q.votes - 1 : q.votes + 1,
      );
    }).toList();
  }

  void reportQuestion(String questionId) {
    Analytics.reportContent('community_post', questionId, 'inappropriate');
  }
}

final forumProvider = NotifierProvider<ForumNotifier, List<ForumQuestion>>(
  ForumNotifier.new,
);

// ── Marketplace Notifier ──────────────────────────────────────────────────

class MarketplaceNotifier extends Notifier<List<MarketplaceDeck>> {
  @override
  List<MarketplaceDeck> build() => _sampleDecks;

  void reportDeck(String deckId) {
    Analytics.reportContent('deck', deckId, 'inappropriate');
  }
}

final marketplaceProvider =
    NotifierProvider<MarketplaceNotifier, List<MarketplaceDeck>>(
      MarketplaceNotifier.new,
    );

// ── Friends Provider ──────────────────────────────────────────────────────

class FriendsNotifier extends Notifier<List<Friend>> {
  @override
  List<Friend> build() => _sampleFriends;

  List<Friend> get accepted =>
      state.where((f) => f.status == FriendStatus.accepted).toList();

  List<Friend> get pending =>
      state.where((f) => f.status == FriendStatus.pending).toList();
}

final friendsProvider = NotifierProvider<FriendsNotifier, List<Friend>>(
  FriendsNotifier.new,
);

// ── Post limit provider (free: 1 post/day) ────────────────────────────────

/// Async provider: fetches today's post count from the server on first read,
/// falls back to local Hive counter when unauthenticated or offline.
final postsRemainingProvider = FutureProvider<int>((ref) async {
  final isPaid = ref.watch(isPaidProvider);
  if (isPaid) return 999;

  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid != null) {
    try {
      final count =
          await Supabase.instance.client.rpc(
                'get_posts_today',
                params: {'p_user_id': uid},
              )
              as int;
      // Sync local Hive with server value
      final today = DateTime.now().toIso8601String().substring(0, 10);
      socialBox.put(kKeySocialLastResetDate, today);
      socialBox.put(kKeyPostsToday, count);
      return (1 - count).clamp(0, 1);
    } catch (_) {
      // Fall through to local
    }
  }

  // Local fallback
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final lastReset =
      socialBox.get(kKeySocialLastResetDate, defaultValue: '') as String;
  final postsToday = lastReset == today
      ? (socialBox.get(kKeyPostsToday, defaultValue: 0) as int)
      : 0;
  return (1 - postsToday).clamp(0, 1);
});

/// Synchronous convenience: true if the user can post right now.
final canPostTodayProvider = Provider<bool>((ref) {
  final isPaid = ref.watch(isPaidProvider);
  if (isPaid) return true;
  // Use async value if available, otherwise fall back to local Hive
  final remaining = ref.watch(postsRemainingProvider);
  return remaining.when(
    data: (r) => r > 0,
    loading: () {
      // Local fallback while loading
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final lastReset =
          socialBox.get(kKeySocialLastResetDate, defaultValue: '') as String;
      final postsToday = lastReset == today
          ? (socialBox.get(kKeyPostsToday, defaultValue: 0) as int)
          : 0;
      return postsToday < 1;
    },
    error: (_, __) => false,
  );
});
