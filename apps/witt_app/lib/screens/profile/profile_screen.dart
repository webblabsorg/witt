import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';
import 'package:witt_monetization/witt_monetization.dart';
import '../../features/progress/providers/progress_providers.dart';
import '../../features/learn/providers/test_prep_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(progressSummaryProvider);
    final isPaid = ref.watch(isPaidUserProvider);
    final entitlement = ref.watch(entitlementProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: WittSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar + name ──────────────────────────────────
                  const SizedBox(height: WittSpacing.md),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: WittColors.primary.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          'W',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: WittColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: WittSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Witt Student',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPaid
                                        ? WittColors.primary.withValues(
                                            alpha: 0.12,
                                          )
                                        : WittColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isPaid
                                          ? WittColors.primary.withValues(
                                              alpha: 0.3,
                                            )
                                          : WittColors.outline,
                                    ),
                                  ),
                                  child: Text(
                                    isPaid
                                        ? (entitlement.isInTrial
                                              ? '✨ Trial'
                                              : '💎 Premium')
                                        : 'Free Plan',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: isPaid
                                          ? WittColors.primary
                                          : WittColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: WittSpacing.sm),
                                Text(
                                  'Level ${summary.level}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: WittColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: WittSpacing.md),

                  // ── XP progress bar ────────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: summary.levelProgress.clamp(0.0, 1.0),
                      backgroundColor: WittColors.outline,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        WittColors.primary,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.xpPoints} XP · ${summary.xpToNextLevel} to Level ${summary.level + 1}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: WittColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: WittSpacing.md),

                  // ── Quick stats row ────────────────────────────────
                  Row(
                    children: [
                      _MiniStat(
                        value: '${summary.streak.currentDays}',
                        label: 'Streak',
                        icon: '🔥',
                      ),
                      _MiniStat(
                        value: '${summary.totalQuestionsAnswered}',
                        label: 'Questions',
                        icon: '📝',
                      ),
                      _MiniStat(
                        value: '${(summary.overallAccuracy * 100).round()}%',
                        label: 'Accuracy',
                        icon: '🎯',
                      ),
                      _MiniStat(
                        value: '${summary.badges.length}',
                        label: 'Badges',
                        icon: '🏅',
                      ),
                    ],
                  ),
                  const SizedBox(height: WittSpacing.md),

                  // ── Progress Dashboard CTA ─────────────────────────
                  _ActionTile(
                    icon: Icons.bar_chart_rounded,
                    iconColor: WittColors.primary,
                    title: 'Progress Dashboard',
                    subtitle: 'Detailed stats, exam readiness & analytics',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/profile/progress'),
                  ),
                  const SizedBox(height: WittSpacing.sm),

                  // ── Upgrade CTA (free users only) ──────────────────
                  if (!isPaid) ...[
                    GestureDetector(
                      onTap: () => context.push('/onboarding/paywall'),
                      child: Container(
                        padding: const EdgeInsets.all(WittSpacing.md),
                        decoration: BoxDecoration(
                          gradient: WittColors.primaryGradient,
                          borderRadius: BorderRadius.circular(WittSpacing.md),
                        ),
                        child: Row(
                          children: [
                            const Text('💎', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: WittSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Upgrade to Premium',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Unlimited AI, all features, 7-day free trial',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: WittSpacing.sm),
                  ],

                  // ── Section: Study ─────────────────────────────────
                  _SectionHeader(title: 'Study'),
                  _ActionTile(
                    icon: Icons.style_outlined,
                    iconColor: const Color(0xFF10B981),
                    title: 'My Flashcard Decks',
                    subtitle:
                        '${summary.totalFlashcardsReviewed} cards reviewed',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  _ActionTile(
                    icon: Icons.quiz_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'Quiz History',
                    subtitle: 'View past quiz results',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),

                  // ── Section: Account ───────────────────────────────
                  _SectionHeader(title: 'Account'),
                  _ActionTile(
                    icon: Icons.notifications_outlined,
                    iconColor: WittColors.primary,
                    title: 'Notifications',
                    subtitle: 'Study reminders & alerts',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  _ActionTile(
                    icon: Icons.dark_mode_outlined,
                    iconColor: WittColors.textSecondary,
                    title: 'Appearance',
                    subtitle: 'Theme & display settings',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  _ActionTile(
                    icon: Icons.help_outline,
                    iconColor: WittColors.textSecondary,
                    title: 'Help & Support',
                    subtitle: 'FAQs, contact us',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const SizedBox(height: WittSpacing.xxxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value;
  final String label;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(
          vertical: WittSpacing.sm,
          horizontal: 4,
        ),
        decoration: BoxDecoration(
          color: WittColors.surfaceVariant,
          borderRadius: BorderRadius.circular(WittSpacing.sm),
          border: Border.all(color: WittColors.outline),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: WittColors.textSecondary,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: WittSpacing.md,
        bottom: WittSpacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: WittColors.textTertiary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WittSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: WittSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: WittSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: WittColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
