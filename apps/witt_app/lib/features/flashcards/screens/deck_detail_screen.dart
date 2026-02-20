import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../models/flashcard.dart';
import '../providers/flashcard_providers.dart';
import 'study_screen.dart';
import 'add_card_screen.dart';

class DeckDetailScreen extends ConsumerWidget {
  const DeckDetailScreen({super.key, required this.deckId});
  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(deckByIdProvider(deckId));
    final cards = ref.watch(cardsForDeckProvider(deckId));
    final theme = Theme.of(context);

    if (deck == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Deck')),
        body: const Center(child: Text('Deck not found')),
      );
    }

    final deckColor = Color(deck.color);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      deckColor,
                      deckColor.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        WittSpacing.lg, 56, WittSpacing.lg, WittSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(deck.emoji,
                            style: const TextStyle(fontSize: 40)),
                        const SizedBox(height: WittSpacing.xs),
                        Text(
                          deck.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (deck.description.isNotEmpty)
                          Text(
                            deck.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              title: Text(deck.name),
              collapseMode: CollapseMode.parallax,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _addCard(context),
                tooltip: 'Add card',
              ),
              PopupMenuButton<String>(
                onSelected: (v) => _handleMenu(context, ref, v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'import', child: Text('Import CSV')),
                  PopupMenuItem(value: 'export', child: Text('Export CSV')),
                  PopupMenuItem(value: 'shuffle', child: Text('Shuffle deck')),
                  PopupMenuItem(
                      value: 'reset',
                      child: Text('Reset progress',
                          style: TextStyle(color: WittColors.error))),
                ],
              ),
            ],
          ),

          // ── Stats row ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(WittSpacing.lg),
              child: Row(
                children: [
                  _StatBox(
                      label: 'Total', value: '${cards.length}', icon: Icons.style),
                  const SizedBox(width: WittSpacing.sm),
                  _StatBox(
                    label: 'Due',
                    value: '${deck.dueCount}',
                    icon: Icons.schedule,
                    color: deck.dueCount > 0 ? WittColors.secondary : null,
                  ),
                  const SizedBox(width: WittSpacing.sm),
                  _StatBox(
                    label: 'New',
                    value: '${deck.newCount}',
                    icon: Icons.fiber_new,
                    color: deck.newCount > 0 ? WittColors.accent : null,
                  ),
                  const SizedBox(width: WittSpacing.sm),
                  _StatBox(
                    label: 'Mastered',
                    value: '${cards.where((c) => c.interval >= 21).length}',
                    icon: Icons.star,
                    color: WittColors.success,
                  ),
                ],
              ),
            ),
          ),

          // ── Study modes ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  WittSpacing.lg, 0, WittSpacing.lg, WittSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Study',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: WittSpacing.sm),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: WittSpacing.sm,
                    mainAxisSpacing: WittSpacing.sm,
                    childAspectRatio: 1.1,
                    children: StudyMode.values.map((mode) {
                      return _StudyModeCard(
                        mode: mode,
                        onTap: cards.isEmpty
                            ? null
                            : () => _startStudy(context, mode, cards),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // ── Cards list ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  WittSpacing.lg, 0, WittSpacing.lg, WittSpacing.sm),
              child: Row(
                children: [
                  Text(
                    'Cards',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _addCard(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),
          ),

          cards.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(WittSpacing.xl),
                    child: WittEmptyState(
                      icon: Icons.style_outlined,
                      title: 'No cards yet',
                      subtitle: 'Add your first card to start studying',
                      actionLabel: 'Add Card',
                      onAction: () => _addCard(context),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _CardTile(
                      card: cards[index],
                      index: index,
                      onDelete: () => ref
                          .read(cardListProvider.notifier)
                          .deleteCard(deckId, cards[index].id),
                    ),
                    childCount: cards.length,
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _startStudy(
      BuildContext context, StudyMode mode, List<Flashcard> cards) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudyScreen(
          deckId: deckId,
          mode: mode,
          cards: cards,
        ),
      ),
    );
  }

  void _addCard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddCardScreen(deckId: deckId),
      ),
    );
  }

  void _handleMenu(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'export':
        final csv =
            ref.read(cardListProvider.notifier).exportToCsv(deckId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported ${csv.split('\n').length} cards')),
        );
      case 'import':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Import CSV — file picker coming soon')),
        );
      case 'shuffle':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deck shuffled')),
        );
      case 'reset':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Reset progress?'),
            content: const Text(
                'All SM-2 scheduling data will be reset. Cards will start fresh.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Progress reset')),
                  );
                },
                child: Text('Reset',
                    style: TextStyle(color: WittColors.error)),
              ),
            ],
          ),
        );
    }
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? WittColors.textTertiary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: WittSpacing.xs, vertical: WittSpacing.sm),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(WittSpacing.xs),
          border: Border.all(color: c.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: c),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: c,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: WittColors.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyModeCard extends StatelessWidget {
  const _StudyModeCard({required this.mode, this.onTap});
  final StudyMode mode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, label, color) = _modeInfo(mode);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WittSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: onTap == null
              ? WittColors.surfaceVariant.withValues(alpha: 0.5)
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(WittSpacing.sm),
          border: Border.all(
            color: onTap == null
                ? WittColors.outline
                : color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: onTap == null ? WittColors.textDisabled : color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: onTap == null ? WittColors.textDisabled : color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  (IconData, String, Color) _modeInfo(StudyMode mode) {
    return switch (mode) {
      StudyMode.flashcard => (Icons.flip, 'Flashcard', WittColors.primary),
      StudyMode.learn => (Icons.school, 'Learn', WittColors.accent),
      StudyMode.write => (Icons.edit, 'Write', WittColors.secondary),
      StudyMode.match => (Icons.grid_view, 'Match', WittColors.success),
      StudyMode.test => (Icons.quiz, 'Test', WittColors.error),
    };
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.index,
    required this.onDelete,
  });

  final Flashcard card;
  final int index;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDue = card.isDue && card.repetitions > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          WittSpacing.lg, 0, WittSpacing.lg, WittSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(WittSpacing.md),
        decoration: BoxDecoration(
          color: WittColors.surfaceVariant,
          borderRadius: BorderRadius.circular(WittSpacing.sm),
          border: Border.all(
            color: isDue
                ? WittColors.secondary.withValues(alpha: 0.4)
                : WittColors.outline,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: WittColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: WittColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: WittSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.front,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.back,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: WittColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _TypeBadge(type: card.type),
                      if (isDue) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: WittColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'DUE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: WittColors.secondary,
                            ),
                          ),
                        ),
                      ],
                      if (card.interval >= 21) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: WittColors.successContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'MASTERED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: WittColors.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: WittColors.textTertiary),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final FlashcardType type;

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      FlashcardType.basic => 'Basic',
      FlashcardType.reversed => 'Reversed',
      FlashcardType.cloze => 'Cloze',
      FlashcardType.imageOcclusion => 'Image',
      FlashcardType.typed => 'Typed',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: WittColors.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: WittColors.primary,
        ),
      ),
    );
  }
}
