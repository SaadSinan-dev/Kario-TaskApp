import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/presentation/enum_presentation.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/app_typography.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/utils/date_utils.dart';
import 'package:kairo/core/widgets/app_avatar.dart';
import 'package:kairo/core/widgets/app_badge.dart';
import 'package:kairo/core/widgets/app_states.dart';
import 'package:kairo/core/widgets/completion_check.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/features/tasks/application/task_actions.dart';

/// Which calendar layout is showing.
enum CalendarMode { month, week, day }

/// Buckets tasks by their due day once, so every cell is an O(1) lookup rather
/// than a scan of the whole task list.
Map<String, List<Task>> bucketByDay(List<Task> tasks) {
  final Map<String, List<Task>> map = <String, List<Task>>{};
  for (final Task task in tasks) {
    final DateTime? due = task.dueDate;
    if (due == null) continue;
    map.putIfAbsent(_key(due), () => <Task>[]).add(task);
  }
  for (final List<Task> day in map.values) {
    day.sort((Task a, Task b) {
      final int byDone = (a.isDone ? 1 : 0).compareTo(b.isDone ? 1 : 0);
      if (byDone != 0) return byDone;
      return b.priority.weight.compareTo(a.priority.weight);
    });
  }
  return map;
}

String _key(DateTime value) => '${value.year}-${value.month}-${value.day}';

/// Month grid. Always six rows so paging between months never resizes the page.
class MonthGrid extends ConsumerWidget {
  const MonthGrid({
    required this.month,
    required this.tasks,
    required this.selectedDay,
    required this.onSelectDay,
    required this.onOpenTask,
    required this.onCreateOn,
    required this.weekStartsOn,
    super.key,
  });

  final DateTime month;
  final List<Task> tasks;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<Task> onOpenTask;
  final ValueChanged<DateTime> onCreateOn;
  final int weekStartsOn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final List<DateTime> days = Dates.monthGrid(
      month,
      weekStartsOn: weekStartsOn,
    );
    final Map<String, List<Task>> buckets = bucketByDay(tasks);

    return Column(
      children: <Widget>[
        _WeekdayHeader(weekStartsOn: weekStartsOn),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.hairline),
                left: BorderSide(color: colors.hairline),
              ),
            ),
            // The row height is derived from the space actually available
            // rather than from a fixed aspect ratio. An aspect ratio makes the
            // grid's height a function of its *width*, so on a narrow screen
            // six rows grew taller than the viewport and every cell reported an
            // overflow. Dividing the real height by the real row count means
            // the grid always fits exactly, at any size.
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                const int rowCount = 6;
                final double rowHeight = constraints.maxHeight / rowCount;
                final double columnWidth = constraints.maxWidth / 7;

                return GridView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisExtent: rowHeight,
                  ),
                  itemCount: days.length,
                  itemBuilder: (BuildContext context, int index) {
                    final DateTime day = days[index];
                    return _DayCell(
                      day: day,
                      tasks: buckets[_key(day)] ?? const <Task>[],
                      isCurrentMonth: Dates.isSameMonth(day, month),
                      isSelected: Dates.isSameDay(day, selectedDay),
                      cellWidth: columnWidth,
                      onSelect: () => onSelectDay(day),
                      onOpenTask: onOpenTask,
                      onCreate: () => onCreateOn(day),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.weekStartsOn});

  final int weekStartsOn;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final List<DateTime> week = Dates.weekDays(
      DateTime.now(),
      weekStartsOn: weekStartsOn,
    );
    return Row(
      children: <Widget>[
        for (final DateTime day in week)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
              child: Text(
                Dates.weekdayShort(day).toUpperCase(),
                textAlign: TextAlign.center,
                style: context.textStyles.labelSmall?.copyWith(
                  color: colors.inkFaint,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Narrowest cell that can still show a readable task chip. Below this a chip
/// shows two or three characters of a title, which is worse than a dot.
const double _chipMinCellWidth = 76;

/// Vertical room one chip occupies, including the gap beneath it.
const double _chipExtent = 20;

/// Vertical room the "+N more" line occupies.
const double _moreExtent = 13;

/// What a month cell shows beneath the date.
///
/// The count is measured, never hardcoded: the cell is told how much height it
/// actually has and fits as many chips as will genuinely display. A fixed
/// `take(3)` was the original bug — three chips need about 60px, and a six-row
/// month grid on a 360px phone gives each cell barely half that.
class _DayCellContents extends StatelessWidget {
  const _DayCellContents({
    required this.tasks,
    required this.available,
    required this.narrow,
    required this.onOpenTask,
  });

  final List<Task> tasks;
  final double available;
  final bool narrow;
  final ValueChanged<Task> onOpenTask;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;

    // On a phone-sized cell no chip fits, so the cell answers "is there work
    // here, and how urgent" with dots. Tapping the day opens the agenda
    // beneath the grid, which is where the titles live at this size.
    if (narrow || available < _chipExtent) {
      return Align(
        alignment: Alignment.topLeft,
        child: _TaskDots(tasks: tasks),
      );
    }

    final int fits = (available / _chipExtent).floor();
    final bool needsMore = tasks.length > fits;
    // Showing "+N more" costs a chip slot, but only when it would actually be
    // hiding something.
    final int shown = needsMore
        ? ((available - _moreExtent) / _chipExtent).floor().clamp(0, fits)
        : fits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final Task task in tasks.take(shown))
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: DraggableTaskChip(task: task, onTap: () => onOpenTask(task)),
          ),
        if (tasks.length > shown)
          Text(
            '+${tasks.length - shown} more',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.labelSmall?.copyWith(
              color: colors.inkFaint,
              fontSize: 9.5,
              height: 1.2,
            ),
          ),
      ],
    );
  }
}

/// Up to three priority-coloured dots, plus a count when there are more.
class _TaskDots extends StatelessWidget {
  const _TaskDots({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const int maxDots = 3;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final Task task in tasks.take(maxDots))
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: task.isDone
                    ? colors.inkFaint
                    : task.priority.color(colors),
                shape: BoxShape.circle,
              ),
            ),
          ),
        if (tasks.length > maxDots)
          Flexible(
            child: Text(
              '+${tasks.length - maxDots}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.labelSmall?.copyWith(
                color: colors.inkFaint,
                fontSize: 8.5,
                height: 1,
              ),
            ),
          ),
      ],
    );
  }
}

/// A single month cell: a drop target for rescheduling and a tap target for
/// creating on that day.
class _DayCell extends ConsumerStatefulWidget {
  const _DayCell({
    required this.day,
    required this.tasks,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.cellWidth,
    required this.onSelect,
    required this.onOpenTask,
    required this.onCreate,
  });

  final DateTime day;
  final List<Task> tasks;
  final bool isCurrentMonth;
  final bool isSelected;

  /// How wide this cell is. Below roughly 76px a task chip cannot show enough
  /// of a title to be worth the room, so the cell switches to dots.
  final double cellWidth;

  final VoidCallback onSelect;
  final ValueChanged<Task> onOpenTask;
  final VoidCallback onCreate;

  @override
  ConsumerState<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends ConsumerState<_DayCell> {
  bool _hovered = false;
  bool _dragOver = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool isToday = Dates.isToday(widget.day);
    final int overdueCount = widget.tasks.where((Task t) => t.isOverdue).length;

    return DragTarget<Task>(
      onWillAcceptWithDetails: (_) {
        setState(() => _dragOver = true);
        return true;
      },
      onLeave: (_) => setState(() => _dragOver = false),
      onAcceptWithDetails: (DragTargetDetails<Task> details) {
        setState(() => _dragOver = false);
        ref
            .read(taskActionsProvider)
            .update(
              l10n: context.l10n,
              task: details.data.copyWith(dueDate: widget.day),
              silent: true,
            );
      },
      builder: (BuildContext context, _, _) {
        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onSelect,
            onDoubleTap: widget.onCreate,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: context.motion(Motion.fast),
              decoration: BoxDecoration(
                color: _dragOver
                    ? colors.dragTint
                    : (widget.isSelected
                          ? colors.brandSoft
                          : (widget.isCurrentMonth
                                ? colors.surface
                                : colors.surfaceSunken)),
                border: Border(
                  right: BorderSide(color: colors.hairline),
                  bottom: BorderSide(color: colors.hairline),
                ),
              ),
              // Every dimension below is a function of the height the grid
              // actually handed this cell. A month has to show six rows
              // whatever the screen, so on a small phone a cell is roughly
              // 28px tall — and a 20px date badge with fixed padding simply
              // does not fit inside that. The cell scales instead of spilling.
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool tiny = constraints.maxHeight < 46;
                  final double inset = tiny ? 2 : 5;
                  final double badge = tiny ? 15 : 20;
                  final double contentGap = tiny ? 1 : 3;
                  final double remaining =
                      constraints.maxHeight - badge - contentGap - inset * 2;

                  return Padding(
                    padding: EdgeInsets.all(inset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(
                          height: badge,
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: badge,
                                height: badge,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? colors.brand
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${widget.day.day}',
                                  style: AppTypography.numeric.copyWith(
                                    fontSize: tiny ? 9.5 : 11,
                                    height: 1,
                                    fontWeight: isToday
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isToday
                                        ? Colors.white
                                        : (widget.isCurrentMonth
                                              ? colors.inkSoft
                                              : colors.inkFaint),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (overdueCount > 0)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: colors.danger,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              // Hover-to-create is a pointer affordance, and a
                              // cell this small has no room for it anyway.
                              else if (_hovered && !tiny)
                                InkWell(
                                  onTap: widget.onCreate,
                                  child: Icon(
                                    AppIcons.add,
                                    size: 13,
                                    color: colors.inkFaint,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (remaining > 4) ...<Widget>[
                          SizedBox(height: contentGap),
                          // Loose rather than `Expanded`: the contents take
                          // what is left over, and take nothing when there is
                          // nothing left over.
                          Flexible(
                            child: _DayCellContents(
                              tasks: widget.tasks,
                              available: remaining,
                              narrow: widget.cellWidth < _chipMinCellWidth,
                              onOpenTask: widget.onOpenTask,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A compact task pill that can be dragged onto another day.
class DraggableTaskChip extends ConsumerWidget {
  const DraggableTaskChip({
    required this.task,
    required this.onTap,
    this.dense = true,
    super.key,
  });

  final Task task;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final Map<String, Project> projects = ref.watch(projectsByIdProvider);
    final Project? project = task.projectId == null
        ? null
        : projects[task.projectId!];
    final Color accent = project == null
        ? task.priority.color(colors)
        : Color(project.colorValue);

    final Widget chip = Container(
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: dense ? 2.5 : 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: colors.isDark ? 0.18 : 0.11),
        borderRadius: Radii.brXs,
        border: BorderDirectional(start: BorderSide(color: accent, width: 2.5)),
      ),
      child: Row(
        children: <Widget>[
          if (task.isDone) ...<Widget>[
            Icon(AppIcons.check, size: 9, color: colors.success),
            const SizedBox(width: 3),
          ],
          Expanded(
            child: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.labelSmall?.copyWith(
                fontSize: dense ? 9.8 : 11,
                height: 1.35,
                color: task.isDone ? colors.inkFaint : colors.inkSoft,
                decoration: task.isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );

    final Widget feedback = Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 180,
        child: Transform.rotate(
          angle: -0.02,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: Radii.brXs,
              boxShadow: Shadows.lg(colors.isDark),
            ),
            child: chip,
          ),
        ),
      ),
    );

    final Widget tappable = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(cursor: SystemMouseCursors.click, child: chip),
    );

    if (context.isTouchFirst) {
      return LongPressDraggable<Task>(
        data: task,
        feedback: feedback,
        childWhenDragging: Opacity(opacity: 0.3, child: chip),
        hapticFeedbackOnStart: true,
        child: tappable,
      );
    }

    return Draggable<Task>(
      data: task,
      feedback: feedback,
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      child: tappable,
    );
  }
}

/// Week view: seven day columns with a full task list in each.
class WeekView extends ConsumerWidget {
  const WeekView({
    required this.anchor,
    required this.tasks,
    required this.onOpenTask,
    required this.onCreateOn,
    required this.weekStartsOn,
    super.key,
  });

  final DateTime anchor;
  final List<Task> tasks;
  final ValueChanged<Task> onOpenTask;
  final ValueChanged<DateTime> onCreateOn;
  final int weekStartsOn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final List<DateTime> days = Dates.weekDays(
      anchor,
      weekStartsOn: weekStartsOn,
    );
    final Map<String, List<Task>> buckets = bucketByDay(tasks);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final DateTime day in days)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: colors.hairline)),
                color: Dates.isToday(day) ? colors.brandSoft : null,
              ),
              child: _WeekColumn(
                day: day,
                tasks: buckets[_key(day)] ?? const <Task>[],
                onOpenTask: onOpenTask,
                onCreate: () => onCreateOn(day),
              ),
            ),
          ),
      ],
    );
  }
}

class _WeekColumn extends ConsumerStatefulWidget {
  const _WeekColumn({
    required this.day,
    required this.tasks,
    required this.onOpenTask,
    required this.onCreate,
  });

  final DateTime day;
  final List<Task> tasks;
  final ValueChanged<Task> onOpenTask;
  final VoidCallback onCreate;

  @override
  ConsumerState<_WeekColumn> createState() => _WeekColumnState();
}

class _WeekColumnState extends ConsumerState<_WeekColumn> {
  bool _dragOver = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool isToday = Dates.isToday(widget.day);

    return DragTarget<Task>(
      onWillAcceptWithDetails: (_) {
        setState(() => _dragOver = true);
        return true;
      },
      onLeave: (_) => setState(() => _dragOver = false),
      onAcceptWithDetails: (DragTargetDetails<Task> details) {
        setState(() => _dragOver = false);
        ref
            .read(taskActionsProvider)
            .update(
              l10n: context.l10n,
              task: details.data.copyWith(dueDate: widget.day),
              silent: true,
            );
      },
      builder: (BuildContext context, _, _) => AnimatedContainer(
        duration: context.motion(Motion.fast),
        color: _dragOver ? colors.dragTint : Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.hairline)),
              ),
              child: Column(
                children: <Widget>[
                  Text(
                    Dates.weekdayShort(widget.day).toUpperCase(),
                    style: context.textStyles.labelSmall?.copyWith(
                      color: colors.inkFaint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isToday ? colors.brand : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${widget.day.day}',
                      style: AppTypography.numeric.copyWith(
                        fontSize: 13,
                        color: isToday ? Colors.white : colors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(Spacing.sm - 2),
                children: <Widget>[
                  for (final Task task in widget.tasks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: DraggableTaskChip(
                        task: task,
                        dense: false,
                        onTap: () => widget.onOpenTask(task),
                      ),
                    ),
                  InkWell(
                    onTap: widget.onCreate,
                    borderRadius: Radii.brXs,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                      child: Icon(
                        AppIcons.add,
                        size: 14,
                        color: colors.inkFaint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Day view: a single agenda with full task rows.
class DayAgenda extends ConsumerWidget {
  const DayAgenda({
    required this.day,
    required this.tasks,
    required this.onOpenTask,
    required this.onCreate,
    super.key,
  });

  final DateTime day;
  final List<Task> tasks;
  final ValueChanged<Task> onOpenTask;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final Map<String, User> members = ref.watch(membersByIdProvider);
    final Map<String, Project> projects = ref.watch(projectsByIdProvider);

    if (tasks.isEmpty) {
      return AppEmptyState(
        icon: AppIcons.calendar,
        title: context.l10n.emptyCalendarTitle,
        message: context.l10n.emptyCalendarBody,
        actionLabel: context.l10n.actionCreateTask,
        onAction: onCreate,
        compact: true,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(Spacing.lg),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
      itemBuilder: (BuildContext context, int index) {
        final Task task = tasks[index];
        final Project? project = task.projectId == null
            ? null
            : projects[task.projectId!];
        return Entrance(
          index: index,
          child: Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: Radii.brMd,
              border: Border.all(color: colors.hairline),
              boxShadow: Shadows.xs(colors.isDark),
            ),
            child: Row(
              children: <Widget>[
                CompletionCheckbox(
                  isCompleted: task.isDone,
                  size: 18,
                  onChanged: (bool value) => ref
                      .read(taskActionsProvider)
                      .setCompleted(
                        l10n: context.l10n,
                        task: task,
                        completed: value,
                      ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onOpenTask(task),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          task.title,
                          style: context.textStyles.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: task.isDone ? colors.inkFaint : colors.ink,
                            decoration: task.isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (project != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${project.iconEmoji}  ${project.name}',
                              style: context.textStyles.labelSmall?.copyWith(
                                color: colors.inkFaint,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                PriorityPill(priority: task.priority, showLabel: false),
                const SizedBox(width: Spacing.md),
                AppAvatar(
                  user: task.assigneeId == null
                      ? null
                      : members[task.assigneeId!],
                  size: 24,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
