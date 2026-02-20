import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../models/flashcard.dart';
import '../providers/flashcard_providers.dart';

class CreateDeckScreen extends ConsumerStatefulWidget {
  const CreateDeckScreen({super.key});

  @override
  ConsumerState<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends ConsumerState<CreateDeckScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _emoji = '📚';
  int _color = 0xFF4F46E5;
  bool _isPublic = false;

  static const List<String> _emojis = [
    '📚',
    '📖',
    '✏️',
    '🧠',
    '🔬',
    '⚗️',
    '🧮',
    '📐',
    '🌍',
    '🗺️',
    '💡',
    '🎓',
    '🏆',
    '⚡',
    '🧬',
    '🔭',
    '📊',
    '💻',
    '🎵',
    '🎨',
  ];

  static const List<int> _colors = [
    0xFF4F46E5,
    0xFF10B981,
    0xFFF59E0B,
    0xFFEF4444,
    0xFF0EA5E9,
    0xFF8B5CF6,
    0xFFEC4899,
    0xFF6366F1,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _create() {
    if (_nameController.text.trim().isEmpty) return;
    final deck = FlashcardDeck(
      id: 'deck_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      userId: 'local_user',
      description: _descController.text.trim(),
      emoji: _emoji,
      color: _color,
      isPublic: _isPublic,
      cardCount: 0,
      dueCount: 0,
      newCount: 0,
      createdAt: DateTime.now(),
    );
    ref.read(deckListProvider.notifier).createDeck(deck);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deckColor = Color(_color);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Deck'),
        actions: [
          TextButton(
            onPressed: _nameController.text.trim().isEmpty ? null : _create,
            child: const Text('Create'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WittSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Preview card ───────────────────────────────────────────
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [deckColor, deckColor.withValues(alpha: 0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(WittSpacing.md),
                  boxShadow: [
                    BoxShadow(
                      color: deckColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(_emoji, style: const TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: WittSpacing.xl),

            // ── Name ───────────────────────────────────────────────────
            Text(
              'Deck Name',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: WittSpacing.xs),
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'e.g. SAT Vocabulary',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: WittSpacing.md),

            // ── Description ────────────────────────────────────────────
            Text(
              'Description (optional)',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: WittSpacing.xs),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'What is this deck about?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: WittSpacing.lg),

            // ── Emoji picker ───────────────────────────────────────────
            Text(
              'Icon',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: WittSpacing.xs),
            Wrap(
              spacing: WittSpacing.sm,
              runSpacing: WittSpacing.sm,
              children: _emojis.map((e) {
                final selected = e == _emoji;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? WittColors.primaryContainer
                          : WittColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(WittSpacing.xs),
                      border: Border.all(
                        color: selected
                            ? WittColors.primary
                            : WittColors.outline,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: WittSpacing.lg),

            // ── Color picker ───────────────────────────────────────────
            Text(
              'Color',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: WittSpacing.xs),
            Wrap(
              spacing: WittSpacing.sm,
              runSpacing: WittSpacing.sm,
              children: _colors.map((c) {
                final selected = c == _color;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: Color(c).withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: WittSpacing.lg),

            // ── Visibility ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Public deck',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Allow others to discover and use this deck',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: WittColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isPublic,
                  onChanged: (v) => setState(() => _isPublic = v),
                  activeThumbColor: WittColors.primary,
                ),
              ],
            ),
            const SizedBox(height: WittSpacing.xl),

            // ── Create button ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: WittButton(
                label: 'Create Deck',
                onPressed: _nameController.text.trim().isEmpty ? null : _create,
                icon: Icons.add,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
