import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../models/note.dart';
import '../providers/notes_providers.dart';
import '../providers/ai_notes_provider.dart';
import '../../flashcards/providers/ai_flashcard_provider.dart';
import '../../flashcards/screens/deck_detail_screen.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, required this.noteId});
  final String noteId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  Timer? _autoSaveTimer;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    final note = ref.read(noteByIdProvider(widget.noteId));
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');

    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
  }

  void _onChanged() {
    ref.read(noteEditorProvider(widget.noteId).notifier)
      ..updateTitle(_titleController.text)
      ..updateContent(_contentController.text);

    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        ref.read(noteEditorProvider(widget.noteId).notifier).save();
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    ref.read(noteEditorProvider(widget.noteId).notifier).save();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _exportNote() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export to PDF/MD — coming in Phase 3')),
    );
  }

  void _showFormatMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _FormatToolbar(
        onInsert: (text) {
          final sel = _contentController.selection;
          final current = _contentController.text;
          final newText = sel.isValid
              ? current.replaceRange(sel.start, sel.end, text)
              : current + text;
          _contentController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(
              offset: sel.isValid ? sel.start + text.length : newText.length,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(noteEditorProvider(widget.noteId));
    final note = ref.watch(noteByIdProvider(widget.noteId));
    final theme = Theme.of(context);

    if (note == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Note')),
        body: const Center(child: Text('Note not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: editorState?.isDirty == true
            ? Row(
                children: [
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: WittColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Editing',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: WittColors.textSecondary,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.check_circle,
                    size: 14,
                    color: WittColors.success,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Saved',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: WittColors.textSecondary,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_showPreview ? Icons.edit : Icons.preview),
            onPressed: () => setState(() => _showPreview = !_showPreview),
            tooltip: _showPreview ? 'Edit' : 'Preview',
          ),
          IconButton(
            icon: const Icon(Icons.text_format),
            onPressed: _showFormatMenu,
            tooltip: 'Format',
          ),
          PopupMenuButton<String>(
            onSelected: (v) => _handleMenu(context, ref, v, note),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'export',
                child: Text('Export (PDF/MD)'),
              ),
              const PopupMenuItem(value: 'pin', child: Text('Pin / Unpin')),
              const PopupMenuItem(value: 'favorite', child: Text('Favorite')),
              const PopupMenuItem(
                value: 'summarize',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16),
                    SizedBox(width: 8),
                    Text('AI Summary'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'flashcards',
                child: Row(
                  children: [
                    Icon(Icons.style_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Generate Flashcards'),
                  ],
                ),
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
      body: _showPreview
          ? _MarkdownPreview(content: _contentController.text)
          : Column(
              children: [
                // ── Title field ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    WittSpacing.lg,
                    WittSpacing.md,
                    WittSpacing.lg,
                    0,
                  ),
                  child: TextField(
                    controller: _titleController,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Title',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 1,
                  ),
                ),

                // ── Metadata row ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: WittSpacing.lg,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${editorState?.wordCount ?? note.wordCount} words',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: WittColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: WittSpacing.sm),
                      Text(
                        '·',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: WittColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: WittSpacing.sm),
                      Text(
                        note.format.name.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: WittColors.textTertiary,
                        ),
                      ),
                      if (note.examId != null) ...[
                        const SizedBox(width: WittSpacing.sm),
                        Text(
                          '·',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: WittColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: WittSpacing.sm),
                        Text(
                          note.examId!.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: WittColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const Divider(height: 1),

                // ── Content field ────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: WittSpacing.lg,
                    ),
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.7,
                        fontFamily: note.format == NoteFormat.markdown
                            ? 'monospace'
                            : null,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Start writing…',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: WittSpacing.md,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                ),

                // ── Word count limit warning ──────────────────────────
                if ((editorState?.wordCount ?? 0) >
                    NoteListNotifier.freeWordLimit * 0.9)
                  Container(
                    color: WittColors.warningContainer,
                    padding: const EdgeInsets.symmetric(
                      horizontal: WittSpacing.lg,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          size: 16,
                          color: WittColors.warning,
                        ),
                        const SizedBox(width: WittSpacing.xs),
                        Text(
                          'Approaching ${NoteListNotifier.freeWordLimit} word limit. Upgrade for unlimited.',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: WittColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _deleteNote(
    BuildContext context,
    WidgetRef ref,
    String noteId,
  ) async {
    final nav = Navigator.of(context);
    final del = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: WittColors.error)),
          ),
        ],
      ),
    );
    if (del == true && mounted) {
      ref.read(noteListProvider.notifier).deleteNote(noteId);
      nav.pop();
    }
  }

  void _handleMenu(
    BuildContext context,
    WidgetRef ref,
    String action,
    Note note,
  ) {
    switch (action) {
      case 'export':
        _exportNote();
      case 'pin':
        ref.read(noteListProvider.notifier).togglePin(note.id);
      case 'favorite':
        ref.read(noteListProvider.notifier).toggleFavorite(note.id);
      case 'summarize':
        _showSummarySheet(context, ref, note.id);
      case 'flashcards':
        _generateFlashcardsFromNote(context, ref, note);
      case 'delete':
        _deleteNote(context, ref, note.id);
    }
  }

  void _showSummarySheet(BuildContext context, WidgetRef ref, String noteId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AiSummarySheet(noteId: noteId),
    );
  }

  Future<void> _generateFlashcardsFromNote(
    BuildContext context,
    WidgetRef ref,
    Note note,
  ) async {
    final topic = note.subject ?? note.title;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating flashcards for "$topic"…')),
    );
    await ref
        .read(aiFlashcardGenProvider.notifier)
        .generateDeck(topic: topic, examId: note.examId);
    final state = ref.read(aiFlashcardGenProvider);
    if (state.status == AiFlashcardGenStatus.done &&
        state.generatedDeckId != null &&
        context.mounted) {
      ref.read(aiFlashcardGenProvider.notifier).reset();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DeckDetailScreen(deckId: state.generatedDeckId!),
        ),
      );
    } else if (state.status == AiFlashcardGenStatus.error && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Generation failed'),
          backgroundColor: WittColors.error,
        ),
      );
    }
  }
}

// ── AI Summary Sheet ──────────────────────────────────────────────────────────

class _AiSummarySheet extends ConsumerStatefulWidget {
  const _AiSummarySheet({required this.noteId});
  final String noteId;

  @override
  ConsumerState<_AiSummarySheet> createState() => _AiSummarySheetState();
}

class _AiSummarySheetState extends ConsumerState<_AiSummarySheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiNoteSummaryProvider(widget.noteId).notifier).summarize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(aiNoteSummaryProvider(widget.noteId));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: WittColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WittSpacing.lg,
                WittSpacing.md,
                WittSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: WittColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: WittSpacing.sm),
                  Text(
                    'AI Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (state.status == AiNoteSummaryStatus.done)
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () => ref
                          .read(aiNoteSummaryProvider(widget.noteId).notifier)
                          .summarize(),
                      tooltip: 'Regenerate',
                    ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: switch (state.status) {
                AiNoteSummaryStatus.loading => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: WittSpacing.md),
                      Text('Summarizing with AI…'),
                    ],
                  ),
                ),
                AiNoteSummaryStatus.error ||
                AiNoteSummaryStatus.limited => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(WittSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: WittColors.error,
                          size: 40,
                        ),
                        const SizedBox(height: WittSpacing.md),
                        Text(
                          state.errorMessage ?? 'Could not generate summary',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: WittColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AiNoteSummaryStatus.done when state.summary != null => ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(WittSpacing.lg),
                  children: [
                    Text(
                      'Summary',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: WittSpacing.sm),
                    Text(
                      state.summary!.summary,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                    if (state.summary!.keyPoints.isNotEmpty) ...[
                      const SizedBox(height: WittSpacing.md),
                      Text(
                        'Key Points',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: WittSpacing.xs),
                      ...state.summary!.keyPoints.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: WittSpacing.xs,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(
                                child: Text(
                                  p,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (state.summary!.definitions.isNotEmpty) ...[
                      const SizedBox(height: WittSpacing.md),
                      Text(
                        'Definitions',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: WittSpacing.xs),
                      ...state.summary!.definitions.map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: WittSpacing.sm,
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodyMedium,
                              children: [
                                TextSpan(
                                  text: '${d['term']}: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(text: d['definition']),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                _ => const SizedBox.shrink(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Markdown preview ──────────────────────────────────────────────────────

class _MarkdownPreview extends StatelessWidget {
  const _MarkdownPreview({required this.content});
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Phase 2: simple text preview; Phase 3 will use flutter_markdown
    return SingleChildScrollView(
      padding: const EdgeInsets.all(WittSpacing.lg),
      child: Text(
        content.isEmpty ? 'Nothing to preview yet.' : content,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
      ),
    );
  }
}

// ── Format toolbar ────────────────────────────────────────────────────────

class _FormatToolbar extends StatelessWidget {
  const _FormatToolbar({required this.onInsert});
  final void Function(String) onInsert;

  static const List<(String, String, String)> _formats = [
    ('H1', '# ', 'Heading 1'),
    ('H2', '## ', 'Heading 2'),
    ('H3', '### ', 'Heading 3'),
    ('**B**', '**bold**', 'Bold'),
    ('*I*', '*italic*', 'Italic'),
    ('`Code`', '`code`', 'Inline code'),
    ('- List', '\n- ', 'Bullet list'),
    ('1. List', '\n1. ', 'Numbered list'),
    ('> Quote', '\n> ', 'Blockquote'),
    ('---', '\n---\n', 'Divider'),
    ('[ ] Task', '\n- [ ] ', 'Task item'),
    (
      'Table',
      '\n| Col 1 | Col 2 |\n|-------|-------|\n| Cell | Cell |\n',
      'Table',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        WittSpacing.lg,
        WittSpacing.md,
        WittSpacing.lg,
        WittSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insert Formatting',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: WittSpacing.md),
          Wrap(
            spacing: WittSpacing.sm,
            runSpacing: WittSpacing.sm,
            children: _formats.map((f) {
              return GestureDetector(
                onTap: () {
                  onInsert(f.$2);
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: WittColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(WittSpacing.xs),
                    border: Border.all(color: WittColors.outline),
                  ),
                  child: Text(
                    f.$1,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
