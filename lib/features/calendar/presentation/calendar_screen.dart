import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/responsive/breakpoints.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/utils/date_utils.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/core/widgets/app_segmented.dart';
import 'package:kairo/domain/entities/preferences.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/features/calendar/presentation/widgets/calendar_views.dart';
import 'package:kairo/features/shell/presentation/app_shell.dart';
import 'package:kairo/features/tasks/application/task_view_controller.dart';
import 'package:kairo/features/tasks/presentation/task_composer.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';

/// The calendar, with month, week and day layouts.
///
/// The header adapts its label to the mode — a month name, a week range, or a
/// full date — so the paging controls always say what they will change.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarMode _mode = CalendarMode.month;
  DateTime _anchor = Dates.today();
  DateTime _selected = Dates.today();

  void _step(int direction) {
    setState(() {
      _anchor = switch (_mode) {
        CalendarMode.month => Dates.addMonths(_anchor, direction),
        CalendarMode.week => _anchor.add(Duration(days: 7 * direction)),
        CalendarMode.day => _anchor.add(Duration(days: direction)),
      };
      if (_mode != CalendarMode.month) _selected = _anchor;
    });
  }

  String _title(int weekStartsOn) {
    switch (_mode) {
      case CalendarMode.month:
        return Dates.monthYear(_anchor);
      case CalendarMode.week:
        final DateTime start = Dates.startOfWeek(
          _anchor,
          weekStartsOn: weekStartsOn,
        );
        final DateTime end = Dates.endOfWeek(
          _anchor,
          weekStartsOn: weekStartsOn,
        );
        return '${Dates.dayMonth(start)} – ${Dates.dayMonth(end)}';
      case CalendarMode.day:
        return '${Dates.weekdayLong(_anchor)}, ${Dates.dayMonthYear(_anchor)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l10n = context.l10n;
    final int weekStartsOn = ref.watch(
      preferencesProvider.select((UserPreferences p) => p.weekStartsOn),
    );
    final List<Task> tasks = ref.watch(filteredTasksProvider);

    final List<Task> dayTasks = tasks
        .where((Task t) => Dates.isSameDay(t.dueDate, _selected))
        .toList(growable: false);

    return ShellPage(
      title: l10n.navCalendar,
      subtitle: _title(weekStartsOn),
      padded: false,
      actions: const <Widget>[CreateTaskAction()],
      toolbar: _CalendarToolbar(
        mode: _mode,
        onModeChanged: (CalendarMode mode) => setState(() => _mode = mode),
        onPrevious: () => _step(-1),
        onNext: () => _step(1),
        onToday: () => setState(() {
          _anchor = Dates.today();
          _selected = Dates.today();
        }),
      ),
      child: AnimatedSwitcher(
        duration: context.motion(Motion.base),
        child: switch (_mode) {
          CalendarMode.month => _MonthLayout(
            key: const ValueKey<String>('month'),
            grid: MonthGrid(
              month: _anchor,
              tasks: tasks,
              selectedDay: _selected,
              weekStartsOn: weekStartsOn,
              onSelectDay: (DateTime day) => setState(() => _selected = day),
              onOpenTask: (Task task) => openTaskDetail(context, task.id),
              onCreateOn: (DateTime day) =>
                  openTaskComposer(context, ref, dueDate: day),
            ),
            rail: _DayRail(
              day: _selected,
              tasks: dayTasks,
              onCreate: () =>
                  openTaskComposer(context, ref, dueDate: _selected),
            ),
          ),
          CalendarMode.week => WeekView(
            key: const ValueKey<String>('week'),
            anchor: _anchor,
            tasks: tasks,
            weekStartsOn: weekStartsOn,
            onOpenTask: (Task task) => openTaskDetail(context, task.id),
            onCreateOn: (DateTime day) =>
                openTaskComposer(context, ref, dueDate: day),
          ),
          CalendarMode.day => DayAgenda(
            key: const ValueKey<String>('day'),
            day: _anchor,
            tasks: tasks
                .where((Task t) => Dates.isSameDay(t.dueDate, _anchor))
                .toList(growable: false),
            onOpenTask: (Task task) => openTaskDetail(context, task.id),
            onCreate: () => openTaskComposer(context, ref, dueDate: _anchor),
          ),
        },
      ),
    );
  }
}

/// Arranges the month grid and the day agenda for the space available.
///
/// The two are the same pair of panels at every size; only their axis changes.
/// On a phone the grid cannot show task titles at all, so the agenda stops
/// being an optional side rail and becomes the half of the screen that answers
/// "what is due" — stacked beneath the grid rather than squeezed beside it.
class _MonthLayout extends StatelessWidget {
  const _MonthLayout({required this.grid, required this.rail, super.key});

  final Widget grid;
  final Widget rail;

  /// Share of the height the grid keeps on phones. Six rows need enough room to
  /// stay tappable; the rest goes to the agenda.
  static const int _gridFlex = 5;
  static const int _agendaFlex = 4;

  @override
  Widget build(BuildContext context) {
    final ScreenSize size = context.breakpoint;

    if (size.isCompact) {
      return Column(
        children: <Widget>[
          Expanded(flex: _gridFlex, child: grid),
          Expanded(flex: _agendaFlex, child: rail),
        ],
      );
    }

    return Row(
      children: <Widget>[
        Expanded(child: grid),
        // A day rail beside the grid on wide screens: the month answers
        // "when", the rail answers "what".
        if (size.hasDetailPanel) SizedBox(width: 320, child: rail),
      ],
    );
  }
}

class _CalendarToolbar extends StatelessWidget {
  const _CalendarToolbar({
    required this.mode,
    required this.onModeChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final CalendarMode mode;
  final ValueChanged<CalendarMode> onModeChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final AppL10n l10n = context.l10n;

    final bool compact = context.breakpoint.isCompact;

    final Widget navigation = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppIconButton(
          icon: AppIcons.chevronLeft,
          tooltip: 'Previous',
          onPressed: onPrevious,
        ),
        AppIconButton(
          icon: AppIcons.chevronRight,
          tooltip: 'Next',
          onPressed: onNext,
        ),
        const SizedBox(width: Spacing.sm),
        AppButton(
          label: l10n.calendarToday,
          size: AppButtonSize.small,
          onPressed: onToday,
        ),
      ],
    );

    final Widget modes = AppSegmentedControl<CalendarMode>(
      value: mode,
      dense: true,
      // Expanding is what lets the three modes share a full-width row on a
      // phone instead of each taking its natural width and spilling.
      expand: compact,
      options: <SegmentOption<CalendarMode>>[
        SegmentOption<CalendarMode>(
          value: CalendarMode.month,
          label: l10n.calendarMonth,
        ),
        SegmentOption<CalendarMode>(
          value: CalendarMode.week,
          label: l10n.calendarWeek,
        ),
        SegmentOption<CalendarMode>(
          value: CalendarMode.day,
          label: l10n.calendarDay,
        ),
      ],
      onChanged: onModeChanged,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? Spacing.md : Spacing.lg,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.hairline)),
      ),
      // Two controls that each need their natural width cannot share one row
      // on a 320px screen, so below the compact breakpoint they take a line
      // each rather than being crushed together.
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                navigation,
                const SizedBox(height: Spacing.sm),
                modes,
              ],
            )
          : Row(
              children: <Widget>[
                navigation,
                const Spacer(),
                Flexible(child: modes),
              ],
            ),
    );
  }
}

class _DayRail extends StatelessWidget {
  const _DayRail({
    required this.day,
    required this.tasks,
    required this.onCreate,
  });

  final DateTime day;
  final List<Task> tasks;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: BorderDirectional(start: BorderSide(color: colors.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(Spacing.lg),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.hairline)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        Dates.weekdayLong(day),
                        style: context.textStyles.titleMedium,
                      ),
                      Text(
                        Dates.dayMonthYear(day),
                        style: context.textStyles.bodySmall?.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                AppIconButton(
                  icon: AppIcons.add,
                  tooltip: context.l10n.actionCreateTask,
                  onPressed: onCreate,
                ),
              ],
            ),
          ),
          Expanded(
            child: DayAgenda(
              day: day,
              tasks: tasks,
              onOpenTask: (Task task) => openTaskDetail(context, task.id),
              onCreate: onCreate,
            ),
          ),
        ],
      ),
    );
  }
}
