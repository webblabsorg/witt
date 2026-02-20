import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';

import '../models/teacher_models.dart';
import '../providers/teacher_providers.dart';

class ParentScreen extends ConsumerWidget {
  const ParentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(childLinksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link_rounded),
            tooltip: 'Link Child',
            onPressed: () => _showLinkChild(context),
          ),
        ],
      ),
      body: children.isEmpty
          ? _EmptyState(onLink: () => _showLinkChild(context))
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                WittSpacing.lg,
                WittSpacing.md,
                WittSpacing.lg,
                100,
              ),
              children: children
                  .map((c) => _ChildCard(child: c, isDark: isDark))
                  .toList(),
            ),
    );
  }

  void _showLinkChild(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LinkChildSheet(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onLink});
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WittSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👨‍👩‍👧', style: TextStyle(fontSize: 64)),
            const SizedBox(height: WittSpacing.lg),
            Text(
              'Link your child\'s account',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WittSpacing.sm),
            Text(
              'Enter the invite code from your child\'s Witt app to start monitoring their progress.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WittSpacing.xl),
            WittButton(
              label: 'Link Child Account',
              onPressed: onLink,
              variant: WittButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.child, required this.isDark});
  final ChildLink child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = DateTime.now().difference(child.lastActive);
    final lastSeen = diff.inMinutes < 60
        ? '${diff.inMinutes}m ago'
        : diff.inHours < 24
        ? '${diff.inHours}h ago'
        : '${diff.inDays}d ago';
    final weeklyProgress =
        (child.studyMinutesToday * 7 / child.weeklyGoalMinutes).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Child header
        WittCard(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F4C81), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          padding: const EdgeInsets.all(WittSpacing.lg),
          child: Row(
            children: [
              WittAvatar(
                initials: child.avatarInitials,
                size: WittAvatarSize.lg,
              ),
              const SizedBox(width: WittSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.childName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Last active: $lastSeen',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: WittSpacing.xs),
                    Wrap(
                      spacing: WittSpacing.xs,
                      children: child.activeExams
                          .map(
                            (e) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: WittSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(51),
                                borderRadius: WittSpacing.borderRadiusFull,
                              ),
                              child: Text(
                                e,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: WittSpacing.md),

        // Stats row
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'XP Earned',
                value: '${child.xp}',
                icon: Icons.star_rounded,
                color: WittColors.streak,
              ),
            ),
            const SizedBox(width: WittSpacing.sm),
            Expanded(
              child: _StatTile(
                label: 'Day Streak',
                value: '🔥 ${child.streak}',
                icon: Icons.local_fire_department_rounded,
                color: WittColors.secondary,
              ),
            ),
            const SizedBox(width: WittSpacing.sm),
            Expanded(
              child: _StatTile(
                label: 'Today',
                value: '${child.studyMinutesToday}m',
                icon: Icons.timer_rounded,
                color: WittColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: WittSpacing.md),

        // Weekly goal
        WittCard(
          padding: const EdgeInsets.all(WittSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Weekly Study Goal', style: theme.textTheme.titleSmall),
                  Text(
                    '${child.studyMinutesToday * 7}/${child.weeklyGoalMinutes} min',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? WittColors.textSecondaryDark
                          : WittColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: WittSpacing.sm),
              WittProgressBar(
                value: weeklyProgress,
                color: weeklyProgress >= 1.0
                    ? WittColors.success
                    : WittColors.primary,
              ),
              const SizedBox(height: WittSpacing.xs),
              Text(
                weeklyProgress >= 1.0
                    ? '🎉 Weekly goal achieved!'
                    : '${((1 - weeklyProgress) * child.weeklyGoalMinutes).round()} min remaining this week',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: weeklyProgress >= 1.0
                      ? WittColors.success
                      : isDark
                      ? WittColors.textSecondaryDark
                      : WittColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: WittSpacing.md),

        // Activity summary
        WittCard(
          padding: const EdgeInsets.all(WittSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recent Activity', style: theme.textTheme.titleSmall),
              const SizedBox(height: WittSpacing.sm),
              _ActivityRow(
                icon: Icons.quiz_rounded,
                label: 'Completed SAT Math Quiz',
                detail: 'Score: 85% · 2h ago',
                isDark: isDark,
              ),
              _ActivityRow(
                icon: Icons.style_rounded,
                label: 'Studied Vocabulary Deck',
                detail: '40 cards · 4h ago',
                isDark: isDark,
              ),
              _ActivityRow(
                icon: Icons.psychology_rounded,
                label: 'Brain Challenge',
                detail: 'Streak +1 · Yesterday',
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: WittSpacing.md),

        // Report button
        WittButton(
          label: 'Download Progress Report',
          // Report export not yet wired.
          onPressed: () {},
          variant: WittButtonVariant.outline,
          icon: Icons.download_rounded,
        ),
        const SizedBox(height: WittSpacing.xxl),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WittCard(
      padding: const EdgeInsets.all(WittSpacing.md),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: WittSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.label,
    required this.detail,
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final String detail;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: WittSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: WittColors.primary.withAlpha(26),
              borderRadius: WittSpacing.borderRadiusSm,
            ),
            child: Icon(icon, size: 16, color: WittColors.primary),
          ),
          const SizedBox(width: WittSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                Text(
                  detail,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? WittColors.textSecondaryDark
                        : WittColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkChildSheet extends StatefulWidget {
  const _LinkChildSheet();

  @override
  State<_LinkChildSheet> createState() => _LinkChildSheetState();
}

class _LinkChildSheetState extends State<_LinkChildSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        WittSpacing.lg,
        WittSpacing.lg,
        WittSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + WittSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Link Child Account', style: theme.textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: WittSpacing.sm),
          Text(
            'Ask your child to open Witt → Profile → Share Invite Code, then enter it below.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: WittSpacing.md),
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(
              hintText: 'Enter invite code (e.g. WITT-ABC123)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link_rounded),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: WittSpacing.md),
          WittButton(
            label: 'Link Account',
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Child account linked successfully!'),
                ),
              );
            },
            variant: WittButtonVariant.primary,
          ),
        ],
      ),
    );
  }
}
