import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static final _notifications = [
    _Notif(
      icon: Icons.local_fire_department_rounded,
      color: WittColors.streak,
      title: 'Keep your streak alive!',
      body: 'You haven\'t studied today. 23 hours left to maintain your 7-day streak.',
      time: '2h ago',
      isUnread: true,
    ),
    _Notif(
      icon: Icons.emoji_events_rounded,
      color: WittColors.secondary,
      title: 'New badge unlocked',
      body: 'You earned the "7-Day Streak" badge. Keep it up!',
      time: '5h ago',
      isUnread: true,
    ),
    _Notif(
      icon: Icons.auto_awesome_rounded,
      color: WittColors.primary,
      title: 'Your AI study plan is ready',
      body: 'Sage has created a personalised 4-week SAT prep plan based on your weak areas.',
      time: 'Yesterday',
      isUnread: false,
    ),
    _Notif(
      icon: Icons.calendar_today_rounded,
      color: WittColors.accent,
      title: 'SAT exam in 42 days',
      body: 'You\'re 68% ready. Focus on Math: Algebra and Reading: Evidence-Based this week.',
      time: 'Yesterday',
      isUnread: false,
    ),
    _Notif(
      icon: Icons.new_releases_rounded,
      color: WittColors.success,
      title: 'New WAEC 2025 pack available',
      body: '500 new questions covering all subjects. Download now for offline access.',
      time: '2 days ago',
      isUnread: false,
    ),
    _Notif(
      icon: Icons.people_rounded,
      color: WittColors.secondary,
      title: 'Amara challenged you',
      body: 'Amara sent you a Math Duel challenge. Accept before it expires in 24h.',
      time: '3 days ago',
      isUnread: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unreadCount = _notifications.where((n) => n.isUnread).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () => setState(() {
                for (final n in _notifications) {
                  n.isUnread = false;
                }
              }),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? WittEmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications yet',
              subtitle: 'We\'ll notify you about streaks, exams, and updates.',
            )
          : ListView.separated(
              padding: WittSpacing.pagePadding,
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: isDark ? WittColors.outlineDark : WittColors.outline,
              ),
              itemBuilder: (context, i) {
                final n = _notifications[i];
                return _NotifTile(notif: n, isDark: isDark);
              },
            ),
    );
  }
}

class _Notif {
  _Notif({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.time,
    required this.isUnread,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String time;
  bool isUnread;
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.notif, required this.isDark});
  final _Notif notif;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: notif.isUnread
          ? WittColors.primaryContainer.withAlpha(isDark ? 40 : 60)
          : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: WittSpacing.lg,
          vertical: WittSpacing.sm,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: notif.color.withAlpha(26),
            borderRadius: WittSpacing.borderRadiusMd,
          ),
          child: Icon(notif.icon, color: notif.color, size: WittSpacing.iconMd),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notif.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight:
                      notif.isUnread ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (notif.isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: WittColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: WittSpacing.xs),
            Text(
              notif.body,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? WittColors.textSecondaryDark
                    : WittColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: WittSpacing.xs),
            Text(
              notif.time,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark
                    ? WittColors.textTertiaryDark
                    : WittColors.textTertiary,
              ),
            ),
          ],
        ),
        onTap: () {},
      ),
    );
  }
}
