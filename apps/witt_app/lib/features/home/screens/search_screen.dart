import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  static const _recents = [
    'SAT Math — Algebra',
    'IELTS Writing Task 2',
    'Vocabulary: ephemeral',
    'GRE Verbal flashcards',
  ];

  static const _trending = [
    _Trend(Icons.trending_up_rounded, 'SAT 2025 changes', WittColors.primary),
    _Trend(Icons.trending_up_rounded, 'WAEC past questions', WittColors.accent),
    _Trend(Icons.trending_up_rounded, 'IELTS band 9 tips', WittColors.success),
    _Trend(Icons.trending_up_rounded, 'GRE math shortcuts', WittColors.secondary),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search exams, topics, flashcards…',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: isDark
                  ? WittColors.textTertiaryDark
                  : WittColors.textTertiary,
            ),
          ),
          style: theme.textTheme.bodyLarge,
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _ctrl.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.isEmpty ? _buildEmpty(theme, isDark) : _buildResults(theme),
    );
  }

  Widget _buildEmpty(ThemeData theme, bool isDark) {
    return ListView(
      padding: WittSpacing.pagePadding,
      children: [
        const SizedBox(height: WittSpacing.lg),
        // Recent searches
        if (_recents.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent', style: theme.textTheme.titleSmall),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: WittSpacing.sm),
          ..._recents.map(
            (r) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.history_rounded,
                color: isDark
                    ? WittColors.textSecondaryDark
                    : WittColors.textSecondary,
                size: WittSpacing.iconMd,
              ),
              title: Text(r, style: theme.textTheme.bodyMedium),
              trailing: Icon(
                Icons.north_west_rounded,
                size: 16,
                color: isDark
                    ? WittColors.textTertiaryDark
                    : WittColors.textTertiary,
              ),
              onTap: () {
                _ctrl.text = r;
                setState(() => _query = r);
              },
            ),
          ),
          const SizedBox(height: WittSpacing.xxl),
        ],
        // Trending
        Text('Trending', style: theme.textTheme.titleSmall),
        const SizedBox(height: WittSpacing.sm),
        ..._trending.map(
          (t) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: t.color.withAlpha(26),
                borderRadius: WittSpacing.borderRadiusMd,
              ),
              child: Icon(t.icon, color: t.color, size: WittSpacing.iconSm),
            ),
            title: Text(t.label, style: theme.textTheme.bodyMedium),
            onTap: () {
              _ctrl.text = t.label;
              setState(() => _query = t.label);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResults(ThemeData theme) {
    return WittEmptyState(
      icon: Icons.search_off_rounded,
      title: 'No results for "$_query"',
      subtitle: 'Try a different keyword or browse by exam',
    );
  }
}

class _Trend {
  const _Trend(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;
}
