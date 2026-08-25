import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/presentation/enum_presentation.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/utils/date_utils.dart';
import 'package:kairo/core/widgets/app_skeleton.dart';
import 'package:kairo/domain/entities/collaboration.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/domain/entities/workspace.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';

/// The history of a task, drawn as a connected timeline.
///
/// Each entry names the actor and the change in one line — "Priya changed
/// priority · High → Urgent" — which is what makes a feed scannable rather
/// than a wall of "task updated".
class ActivityFeed extends ConsumerWidget {
  const ActivityFeed({
    required this.activities,
    this.isLoading = false,
    this.showTaskTitles = false,
    this.limit,
    super.key,
  });

  final List<Activity> activities;
  final bool isLoading;

  /// Workspace-level feeds name the task; a task's own feed does not.
  final bool showTaskTitles;

  final int? limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return SkeletonList(
        count: 4,
        separator: Spacing.md,
        itemBuilder: (BuildContext context) => const Row(
          children: <Widget>[
            Skeleton.circle(size: 24),
            SizedBox(width: Spacing.md),
            Expanded(child: Skeleton(height: 11)),
          ],
        ),
      );
    }

    if (activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
        child: Text(
          'Nothing has happened here yet.',
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.inkFaint,
          ),
        ),
      );
    }

    final Map<String, User> members = ref.watch(membersByIdProvider);
    final Map<String, Project> projects = ref.watch(projectsByIdProvider);
    final Map<String, Label> labels = ref.watch(labelsByIdProvider);
    final List<Task> tasks = ref.watch(tasksProvider).value ?? const <Task>[];
    final List<Activity> visible = limit == null
        ? activities
        : activities.take(limit!).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < visible.length; i++)
          Entrance(
            index: i,
            offset: 6,
            child: _ActivityRow(
              activity: visible[i],
              isLast: i == visible.length - 1,
              members: members,
              projects: projects,
              labels: labels,
              tasks: tasks,
              showTaskTitle: showTaskTitles,
            ),
          ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.activity,
    required this.isLast,
    required this.members,
    required this.projects,
    required this.labels,
    required this.tasks,
    required this.showTaskTitle,
  });

  final Activity activity;
  final bool isLast;
  final Map<String, User> members;
  final Map<String, Project> projects;
  final Map<String, Label> labels;
  final List<Task> tasks;
  final bool showTaskTitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color accent = activity.type.color(colors);
    final User? actor = members[activity.actorId];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Rail: icon plus the connector to the next entry.
          Column(
            children: <Widget>[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: colors.isDark ? 0.20 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(activity.type.icon, size: 12, color: accent),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: colors.hairline,
                  ),
                ),
            ],
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        TextSpan(
                          text: actor?.firstName ?? 'Someone',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: colors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: ' ${_describe(context)}',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                        if (showTaskTitle && activity.taskId != null)
                          TextSpan(
                            text: ' · ${_taskTitle(activity.taskId!)}',
                            style: context.textStyles.bodySmall?.copyWith(
                              color: colors.inkSoft,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Dates.relative(activity.createdAt, context.l10n),
                    style: context.textStyles.labelSmall?.copyWith(
                      color: colors.inkFaint,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _taskTitle(String taskId) =>
      tasks.where((Task t) => t.id == taskId).firstOrNull?.title ?? '';

  String _describe(BuildContext context) {
    final AppL10n l10n = context.l10n;

    String statusName(String? raw) => raw == null
        ? '—'
        : TaskStatus.values
              .firstWhere(
                (TaskStatus s) => s.name == raw,
                orElse: () => TaskStatus.todo,
              )
              .label(l10n);

    String priorityName(String? raw) => raw == null
        ? '—'
        : TaskPriority.values
              .firstWhere(
                (TaskPriority p) => p.name == raw,
                orElse: () => TaskPriority.medium,
              )
              .label(l10n);

    String labelName(String? raw) =>
        raw == null ? '—' : labels[raw]?.name ?? raw;

    String dateName(String? raw) {
      if (raw == null) return l10n.timeNoDate;
      final DateTime? parsed = DateTime.tryParse(raw);
      return parsed == null ? raw : Dates.dueLabel(parsed, l10n);
    }

    return switch (activity.type) {
      ActivityType.taskCreated => 'created this task',
      ActivityType.taskCompleted => 'completed it',
      ActivityType.taskReopened => 'reopened it',
      ActivityType.taskArchived => 'archived it',
      ActivityType.taskRestored => 'restored it',
      ActivityType.statusChanged =>
        'moved it · ${statusName(activity.from)} → ${statusName(activity.to)}',
      ActivityType.priorityChanged =>
        'changed priority · ${priorityName(activity.from)} → '
            '${priorityName(activity.to)}',
      ActivityType.assigneeChanged =>
        activity.to == null ? 'unassigned it' : 'assigned it to ${activity.to}',
      ActivityType.dueDateChanged =>
        'set the due date · ${dateName(activity.to)}',
      ActivityType.labelAdded => 'added the label ${labelName(activity.to)}',
      ActivityType.labelRemoved =>
        'removed the label ${labelName(activity.from)}',
      ActivityType.commentAdded => 'commented',
      ActivityType.subtaskCompleted =>
        'completed a subtask${activity.to == null ? '' : ' · ${activity.to}'}',
      ActivityType.dependencyAdded =>
        'added a dependency${activity.to == null ? '' : ' on ${activity.to}'}',
      ActivityType.projectCreated =>
        'created the project ${activity.to ?? ''}'.trim(),
      ActivityType.projectUpdated =>
        'updated the project ${activity.to ?? ''}'.trim(),
      ActivityType.memberJoined => 'joined the workspace',
    };
  }
}
