import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/features/shell/presentation/app_shell.dart';
import 'package:kairo/features/timeline/presentation/widgets/timeline_view.dart';

/// Adapts the timeline widget to a task list that may span several projects.
///
/// Milestones are project-scoped, so a cross-project timeline shows the union
/// of the milestones belonging to the projects actually represented in the
/// current task set — not every milestone in the workspace, which would be
/// noise.
class TimelinePane extends ConsumerWidget {
  const TimelinePane({required this.tasks, this.projectId, super.key});

  final List<Task> tasks;
  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, Project> projects = ref.watch(projectsByIdProvider);

    final Set<String> represented = <String>{
      for (final Task task in tasks)
        if (task.projectId != null) task.projectId!,
    };

    final List<Milestone> milestones = <Milestone>[
      for (final String id
          in projectId == null ? represented : <String>{projectId!})
        ...?projects[id]?.milestones,
    ]..sort((Milestone a, Milestone b) => a.date.compareTo(b.date));

    return TimelineView(
      tasks: tasks,
      milestones: milestones,
      onOpenTask: (Task task) => openTaskDetail(context, task.id),
    );
  }
}
