import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../models/note.dart';
import '../providers/notes_providers.dart';
import 'note_editor_screen.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(activeNotesProvider);
    final pinned = ref.watch(pinnedNotesProvider);
    final unpinned = notes.where((n) => !n.isPinned).toList();
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Notes'),
            actions: [
              IconButton(icon: const Icon(Icons.search), onPressed: () {}),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _createNote(context, ref),
              ),
            ],
          ),

          // ── Stats bar ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  WittSpacing.lg, WittSpacing.sm, WittSpacing.lg, 0),
              child: Row(
                children: [
                  _StatChip(
                    icon: Icons.note,
                    label: '${notes.length} notes',
                    color: WittColors.primary,
                  ),
                  const SizedBox(width: WittSpacing.sm),
                  _StatChip(
                    icon: Icons.push_pin,
                    label: '${pinned.length} pinned',
                    color: WittColors.secondary,
                  ),
                  const Spacer(),
                  Text(
                    '${NoteListNotifier.freeNoteLimit - notes.length} free slots',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: WittColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Template picker ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  WittSpacing.lg, WittSpacing.md, WittSpacing.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New from template',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: WittColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: WittSpacing.xs),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: NoteTemplate.values.map((t) {
                        return Padding(
                          padding:
                              const EdgeInsets.only(right: WittSpacing.sm),
                          child: _TemplateChip(
                            template: t,
                            onTap: () => _createNote(context, ref,
                                template: t),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Pinned notes ──────────────────────────────────────────────
          if (pinned.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    WittSpacing.lg, WittSpacing.lg, WittSpacing.lg,
                    WittSpacing.sm),
                child: Text(
                  'Pinned',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: WittColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _NoteTile(
                  note: pinned[index],
                  onTap: () => _openNote(context, pinned[index].id),
                  onPin: () => ref
                      .read(noteListProvider.notifier)
                      .togglePin(pinned[index].id),
                  onDelete: () => ref
                      .read(noteListProvider.notifier)
                      .deleteNote(pinned[index].id),
                ),
                childCount: pinned.length,
              ),
            ),
          ],

          // ── All notes ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  WittSpacing.lg, WittSpacing.lg, WittSpacing.lg,
                  WittSpacing.sm),
              child: Text(
                pinned.isEmpty ? 'All Notes' : 'Other Notes',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: WittColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          unpinned.isEmpty && pinned.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(WittSpacing.xl),
                    child: WittEmptyState(
                      icon: Icons.note_outlined,
                      title: 'No notes yet',
                      subtitle:
                          'Create your first note to start organizing your study material',
                      actionLabel: 'Create Note',
                      onAction: () => _createNote(context, ref),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _NoteTile(
                      note: unpinned[index],
                      onTap: () => _openNote(context, unpinned[index].id),
                      onPin: () => ref
                          .read(noteListProvider.notifier)
                          .togglePin(unpinned[index].id),
                      onDelete: () => ref
                          .read(noteListProvider.notifier)
                          .deleteNote(unpinned[index].id),
                    ),
                    childCount: unpinned.length,
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNote(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
        backgroundColor: WittColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _createNote(BuildContext context, WidgetRef ref,
      {NoteTemplate template = NoteTemplate.blank}) {
    final note = Note(
      id: 'note_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'local_user',
      title: '',
      content: _templateContent(template),
      format: NoteFormat.markdown,
      template: template,
      wordCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    ref.read(noteListProvider.notifier).createNote(note);
    _openNote(context, note.id);
  }

  void _openNote(BuildContext context, String noteId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(noteId: noteId),
      ),
    );
  }

  String _templateContent(NoteTemplate template) {
    return switch (template) {
      NoteTemplate.blank => '',
      NoteTemplate.cornell =>
        '# Title\n\n## Cues / Questions\n\n\n## Notes\n\n\n## Summary\n\n',
      NoteTemplate.outline =>
        '# Topic\n\n## I. Main Point\n   - Sub-point\n   - Sub-point\n\n## II. Main Point\n   - Sub-point\n',
      NoteTemplate.mindMap =>
        '# Central Topic\n\n## Branch 1\n- Idea\n- Idea\n\n## Branch 2\n- Idea\n- Idea\n',
      NoteTemplate.studyGuide =>
        '# Study Guide\n\n## Key Concepts\n\n## Important Formulas\n\n## Practice Questions\n\n## Summary\n',
      NoteTemplate.flashcardGen =>
        '# Flashcard Source\n\nQ: Question 1?\nA: Answer 1\n\nQ: Question 2?\nA: Answer 2\n',
    };
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  const _TemplateChip({required this.template, required this.onTap});
  final NoteTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = _info(template);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: WittColors.surfaceVariant,
          borderRadius: BorderRadius.circular(WittSpacing.sm),
          border: Border.all(color: WittColors.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  (String, String) _info(NoteTemplate t) => switch (t) {
        NoteTemplate.blank => ('📄', 'Blank'),
        NoteTemplate.cornell => ('📋', 'Cornell'),
        NoteTemplate.outline => ('📑', 'Outline'),
        NoteTemplate.mindMap => ('🧠', 'Mind Map'),
        NoteTemplate.studyGuide => ('📚', 'Study Guide'),
        NoteTemplate.flashcardGen => ('🃏', 'Flashcard Gen'),
      };
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({
    required this.note,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = note.content.isEmpty
        ? 'Empty note'
        : note.content
            .replaceAll(RegExp(r'[#*_`\[\]()]'), '')
            .trim()
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .take(2)
            .join(' ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          WittSpacing.lg, 0, WittSpacing.lg, WittSpacing.sm),
      child: Dismissible(
        key: Key(note.id),
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
              title: const Text('Delete note?'),
              content: Text('Delete "${note.title.isEmpty ? 'Untitled' : note.title}"?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text('Delete',
                        style: TextStyle(color: WittColors.error))),
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
              border: Border.all(
                color: note.isPinned
                    ? WittColors.secondary.withValues(alpha: 0.4)
                    : WittColors.outline,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.title.isEmpty ? 'Untitled' : note.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: note.title.isEmpty
                              ? WittColors.textTertiary
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (note.isPinned)
                      const Icon(Icons.push_pin,
                          size: 14, color: WittColors.secondary),
                    if (note.isFavorite)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.star,
                            size: 14, color: WittColors.secondary),
                      ),
                    IconButton(
                      icon: Icon(
                        note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 16,
                        color: WittColors.textTertiary,
                      ),
                      onPressed: onPin,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  preview,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: WittColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _FormatBadge(format: note.format),
                    const SizedBox(width: 6),
                    Text(
                      '${note.wordCount} words',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: WittColors.textTertiary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _timeAgo(note.updatedAt ?? note.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: WittColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).round()}w ago';
  }
}

class _FormatBadge extends StatelessWidget {
  const _FormatBadge({required this.format});
  final NoteFormat format;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (format) {
      NoteFormat.plainText => ('Text', WittColors.textTertiary),
      NoteFormat.markdown => ('MD', WittColors.accent),
      NoteFormat.richText => ('Rich', WittColors.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
