import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../data/exam_catalog.dart';
import '../models/exam.dart';
import '../providers/exam_providers.dart';
import 'exam_hub_screen.dart';

class ExamBrowserScreen extends ConsumerStatefulWidget {
  const ExamBrowserScreen({super.key, this.initialRegion});
  final ExamRegion? initialRegion;

  @override
  ConsumerState<ExamBrowserScreen> createState() =>
      _ExamBrowserScreenState();
}

class _ExamBrowserScreenState extends ConsumerState<ExamBrowserScreen> {
  late ExamRegion? _selectedRegion;
  ExamTier? _selectedTier;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedRegion = widget.initialRegion;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Exam> get _filtered {
    return allExams.where((exam) {
      final matchesRegion =
          _selectedRegion == null || exam.region == _selectedRegion;
      final matchesTier =
          _selectedTier == null || exam.tier == _selectedTier;
      final matchesQuery = _query.isEmpty ||
          exam.name.toLowerCase().contains(_query.toLowerCase()) ||
          exam.fullName.toLowerCase().contains(_query.toLowerCase()) ||
          exam.purpose.toLowerCase().contains(_query.toLowerCase());
      return matchesRegion && matchesTier && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final addedIds = ref.watch(userExamsProvider);
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Exams'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                WittSpacing.md, 0, WittSpacing.md, WittSpacing.sm),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search exams…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: WittSpacing.md, vertical: WittSpacing.sm),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(WittSpacing.sm),
                  borderSide: const BorderSide(color: WittColors.outline),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Region filter ─────────────────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: WittSpacing.md, vertical: 6),
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _selectedRegion == null,
                  onTap: () => setState(() => _selectedRegion = null),
                ),
                ...ExamRegion.values.map((r) {
                  final count =
                      allExams.where((e) => e.region == r).length;
                  if (count == 0) return const SizedBox.shrink();
                  return _FilterChip(
                    label: _regionLabel(r),
                    isSelected: _selectedRegion == r,
                    onTap: () =>
                        setState(() => _selectedRegion = r),
                  );
                }),
              ],
            ),
          ),

          // ── Tier filter ───────────────────────────────────────────────
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: WittSpacing.md, vertical: 4),
              children: [
                _FilterChip(
                  label: 'All Tiers',
                  isSelected: _selectedTier == null,
                  onTap: () => setState(() => _selectedTier = null),
                  small: true,
                ),
                _FilterChip(
                  label: 'Free',
                  isSelected: _selectedTier == ExamTier.free,
                  onTap: () =>
                      setState(() => _selectedTier = ExamTier.free),
                  small: true,
                ),
                _FilterChip(
                  label: 'Tier 1',
                  isSelected: _selectedTier == ExamTier.tier1,
                  onTap: () =>
                      setState(() => _selectedTier = ExamTier.tier1),
                  small: true,
                ),
                _FilterChip(
                  label: 'Tier 2',
                  isSelected: _selectedTier == ExamTier.tier2,
                  onTap: () =>
                      setState(() => _selectedTier = ExamTier.tier2),
                  small: true,
                ),
                _FilterChip(
                  label: 'Tier 3',
                  isSelected: _selectedTier == ExamTier.tier3,
                  onTap: () =>
                      setState(() => _selectedTier = ExamTier.tier3),
                  small: true,
                ),
              ],
            ),
          ),

          // ── Results count ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                WittSpacing.lg, WittSpacing.sm, WittSpacing.lg, 0),
            child: Row(
              children: [
                Text(
                  '${filtered.length} exam${filtered.length == 1 ? '' : 's'}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: WittColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── Exam list ─────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? WittEmptyState(
                    icon: Icons.search_off,
                    title: 'No exams found',
                    subtitle: 'Try a different search or filter',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: WittSpacing.lg,
                        vertical: WittSpacing.sm),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: WittSpacing.sm),
                    itemBuilder: (context, index) {
                      final exam = filtered[index];
                      final isAdded = addedIds.contains(exam.id);
                      return _ExamBrowserTile(
                        exam: exam,
                        isAdded: isAdded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ExamHubScreen(examId: exam.id),
                          ),
                        ),
                        onAdd: () => ref
                            .read(userExamsProvider.notifier)
                            .addExam(exam.id),
                        onRemove: () => ref
                            .read(userExamsProvider.notifier)
                            .removeExam(exam.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _regionLabel(ExamRegion r) {
    switch (r) {
      case ExamRegion.us:
        return '🇺🇸 US';
      case ExamRegion.uk:
        return '🇬🇧 UK';
      case ExamRegion.africa:
        return '🌍 Africa';
      case ExamRegion.india:
        return '🇮🇳 India';
      case ExamRegion.europe:
        return '🇪🇺 Europe';
      case ExamRegion.latinAmerica:
        return '🌎 LatAm';
      case ExamRegion.china:
        return '🇨🇳 China';
      case ExamRegion.global:
        return '🌐 Global';
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.small = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: small ? WittSpacing.sm : WittSpacing.md,
            vertical: small ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? WittColors.primary
                : WittColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? WittColors.primary
                  : WittColors.outline,
            ),
          ),
          child: Text(
            label,
            style: (small
                    ? theme.textTheme.labelSmall
                    : theme.textTheme.labelMedium)
                ?.copyWith(
              color: isSelected ? Colors.white : WittColors.textSecondary,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExamBrowserTile extends StatelessWidget {
  const _ExamBrowserTile({
    required this.exam,
    required this.isAdded,
    required this.onTap,
    required this.onAdd,
    required this.onRemove,
  });

  final Exam exam;
  final bool isAdded;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WittSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(WittSpacing.md),
        decoration: BoxDecoration(
          color: WittColors.surfaceVariant,
          borderRadius: BorderRadius.circular(WittSpacing.sm),
          border: Border.all(
            color: isAdded
                ? WittColors.primary.withValues(alpha: 0.4)
                : WittColors.outline,
          ),
        ),
        child: Row(
          children: [
            Text(exam.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: WittSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        exam.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _TierBadge(tier: exam.tier),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exam.purpose,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: WittColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${exam.sections.length} sections · ${exam.totalQuestions} Qs · ${exam.totalTimeMinutes}m',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: WittColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: WittSpacing.sm),
            GestureDetector(
              onTap: isAdded ? onRemove : onAdd,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: WittSpacing.sm, vertical: 6),
                decoration: BoxDecoration(
                  color: isAdded
                      ? WittColors.successContainer
                      : WittColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isAdded
                        ? WittColors.success
                        : WittColors.primary,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAdded ? Icons.check : Icons.add,
                      size: 14,
                      color: isAdded
                          ? WittColors.success
                          : WittColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAdded ? 'Added' : 'Add',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isAdded
                            ? WittColors.success
                            : WittColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});
  final ExamTier tier;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (tier) {
      case ExamTier.free:
        color = WittColors.success;
        label = 'FREE';
      case ExamTier.tier1:
        color = WittColors.secondary;
        label = 'T1';
      case ExamTier.tier2:
        color = WittColors.accent;
        label = 'T2';
      case ExamTier.tier3:
        color = WittColors.error;
        label = 'T3';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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
