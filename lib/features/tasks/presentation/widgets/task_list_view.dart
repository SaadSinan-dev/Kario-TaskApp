import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/presentation/enum_presentation.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/utils/date_utils.dart';
import 'package:kairo/core/utils/keyboard.dart';
import 'package:kairo/core/widgets/app_skeleton.dart';
import 'package:kairo/core/widgets/app_states.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/entities/task_query.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/domain/services/task_query_engine.dart';
import 'package:kairo/features/tasks/application/task_actions.dart';
import 'package:kairo/features/tasks/application/task_view_controller.dart';
import 'package:kairo/features/tasks/presentation/task_composer.dart';
import 'package:kairo/features/tasks/presentation/widgets/task_row.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';

/// The grouped, keyboard-navigable task list.
///
/// A flat index over the visible rows backs both arrow-key navigation and the
/// selection model, so the keyboard and the mouse are always looking at the
/// same list — which is what makes `↑ ↓ Space E` feel reliable rather than
/// approximate.
class TaskListView extends ConsumerStatefulWidget {
  const TaskListView({
    required this.tasks,
    required this.onOpenTask,
    this.emptyTitle,
    this.emptyMessage,
    this.onCreate,
    this.showProject = true,
    this.isLoading = false,
    super.key,
  });

  final List<Task> tasks;
  final ValueChanged<Task> onOpenTask;
  final String? emptyTitle;
  final String? emptyMessage;
  final VoidCallback? onCreate;
  final bool showProject;
  final bool isLoading;

  @override
  ConsumerState<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends ConsumerState<TaskListView> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'task-list');
  int _cursor = -1;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _moveCursor(int delta, int length) {
    if (length == 0) return;
    setState(() {
      _cursor = (_cursor + delta).clamp(0, length - 1);
    });
  }

  Task? _cursorTask(List<Task> flat) =>
      _cursor >= 0 && _cursor < flat.length ? flat[_cursor] : null;

  @override
  Widget build(BuildContext context) {
    final TaskQuery query = ref.watch(taskQueryProvider);
    final Set<String> selection = ref.watch(taskSelectionProvider);
    final Map<String, Project> projects = ref.watch(projectsByIdProvider);
    final Map<String, User> members = ref.watch(membersByIdProvider);
    final AppL10n l10n = context.l10n;

    if (widget.isLoading) {
      return SkeletonList(
        count: 8,
        itemBuilder: (BuildContext context) => const TaskRowSkeleton(),
      );
    }

    if (widget.tasks.isEmpty) {
      return AppEmptyState(
        icon: query.hasActiveFilters ? AppIcons.filter : AppIcons.tasks,
        title: query.hasActiveFilters
            ? 'No tasks match these filters'
            : (widget.emptyTitle ?? l10n.emptyTasksTitle),
        message: query.hasActiveFilters
            ? 'Try widening the filter, or clear it to see everything again.'
            : (widget.emptyMessage ?? l10n.emptyTasksBody),
        actionLabel: query.hasActiveFilters ? null : l10n.actionCreateTask,
        onAction: widget.onCreate,
        secondaryActionLabel: query.hasActiveFilters
            ? l10n.actionClearAll
            : null,
        onSecondaryAction: query.hasActiveFilters
            ? ref.read(taskQueryProvider.notifier).clearFilters
            : null,
      );
    }

    final List<TaskGroup<Task>> groups = TaskQueryEngine.group(
      widget.tasks,
      query,
      labelFor: (TaskGrouping grouping, String key) =>
          _groupLabel(context, grouping, key, projects, members),
      colorFor: (TaskGrouping grouping, String key) =>
          _groupColor(context, grouping, key, projects),
    );

    final List<Task> flat = <Task>[
      for (final TaskGroup<Task> group in groups) ...group.items,
    ];

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      child: CallbackShortcuts(
        bindings: _bindings(flat, l10n),
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: Spacing.huge),
          itemCount: groups.length,
          itemBuilder: (BuildContext context, int groupIndex) {
            final TaskGroup<Task> group = groups[groupIndex];
            final int offset = groups
                .take(groupIndex)
                .fold<int>(0, (int sum, TaskGroup<Task> g) => sum + g.count);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (query.grouping != TaskGrouping.none)
                  _GroupHeader(
                    group: group,
                    onAdd: widget.onCreate == null
                        ? null
                        : () => _createInGroup(context, query, group),
                  ),
                for (int i = 0; i < group.items.length; i++)
                  _row(
                    context,
                    group.items[i],
                    flatIndex: offset + i,
                    selection: selection,
                    l10n: l10n,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Map<ShortcutActivator, VoidCallback> _bindings(
    List<Task> flat,
    AppL10n l10n,
  ) {
    // Every binding here is an unmodified key, so each is gated on the caret
    // not being in a field — a row being renamed inline lives inside this
    // same subtree, and Space must type a space there, not complete the task.
    return <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.arrowDown):
          KeyboardGuards.unlessTyping(() => _moveCursor(1, flat.length)),
      const SingleActivator(LogicalKeyboardKey.arrowUp):
          KeyboardGuards.unlessTyping(() => _moveCursor(-1, flat.length)),
      const SingleActivator(
        LogicalKeyboardKey.space,
      ): KeyboardGuards.unlessTyping(() {
        final Task? task = _cursorTask(flat);
        if (task == null) return;
        ref
            .read(taskActionsProvider)
            .setCompleted(l10n: l10n, task: task, completed: !task.isDone);
      }),
      const SingleActivator(
        LogicalKeyboardKey.enter,
      ): KeyboardGuards.unlessTyping(() {
        final Task? task = _cursorTask(flat);
        if (task != null) widget.onOpenTask(task);
      }),
      const SingleActivator(
        LogicalKeyboardKey.keyE,
      ): KeyboardGuards.unlessTyping(() {
        final Task? task = _cursorTask(flat);
        if (task != null) openTaskComposer(context, ref, task: task);
      }),
      const SingleActivator(LogicalKeyboardKey.escape): () {
        ref.read(taskSelectionProvider.notifier).clear();
        setState(() => _cursor = -1);
      },
    };
  }

  Widget _row(
    BuildContext context,
    Task task, {
    required int flatIndex,
    required Set<String> selection,
    required AppL10n l10n,
  }) {
    final TaskActions actions = ref.read(taskActionsProvider);
    return Entrance(
      index: flatIndex,
      offset: 6,
      child: TaskRow(
        key: ValueKey<String>(task.id),
        task: task,
        index: flatIndex,
        showProject: widget.showProject,
        isSelected: selection.contains(task.id),
        isFocused: _cursor == flatIndex,
        selectionMode: selection.isNotEmpty,
        onSelectionChanged: (bool value) => ref
            .read(taskSelectionProvider.notifier)
            .toggle(task.id, selected: value),
        onOpen: () {
          setState(() => _cursor = flatIndex);
          widget.onOpenTask(task);
        },
        onToggleComplete: (bool value) =>
            actions.setCompleted(l10n: l10n, task: task, completed: value),
        onEdit: () => openTaskComposer(context, ref, task: task),
        onDuplicate: () => actions.duplicate(l10n: l10n, task: task),
        onToggleFavorite: () => actions.toggleFavorite(task.id),
        onArchive: () => actions.setArchived(
          l10n: l10n,
          task: task,
          archived: !task.isArchived,
        ),
        onDelete: () => actions.delete(l10n: l10n, task: task),
      ),
    );
  }

  /// Creating from a group header pre-fills whatever that group represents —
  /// adding to "In Progress" should not require setting the status again.
  void _createInGroup(
    BuildContext context,
    TaskQuery query,
    TaskGroup<Task> group,
  ) {
    switch (query.grouping) {
      case TaskGrouping.status:
        openTaskComposer(
          context,
          ref,
          status: TaskStatus.values.firstWhere(
            (TaskStatus s) => s.name == group.key,
            orElse: () => TaskStatus.todo,
          ),
        );
      case TaskGrouping.project:
        openTaskComposer(
          context,
          ref,
          projectId: group.key == '__none__' ? null : group.key,
        );
      case TaskGrouping.assignee:
        openTaskComposer(
          context,
          ref,
          assigneeId: group.key == '__none__' ? null : group.key,
        );
      case TaskGrouping.dueDate:
        openTaskComposer(context, ref, dueDate: _dateForBucket(group.key));
      case TaskGrouping.priority:
      case TaskGrouping.none:
        openTaskComposer(context, ref);
    }
  }

  DateTime? _dateForBucket(String key) {
    final DateTime today = Dates.today();
    return switch (key) {
      'b_today' => today,
      'c_tomorrow' => today.add(const Duration(days: 1)),
      'd_week' => today.add(const Duration(days: 3)),
      'e_month' => today.add(const Duration(days: 14)),
      _ => null,
    };
  }
}

String _groupLabel(
  BuildContext context,
  TaskGrouping grouping,
  String key,
  Map<String, Project> projects,
  Map<String, User> members,
) {
  final AppL10n l10n = context.l10n;
  switch (grouping) {
    case TaskGrouping.none:
      return l10n.tasksTitle;
    case TaskGrouping.status:
      return TaskStatus.values
          .firstWhere(
            (TaskStatus s) => s.name == key,
            orElse: () => TaskStatus.todo,
          )
          .label(l10n);
    case TaskGrouping.priority:
      return TaskPriority.values
          .firstWhere(
            (TaskPriority p) => p.name == key,
            orElse: () => TaskPriority.medium,
          )
          .label(l10n);
    case TaskGrouping.project:
      return key == '__none__'
          ? l10n.fieldNoProject
          : projects[key]?.name ?? l10n.fieldNoProject;
    case TaskGrouping.assignee:
      return key == '__none__'
          ? l10n.fieldUnassigned
          : members[key]?.name ?? l10n.fieldUnassigned;
    case TaskGrouping.dueDate:
      return switch (key) {
        'a_overdue' => l10n.dashboardOverdue,
        'b_today' => l10n.timeToday,
        'c_tomorrow' => l10n.timeTomorrow,
        'd_week' => 'This week',
        'e_month' => 'This month',
        'f_later' => 'Later',
        _ => l10n.timeNoDate,
      };
  }
}

int? _groupColor(
  BuildContext context,
  TaskGrouping grouping,
  String key,
  Map<String, Project> projects,
) {
  switch (grouping) {
    case TaskGrouping.status:
      return TaskStatus.values
          .firstWhere(
            (TaskStatus s) => s.name == key,
            orElse: () => TaskStatus.todo,
          )
          .color(context.colors)
          .toARGB32();
    case TaskGrouping.priority:
      return TaskPriority.values
          .firstWhere(
            (TaskPriority p) => p.name == key,
            orElse: () => TaskPriority.medium,
          )
          .color(context.colors)
          .toARGB32();
    case TaskGrouping.project:
      return projects[key]?.colorValue;
    case TaskGrouping.dueDate:
      return key == 'a_overdue' ? context.colors.danger.toARGB32() : null;
    case TaskGrouping.assignee:
    case TaskGrouping.none:
      return null;
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group, this.onAdd});

  final TaskGroup<Task> group;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color accent = group.accentColorValue == null
        ? colors.inkMuted
        : Color(group.accentColorValue!);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.lg,
        Spacing.md,
        Spacing.sm,
      ),
      color: colors.canvas,
      child: Row(
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: Spacing.sm),
          Text(group.label, style: context.textStyles.titleSmall),
          const SizedBox(width: Spacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: colors.surfaceSunken,
              borderRadius: Radii.brXs,
            ),
            child: Text(
              '${group.count}',
              style: context.textStyles.labelSmall?.copyWith(
                color: colors.inkFaint,
              ),
            ),
          ),
          const Spacer(),
          if (onAdd != null)
            IconButton(
              icon: const Icon(AppIcons.add, size: 15),
              onPressed: onAdd,
              tooltip: context.l10n.tasksNewInColumn,
              color: colors.inkFaint,
              splashRadius: 14,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}

/// Floating toolbar shown while rows are selected.
class BulkActionBar extends ConsumerWidget {
  const BulkActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final Set<String> selection = ref.watch(taskSelectionProvider);
    final AppL10n l10n = context.l10n;

    if (selection.isEmpty) return const SizedBox.shrink();

    final TaskActions actions = ref.read(taskActionsProvider);
    final TaskSelectionController controller = ref.read(
      taskSelectionProvider.notifier,
    );

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Entrance(
          offset: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceOverlay,
              borderRadius: Radii.brXl,
              border: Border.all(color: colors.hairlineStrong),
              boxShadow: Shadows.lg(colors.isDark),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                  child: Text(
                    l10n.tasksSelectedCount(selection.length),
                    style: context.textStyles.labelLarge,
                  ),
                ),
                _BulkButton(
                  icon: AppIcons.complete,
                  tooltip: l10n.actionComplete,
                  onTap: () {
                    actions.bulkUpdate(
                      l10n: l10n,
                      taskIds: selection.toList(),
                      status: TaskStatus.done,
                    );
                    controller.clear();
                  },
                ),
                _BulkButton(
                  icon: AppIcons.archive,
                  tooltip: l10n.actionArchive,
                  onTap: () {
                    actions.bulkUpdate(
                      l10n: l10n,
                      taskIds: selection.toList(),
                      archived: true,
                    );
                    controller.clear();
                  },
                ),
                _BulkButton(
                  icon: AppIcons.delete,
                  tooltip: l10n.actionDelete,
                  destructive: true,
                  onTap: () async {
                    await actions.bulkDelete(
                      l10n: l10n,
                      taskIds: selection.toList(),
                    );
                    controller.clear();
                  },
                ),
                Container(
                  width: 1,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                  color: colors.hairline,
                ),
                _BulkButton(
                  icon: AppIcons.close,
                  tooltip: l10n.actionCancel,
                  onTap: controller.clear,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BulkButton extends StatelessWidget {
  const _BulkButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 17),
        onPressed: onTap,
        color: destructive ? colors.danger : colors.inkMuted,
        splashRadius: 18,
      ),
    );
  }
}
