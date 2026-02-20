import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_monetization/witt_monetization.dart';
import 'package:witt_ui/witt_ui.dart';

import '../models/social_models.dart';
import '../providers/social_providers.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Add Friend',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add Friend — coming soon')),
            ),
          ),
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _tab,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Feed'),
            Tab(text: 'Groups'),
            Tab(text: 'Forum'),
            Tab(text: 'Market'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _FeedTab(isDark: isDark),
          _GroupsTab(isDark: isDark),
          _ForumTab(isDark: isDark),
          _MarketplaceTab(isDark: isDark),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tab,
        builder: (_, __) => switch (_tab.index) {
          0 => FloatingActionButton.extended(
            onPressed: () => _showCreatePost(context),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Post'),
            backgroundColor: WittColors.primary,
            foregroundColor: Colors.white,
          ),
          1 => FloatingActionButton.extended(
            onPressed: () {},
            icon: const Icon(Icons.group_add_rounded),
            label: const Text('New Group'),
            backgroundColor: WittColors.secondary,
            foregroundColor: Colors.white,
          ),
          2 => FloatingActionButton.extended(
            onPressed: () {},
            icon: const Icon(Icons.help_outline_rounded),
            label: const Text('Ask'),
            backgroundColor: WittColors.accent,
            foregroundColor: Colors.white,
          ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  void _showCreatePost(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePostSheet(controller: ctrl),
    );
  }
}

// ── Feed Tab ──────────────────────────────────────────────────────────────

class _FeedTab extends ConsumerWidget {
  const _FeedTab({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(feedProvider);
    final friends = ref.watch(friendsProvider);
    final accepted = friends
        .where((f) => f.status == FriendStatus.accepted)
        .toList();

    return RefreshIndicator(
      color: WittColors.primary,
      onRefresh: () async => Future.delayed(const Duration(milliseconds: 600)),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          if (accepted.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WittSpacing.lg,
                WittSpacing.md,
                WittSpacing.lg,
                0,
              ),
              child: Text(
                'Friends',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: WittSpacing.lg,
                  vertical: WittSpacing.sm,
                ),
                itemCount: accepted.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: WittSpacing.md),
                itemBuilder: (_, i) => Column(
                  children: [
                    WittAvatar(
                      initials: accepted[i].avatarUrl,
                      size: WittAvatarSize.md,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      accepted[i].name.split(' ').first,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: WittSpacing.lg),
          ],
          ...posts.map((p) => _PostCard(post: p, isDark: isDark)),
        ],
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post, required this.isDark});
  final SocialPost post;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final diff = DateTime.now().difference(post.createdAt);
    final timeAgo = diff.inMinutes < 60
        ? '${diff.inMinutes}m ago'
        : diff.inHours < 24
        ? '${diff.inHours}h ago'
        : '${diff.inDays}d ago';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: WittSpacing.lg,
        vertical: WittSpacing.sm,
      ),
      child: WittCard(
        padding: const EdgeInsets.all(WittSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                WittAvatar(
                  initials: post.authorAvatar,
                  size: WittAvatarSize.sm,
                ),
                const SizedBox(width: WittSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName, style: theme.textTheme.titleSmall),
                      Text(
                        post.groupName != null
                            ? '${post.groupName} · $timeAgo'
                            : timeAgo,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? WittColors.textSecondaryDark
                              : WittColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (post.type == PostType.question)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: WittSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: WittColors.accent.withAlpha(26),
                      borderRadius: WittSpacing.borderRadiusFull,
                    ),
                    child: Text(
                      'Q&A',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: WittColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: WittSpacing.sm),
            Text(post.content, style: theme.textTheme.bodyMedium),
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: WittSpacing.sm),
              Wrap(
                spacing: WittSpacing.xs,
                children: post.tags
                    .map((t) => WittChip(label: '#$t', onTap: () {}))
                    .toList(),
              ),
            ],
            const SizedBox(height: WittSpacing.sm),
            Row(
              children: [
                GestureDetector(
                  onTap: () =>
                      ref.read(feedProvider.notifier).toggleLike(post.id),
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 18,
                        color: post.isLiked ? Colors.red : null,
                      ),
                      const SizedBox(width: 4),
                      Text('${post.likes}', style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
                const SizedBox(width: WittSpacing.lg),
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${post.commentCount}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.share_outlined, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Groups Tab ────────────────────────────────────────────────────────────

class _GroupsTab extends ConsumerWidget {
  const _GroupsTab({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider);
    final isPaid = ref.watch(isPaidProvider);
    final joined = groups.where((g) => g.isJoined).toList();
    final discover = groups.where((g) => !g.isJoined).toList();
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        WittSpacing.lg,
        WittSpacing.md,
        WittSpacing.lg,
        100,
      ),
      children: [
        if (!isPaid)
          _FreeLimitBanner(
            message: 'Free plan: join up to 2 groups. Upgrade for unlimited.',
            current: joined.length,
            limit: 2,
          ),
        if (joined.isNotEmpty) ...[
          Text('My Groups', style: theme.textTheme.titleSmall),
          const SizedBox(height: WittSpacing.sm),
          ...joined.map(
            (g) => _GroupCard(group: g, isDark: isDark, isPaid: isPaid),
          ),
          const SizedBox(height: WittSpacing.lg),
        ],
        Text('Discover', style: theme.textTheme.titleSmall),
        const SizedBox(height: WittSpacing.sm),
        ...discover.map(
          (g) => _GroupCard(group: g, isDark: isDark, isPaid: isPaid),
        ),
      ],
    );
  }
}

class _GroupCard extends ConsumerWidget {
  const _GroupCard({
    required this.group,
    required this.isDark,
    required this.isPaid,
  });
  final StudyGroup group;
  final bool isDark;
  final bool isPaid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canJoin = ref.read(groupsProvider.notifier).canJoin(isPaid);

    return Padding(
      padding: const EdgeInsets.only(bottom: WittSpacing.sm),
      child: WittCard(
        padding: const EdgeInsets.all(WittSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: WittColors.primary.withAlpha(26),
                borderRadius: WittSpacing.borderRadiusMd,
              ),
              child: Center(
                child: Text(
                  group.coverEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: WittSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name, style: theme.textTheme.titleSmall),
                  Text(
                    '${group.memberCount} members · ${group.examTag}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? WittColors.textSecondaryDark
                          : WittColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            WittButton(
              label: group.isJoined ? 'Joined' : 'Join',
              onPressed: (!group.isJoined && !canJoin)
                  ? null
                  : () => ref
                        .read(groupsProvider.notifier)
                        .toggleJoin(group.id, isPaid),
              variant: group.isJoined
                  ? WittButtonVariant.outline
                  : WittButtonVariant.primary,
              size: WittButtonSize.sm,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Forum Tab ─────────────────────────────────────────────────────────────

class _ForumTab extends ConsumerWidget {
  const _ForumTab({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(forumProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        WittSpacing.lg,
        WittSpacing.md,
        WittSpacing.lg,
        100,
      ),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Unanswered', 'SAT', 'GRE', 'WAEC', 'IELTS']
                .map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(right: WittSpacing.sm),
                    child: WittChip(label: t, onTap: () {}),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: WittSpacing.md),
        ...questions.map((q) => _QuestionCard(q: q, isDark: isDark)),
      ],
    );
  }
}

class _QuestionCard extends ConsumerWidget {
  const _QuestionCard({required this.q, required this.isDark});
  final ForumQuestion q;
  final bool isDark;

  void _showReportMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(WittSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Question',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: WittSpacing.md),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: WittColors.error),
              title: const Text('Inappropriate content'),
              onTap: () {
                ref.read(forumProvider.notifier).reportQuestion(q.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Question reported. Thank you.'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded),
              title: const Text('Spam or misleading'),
              onTap: () {
                ref.read(forumProvider.notifier).reportQuestion(q.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Question reported. Thank you.'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: WittSpacing.sm),
      child: GestureDetector(
        onLongPress: () => _showReportMenu(context, ref),
        child: WittCard(
          padding: const EdgeInsets.all(WittSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  GestureDetector(
                    onTap: () =>
                        ref.read(forumProvider.notifier).toggleUpvote(q.id),
                    child: Icon(
                      q.isUpvoted
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_upward_outlined,
                      color: q.isUpvoted ? WittColors.primary : null,
                      size: 20,
                    ),
                  ),
                  Text(
                    '${q.votes}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: q.isUpvoted ? WittColors.primary : null,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: WittSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (q.isAnswered)
                      Container(
                        margin: const EdgeInsets.only(bottom: WittSpacing.xs),
                        padding: const EdgeInsets.symmetric(
                          horizontal: WittSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: WittColors.success.withAlpha(26),
                          borderRadius: WittSpacing.borderRadiusFull,
                        ),
                        child: Text(
                          '✓ Answered',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: WittColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Text(
                      q.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: WittSpacing.xs),
                    Text(
                      q.body,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? WittColors.textSecondaryDark
                            : WittColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: WittSpacing.sm),
                    Row(
                      children: [
                        WittAvatar(
                          initials: q.authorAvatar,
                          size: WittAvatarSize.xs,
                        ),
                        const SizedBox(width: 4),
                        Text(q.authorName, style: theme.textTheme.labelSmall),
                        const Spacer(),
                        const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${q.answerCount}',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: WittSpacing.xs),
                    Wrap(
                      spacing: WittSpacing.xs,
                      children: q.tags
                          .map((t) => WittChip(label: '#$t', onTap: () {}))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Marketplace Tab ───────────────────────────────────────────────────────

class _MarketplaceTab extends ConsumerWidget {
  const _MarketplaceTab({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decks = ref.watch(marketplaceProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        WittSpacing.lg,
        WittSpacing.md,
        WittSpacing.lg,
        100,
      ),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Free', 'SAT', 'GRE', 'WAEC', 'IELTS', 'JAMB']
                .map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(right: WittSpacing.sm),
                    child: WittChip(label: t, onTap: () {}),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: WittSpacing.md),
        ...decks.map(
          (d) => Padding(
            padding: const EdgeInsets.only(bottom: WittSpacing.sm),
            child: GestureDetector(
              onLongPress: () => showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.all(WittSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Report Deck', style: theme.textTheme.titleMedium),
                      const SizedBox(height: WittSpacing.md),
                      ListTile(
                        leading: const Icon(
                          Icons.flag_outlined,
                          color: WittColors.error,
                        ),
                        title: const Text('Inappropriate content'),
                        onTap: () {
                          ref
                              .read(marketplaceProvider.notifier)
                              .reportDeck(d.id);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Deck reported. Thank you.'),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.block_rounded),
                        title: const Text('Spam or misleading'),
                        onTap: () {
                          ref
                              .read(marketplaceProvider.notifier)
                              .reportDeck(d.id);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Deck reported. Thank you.'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              child: WittCard(
                padding: const EdgeInsets.all(WittSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.title,
                            style: theme.textTheme.titleSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: WittSpacing.xs),
                          Row(
                            children: [
                              WittAvatar(
                                initials: d.authorAvatar,
                                size: WittAvatarSize.xs,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                d.authorName,
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: WittSpacing.xs),
                          Row(
                            children: [
                              const Icon(Icons.style_rounded, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '${d.cardCount} cards',
                                style: theme.textTheme.labelSmall,
                              ),
                              const SizedBox(width: WittSpacing.md),
                              const Icon(Icons.download_rounded, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '${d.downloads}',
                                style: theme.textTheme.labelSmall,
                              ),
                              const SizedBox(width: WittSpacing.md),
                              const Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: WittColors.streak,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                d.rating.toStringAsFixed(1),
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: WittSpacing.md),
                    WittButton(
                      label: d.isPremium
                          ? '\$${d.priceUsd?.toStringAsFixed(2)}'
                          : 'Get',
                      onPressed: () {},
                      variant: d.isPremium
                          ? WittButtonVariant.primary
                          : WittButtonVariant.outline,
                      size: WittButtonSize.sm,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Free Limit Banner ─────────────────────────────────────────────────────

class _FreeLimitBanner extends StatelessWidget {
  const _FreeLimitBanner({
    required this.message,
    required this.current,
    required this.limit,
  });
  final String message;
  final int current;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: WittSpacing.md),
      padding: const EdgeInsets.all(WittSpacing.md),
      decoration: BoxDecoration(
        color: WittColors.secondary.withAlpha(26),
        borderRadius: WittSpacing.borderRadiusMd,
        border: Border.all(color: WittColors.secondary.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: WittColors.secondary,
            size: 18,
          ),
          const SizedBox(width: WittSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: WittColors.secondary,
              ),
            ),
          ),
          Text(
            '$current/$limit',
            style: theme.textTheme.labelMedium?.copyWith(
              color: WittColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Create Post Sheet ─────────────────────────────────────────────────────

class _CreatePostSheet extends ConsumerStatefulWidget {
  const _CreatePostSheet({required this.controller});
  final TextEditingController controller;

  @override
  ConsumerState<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<_CreatePostSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPost = ref.watch(canPostTodayProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        WittSpacing.lg,
        WittSpacing.lg,
        WittSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + WittSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Create Post', style: theme.textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: WittSpacing.md),
          if (!canPost)
            Container(
              padding: const EdgeInsets.all(WittSpacing.md),
              decoration: BoxDecoration(
                color: WittColors.secondary.withAlpha(26),
                borderRadius: WittSpacing.borderRadiusMd,
              ),
              child: Text(
                'Free plan: 1 post per day. Upgrade for unlimited posting.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: WittColors.secondary,
                ),
              ),
            )
          else ...[
            TextField(
              controller: widget.controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Share something with the community…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: WittSpacing.md),
            WittButton(
              label: 'Post',
              onPressed: () {
                final text = widget.controller.text.trim();
                if (text.isEmpty) return;
                ref.read(feedProvider.notifier).addPost(text, []);
                Navigator.pop(context);
              },
              variant: WittButtonVariant.primary,
            ),
          ],
        ],
      ),
    );
  }
}
