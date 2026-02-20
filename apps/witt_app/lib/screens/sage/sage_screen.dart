import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';
import '../../features/sage/models/sage_models.dart';
import '../../features/sage/providers/sage_providers.dart';
import '../../features/learn/providers/test_prep_providers.dart';

class SageScreen extends ConsumerStatefulWidget {
  const SageScreen({super.key});

  @override
  ConsumerState<SageScreen> createState() => _SageScreenState();
}

class _SageScreenState extends ConsumerState<SageScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    await ref.read(sageSessionProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sageSessionProvider);
    final remaining = ref.watch(sageRemainingMessagesProvider);
    final isPaid = ref.watch(isPaidUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [WittColors.primary, WittColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: WittSpacing.sm),
            const Text('Sage'),
            if (!isPaid) ...[
              const SizedBox(width: WittSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: WittColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Groq',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: WittColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (remaining != null)
            Padding(
              padding: const EdgeInsets.only(right: WittSpacing.sm),
              child: Center(
                child: Text(
                  '$remaining/10',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: remaining <= 2
                        ? WittColors.error
                        : WittColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => _showHistory(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'New conversation',
            onPressed: () =>
                ref.read(sageSessionProvider.notifier).newConversation(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode selector
          _ModeSelector(
            selected: session.mode,
            isPaid: isPaid,
            onSelect: (mode) =>
                ref.read(sageSessionProvider.notifier).setMode(mode),
          ),

          // Messages
          Expanded(
            child: session.messages.isEmpty && !session.isStreaming
                ? _EmptyState(mode: session.mode, isPaid: isPaid)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: WittSpacing.md,
                      vertical: WittSpacing.sm,
                    ),
                    itemCount:
                        session.messages.length + (session.isStreaming ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == session.messages.length &&
                          session.isStreaming) {
                        return _MessageBubble(
                          message: AiMessage(
                            id: 'streaming',
                            role: 'assistant',
                            content: session.streamingContent,
                            createdAt: DateTime.now(),
                            isStreaming: true,
                          ),
                        );
                      }
                      return _MessageBubble(message: session.messages[index]);
                    },
                  ),
          ),

          // Error / limit banner
          if (session.error != null)
            _Banner(
              message: session.error!,
              color: WittColors.error,
              icon: Icons.error_outline,
            ),
          if (session.limitMessage != null)
            _Banner(
              message: session.limitMessage!,
              color: WittColors.warning,
              icon: Icons.lock_outline,
              action: TextButton(
                onPressed: () => context.push('/onboarding/paywall'),
                child: const Text('Upgrade'),
              ),
            ),

          // Input bar
          _InputBar(
            controller: _inputController,
            isPaid: isPaid,
            isStreaming: session.isStreaming,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  void _showHistory(BuildContext context) {
    final history = ref.read(sageHistoryProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _HistorySheet(
        history: history,
        onSelect: (conv) {
          Navigator.pop(context);
          ref.read(sageSessionProvider.notifier).loadConversation(conv);
        },
        onDelete: (id) => ref.read(sageHistoryProvider.notifier).delete(id),
      ),
    );
  }
}

// ── Mode selector ─────────────────────────────────────────────────────────

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.selected,
    required this.isPaid,
    required this.onSelect,
  });
  final SageMode selected;
  final bool isPaid;
  final ValueChanged<SageMode> onSelect;

  static const _modes = [
    (SageMode.chat, 'Chat', Icons.chat_bubble_outline),
    (SageMode.explain, 'Explain', Icons.lightbulb_outline),
    (SageMode.homework, 'Homework', Icons.calculate_outlined),
    (SageMode.quiz, 'Quiz', Icons.quiz_outlined),
    (SageMode.planning, 'Planning', Icons.calendar_today_outlined),
    (SageMode.flashcardGen, 'Flashcards', Icons.style_outlined),
    (SageMode.lectureSummary, 'Lecture', Icons.mic_none),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: WittSpacing.md),
        itemCount: _modes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final (mode, label, icon) = _modes[i];
          final isSelected = mode == selected;
          final isPaidOnly = mode != SageMode.chat && mode != SageMode.explain;
          final locked = isPaidOnly && !isPaid;

          return Semantics(
            button: !locked,
            label: locked ? '$label (Premium only)' : '$label mode',
            selected: isSelected,
            child: GestureDetector(
              onTap: locked ? null : () => onSelect(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? WittColors.primary
                      : WittColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? WittColors.primary : WittColors.outline,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      locked ? Icons.lock_outline : icon,
                      size: 14,
                      color: isSelected
                          ? Colors.white
                          : locked
                          ? WittColors.textTertiary
                          : WittColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : locked
                            ? WittColors.textTertiary
                            : WittColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final AiMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == 'user';

    final role = isUser ? 'You' : 'Sage';
    return Semantics(
      label: '$role: ${message.content}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [WittColors.primary, WittColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: WittSpacing.sm),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: WittSpacing.md,
                  vertical: WittSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isUser
                      ? WittColors.primary
                      : WittColors.surfaceVariant,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content.isEmpty && message.isStreaming
                          ? '…'
                          : message.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isUser ? Colors.white : null,
                      ),
                    ),
                    if (message.isStreaming && message.content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: SizedBox(
                          width: 16,
                          height: 8,
                          child: LinearProgressIndicator(
                            backgroundColor: WittColors.outline,
                            color: WittColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (isUser) const SizedBox(width: 36),
          ],
        ),
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────

class _InputBar extends ConsumerStatefulWidget {
  const _InputBar({
    required this.controller,
    required this.isPaid,
    required this.isStreaming,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool isPaid;
  final bool isStreaming;
  final VoidCallback onSend;

  @override
  ConsumerState<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends ConsumerState<_InputBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        WittSpacing.md,
        WittSpacing.sm,
        WittSpacing.md,
        WittSpacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: WittColors.outline, width: 0.5)),
      ),
      child: Row(
        children: [
          // Mic (paid only)
          IconButton(
            icon: Icon(
              Icons.mic_none,
              color: widget.isPaid
                  ? WittColors.primary
                  : WittColors.textTertiary,
            ),
            tooltip: widget.isPaid
                ? 'Voice input'
                : 'Voice input requires Premium',
            onPressed: widget.isPaid ? () {} : null,
          ),
          // Text field
          Expanded(
            child: TextField(
              controller: widget.controller,
              maxLines: 4,
              minLines: 1,
              maxLength: widget.isPaid ? 4000 : 500,
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
              decoration: InputDecoration(
                hintText: 'Ask Sage anything…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: WittColors.outline),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: WittSpacing.md,
                  vertical: WittSpacing.sm,
                ),
                isDense: true,
              ),
              textInputAction: TextInputAction.newline,
            ),
          ),
          const SizedBox(width: WittSpacing.sm),
          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            child: widget.isStreaming
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton.filled(
                    icon: const Icon(Icons.send_rounded),
                    onPressed: widget.controller.text.trim().isEmpty
                        ? null
                        : widget.onSend,
                    style: IconButton.styleFrom(
                      backgroundColor: WittColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: WittColors.primary.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.mode, required this.isPaid});
  final SageMode mode;
  final bool isPaid;

  static const _prompts = {
    SageMode.chat: [
      'Explain photosynthesis simply',
      'What is the difference between mitosis and meiosis?',
      'Help me understand quadratic equations',
      'What are the causes of World War I?',
    ],
    SageMode.explain: [
      'Explain the Pythagorean theorem',
      'What is Newton\'s second law?',
      'Explain supply and demand',
      'What is DNA replication?',
    ],
    SageMode.homework: [
      'Solve: 2x² + 5x - 3 = 0',
      'Find the derivative of f(x) = x³ + 2x',
      'Balance this equation: H₂ + O₂ → H₂O',
      'Analyze the themes in Romeo and Juliet',
    ],
    SageMode.quiz: [
      'Quiz me on SAT Math',
      'Test my knowledge of World War II',
      'Quiz me on cell biology',
      'Test my vocabulary for GRE',
    ],
    SageMode.planning: [
      'Make me a 3-month SAT study plan',
      'I have 2 weeks until my chemistry exam',
      'Help me balance 3 exams next month',
      'Create a daily study schedule for me',
    ],
    SageMode.flashcardGen: [
      'Create flashcards for the French Revolution',
      'Generate biology cell organelle cards',
      'Make vocabulary cards for SAT',
      'Create math formula flashcards',
    ],
    SageMode.lectureSummary: [
      'Paste your lecture notes here to summarize',
      'I\'ll summarize any text you share',
      'Share your lecture transcript',
      'Paste your class notes for key points',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prompts = _prompts[mode] ?? _prompts[SageMode.chat]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(WittSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: WittSpacing.xl),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [WittColors.primary, WittColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: WittSpacing.md),
          Text(
            'Hi, I\'m Sage',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: WittSpacing.sm),
          Text(
            isPaid
                ? 'Powered by GPT-4o — unlimited access'
                : 'Powered by Groq — 10 messages/day free',
            style: theme.textTheme.bodySmall?.copyWith(
              color: WittColors.textSecondary,
            ),
          ),
          const SizedBox(height: WittSpacing.xl),
          Wrap(
            spacing: WittSpacing.sm,
            runSpacing: WittSpacing.sm,
            alignment: WrapAlignment.center,
            children: prompts.map((p) => _PromptChip(text: p)).toList(),
          ),
        ],
      ),
    );
  }
}

class _PromptChip extends ConsumerWidget {
  const _PromptChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => ref.read(sageSessionProvider.notifier).sendMessage(text),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: WittSpacing.md,
          vertical: WittSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: WittColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: WittColors.outline),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: WittColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Banner ────────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  const _Banner({
    required this.message,
    required this.color,
    required this.icon,
    this.action,
  });
  final String message;
  final Color color;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: WittSpacing.md,
        vertical: WittSpacing.xs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: WittSpacing.md,
        vertical: WittSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(WittSpacing.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: WittSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

// ── History sheet ─────────────────────────────────────────────────────────

class _HistorySheet extends StatelessWidget {
  const _HistorySheet({
    required this.history,
    required this.onSelect,
    required this.onDelete,
  });
  final List<SageConversation> history;
  final ValueChanged<SageConversation> onSelect;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(WittSpacing.md),
            child: Text(
              'Conversation History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Text(
                      'No past conversations',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: WittColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: controller,
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final conv = history[i];
                      return ListTile(
                        leading: const Icon(Icons.chat_bubble_outline),
                        title: Text(
                          conv.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${conv.messages.length} messages',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: WittColors.textSecondary,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => onDelete(conv.id),
                        ),
                        onTap: () => onSelect(conv),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
