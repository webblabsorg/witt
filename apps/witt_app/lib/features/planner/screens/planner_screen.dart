import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witt_ui/witt_ui.dart';
import '../models/planner.dart';
import '../providers/planner_providers.dart';

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final todayEvents = ref.watch(eventsForSelectedDayProvider);
    final goals = ref.watch(studyGoalsProvider);
    final countdowns = ref.watch(examCountdownsProvider);
    final weeklyMins = ref.watch(weeklyStudyMinutesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Study Planner'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddEventSheet(context, ref, selectedDay),
              ),
            ],
          ),

          // ── Week strip ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _WeekStrip(selectedDay: selectedDay, ref: ref),
          ),

          // ── Exam countdowns ───────────────────────────────────────
          if (countdowns.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  WittSpacing.lg,
                  WittSpacing.lg,
                  WittSpacing.lg,
                  WittSpacing.sm,
                ),
                child: Text(
                  'Exam Countdowns',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: WittSpacing.lg,
                  ),
                  itemCount: countdowns.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: WittSpacing.sm),
                  itemBuilder: (_, i) =>
                      _CountdownCard(countdown: countdowns[i]),
                ),
              ),
            ),
          ],

          // ── Study goals ───────────────────────────────────────────
          if (goals.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  WittSpacing.lg,
                  WittSpacing.lg,
                  WittSpacing.lg,
                  WittSpacing.sm,
                ),
                child: Row(
                  children: [
                    Text(
                      'Study Goals',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(weeklyMins / 60).toStringAsFixed(1)}h this week',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: WittColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _GoalTile(goal: goals[i]),
                childCount: goals.length,
              ),
            ),
          ],

          // ── Today's schedule ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                WittSpacing.lg,
                WittSpacing.lg,
                WittSpacing.lg,
                WittSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    _dayLabel(selectedDay),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (todayEvents.isNotEmpty)
                    Text(
                      '${todayEvents.length} event${todayEvents.length == 1 ? '' : 's'}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: WittColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (todayEvents.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: WittSpacing.lg),
                child: _EmptyDayBanner(
                  onAdd: () => _showAddEventSheet(context, ref, selectedDay),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _EventTile(
                  event: todayEvents[i],
                  onToggle: () => ref
                      .read(plannerEventsProvider.notifier)
                      .toggleComplete(todayEvents[i].id),
                  onDelete: () => ref
                      .read(plannerEventsProvider.notifier)
                      .deleteEvent(todayEvents[i].id),
                ),
                childCount: todayEvents.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventSheet(context, ref, selectedDay),
        backgroundColor: WittColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    if (day == today) return "Today's Schedule";
    if (day == tomorrow) return "Tomorrow's Schedule";
    if (day == yesterday) return "Yesterday's Schedule";
    return '${_monthName(day.month)} ${day.day}';
  }

  String _monthName(int m) => const [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m];

  void _showAddEventSheet(BuildContext context, WidgetRef ref, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddEventSheet(date: date, ref: ref),
    );
  }
}

// ── Week strip ────────────────────────────────────────────────────────────

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.selectedDay, required this.ref});
  final DateTime selectedDay;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Show 7 days centred around today
    final days = List.generate(
      14,
      (i) => today.subtract(Duration(days: 3)).add(Duration(days: i)),
    );
    final theme = Theme.of(context);

    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: WittSpacing.md,
          vertical: WittSpacing.sm,
        ),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = day == selectedDay;
          final isToday = day == today;
          final allEvents = ref.watch(plannerEventsProvider);
          final hasEvents = allEvents.any(
            (e) =>
                e.date.year == day.year &&
                e.date.month == day.month &&
                e.date.day == day.day,
          );

          return GestureDetector(
            onTap: () => ref.read(selectedDayProvider.notifier).state = day,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? WittColors.primary
                    : isToday
                    ? WittColors.primaryContainer
                    : WittColors.surfaceVariant,
                borderRadius: BorderRadius.circular(WittSpacing.sm),
                border: Border.all(
                  color: isSelected
                      ? WittColors.primary
                      : isToday
                      ? WittColors.primary.withValues(alpha: 0.4)
                      : WittColors.outline,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekdayShort(day.weekday),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : WittColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '${day.day}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                  if (hasEvents)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.7)
                            : WittColors.primary,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _weekdayShort(int w) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];
}

// ── Countdown card ────────────────────────────────────────────────────────

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({required this.countdown});
  final ExamCountdown countdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = countdown.daysRemaining;
    final urgentColor = days <= 7
        ? WittColors.error
        : days <= 30
        ? WittColors.warning
        : WittColors.primary;

    return Container(
      width: 130,
      padding: const EdgeInsets.all(WittSpacing.sm),
      decoration: BoxDecoration(
        color: urgentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(WittSpacing.sm),
        border: Border.all(color: urgentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(countdown.examEmoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  countdown.examName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            countdown.isPast ? 'Exam passed' : '$days days left',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: urgentColor,
            ),
          ),
          if (countdown.targetScore != null)
            Text(
              'Target: ${countdown.targetScore!.toStringAsFixed(0)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: WittColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Goal tile ─────────────────────────────────────────────────────────────

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal});
  final StudyGoal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = goal.isAchieved ? WittColors.success : WittColors.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WittSpacing.lg,
        0,
        WittSpacing.lg,
        WittSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(WittSpacing.md),
        decoration: BoxDecoration(
          color: WittColors.surfaceVariant,
          borderRadius: BorderRadius.circular(WittSpacing.sm),
          border: Border.all(color: WittColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (goal.isAchieved)
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: WittColors.success,
                  ),
                const SizedBox(width: 4),
                Text(
                  '${goal.currentMinutes}/${goal.targetMinutes} min',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: WittColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: WittSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal.progress,
                backgroundColor: WittColors.outline,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${goal.period.name[0].toUpperCase()}${goal.period.name.substring(1)} goal · ${(goal.progress * 100).round()}% complete',
              style: theme.textTheme.labelSmall?.copyWith(
                color: WittColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Event tile ────────────────────────────────────────────────────────────

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.onToggle,
    required this.onDelete,
  });
  final PlannerEvent event;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _eventColor(event.type);
    final timeStr =
        '${event.startTime.format(context)} · ${event.durationMinutes} min';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WittSpacing.lg,
        0,
        WittSpacing.lg,
        WittSpacing.sm,
      ),
      child: Dismissible(
        key: Key(event.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: WittSpacing.lg),
          decoration: BoxDecoration(
            color: WittColors.error,
            borderRadius: BorderRadius.circular(WittSpacing.sm),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) => onDelete(),
        child: Container(
          padding: const EdgeInsets.all(WittSpacing.md),
          decoration: BoxDecoration(
            color: event.isCompleted
                ? WittColors.surfaceVariant.withValues(alpha: 0.5)
                : WittColors.surfaceVariant,
            borderRadius: BorderRadius.circular(WittSpacing.sm),
            border: Border.all(
              color: event.isCompleted
                  ? WittColors.outline
                  : color.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: event.isCompleted ? WittColors.outline : color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: WittSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: event.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: event.isCompleted
                            ? WittColors.textTertiary
                            : null,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: WittColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _eventTypeLabel(event.type),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: WittSpacing.sm),
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                  event.isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: event.isCompleted
                      ? WittColors.success
                      : WittColors.outline,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _eventColor(PlannerEventType t) => switch (t) {
    PlannerEventType.studySession => WittColors.primary,
    PlannerEventType.mockTest => WittColors.error,
    PlannerEventType.revision => WittColors.secondary,
    PlannerEventType.examDay => WittColors.warning,
    PlannerEventType.milestone => WittColors.success,
    PlannerEventType.break_ => WittColors.textTertiary,
  };

  String _eventTypeLabel(PlannerEventType t) => switch (t) {
    PlannerEventType.studySession => 'Study',
    PlannerEventType.mockTest => 'Mock Test',
    PlannerEventType.revision => 'Revision',
    PlannerEventType.examDay => 'Exam',
    PlannerEventType.milestone => 'Milestone',
    PlannerEventType.break_ => 'Break',
  };
}

// ── Empty day banner ──────────────────────────────────────────────────────

class _EmptyDayBanner extends StatelessWidget {
  const _EmptyDayBanner({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        padding: const EdgeInsets.all(WittSpacing.lg),
        decoration: BoxDecoration(
          color: WittColors.surfaceVariant,
          borderRadius: BorderRadius.circular(WittSpacing.sm),
          border: Border.all(
            color: WittColors.outline,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.event_available,
              size: 36,
              color: WittColors.textTertiary,
            ),
            const SizedBox(height: WittSpacing.sm),
            Text(
              'No events scheduled',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: WittColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + to add a study session',
              style: theme.textTheme.bodySmall?.copyWith(
                color: WittColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add event sheet ───────────────────────────────────────────────────────

class _AddEventSheet extends ConsumerStatefulWidget {
  const _AddEventSheet({required this.date, required this.ref});
  final DateTime date;
  final WidgetRef ref;

  @override
  ConsumerState<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends ConsumerState<_AddEventSheet> {
  final _titleController = TextEditingController();
  PlannerEventType _type = PlannerEventType.studySession;
  TimeOfDay _startTime = TimeOfDay.now();
  int _durationMinutes = 60;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        WittSpacing.lg,
        WittSpacing.lg,
        WittSpacing.lg,
        WittSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Event',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: WittSpacing.md),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
          ),
          const SizedBox(height: WittSpacing.md),
          // Type selector
          Wrap(
            spacing: WittSpacing.sm,
            children: PlannerEventType.values.map((t) {
              final selected = _type == t;
              return GestureDetector(
                onTap: () => setState(() => _type = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? WittColors.primary
                        : WittColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? WittColors.primary : WittColors.outline,
                    ),
                  ),
                  child: Text(
                    _typeLabel(t),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: selected ? Colors.white : WittColors.textSecondary,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: WittSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.access_time, size: 16),
                  label: Text(_startTime.format(context)),
                  onPressed: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: _startTime,
                    );
                    if (t != null) setState(() => _startTime = t);
                  },
                ),
              ),
              const SizedBox(width: WittSpacing.sm),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _durationMinutes,
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [15, 30, 45, 60, 90, 120, 180]
                      .map(
                        (m) =>
                            DropdownMenuItem(value: m, child: Text('$m min')),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _durationMinutes = v ?? 60),
                ),
              ),
            ],
          ),
          const SizedBox(height: WittSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: WittButton(
              label: 'Add Event',
              onPressed: _titleController.text.trim().isEmpty ? null : _save,
              icon: Icons.add,
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final event = PlannerEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      type: _type,
      date: widget.date,
      startTime: _startTime,
      durationMinutes: _durationMinutes,
    );
    ref.read(plannerEventsProvider.notifier).addEvent(event);
    Navigator.of(context).pop();
  }

  String _typeLabel(PlannerEventType t) => switch (t) {
    PlannerEventType.studySession => 'Study',
    PlannerEventType.mockTest => 'Mock Test',
    PlannerEventType.revision => 'Revision',
    PlannerEventType.examDay => 'Exam Day',
    PlannerEventType.milestone => 'Milestone',
    PlannerEventType.break_ => 'Break',
  };
}
