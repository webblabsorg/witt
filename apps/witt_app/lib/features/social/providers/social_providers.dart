import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:witt_monetization/witt_monetization.dart';
import '../models/social_models.dart';
import '../../../core/persistence/hive_boxes.dart';
import '../../../core/analytics/analytics.dart';
import '../../../core/notifications/notification_service.dart';

// ── Feed Notifier ─────────────────────────────────────────────────────────

class FeedNotifier extends Notifier<List<SocialPost>> {
  @override
  List<SocialPost> build() {
    return [];
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
    return [];
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
  List<ForumQuestion> build() => [];

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
  List<MarketplaceDeck> build() => [];

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
  List<Friend> build() => [];

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
