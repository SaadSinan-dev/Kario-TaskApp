import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/features/shell/presentation/app_shell.dart';
import 'package:kairo/features/tasks/application/task_view_controller.dart';
import 'package:kairo/features/tasks/presentation/widgets/task_filter_bar.dart';
import 'package:kairo/features/tasks/presentation/widgets/timeline_bridge.dart';

/// The workspace roadmap.
///
/// Shares the task filter bar with every other view, minus the view switcher —
/// this route *is* the timeline, so offering to switch away from it here would
/// be a dead end back to `/tasks`.
class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Task> tasks = ref.watch(filteredTasksProvider);
    final int dated = tasks
        .where((Task t) => t.startDate != null || t.dueDate != null)
        .length;

    return ShellPage(
      title: context.l10n.timelineTitle,
      subtitle: '$dated of ${tasks.length} tasks have dates',
      padded: false,
      actions: const <Widget>[CreateTaskAction()],
      toolbar: const TaskFilterBar(
        showViewSwitch: false,
        availableViews: <TaskViewType>[],
      ),
      child: TimelinePane(tasks: tasks),
    );
  }
}
