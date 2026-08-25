import 'dart:math' as math;

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
import 'package:kairo/core/widgets/app_states.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/entities/user.dart';

/// Horizontal resolution of the timeline.
enum TimelineZoom {
  days(38, 1),
  weeks(16, 7),
  months(6, 30);

  const TimelineZoom(this.dayWidth, this.tickDays);

  /// Pixels per calendar day.
  final double dayWidth;

  /// How often a labelled gridline is drawn.
  final int tickDays;
}

/// A Gantt-style roadmap.
///
/// Two synchronised panes: a fixed name column on the left and a scrolling time
/// grid on the right. Bars are positioned from `startDate`/`dueDate`, fill
/// according to subtask progress, and dependency edges are drawn as elbow
/// connectors between them — the shape a plan actually has.
class TimelineView extends ConsumerStatefulWidget {
  const TimelineView({
    required this.tasks,
    required this.onOpenTask,
    this.milestones = const <Milestone>[],
    this.isLoading = false,
    super.key,
  });

  final List<Task> tasks;
  final ValueChanged<Task> onOpenTask;
  final List<Milestone> milestones;
  final bool isLoading;

  @override
  ConsumerState<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends ConsumerState<TimelineView> {
  final ScrollController _horizontal = ScrollController();
  final ScrollController _rowsVertical = ScrollController();
  final ScrollController _namesVertical = ScrollController();

  TimelineZoom _zoom = TimelineZoom.weeks;
  String? _hoveredTaskId;
  bool _syncing = false;

  static const double _rowHeight = 42;
  static const double _headerHeight = 52;

  /// Width of the pinned task-name column.
  ///
  /// 232px is right on a desktop and absurd on a 320px phone, where it would
  /// leave 88px of actual timeline. The names stay pinned at every size — that
  /// is what makes the chart readable while scrolling — but they take a share
  /// of the screen rather than a fixed slab of it.
  static const double _nameColumnWideWidth = 232;
  static const double _nameColumnCompactWidth = 124;

  @override
  void initState() {
    super.initState();
    // Two vertical scrollables, one gesture: mirror offsets both ways.
    _rowsVertical.addListener(() => _mirror(_rowsVertical, _namesVertical));
    _namesVertical.addListener(() => _mirror(_namesVertical, _rowsVertical));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  void _mirror(ScrollController source, ScrollController target) {
    if (_syncing || !target.hasClients || !source.hasClients) return;
    if ((target.offset - source.offset).abs() < 0.5) return;
    _syncing = true;
    target.jumpTo(source.offset.clamp(0, target.position.maxScrollExtent));
    _syncing = false;
  }

  @override
  void dispose() {
    _horizontal.dispose();
    _rowsVertical.dispose();
    _namesVertical.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    if (!_horizontal.hasClients) return;
    final _TimelineRange? range = _range();
    if (range == null) return;
    final double offset =
        Dates.daysBetween(range.start, Dates.today()) * _zoom.dayWidth - 180;
    _horizontal.jumpTo(offset.clamp(0, _horizontal.position.maxScrollExtent));
  }

  /// Only tasks with at least one date can be placed on a timeline.
  List<Task> get _dated =>
      widget.tasks
          .where((Task t) => t.startDate != null || t.dueDate != null)
          .toList(growable: false)
        ..sort((Task a, Task b) {
          final DateTime aStart = a.startDate ?? a.dueDate!;
          final DateTime bStart = b.startDate ?? b.dueDate!;
          return aStart.compareTo(bStart);
        });

  _TimelineRange? _range() {
    final List<Task> tasks = _dated;
    if (tasks.isEmpty) return null;
    DateTime min = tasks.first.startDate ?? tasks.first.dueDate!;
    DateTime max = min;
    for (final Task task in tasks) {
      final DateTime start = task.startDate ?? task.dueDate!;
      final DateTime end = task.dueDate ?? task.startDate!;
      if (start.isBefore(min)) min = start;
      if (end.isAfter(max)) max = end;
    }
    for (final Milestone milestone in widget.milestones) {
      if (milestone.date.isBefore(min)) min = milestone.date;
      if (milestone.date.isAfter(max)) max = milestone.date;
    }
    final DateTime today = Dates.today();
    if (today.isBefore(min)) min = today;
    if (today.isAfter(max)) max = today;
    return _TimelineRange(
      start: Dates.dayOf(min).subtract(const Duration(days: 4)),
      end: Dates.dayOf(max).add(const Duration(days: 6)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final List<Task> tasks = _dated;
    final _TimelineRange? range = _range();

    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (tasks.isEmpty || range == null) {
      return AppEmptyState(
        icon: AppIcons.timeline,
        title: context.l10n.emptyTimelineTitle,
        message: context.l10n.emptyTimelineBody,
      );
    }

    final double contentWidth = range.days * _zoom.dayWidth;

    return Column(
      children: <Widget>[
        _Toolbar(
          zoom: _zoom,
          onZoomChanged: (TimelineZoom zoom) {
            setState(() => _zoom = zoom);
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _scrollToToday(),
            );
          },
          onToday: _scrollToToday,
          taskCount: tasks.length,
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: context.breakpoint.isCompact
                    ? _nameColumnCompactWidth
                    : _nameColumnWideWidth,
                child: _NameColumn(
                  tasks: tasks,
                  controller: _namesVertical,
                  rowHeight: _rowHeight,
                  headerHeight: _headerHeight,
                  hoveredId: _hoveredTaskId,
                  onHover: (String? id) => setState(() => _hoveredTaskId = id),
                  onOpen: widget.onOpenTask,
                ),
              ),
              Expanded(
                child: Scrollbar(
                  controller: _horizontal,
                  child: SingleChildScrollView(
                    controller: _horizontal,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: math.max(contentWidth, 600),
                      child: Column(
                        children: <Widget>[
                          SizedBox(
                            height: _headerHeight,
                            child: _TimelineHeader(
                              range: range,
                              zoom: _zoom,
                              milestones: widget.milestones,
                            ),
                          ),
                          Expanded(
                            child: Stack(
                              children: <Widget>[
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _GridPainter(
                                      range: range,
                                      zoom: _zoom,
                                      gridColor: colors.chartGrid,
                                      todayColor: colors.brand,
                                      weekendColor: colors.surfaceSunken,
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: SingleChildScrollView(
                                    controller: _rowsVertical,
                                    child: SizedBox(
                                      height: tasks.length * _rowHeight + 24,
                                      child: Stack(
                                        children: <Widget>[
                                          Positioned.fill(
                                            child: CustomPaint(
                                              painter: _DependencyPainter(
                                                tasks: tasks,
                                                range: range,
                                                zoom: _zoom,
                                                rowHeight: _rowHeight,
                                                color: colors.violet,
                                              ),
                                            ),
                                          ),
                                          for (int i = 0; i < tasks.length; i++)
                                            _TaskBar(
                                              task: tasks[i],
                                              range: range,
                                              zoom: _zoom,
                                              top: i * _rowHeight + 7,
                                              height: _rowHeight - 16,
                                              hovered:
                                                  _hoveredTaskId == tasks[i].id,
                                              onHover: (bool hovered) =>
                                                  setState(
                                                    () =>
                                                        _hoveredTaskId = hovered
                                                        ? tasks[i].id
                                                        : null,
                                                  ),
                                              onTap: () =>
                                                  widget.onOpenTask(tasks[i]),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineRange {
  const _TimelineRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  int get days => Dates.daysBetween(start, end) + 1;

  double offsetFor(DateTime date, double dayWidth) =>
      Dates.daysBetween(start, date) * dayWidth;
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.zoom,
    required this.onZoomChanged,
    required this.onToday,
    required this.taskCount,
  });

  final TimelineZoom zoom;
  final ValueChanged<TimelineZoom> onZoomChanged;
  final VoidCallback onToday;
  final int taskCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool compact = context.breakpoint.isCompact;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? Spacing.md : Spacing.lg,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.hairline)),
      ),
      child: Row(
        children: <Widget>[
          // The task count is the least important thing in this bar, so it is
          // the first to give way — and on a phone it goes entirely, because
          // the zoom control and the today button both need their labels.
          if (!compact) ...<Widget>[
            Flexible(
              child: Text(
                context.l10n.tasksCount(taskCount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.labelMedium?.copyWith(
                  color: colors.inkMuted,
                ),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onToday,
              icon: const Icon(AppIcons.dueDate, size: 14),
              label: Text(context.l10n.calendarToday),
            ),
          ] else
            IconButton(
              onPressed: onToday,
              icon: const Icon(AppIcons.dueDate, size: 16),
              tooltip: context.l10n.calendarToday,
              visualDensity: VisualDensity.compact,
            ),
          const SizedBox(width: Spacing.sm),
          if (compact) const Spacer(),
          Flexible(
            child: SegmentedButton<TimelineZoom>(
              segments: <ButtonSegment<TimelineZoom>>[
                ButtonSegment<TimelineZoom>(
                  value: TimelineZoom.days,
                  label: Text(context.l10n.timelineZoomDays),
                ),
                ButtonSegment<TimelineZoom>(
                  value: TimelineZoom.weeks,
                  label: Text(context.l10n.timelineZoomWeeks),
                ),
                ButtonSegment<TimelineZoom>(
                  value: TimelineZoom.months,
                  label: Text(context.l10n.timelineZoomMonths),
                ),
              ],
              selected: <TimelineZoom>{zoom},
              showSelectedIcon: false,
              onSelectionChanged: (Set<TimelineZoom> value) =>
                  onZoomChanged(value.first),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameColumn extends ConsumerWidget {
  const _NameColumn({
    required this.tasks,
    required this.controller,
    required this.rowHeight,
    required this.headerHeight,
    required this.hoveredId,
    required this.onHover,
    required this.onOpen,
  });

  final List<Task> tasks;
  final ScrollController controller;
  final double rowHeight;
  final double headerHeight;
  final String? hoveredId;
  final ValueChanged<String?> onHover;
  final ValueChanged<Task> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final Map<String, Project> projects = ref.watch(projectsByIdProvider);
    final Map<String, User> members = ref.watch(membersByIdProvider);

    return Container(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: colors.hairline)),
      ),
      child: Column(
        children: <Widget>[
          Container(
            height: headerHeight,
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.hairline)),
            ),
            child: Text(
              context.l10n.fieldTitle.toUpperCase(),
              style: context.textStyles.labelSmall?.copyWith(
                color: colors.inkFaint,
                letterSpacing: 0.7,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: tasks.length,
              itemExtent: rowHeight,
              itemBuilder: (BuildContext context, int index) {
                final Task task = tasks[index];
                final Project? project = task.projectId == null
                    ? null
                    : projects[task.projectId!];
                return MouseRegion(
                  onEnter: (_) => onHover(task.id),
                  onExit: (_) => onHover(null),
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => onOpen(task),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      color: hoveredId == task.id
                          ? colors.surfaceSunken
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.md,
                      ),
                      child: Row(
                        children: <Widget>[
                          if (project != null) ...<Widget>[
                            Container(
                              width: 3,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Color(project.colorValue),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: Spacing.sm),
                          ],
                          Expanded(
                            child: Text(
                              task.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.labelMedium?.copyWith(
                                color: task.isDone
                                    ? colors.inkFaint
                                    : colors.inkSoft,
                                decoration: task.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          AppAvatar(
                            user: task.assigneeId == null
                                ? null
                                : members[task.assigneeId!],
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineHeader extends StatelessWidget {
  const _TimelineHeader({
    required this.range,
    required this.zoom,
    required this.milestones,
  });

  final _TimelineRange range;
  final TimelineZoom zoom;
  final List<Milestone> milestones;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.hairline)),
      ),
      child: Stack(
        children: <Widget>[
          for (int i = 0; i < range.days; i += zoom.tickDays)
            Positioned(
              left: i * zoom.dayWidth,
              top: 6,
              child: _Tick(
                date: range.start.add(Duration(days: i)),
                zoom: zoom,
              ),
            ),
          for (final Milestone milestone in milestones)
            Positioned(
              left: range.offsetFor(milestone.date, zoom.dayWidth) - 7,
              bottom: 4,
              child: _MilestoneMarker(milestone: milestone),
            ),
        ],
      ),
    );
  }
}

class _Tick extends StatelessWidget {
  const _Tick({required this.date, required this.zoom});

  final DateTime date;
  final TimelineZoom zoom;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool isToday = Dates.isToday(date);
    final String label = switch (zoom) {
      TimelineZoom.days => '${Dates.weekdayShort(date)[0]}${date.day}',
      TimelineZoom.weeks => Dates.dayMonth(date),
      TimelineZoom.months => Dates.monthShort(date),
    };

    return SizedBox(
      width: zoom.dayWidth * zoom.tickDays,
      child: Text(
        label,
        style: AppTypography.numeric.copyWith(
          fontSize: 10,
          fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
          color: isToday ? colors.brand : colors.inkFaint,
        ),
      ),
    );
  }
}

class _MilestoneMarker extends StatelessWidget {
  const _MilestoneMarker({required this.milestone});

  final Milestone milestone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color color = milestone.isReached ? colors.success : colors.violet;
    return Tooltip(
      message: '${milestone.title} · ${Dates.dayMonth(milestone.date)}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskBar extends StatelessWidget {
  const _TaskBar({
    required this.task,
    required this.range,
    required this.zoom,
    required this.top,
    required this.height,
    required this.hovered,
    required this.onHover,
    required this.onTap,
  });

  final Task task;
  final _TimelineRange range;
  final TimelineZoom zoom;
  final double top;
  final double height;
  final bool hovered;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final DateTime start = task.startDate ?? task.dueDate!;
    final DateTime end = task.dueDate ?? task.startDate!;
    final double left = range.offsetFor(start, zoom.dayWidth);
    final double width = math.max(
      (Dates.daysBetween(start, end) + 1) * zoom.dayWidth,
      zoom.dayWidth * 0.9,
    );

    final Color accent = task.isDone
        ? colors.success
        : (task.isOverdue ? colors.danger : task.priority.color(colors));
    final double progress = task.subtaskProgress;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        child: Tooltip(
          message:
              '${task.title}\n${Dates.dayMonth(start)} → ${Dates.dayMonth(end)}',
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: context.motion(Motion.fast),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: colors.isDark ? 0.24 : 0.16),
                borderRadius: Radii.brSm,
                border: Border.all(
                  color: accent.withValues(alpha: hovered ? 0.9 : 0.45),
                  width: hovered ? 1.5 : 1,
                ),
                boxShadow: hovered ? Shadows.sm(colors.isDark) : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: <Widget>[
                  if (progress > 0)
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0, 1),
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.42),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.labelSmall?.copyWith(
                          fontSize: 10.5,
                          color: colors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({
    required this.range,
    required this.zoom,
    required this.gridColor,
    required this.todayColor,
    required this.weekendColor,
  });

  final _TimelineRange range;
  final TimelineZoom zoom;
  final Color gridColor;
  final Color todayColor;
  final Color weekendColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint line = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    // Weekend shading only reads at day resolution.
    if (zoom == TimelineZoom.days) {
      final Paint weekend = Paint()..color = weekendColor;
      for (int i = 0; i < range.days; i++) {
        final DateTime day = range.start.add(Duration(days: i));
        if (day.weekday == DateTime.saturday ||
            day.weekday == DateTime.sunday) {
          canvas.drawRect(
            Rect.fromLTWH(i * zoom.dayWidth, 0, zoom.dayWidth, size.height),
            weekend,
          );
        }
      }
    }

    for (int i = 0; i < range.days; i += zoom.tickDays) {
      final double x = i * zoom.dayWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }

    final double todayX =
        Dates.daysBetween(range.start, Dates.today()) * zoom.dayWidth;
    canvas.drawLine(
      Offset(todayX, 0),
      Offset(todayX, size.height),
      Paint()
        ..color = todayColor.withValues(alpha: 0.7)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.zoom != zoom || old.range.start != range.start;
}

/// Draws elbow connectors from each blocking task's bar to the bar it blocks.
class _DependencyPainter extends CustomPainter {
  const _DependencyPainter({
    required this.tasks,
    required this.range,
    required this.zoom,
    required this.rowHeight,
    required this.color,
  });

  final List<Task> tasks;
  final _TimelineRange range;
  final TimelineZoom zoom;
  final double rowHeight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Map<String, int> rowOf = <String, int>{
      for (int i = 0; i < tasks.length; i++) tasks[i].id: i,
    };

    final Paint stroke = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (final Task task in tasks) {
      final int? targetRow = rowOf[task.id];
      if (targetRow == null) continue;

      for (final String blockerId in task.dependsOnIds) {
        final int? sourceRow = rowOf[blockerId];
        if (sourceRow == null) continue;
        final Task blocker = tasks[sourceRow];

        final DateTime blockerEnd = blocker.dueDate ?? blocker.startDate!;
        final DateTime taskStart = task.startDate ?? task.dueDate!;

        final double x1 =
            range.offsetFor(blockerEnd, zoom.dayWidth) + zoom.dayWidth;
        final double y1 = sourceRow * rowHeight + rowHeight / 2;
        final double x2 = range.offsetFor(taskStart, zoom.dayWidth);
        final double y2 = targetRow * rowHeight + rowHeight / 2;

        final double midX = math.max(x1 + 10, x2 - 10);
        final Path path = Path()
          ..moveTo(x1, y1)
          ..lineTo(midX, y1)
          ..lineTo(midX, y2)
          ..lineTo(x2, y2);
        canvas.drawPath(path, stroke);

        // Arrowhead at the dependent task.
        final Path head = Path()
          ..moveTo(x2, y2)
          ..lineTo(x2 - 5, y2 - 3.5)
          ..lineTo(x2 - 5, y2 + 3.5)
          ..close();
        canvas.drawPath(head, Paint()..color = color.withValues(alpha: 0.75));
      }
    }
  }

  @override
  bool shouldRepaint(_DependencyPainter old) =>
      old.tasks != tasks || old.zoom != zoom;
}
