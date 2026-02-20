import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';

import '../models/translation_models.dart';
import '../providers/translation_providers.dart';

class TranslationScreen extends ConsumerStatefulWidget {
  const TranslationScreen({super.key});

  @override
  ConsumerState<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends ConsumerState<TranslationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _inputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Translate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'History',
            onPressed: () => _tab.animateTo(1),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Translate'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _TranslateTab(inputCtrl: _inputCtrl, isDark: isDark),
          _HistoryTab(isDark: isDark),
        ],
      ),
    );
  }
}

// ── Translate Tab ─────────────────────────────────────────────────────────

class _TranslateTab extends ConsumerWidget {
  const _TranslateTab({required this.inputCtrl, required this.isDark});
  final TextEditingController inputCtrl;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(translationProvider);
    final langs = ref.watch(supportedLanguagesProvider);
    final theme = Theme.of(context);

    final sourceLang = langs.firstWhere(
      (l) => l.code == state.sourceLang,
      orElse: () => langs.first,
    );
    final targetLang = langs.firstWhere(
      (l) => l.code == state.targetLang,
      orElse: () => langs[1],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        WittSpacing.lg,
        WittSpacing.md,
        WittSpacing.lg,
        100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language selector row
          Row(
            children: [
              Expanded(
                child: _LangButton(
                  lang: sourceLang,
                  onTap: () => _pickLang(context, ref, isSource: true),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz_rounded),
                onPressed: () =>
                    ref.read(translationProvider.notifier).swapLanguages(),
                color: WittColors.primary,
              ),
              Expanded(
                child: _LangButton(
                  lang: targetLang,
                  onTap: () => _pickLang(context, ref, isSource: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: WittSpacing.md),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? WittColors.surfaceVariantDark
                  : WittColors.surfaceVariant,
              borderRadius: WittSpacing.borderRadiusMd,
              border: Border.all(
                color: isDark ? WittColors.outlineDark : WittColors.outline,
              ),
            ),
            padding: const EdgeInsets.all(WittSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${sourceLang.flag} ${sourceLang.name}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? WittColors.textSecondaryDark
                            : WittColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (inputCtrl.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          inputCtrl.clear();
                          ref.read(translationProvider.notifier).setInput('');
                        },
                        child: const Icon(Icons.close_rounded, size: 18),
                      ),
                  ],
                ),
                const SizedBox(height: WittSpacing.sm),
                TextField(
                  controller: inputCtrl,
                  maxLines: 5,
                  minLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter text to translate…',
                    border: InputBorder.none,
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? WittColors.textSecondaryDark
                          : WittColors.textSecondary,
                    ),
                  ),
                  onChanged: (v) =>
                      ref.read(translationProvider.notifier).setInput(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: WittSpacing.sm),

          // Translate button
          WittButton(
            label: state.status == TranslationStatus.loading
                ? 'Translating…'
                : 'Translate',
            onPressed: state.status == TranslationStatus.loading
                ? null
                : () => ref.read(translationProvider.notifier).translate(),
            variant: WittButtonVariant.primary,
            icon: Icons.translate_rounded,
          ),
          const SizedBox(height: WittSpacing.md),

          // Result area
          if (state.status == TranslationStatus.loading)
            const Center(child: WittLoading())
          else if (state.status == TranslationStatus.error)
            Container(
              padding: const EdgeInsets.all(WittSpacing.md),
              decoration: BoxDecoration(
                color: WittColors.error.withAlpha(26),
                borderRadius: WittSpacing.borderRadiusMd,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: WittColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: WittSpacing.sm),
                  Expanded(
                    child: Text(
                      state.error ?? 'Translation failed.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: WittColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (state.result != null) ...[
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? WittColors.surfaceVariantDark
                    : WittColors.surfaceVariant,
                borderRadius: WittSpacing.borderRadiusMd,
                border: Border.all(color: WittColors.primary.withAlpha(77)),
              ),
              padding: const EdgeInsets.all(WittSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${targetLang.flag} ${targetLang.name}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: WittColors.primary,
                        ),
                      ),
                      if (state.result!.isOffline) ...[
                        const SizedBox(width: WittSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: WittSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: WittColors.success.withAlpha(26),
                            borderRadius: WittSpacing.borderRadiusFull,
                          ),
                          child: Text(
                            'Offline',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: WittColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: state.result!.translatedText),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: WittSpacing.sm),
                  Text(
                    state.result!.translatedText,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: WittSpacing.lg),

          // Offline languages section
          Text('Offline Languages', style: theme.textTheme.titleSmall),
          const SizedBox(height: WittSpacing.sm),
          Text(
            'Download language packs for offline translation without internet.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? WittColors.textSecondaryDark
                  : WittColors.textSecondary,
            ),
          ),
          const SizedBox(height: WittSpacing.sm),
          ...langs
              .where((l) => l.isOfflineAvailable)
              .map(
                (l) => Padding(
                  padding: const EdgeInsets.only(bottom: WittSpacing.sm),
                  child: WittCard(
                    padding: const EdgeInsets.all(WittSpacing.md),
                    child: Row(
                      children: [
                        Text(l.flag, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: WittSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.name, style: theme.textTheme.titleSmall),
                              Text(
                                l.nativeName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? WittColors.textSecondaryDark
                                      : WittColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: WittSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: WittColors.success.withAlpha(26),
                            borderRadius: WittSpacing.borderRadiusFull,
                          ),
                          child: Text(
                            'Downloaded',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: WittColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  void _pickLang(
    BuildContext context,
    WidgetRef ref, {
    required bool isSource,
  }) {
    final langs = ref.read(supportedLanguagesProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LangPickerSheet(
        langs: langs,
        onSelected: (code) {
          if (isSource) {
            ref.read(translationProvider.notifier).setSourceLang(code);
          } else {
            ref.read(translationProvider.notifier).setTargetLang(code);
          }
        },
      ),
    );
  }
}

// ── History Tab ───────────────────────────────────────────────────────────

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(translationProvider).history;
    final theme = Theme.of(context);
    final langs = ref.watch(supportedLanguagesProvider);

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌐', style: TextStyle(fontSize: 48)),
            const SizedBox(height: WittSpacing.md),
            Text('No translations yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: WittSpacing.sm),
            Text(
              'Your translation history will appear here.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        WittSpacing.lg,
        WittSpacing.md,
        WittSpacing.lg,
        100,
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${history.length} translations',
              style: theme.textTheme.bodySmall,
            ),
            TextButton(
              onPressed: () =>
                  ref.read(translationProvider.notifier).clearHistory(),
              child: const Text('Clear All'),
            ),
          ],
        ),
        ...history.map((r) {
          final src = langs.firstWhere(
            (l) => l.code == r.sourceLang,
            orElse: () => langs.first,
          );
          final tgt = langs.firstWhere(
            (l) => l.code == r.targetLang,
            orElse: () => langs[1],
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: WittSpacing.sm),
            child: WittCard(
              padding: const EdgeInsets.all(WittSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${src.flag} → ${tgt.flag}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? WittColors.textSecondaryDark
                              : WittColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _timeAgo(r.timestamp),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? WittColors.textSecondaryDark
                              : WittColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: WittSpacing.xs),
                  Text(r.sourceText, style: theme.textTheme.bodySmall),
                  const Divider(height: WittSpacing.md),
                  Text(
                    r.translatedText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Language Button ───────────────────────────────────────────────────────

class _LangButton extends StatelessWidget {
  const _LangButton({required this.lang, required this.onTap});
  final SupportedLanguage lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: WittSpacing.md,
          vertical: WittSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? WittColors.surfaceVariantDark
              : WittColors.surfaceVariant,
          borderRadius: WittSpacing.borderRadiusMd,
          border: Border.all(
            color: isDark ? WittColors.outlineDark : WittColors.outline,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(lang.flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: WittSpacing.xs),
            Text(lang.name, style: theme.textTheme.titleSmall),
            const SizedBox(width: WittSpacing.xs),
            const Icon(Icons.arrow_drop_down_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Language Picker Sheet ─────────────────────────────────────────────────

class _LangPickerSheet extends StatefulWidget {
  const _LangPickerSheet({required this.langs, required this.onSelected});
  final List<SupportedLanguage> langs;
  final void Function(String code) onSelected;

  @override
  State<_LangPickerSheet> createState() => _LangPickerSheetState();
}

class _LangPickerSheetState extends State<_LangPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = widget.langs
        .where(
          (l) =>
              l.name.toLowerCase().contains(_query.toLowerCase()) ||
              l.nativeName.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(WittSpacing.md),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search language…',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final l = filtered[i];
                return ListTile(
                  leading: Text(l.flag, style: const TextStyle(fontSize: 24)),
                  title: Text(l.name),
                  subtitle: Text(l.nativeName),
                  trailing: l.isOfflineAvailable
                      ? const Icon(
                          Icons.offline_bolt_rounded,
                          color: WittColors.success,
                          size: 18,
                        )
                      : null,
                  onTap: () {
                    widget.onSelected(l.code);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
