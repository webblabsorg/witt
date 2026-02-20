import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../models/vocabulary.dart';
import '../providers/vocabulary_providers.dart';

class VocabularyScreen extends ConsumerStatefulWidget {
  const VocabularyScreen({super.key});

  @override
  ConsumerState<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends ConsumerState<VocabularyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Vocabulary'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Dictionary'),
                Tab(text: 'My Words'),
                Tab(text: 'Lists'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: const [
            _DictionaryTab(),
            _SavedWordsTab(),
            _VocabListsTab(),
          ],
        ),
      ),
    );
  }
}

// ── Dictionary tab ────────────────────────────────────────────────────────

class _DictionaryTab extends ConsumerStatefulWidget {
  const _DictionaryTab();

  @override
  ConsumerState<_DictionaryTab> createState() => _DictionaryTabState();
}

class _DictionaryTabState extends ConsumerState<_DictionaryTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(dictionarySearchProvider);
    final wordOfDay = ref.watch(wordOfDayProvider);
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        // ── Search bar ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(WittSpacing.lg),
            child: TextField(
              controller: _searchController,
              onChanged: (q) =>
                  ref.read(dictionarySearchProvider.notifier).search(q),
              decoration: InputDecoration(
                hintText: 'Search dictionary…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(dictionarySearchProvider.notifier).clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(WittSpacing.sm),
                ),
                filled: true,
                fillColor: WittColors.surfaceVariant,
              ),
            ),
          ),
        ),

        // ── Search results ─────────────────────────────────────────────
        if (searchState.query.isNotEmpty) ...[
          if (searchState.isLoading)
            const SliverToBoxAdapter(child: Center(child: WittLoading()))
          else if (searchState.results.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(WittSpacing.xl),
                child: WittEmptyState(
                  icon: Icons.search_off,
                  title: 'No results for "${searchState.query}"',
                  subtitle: 'Try a different spelling or search term',
                ),
              ),
            )
          else ...[
            if (searchState.currentWord != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: WittSpacing.lg,
                  ),
                  child: _WordCard(word: searchState.currentWord!),
                ),
              ),
            if (searchState.results.length > 1) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    WittSpacing.lg,
                    WittSpacing.lg,
                    WittSpacing.lg,
                    WittSpacing.sm,
                  ),
                  child: Text(
                    'Other results',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: WittColors.textSecondary,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final word = searchState.results[index + 1];
                  return _WordListTile(
                    word: word,
                    onTap: () => ref
                        .read(dictionarySearchProvider.notifier)
                        .selectWord(word),
                  );
                }, childCount: searchState.results.length - 1),
              ),
            ],
          ],
        ] else ...[
          // ── Word of the Day ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                WittSpacing.lg,
                0,
                WittSpacing.lg,
                WittSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: WittColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.wb_sunny, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'WORD OF THE DAY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: WittSpacing.sm),
                  _WordCard(word: wordOfDay, isWordOfDay: true),
                ],
              ),
            ),
          ),

          // ── Recent searches ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                WittSpacing.lg,
                WittSpacing.md,
                WittSpacing.lg,
                WittSpacing.sm,
              ),
              child: Text(
                'Browse Dictionary',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final word = _localDictionary[index];
              return _WordListTile(
                word: word,
                onTap: () {
                  _searchController.text = word.word;
                  ref.read(dictionarySearchProvider.notifier).search(word.word);
                },
              );
            }, childCount: _localDictionary.length),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// ── Word card ─────────────────────────────────────────────────────────────

class _WordCard extends ConsumerWidget {
  const _WordCard({required this.word, this.isWordOfDay = false});
  final VocabWord word;
  final bool isWordOfDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSaved = ref.watch(
      savedWordsProvider.select((words) => words.any((w) => w.id == word.id)),
    );

    return Container(
      padding: const EdgeInsets.all(WittSpacing.lg),
      decoration: BoxDecoration(
        color: isWordOfDay
            ? WittColors.primaryContainer
            : WittColors.surfaceVariant,
        borderRadius: BorderRadius.circular(WittSpacing.md),
        border: Border.all(
          color: isWordOfDay
              ? WittColors.primary.withValues(alpha: 0.3)
              : WittColors.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.word,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isWordOfDay ? WittColors.primary : null,
                      ),
                    ),
                    if (word.pronunciation != null)
                      Text(
                        word.pronunciation!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: WittColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  _DifficultyBadge(difficulty: word.difficulty),
                  const SizedBox(width: WittSpacing.sm),
                  IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved
                          ? WittColors.primary
                          : WittColors.textTertiary,
                    ),
                    onPressed: () {
                      if (isSaved) {
                        ref
                            .read(savedWordsProvider.notifier)
                            .removeWord(word.id);
                      } else {
                        ref.read(savedWordsProvider.notifier).saveWord(word);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: WittSpacing.md),

          // Definitions
          ...word.definitions.asMap().entries.map((entry) {
            final def = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: WittSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: WittColors.accentContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          def.partOfSpeech.name,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: WittColors.accent,
                          ),
                        ),
                      ),
                      if (entry.key == 0 && word.definitions.length > 1) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${word.definitions.length} definitions',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: WittColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    def.definition,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  if (def.example != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '"${def.example}"',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: WittColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (def.synonyms.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: [
                        Text(
                          'Synonyms:',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: WittColors.textTertiary,
                          ),
                        ),
                        ...def.synonyms
                            .take(4)
                            .map(
                              (s) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: WittColors.successContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  s,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: WittColors.success,
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),

          if (word.etymology != null) ...[
            const Divider(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.history_edu,
                  size: 14,
                  color: WittColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    word.etymology!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: WittColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});
  final WordDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (difficulty) {
      WordDifficulty.beginner => (WittColors.success, 'Beginner'),
      WordDifficulty.intermediate => (WittColors.secondary, 'Intermediate'),
      WordDifficulty.advanced => (WittColors.error, 'Advanced'),
      WordDifficulty.expert => (WittColors.accent, 'Expert'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _WordListTile extends StatelessWidget {
  const _WordListTile({required this.word, required this.onTap});
  final VocabWord word;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      title: Text(
        word.word,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        word.primaryDefinition,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: WittColors.textSecondary,
        ),
      ),
      trailing: Text(
        word.primaryPartOfSpeech,
        style: theme.textTheme.labelSmall?.copyWith(
          color: WittColors.textTertiary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// ── Saved words tab ───────────────────────────────────────────────────────

class _SavedWordsTab extends ConsumerWidget {
  const _SavedWordsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedWords = ref.watch(savedWordsProvider);
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(WittSpacing.lg),
            child: Row(
              children: [
                Text(
                  '${savedWords.length} saved words',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (savedWords.isNotEmpty)
                  TextButton.icon(
                    onPressed: () =>
                        _generateFlashcards(context, ref, savedWords),
                    icon: const Icon(Icons.style, size: 16),
                    label: const Text('Make Flashcards'),
                  ),
              ],
            ),
          ),
        ),
        savedWords.isEmpty
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(WittSpacing.xl),
                  child: WittEmptyState(
                    icon: Icons.bookmark_border,
                    title: 'No saved words yet',
                    subtitle:
                        'Search the dictionary and save words to build your vocabulary',
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final word = savedWords[index];
                  return Dismissible(
                    key: Key(word.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: WittSpacing.lg),
                      color: WittColors.error,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => ref
                        .read(savedWordsProvider.notifier)
                        .removeWord(word.id),
                    child: _WordListTile(
                      word: word,
                      onTap: () => _showWordDetail(context, word),
                    ),
                  );
                }, childCount: savedWords.length),
              ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  void _showWordDetail(BuildContext context, VocabWord word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(WittSpacing.lg),
          child: Consumer(builder: (context, ref, _) => _WordCard(word: word)),
        ),
      ),
    );
  }

  void _generateFlashcards(
    BuildContext context,
    WidgetRef ref,
    List<VocabWord> words,
  ) {
    final cards = ref
        .read(savedWordsProvider.notifier)
        .generateFlashcards(
          deckId: 'deck_vocab_auto',
          wordIds: words.map((w) => w.id).toList(),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generated ${cards.length} flashcards from saved words'),
        action: SnackBarAction(label: 'View', onPressed: () {}),
      ),
    );
  }
}

// ── Vocab lists tab ───────────────────────────────────────────────────────

class _VocabListsTab extends ConsumerWidget {
  const _VocabListsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(vocabListProvider);
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(WittSpacing.lg),
            child: Row(
              children: [
                Text(
                  '${lists.length} / $freeVocabListLimit lists (free)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: WittColors.textSecondary,
                  ),
                ),
                const Spacer(),
                WittButton(
                  label: 'New List',
                  onPressed: lists.length >= freeVocabListLimit
                      ? null
                      : () => _createList(context, ref),
                  size: WittButtonSize.sm,
                  icon: Icons.add,
                ),
              ],
            ),
          ),
        ),
        lists.isEmpty
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(WittSpacing.xl),
                  child: WittEmptyState(
                    icon: Icons.list_alt,
                    title: 'No vocabulary lists',
                    subtitle: 'Create lists to organize words by topic or exam',
                    actionLabel: 'Create List',
                    onAction: () => _createList(context, ref),
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final list = lists[index];
                  return _VocabListTile(
                    vocabList: list,
                    onTap: () {},
                    onDelete: () => ref
                        .read(vocabListProvider.notifier)
                        .deleteList(list.id),
                    onGenerateFlashcards: () =>
                        _generateFromList(context, ref, list),
                  );
                }, childCount: lists.length),
              ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  void _createList(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('New Vocabulary List'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'List name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  ref
                      .read(vocabListProvider.notifier)
                      .createList(
                        VocabList(
                          id: 'vlist_${DateTime.now().millisecondsSinceEpoch}',
                          name: controller.text.trim(),
                          userId: 'local_user',
                          createdAt: DateTime.now(),
                        ),
                      );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _generateFromList(BuildContext context, WidgetRef ref, VocabList list) {
    final cards = ref.read(autoFlashcardGenProvider(list.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Generated ${cards.length} flashcards from "${list.name}"',
        ),
      ),
    );
  }
}

class _VocabListTile extends StatelessWidget {
  const _VocabListTile({
    required this.vocabList,
    required this.onTap,
    required this.onDelete,
    required this.onGenerateFlashcards,
  });

  final VocabList vocabList;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onGenerateFlashcards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WittSpacing.lg,
        0,
        WittSpacing.lg,
        WittSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(WittSpacing.md),
        decoration: BoxDecoration(
          color: WittColors.surfaceVariant,
          borderRadius: BorderRadius.circular(WittSpacing.sm),
          border: Border.all(color: WittColors.outline),
        ),
        child: Row(
          children: [
            Text(vocabList.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: WittSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vocabList.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (vocabList.description.isNotEmpty)
                    Text(
                      vocabList.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: WittColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    '${vocabList.wordCount} words',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: WittColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'flashcards') onGenerateFlashcards();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'flashcards',
                  child: Text('Generate Flashcards'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete',
                    style: TextStyle(color: WittColors.error),
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

// ── Local dictionary reference ────────────────────────────────────────────

final List<VocabWord> _localDictionary = [
  VocabWord(
    id: 'word_ephemeral',
    word: 'Ephemeral',
    definitions: const [
      WordDefinition(
        partOfSpeech: PartOfSpeech.adjective,
        definition: 'Lasting for a very short time.',
        example: 'The ephemeral beauty of cherry blossoms.',
        synonyms: ['transient', 'fleeting', 'momentary'],
        antonyms: ['permanent', 'lasting', 'enduring'],
      ),
    ],
    pronunciation: '/ɪˈfem(ə)r(ə)l/',
    difficulty: WordDifficulty.intermediate,
    frequency: 3500,
    tags: const ['SAT', 'GRE'],
  ),
  VocabWord(
    id: 'word_ubiquitous',
    word: 'Ubiquitous',
    definitions: const [
      WordDefinition(
        partOfSpeech: PartOfSpeech.adjective,
        definition: 'Present, appearing, or found everywhere.',
        example: 'Mobile phones are now ubiquitous in modern society.',
        synonyms: ['omnipresent', 'pervasive', 'universal'],
        antonyms: ['rare', 'scarce', 'uncommon'],
      ),
    ],
    pronunciation: '/juːˈbɪkwɪtəs/',
    difficulty: WordDifficulty.intermediate,
    frequency: 5200,
    tags: const ['SAT', 'GRE', 'IELTS'],
  ),
  VocabWord(
    id: 'word_ameliorate',
    word: 'Ameliorate',
    definitions: const [
      WordDefinition(
        partOfSpeech: PartOfSpeech.verb,
        definition: 'Make (something bad or unsatisfactory) better.',
        example:
            'The new policy was designed to ameliorate the housing crisis.',
        synonyms: ['improve', 'better', 'enhance', 'alleviate'],
        antonyms: ['worsen', 'aggravate', 'exacerbate'],
      ),
    ],
    pronunciation: '/əˈmiːlɪəreɪt/',
    difficulty: WordDifficulty.advanced,
    frequency: 1800,
    tags: const ['SAT', 'GRE'],
  ),
  VocabWord(
    id: 'word_verbose',
    word: 'Verbose',
    definitions: const [
      WordDefinition(
        partOfSpeech: PartOfSpeech.adjective,
        definition: 'Using or expressed in more words than are needed.',
        example: 'The verbose report could have been summarised in one page.',
        synonyms: ['wordy', 'long-winded', 'prolix'],
        antonyms: ['concise', 'succinct', 'terse'],
      ),
    ],
    pronunciation: '/vɜːˈbəʊs/',
    difficulty: WordDifficulty.intermediate,
    frequency: 2900,
    tags: const ['SAT', 'IELTS', 'TOEFL'],
  ),
];
