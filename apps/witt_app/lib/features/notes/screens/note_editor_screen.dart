import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../models/note.dart';
import '../providers/notes_providers.dart';

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
      case 'flashcards':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flashcard generation — coming in Phase 3'),
          ),
        );
      case 'delete':
        _deleteNote(context, ref, note.id);
    }
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
