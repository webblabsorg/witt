import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../models/content_pack.dart';
import '../providers/offline_providers.dart';

class OfflineScreen extends ConsumerWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(offlineSyncProvider);
    final packs = ref.watch(contentPacksProvider);
    final downloaded = ref.watch(downloadedPacksProvider);
    final storageUsed = ref.watch(totalStorageUsedProvider);
    final theme = Theme.of(context);

    final byCategory = <ContentPackCategory, List<ContentPack>>{};
    for (final p in packs) {
      byCategory.putIfAbsent(p.category, () => []).add(p);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Offline & Downloads'),
            actions: [
              if (syncStatus.isOnline)
                IconButton(
                  icon: syncStatus.isSyncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.sync),
                  onPressed: syncStatus.isSyncing
                      ? null
                      : () => ref.read(offlineSyncProvider.notifier).sync(),
                ),
            ],
          ),

          // ── Sync status banner ────────────────────────────────────
          SliverToBoxAdapter(
            child: _SyncBanner(status: syncStatus),
          ),

          // ── Storage summary ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(WittSpacing.lg),
              child: _StorageSummary(
                downloadedCount: downloaded.length,
                storageUsedBytes: storageUsed,
              ),
            ),
          ),

          // ── Downloaded packs ──────────────────────────────────────
          if (downloaded.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    WittSpacing.lg, 0, WittSpacing.lg, WittSpacing.sm),
                child: Text('Downloaded',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _PackTile(
                  pack: downloaded[i],
                  onAction: () => _handlePackAction(context, ref, downloaded[i]),
                ),
                childCount: downloaded.length,
              ),
            ),
          ],

          // ── Available by category ─────────────────────────────────
          ...byCategory.entries
              .where((e) =>
                  e.value.any((p) => !p.isDownloaded && !p.isDownloading))
              .expand((entry) => [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(WittSpacing.lg,
                            WittSpacing.lg, WittSpacing.lg, WittSpacing.sm),
                        child: Text(
                          _categoryLabel(entry.key),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final available = entry.value
                              .where((p) => !p.isDownloaded)
                              .toList();
                          return _PackTile(
                            pack: available[i],
                            onAction: () => _handlePackAction(
                                context, ref, available[i]),
                          );
                        },
                        childCount: entry.value
                            .where((p) => !p.isDownloaded)
                            .length,
                      ),
                    ),
                  ]),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _handlePackAction(
      BuildContext context, WidgetRef ref, ContentPack pack) {
    if (pack.isDownloading) return;
    if (pack.isDownloaded) {
      _confirmDelete(context, ref, pack);
    } else {
      ref.read(contentPacksProvider.notifier).downloadPack(pack.id);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, ContentPack pack) async {
    final nav = Navigator.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete download?'),
        content: Text(
            '${pack.title} (${pack.sizeLabel}) will be removed from your device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: WittColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(contentPacksProvider.notifier).deletePack(pack.id);
    }
    // suppress unused variable warning
    nav.toString();
  }

  String _categoryLabel(ContentPackCategory c) => switch (c) {
        ContentPackCategory.examPrep => 'Exam Prep',
        ContentPackCategory.vocabulary => 'Vocabulary',
        ContentPackCategory.flashcards => 'Flashcards',
        ContentPackCategory.practiceTests => 'Practice Tests',
        ContentPackCategory.studyGuides => 'Study Guides',
      };
}

// ── Sync banner ───────────────────────────────────────────────────────────

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.status});
  final OfflineSyncStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (status.isOnline && status.pendingUploads == 0) {
      return const SizedBox.shrink();
    }

    final (color, icon, message) = !status.isOnline
        ? (
            WittColors.warning,
            Icons.wifi_off,
            'You\'re offline · Changes saved locally'
          )
        : (
            WittColors.primary,
            Icons.cloud_upload,
            '${status.pendingUploads} change${status.pendingUploads == 1 ? '' : 's'} pending sync'
          );

    return Container(
      margin: const EdgeInsets.fromLTRB(
          WittSpacing.lg, WittSpacing.sm, WittSpacing.lg, 0),
      padding: const EdgeInsets.symmetric(
          horizontal: WittSpacing.md, vertical: WittSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(WittSpacing.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: WittSpacing.sm),
          Expanded(
            child: Text(message,
                style: theme.textTheme.labelMedium?.copyWith(color: color)),
          ),
          if (status.lastSyncedAt != null)
            Text(
              'Last sync: ${_timeAgo(status.lastSyncedAt!)}',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: WittColors.textTertiary),
            ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ── Storage summary ───────────────────────────────────────────────────────

class _StorageSummary extends StatelessWidget {
  const _StorageSummary({
    required this.downloadedCount,
    required this.storageUsedBytes,
  });
  final int downloadedCount;
  final int storageUsedBytes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usedMB = storageUsedBytes / (1024 * 1024);
    final totalMB = 500.0; // 500 MB free tier limit
    final progress = (usedMB / totalMB).clamp(0.0, 1.0);
    final color = progress > 0.8
        ? WittColors.error
        : progress > 0.6
            ? WittColors.warning
            : WittColors.primary;

    return Container(
      padding: const EdgeInsets.all(WittSpacing.md),
      decoration: BoxDecoration(
        color: WittColors.surfaceVariant,
        borderRadius: BorderRadius.circular(WittSpacing.md),
        border: Border.all(color: WittColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage, size: 18, color: WittColors.textSecondary),
              const SizedBox(width: WittSpacing.sm),
              Text('Offline Storage',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('$downloadedCount pack${downloadedCount == 1 ? '' : 's'}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: WittColors.textTertiary)),
            ],
          ),
          const SizedBox(height: WittSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: WittColors.outline,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${usedMB.toStringAsFixed(1)} MB used of ${totalMB.toStringAsFixed(0)} MB',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: WittColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ── Pack tile ─────────────────────────────────────────────────────────────

class _PackTile extends StatelessWidget {
  const _PackTile({required this.pack, required this.onAction});
  final ContentPack pack;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          WittSpacing.lg, 0, WittSpacing.lg, WittSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(WittSpacing.md),
        decoration: BoxDecoration(
          color: WittColors.surfaceVariant,
          borderRadius: BorderRadius.circular(WittSpacing.sm),
          border: Border.all(
            color: pack.isDownloaded
                ? WittColors.success.withValues(alpha: 0.3)
                : WittColors.outline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(pack.examEmoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: WittSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pack.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (pack.isPremium)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: WittColors.xp.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('PRO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: WittColors.xp,
                                  )),
                            ),
                        ],
                      ),
                      Text(
                        '${pack.questionCount} items · ${pack.sizeLabel}',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: WittColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: WittSpacing.sm),
                _ActionButton(pack: pack, onTap: onAction),
              ],
            ),
            if (pack.isDownloading) ...[
              const SizedBox(height: WittSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pack.downloadProgress,
                  backgroundColor: WittColors.outline,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      WittColors.primary),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${(pack.downloadProgress * 100).round()}% downloaded',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: WittColors.textTertiary),
              ),
            ],
            if (!pack.isDownloading) ...[
              const SizedBox(height: 4),
              Text(
                pack.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: WittColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.pack, required this.onTap});
  final ContentPack pack;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (pack.isDownloading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (pack.isDownloaded) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: WittColors.successContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: WittColors.success.withValues(alpha: 0.4)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, size: 12, color: WittColors.success),
              SizedBox(width: 3),
              Text('Saved',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: WittColors.success,
                  )),
            ],
          ),
        ),
      );
    }

    if (pack.status == ContentPackStatus.updateAvailable) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: WittColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: WittColors.warning.withValues(alpha: 0.4)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.update, size: 12, color: WittColors.warning),
              SizedBox(width: 3),
              Text('Update',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: WittColors.warning,
                  )),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: pack.isPremium ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: pack.isPremium
              ? WittColors.surfaceVariant
              : WittColors.primaryContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: pack.isPremium
                ? WittColors.outline
                : WittColors.primary.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              pack.isPremium ? Icons.lock : Icons.download,
              size: 12,
              color: pack.isPremium
                  ? WittColors.textTertiary
                  : WittColors.primary,
            ),
            const SizedBox(width: 3),
            Text(
              pack.isPremium ? 'Pro' : 'Get',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: pack.isPremium
                    ? WittColors.textTertiary
                    : WittColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
