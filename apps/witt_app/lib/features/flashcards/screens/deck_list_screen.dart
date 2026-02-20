import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../models/flashcard.dart';
import '../providers/flashcard_providers.dart';
import '../providers/ai_flashcard_provider.dart';
import 'deck_detail_screen.dart';
import 'create_deck_screen.dart';

class DeckListScreen extends ConsumerWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decks = ref.watch(deckListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Flashcards'),
            actions: [
              IconButton(icon: const Icon(Icons.search), onPressed: () {}),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _createDeck(context),
              ),
            ],
          ),

          // ── Stats bar ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: WittSpacing.lg,
                vertical: WittSpacing.sm,
              ),
              child: _StatsBar(decks: decks),
            ),
          ),

          // ── Due today banner ──────────────────────────────────────────
          if (decks.any((d) => d.dueCount > 0))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  WittSpacing.lg,
                  0,
                  WittSpacing.lg,
                  WittSpacing.sm,
                ),
                child: _DueTodayBanner(decks: decks),
              ),
            ),

          // ── Section header ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                WittSpacing.lg,
                WittSpacing.sm,
                WittSpacing.lg,
                WittSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    'My Decks',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${decks.length} deck${decks.length == 1 ? '' : 's'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: WittColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Deck list ─────────────────────────────────────────────────
          decks.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(WittSpacing.xl),
                    child: WittEmptyState(
                      icon: Icons.style_outlined,
                      title: 'No flashcard decks yet',
                      subtitle: 'Create your first deck to start studying',
                      actionLabel: 'Create Deck',
                      onAction: () => _createDeck(context),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final deck = decks[index];
                    return _DeckTile(
                      deck: deck,
                      onTap: () => _openDeck(context, deck.id),
                      onDelete: () => ref
                          .read(deckListProvider.notifier)
                          .deleteDeck(deck.id),
                    );
                  }, childCount: decks.length),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: WittSpacing.xl)),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'ai_deck',
            onPressed: () => _showAiGenerateSheet(context, ref),
            backgroundColor: WittColors.secondary,
            foregroundColor: Colors.white,
            tooltip: 'Generate with AI',
            child: const Icon(Icons.auto_awesome),
          ),
          const SizedBox(height: WittSpacing.sm),
          FloatingActionButton.extended(
            heroTag: 'new_deck',
            onPressed: () => _createDeck(context),
            icon: const Icon(Icons.add),
            label: const Text('New Deck'),
            backgroundColor: WittColors.primary,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  void _createDeck(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreateDeckScreen()));
  }

  void _openDeck(BuildContext context, String deckId) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => DeckDetailScreen(deckId: deckId)));
  }

  void _showAiGenerateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AiGenerateDeckSheet(ref: ref),
    );
  }
}

// ── AI Generate Deck Sheet ────────────────────────────────────────────────

class _AiGenerateDeckSheet extends ConsumerStatefulWidget {
  const _AiGenerateDeckSheet({required this.ref});
  final WidgetRef ref;

  @override
  ConsumerState<_AiGenerateDeckSheet> createState() =>
      _AiGenerateDeckSheetState();
}

class _AiGenerateDeckSheetState extends ConsumerState<_AiGenerateDeckSheet> {
  final _topicController = TextEditingController();
  int _cardCount = 10;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final genState = ref.watch(aiFlashcardGenProvider);
    final isLoading = genState.status == AiFlashcardGenStatus.loading;

    ref.listen(aiFlashcardGenProvider, (_, next) {
      if (next.status == AiFlashcardGenStatus.done &&
          next.generatedDeckId != null) {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DeckDetailScreen(deckId: next.generatedDeckId!),
          ),
        );
        ref.read(aiFlashcardGenProvider.notifier).reset();
      }
    });

    return Padding(
      padding: EdgeInsets.fromLTRB(
        WittSpacing.lg,
        WittSpacing.lg,
        WittSpacing.lg,
        WittSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: WittColors.secondary),
              const SizedBox(width: WittSpacing.sm),
              Text(
                'Generate Deck with AI',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: WittSpacing.md),
          TextField(
            controller: _topicController,
            decoration: const InputDecoration(
              labelText: 'Topic',
              hintText: 'e.g. SAT Vocabulary, Organic Chemistry',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
          ),
          const SizedBox(height: WittSpacing.md),
          Row(
            children: [
              Text('Cards:', style: theme.textTheme.bodyMedium),
              const SizedBox(width: WittSpacing.sm),
              ...([5, 10, 15, 20].map((n) {
                final selected = _cardCount == n;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _cardCount = n),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? WittColors.secondary
                            : WittColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? WittColors.secondary
                              : WittColors.outline,
                        ),
                      ),
                      child: Text(
                        '$n',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: selected ? Colors.white : null,
                          fontWeight: selected ? FontWeight.w700 : null,
                        ),
                      ),
                    ),
                  ),
                );
              })),
            ],
          ),
          if (genState.status == AiFlashcardGenStatus.error ||
              genState.status == AiFlashcardGenStatus.limited)
            Padding(
              padding: const EdgeInsets.only(top: WittSpacing.sm),
              child: Text(
                genState.errorMessage ?? 'An error occurred',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: WittColors.error,
                ),
              ),
            ),
          const SizedBox(height: WittSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: WittButton(
              label: isLoading ? 'Generating…' : 'Generate Deck',
              onPressed: isLoading || _topicController.text.trim().isEmpty
                  ? null
                  : () => ref
                        .read(aiFlashcardGenProvider.notifier)
                        .generateDeck(
                          topic: _topicController.text.trim(),
                          cardCount: _cardCount,
                        ),
              icon: Icons.auto_awesome,
              isLoading: isLoading,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats bar ─────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.decks});
  final List<FlashcardDeck> decks;

  @override
  Widget build(BuildContext context) {
    final totalCards = decks.fold(0, (sum, d) => sum + d.cardCount);
    final totalDue = decks.fold(0, (sum, d) => sum + d.dueCount);
    final totalNew = decks.fold(0, (sum, d) => sum + d.newCount);

    return Row(
      children: [
        _StatItem(
          label: 'Total Cards',
          value: '$totalCards',
          icon: Icons.style,
        ),
        const SizedBox(width: WittSpacing.sm),
        _StatItem(
          label: 'Due Today',
          value: '$totalDue',
          icon: Icons.schedule,
          valueColor: totalDue > 0 ? WittColors.secondary : null,
        ),
        const SizedBox(width: WittSpacing.sm),
        _StatItem(
          label: 'New',
          value: '$totalNew',
          icon: Icons.fiber_new,
          valueColor: totalNew > 0 ? WittColors.accent : null,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: WittSpacing.sm,
          vertical: WittSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: WittColors.surfaceVariant,
          borderRadius: BorderRadius.circular(WittSpacing.xs),
          border: Border.all(color: WittColors.outline),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: valueColor ?? WittColors.textTertiary),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: valueColor,
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
          ],
        ),
      ),
    );
  }
}

// ── Due today banner ──────────────────────────────────────────────────────

class _DueTodayBanner extends StatelessWidget {
  const _DueTodayBanner({required this.decks});
  final List<FlashcardDeck> decks;

  @override
  Widget build(BuildContext context) {
    final totalDue = decks.fold(0, (sum, d) => sum + d.dueCount);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(WittSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            WittColors.secondary.withValues(alpha: 0.15),
            WittColors.primary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(WittSpacing.sm),
        border: Border.all(color: WittColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: WittColors.secondary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule,
              color: WittColors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: WittSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalDue card${totalDue == 1 ? '' : 's'} due today',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Keep your streak going!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: WittColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: WittColors.textTertiary),
        ],
      ),
    );
  }
}

// ── Deck tile ─────────────────────────────────────────────────────────────

class _DeckTile extends StatelessWidget {
  const _DeckTile({
    required this.deck,
    required this.onTap,
    required this.onDelete,
  });

  final FlashcardDeck deck;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deckColor = Color(deck.color);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WittSpacing.lg,
        0,
        WittSpacing.lg,
        WittSpacing.sm,
      ),
      child: Dismissible(
        key: Key(deck.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: WittSpacing.lg),
          decoration: BoxDecoration(
            color: WittColors.error,
            borderRadius: BorderRadius.circular(WittSpacing.sm),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete deck?'),
              content: Text('Delete "${deck.name}"? This cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    'Delete',
                    style: TextStyle(color: WittColors.error),
                  ),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) => onDelete(),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(WittSpacing.sm),
          child: Container(
            padding: const EdgeInsets.all(WittSpacing.md),
            decoration: BoxDecoration(
              color: WittColors.surfaceVariant,
              borderRadius: BorderRadius.circular(WittSpacing.sm),
              border: Border.all(color: WittColors.outline),
            ),
            child: Row(
              children: [
                // Deck icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: deckColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(WittSpacing.xs),
                    border: Border.all(color: deckColor.withValues(alpha: 0.3)),
                  ),
                  alignment: Alignment.center,
                  child: Text(deck.emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: WittSpacing.md),

                // Deck info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (deck.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          deck.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: WittColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _CountBadge(
                            count: deck.cardCount,
                            label: 'cards',
                            color: WittColors.textTertiary,
                          ),
                          if (deck.dueCount > 0) ...[
                            const SizedBox(width: 6),
                            _CountBadge(
                              count: deck.dueCount,
                              label: 'due',
                              color: WittColors.secondary,
                            ),
                          ],
                          if (deck.newCount > 0) ...[
                            const SizedBox(width: 6),
                            _CountBadge(
                              count: deck.newCount,
                              label: 'new',
                              color: WittColors.accent,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Progress ring
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: deck.cardCount == 0
                            ? 0
                            : 1 -
                                  (deck.dueCount + deck.newCount) /
                                      deck.cardCount,
                        backgroundColor: WittColors.outline,
                        valueColor: AlwaysStoppedAnimation<Color>(deckColor),
                        strokeWidth: 3,
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: WittColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
