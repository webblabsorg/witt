import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../models/flashcard.dart';
import '../providers/flashcard_providers.dart';

class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({super.key, required this.deckId});
  final String deckId;

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  final _hintController = TextEditingController();
  FlashcardType _type = FlashcardType.basic;
  final List<Flashcard> _added = [];

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  void _addCard() {
    if (_frontController.text.trim().isEmpty ||
        _backController.text.trim().isEmpty) {
      return;
    }

    final card = Flashcard(
      id: 'card_${DateTime.now().millisecondsSinceEpoch}',
      deckId: widget.deckId,
      type: _type,
      front: _frontController.text.trim(),
      back: _backController.text.trim(),
      hint: _hintController.text.trim().isEmpty
          ? null
          : _hintController.text.trim(),
      createdAt: DateTime.now(),
    );

    ref.read(cardListProvider.notifier).addCard(card);
    setState(() {
      _added.add(card);
      _frontController.clear();
      _backController.clear();
      _hintController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Card added!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAdd =
        _frontController.text.trim().isNotEmpty &&
        _backController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Cards'),
        actions: [
          if (_added.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Done (${_added.length})'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WittSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card type selector ─────────────────────────────────────
            Text(
              'Card Type',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: WittSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: FlashcardType.values.map((t) {
                  final selected = t == _type;
                  return Padding(
                    padding: const EdgeInsets.only(right: WittSpacing.sm),
                    child: GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: WittSpacing.md,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? WittColors.primary
                              : WittColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? WittColors.primary
                                : WittColors.outline,
                          ),
                        ),
                        child: Text(
                          _typeLabel(t),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: selected
                                ? Colors.white
                                : WittColors.textSecondary,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: WittSpacing.lg),

            // ── Front ──────────────────────────────────────────────────
            Text(
              _type == FlashcardType.cloze ? 'Cloze Text' : 'Front',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_type == FlashcardType.cloze)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  'Wrap the answer in {{double braces}}: e.g. "The capital of France is {{Paris}}"',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: WittColors.textSecondary,
                  ),
                ),
              ),
            const SizedBox(height: WittSpacing.xs),
            TextField(
              controller: _frontController,
              onChanged: (_) => setState(() {}),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: _type == FlashcardType.cloze
                    ? 'The capital of France is {{Paris}}'
                    : 'Question or term',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: WittSpacing.md),

            // ── Back ───────────────────────────────────────────────────
            Text(
              'Back',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: WittSpacing.xs),
            TextField(
              controller: _backController,
              onChanged: (_) => setState(() {}),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Answer or definition',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: WittSpacing.md),

            // ── Hint ───────────────────────────────────────────────────
            Text(
              'Hint (optional)',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: WittSpacing.xs),
            TextField(
              controller: _hintController,
              decoration: const InputDecoration(
                hintText: 'Memory aid or mnemonic',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: WittSpacing.xl),

            // ── Add button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: WittButton(
                label: 'Add Card',
                onPressed: canAdd ? _addCard : null,
                icon: Icons.add,
              ),
            ),

            // ── Added cards preview ────────────────────────────────────
            if (_added.isNotEmpty) ...[
              const SizedBox(height: WittSpacing.xl),
              Text(
                'Added this session (${_added.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: WittSpacing.sm),
              ..._added.reversed
                  .take(5)
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: WittSpacing.sm),
                      child: Container(
                        padding: const EdgeInsets.all(WittSpacing.sm),
                        decoration: BoxDecoration(
                          color: WittColors.successContainer,
                          borderRadius: BorderRadius.circular(WittSpacing.xs),
                          border: Border.all(
                            color: WittColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: WittColors.success,
                            ),
                            const SizedBox(width: WittSpacing.xs),
                            Expanded(
                              child: Text(
                                c.front,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  String _typeLabel(FlashcardType t) => switch (t) {
    FlashcardType.basic => 'Basic',
    FlashcardType.reversed => 'Reversed',
    FlashcardType.cloze => 'Cloze',
    FlashcardType.imageOcclusion => 'Image',
    FlashcardType.typed => 'Typed',
  };
}
