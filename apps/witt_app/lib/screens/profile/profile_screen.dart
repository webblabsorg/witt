import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';
import 'package:witt_monetization/witt_monetization.dart';
import '../../features/progress/providers/progress_providers.dart';
import '../../features/learn/providers/test_prep_providers.dart';
import '../../features/auth/auth_state.dart';
import '../../features/onboarding/onboarding_state.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = ref.watch(progressSummaryProvider);
    final isPaid = ref.watch(isPaidUserProvider);
    final entitlement = ref.watch(entitlementProvider);
    final auth = ref.watch(authNotifierProvider);
    final onboarding = ref.watch(onboardingProvider);
    final role = onboarding.role; // 'student' | 'teacher' | 'parent' | null
    final userName = auth.user?.email?.split('@').first ?? 'Witt Student';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'W';
    final inviteCode =
        'WITT-${(auth.user?.id ?? 'DEMO').substring(0, 6).toUpperCase()}';

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
                          userInitial,
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
                              userName,
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

                  // ── Section: Tools ─────────────────────────────────
                  _SectionHeader(title: 'Tools'),
                  _ActionTile(
                    icon: Icons.translate_rounded,
                    iconColor: const Color(0xFF0891B2),
                    title: 'Translate',
                    subtitle: 'Translate study content to any language',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/home/translate'),
                  ),

                  // ── Section: Portals (role-based) ──────────────────
                  if (role == 'teacher') ...[
                    _SectionHeader(title: 'Teacher Portal'),
                    _ActionTile(
                      icon: Icons.school_rounded,
                      iconColor: const Color(0xFF7C3AED),
                      title: 'My Classes',
                      subtitle: 'Manage students, assignments & grades',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/profile/teacher'),
                    ),
                  ],
                  if (role == 'parent') ...[
                    _SectionHeader(title: 'Parent Portal'),
                    _ActionTile(
                      icon: Icons.family_restroom_rounded,
                      iconColor: const Color(0xFF0F4C81),
                      title: 'My Children',
                      subtitle: 'Monitor progress & activity',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/profile/parent'),
                    ),
                  ],
                  // Show both portals if no role set (demo / admin)
                  if (role == null || role == 'student') ...[
                    _SectionHeader(title: 'Portals'),
                    _ActionTile(
                      icon: Icons.school_rounded,
                      iconColor: const Color(0xFF7C3AED),
                      title: 'Teacher Portal',
                      subtitle: 'Manage classes, assignments & grades',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/profile/teacher'),
                    ),
                    _ActionTile(
                      icon: Icons.family_restroom_rounded,
                      iconColor: const Color(0xFF0F4C81),
                      title: 'Parent Portal',
                      subtitle: 'Monitor your child\'s progress',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/profile/parent'),
                    ),
                  ],

                  // ── Section: Account ───────────────────────────────
                  _SectionHeader(title: 'Account'),
                  _ActionTile(
                    icon: Icons.qr_code_rounded,
                    iconColor: WittColors.primary,
                    title: 'Share Invite Code',
                    subtitle: inviteCode,
                    trailing: IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invite code copied!')),
                        );
                      },
                    ),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invite code copied!')),
                      );
                    },
                  ),
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
                    onTap: () => _showAppearanceSheet(context, ref),
                  ),
                  _ActionTile(
                    icon: Icons.language_rounded,
                    iconColor: const Color(0xFF059669),
                    title: 'App Language',
                    subtitle: 'Change interface language',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),

                  // ── Section: Support ───────────────────────────────
                  _SectionHeader(title: 'Support'),
                  _ActionTile(
                    icon: Icons.help_outline,
                    iconColor: WittColors.textSecondary,
                    title: 'Help & Support',
                    subtitle: 'FAQs, contact us',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showHelpSheet(context),
                  ),
                  _ActionTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: WittColors.textSecondary,
                    title: 'About Witt',
                    subtitle: 'Version 1.0.0 · Terms · Privacy',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showAboutSheet(context),
                  ),
                  if (auth.user != null) ...[
                    const SizedBox(height: WittSpacing.sm),
                    _ActionTile(
                      icon: Icons.logout_rounded,
                      iconColor: WittColors.error,
                      title: 'Sign Out',
                      subtitle: auth.user?.email ?? '',
                      onTap: () => _confirmSignOut(context, ref),
                    ),
                  ],
                  const SizedBox(height: WittSpacing.xxxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAppearanceSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(WittSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: WittSpacing.lg),
            ListTile(
              leading: const Icon(Icons.light_mode_rounded),
              title: const Text('Light'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_rounded),
              title: const Text('Dark'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.phone_android_rounded),
              title: const Text('System Default'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(WittSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help & Support',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: WittSpacing.lg),
            const _HelpItem(
              q: 'How do I start a quiz?',
              a: 'Go to Learn → select a subject → tap Quiz.',
            ),
            const _HelpItem(
              q: 'How do I upgrade to Premium?',
              a: 'Go to Profile → tap Upgrade to Premium.',
            ),
            const _HelpItem(
              q: 'Can I use Witt offline?',
              a: 'Yes! Download content in Learn → Offline Mode.',
            ),
            const _HelpItem(
              q: 'How do I join a study group?',
              a: 'Go to Community → Groups → tap Join.',
            ),
            const _HelpItem(
              q: 'How do I contact support?',
              a: 'Email us at support@witt.app',
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(WittSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📚', style: TextStyle(fontSize: 48)),
            const SizedBox(height: WittSpacing.md),
            Text(
              'Witt',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: WittSpacing.xs),
            Text('Version 1.0.0', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: WittSpacing.sm),
            Text(
              'AI-powered exam preparation for students worldwide.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WittSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {},
                  child: const Text('Terms of Service'),
                ),
                const Text('·'),
                TextButton(
                  onPressed: () {},
                  child: const Text('Privacy Policy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).signOut();
            },
            child: Text('Sign Out', style: TextStyle(color: WittColors.error)),
          ),
        ],
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({required this.q, required this.a});
  final String q;
  final String a;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: WittSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q, style: theme.textTheme.titleSmall),
          const SizedBox(height: WittSpacing.xs),
          Text(
            a,
            style: theme.textTheme.bodySmall?.copyWith(
              color: WittColors.textSecondary,
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
