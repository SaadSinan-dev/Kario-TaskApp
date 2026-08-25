import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/utils/date_utils.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/preferences.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/features/calendar/presentation/widgets/calendar_views.dart';
import 'package:kairo/features/shell/presentation/app_shell.dart';
import 'package:kairo/features/tasks/application/task_view_controller.dart';
import 'package:kairo/features/tasks/presentation/task_composer.dart';
import 'package:kairo/features/tasks/presentation/widgets/task_board_view.dart';
import 'package:kairo/features/tasks/presentation/widgets/task_filter_bar.dart';
import 'package:kairo/features/tasks/presentation/widgets/task_list_view.dart';
import 'package:kairo/features/tasks/presentation/widgets/timeline_bridge.dart';

/// The main task workspace.
///
/// One screen, four renderings of the same filtered query. Switching views
/// keeps the filters, the grouping and the selection — they are properties of
/// what you are looking at, not of how it is drawn.
class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Task>> raw = ref.watch(tasksProvider);
    final List<Task> tasks = ref.watch(filteredTasksProvider);
    final TaskViewType view = ref.watch(taskViewTypeProvider);

    return ShellPage(
      title: context.l10n.tasksTitle,
      subtitle: context.l10n.tasksCount(tasks.length),
      padded: false,
      actions: const <Widget>[CreateTaskAction()],
      toolbar: const TaskFilterBar(),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: switch (view) {
              TaskViewType.list => TaskListView(
                tasks: tasks,
                isLoading: raw.isLoading,
                onOpenTask: (Task task) => openTaskDetail(context, task.id),
                onCreate: () => openTaskComposer(context, ref),
              ),
              TaskViewType.board => TaskBoardView(
                tasks: tasks,
                isLoading: raw.isLoading,
                onOpenTask: (Task task) => openTaskDetail(context, task.id),
              ),
              TaskViewType.calendar => _CalendarPane(tasks: tasks),
              TaskViewType.timeline => TimelinePane(tasks: tasks),
            },
          ),
          const Positioned.fill(child: BulkActionBar()),
        ],
      ),
    );
  }
}

/// The calendar rendering of the task query. The dedicated Calendar screen adds
/// month/week/day switching; here it is a fixed month grid focused on the
/// current filter.
class _CalendarPane extends ConsumerStatefulWidget {
  const _CalendarPane({required this.tasks});

  final List<Task> tasks;

  @override
  ConsumerState<_CalendarPane> createState() => _CalendarPaneState();
}

class _CalendarPaneState extends ConsumerState<_CalendarPane> {
  DateTime _month = Dates.startOfMonth(DateTime.now());
  DateTime _selected = Dates.today();

  @override
  Widget build(BuildContext context) {
    final int weekStartsOn = ref.watch(
      preferencesProvider.select((UserPreferences p) => p.weekStartsOn),
    );

    return Column(
      children: <Widget>[
        _MonthPager(
          month: _month,
          onPrevious: () =>
              setState(() => _month = Dates.addMonths(_month, -1)),
          onNext: () => setState(() => _month = Dates.addMonths(_month, 1)),
          onToday: () => setState(() {
            _month = Dates.startOfMonth(DateTime.now());
            _selected = Dates.today();
          }),
        ),
        Expanded(
          child: MonthGrid(
            month: _month,
            tasks: widget.tasks,
            selectedDay: _selected,
            weekStartsOn: weekStartsOn,
            onSelectDay: (DateTime day) => setState(() => _selected = day),
            onOpenTask: (Task task) => openTaskDetail(context, task.id),
            onCreateOn: (DateTime day) =>
                openTaskComposer(context, ref, dueDate: day),
          ),
        ),
      ],
    );
  }
}

class _MonthPager extends StatelessWidget {
  const _MonthPager({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final bool compact = context.breakpoint.isCompact;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? Spacing.md : Spacing.lg,
        vertical: Spacing.sm,
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(AppIcons.chevronLeft, size: 17),
            tooltip: 'Previous month',
            visualDensity: compact ? VisualDensity.compact : null,
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(AppIcons.chevronRight, size: 17),
            tooltip: 'Next month',
            visualDensity: compact ? VisualDensity.compact : null,
          ),
          const SizedBox(width: Spacing.sm),
          // The month label is the one elastic element here: the buttons need
          // their touch targets, so a long month name is what gives way.
          Flexible(
            child: Text(
              Dates.monthYear(month),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.titleMedium,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onToday,
            child: Text(context.l10n.calendarToday),
          ),
        ],
      ),
    );
  }
}
