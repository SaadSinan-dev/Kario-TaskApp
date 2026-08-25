import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/utils/date_utils.dart';
import 'package:kairo/core/utils/id_generator.dart';
import 'package:kairo/core/widgets/app_avatar.dart';
import 'package:kairo/core/widgets/app_badge.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/core/widgets/app_overlays.dart';
import 'package:kairo/core/widgets/app_progress.dart';
import 'package:kairo/core/widgets/app_segmented.dart';
import 'package:kairo/core/widgets/app_skeleton.dart';
import 'package:kairo/core/widgets/app_states.dart';
import 'package:kairo/core/widgets/app_surfaces.dart';
import 'package:kairo/core/widgets/app_text_field.dart';
import 'package:kairo/core/widgets/completion_check.dart';
import 'package:kairo/domain/entities/collaboration.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/recurrence.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/domain/entities/workspace.dart';
import 'package:kairo/features/tasks/application/task_actions.dart';
import 'package:kairo/features/tasks/presentation/widgets/activity_feed.dart';
import 'package:kairo/features/tasks/presentation/widgets/comment_thread.dart';
import 'package:kairo/features/tasks/presentation/widgets/property_pickers.dart';
import 'package:kairo/features/tasks/presentation/widgets/recurrence_picker.dart';
import 'package:kairo/features/tasks/presentation/widgets/rich_text_editor.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';

/// The full task experience.
///
/// One widget serves three placements — a docked side panel on desktop, a
/// full-screen route on mobile, and a dialog on tablets — because the content
/// is identical and only the frame changes. Every edit writes through
/// immediately; there is no save button, which is what people expect from a
/// detail panel rather than a form.
class TaskDetailPanel extends ConsumerStatefulWidget {
  const TaskDetailPanel({
    required this.taskId,
    required this.onClose,
    this.showCloseButton = true,
    super.key,
  });

  final String taskId;
  final VoidCallback onClose;
  final bool showCloseButton;

  @override
  ConsumerState<TaskDetailPanel> createState() => _TaskDetailPanelState();
}

class _TaskDetailPanelState extends ConsumerState<TaskDetailPanel> {
  late final TextEditingController _description = TextEditingController();
  bool _editingDescription = false;
  bool _editingTitle = false;
  int _tab = 0;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  TaskActions get _actions => ref.read(taskActionsProvider);

  void _patch(Task task, Task Function(Task task) transform) {
    _actions.update(l10n: context.l10n, task: transform(task), silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final AsyncValue<Task?> task = ref.watch(taskByIdProvider(widget.taskId));

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: BorderDirectional(start: BorderSide(color: colors.hairline)),
      ),
      child: task.when(
        loading: _loading,
        error: (Object error, _) => AppErrorState(
          error: error,
          onRetry: () => ref.invalidate(taskByIdProvider(widget.taskId)),
        ),
        data: (Task? value) => value == null
            ? AppEmptyState(
                icon: AppIcons.tasks,
                title: context.l10n.errorNotFoundTitle,
                message: context.l10n.errorNotFoundBody,
                actionLabel: context.l10n.actionClose,
                onAction: widget.onClose,
                compact: true,
              )
            : _content(context, value),
      ),
    );
  }

  Widget _loading() {
    return const Padding(
      padding: EdgeInsets.all(Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Skeleton(width: 120, height: 12),
          SizedBox(height: Spacing.lg),
          Skeleton(height: 20),
          SizedBox(height: Spacing.sm),
          Skeleton(width: 220, height: 20),
          SizedBox(height: Spacing.xxl),
          Skeleton(height: 12),
          SizedBox(height: Spacing.sm),
          Skeleton(height: 12),
          SizedBox(height: Spacing.sm),
          Skeleton(width: 180, height: 12),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, Task task) {
    final AppL10n l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Header(
          task: task,
          onClose: widget.onClose,
          showCloseButton: widget.showCloseButton,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Spacing.xl,
              Spacing.lg,
              Spacing.xl,
              Spacing.huge,
            ),
            children: <Widget>[
              _TitleRow(
                task: task,
                isEditing: _editingTitle,
                onEditToggle: (bool value) =>
                    setState(() => _editingTitle = value),
                onCommit: (String title) {
                  _patch(task, (Task t) => t.copyWith(title: title));
                  setState(() => _editingTitle = false);
                },
                onToggleComplete: (bool value) => _actions.setCompleted(
                  l10n: l10n,
                  task: task,
                  completed: value,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              _PropertyGrid(
                task: task,
                onPatch: (Task next) => _patch(task, (_) => next),
              ),
              const SizedBox(height: Spacing.xxl),

              AppSectionHeader(
                title: l10n.fieldDescription,
                icon: AppIcons.docs,
                trailing: AppIconButton(
                  icon: _editingDescription ? AppIcons.check : AppIcons.edit,
                  tooltip: _editingDescription
                      ? l10n.actionSave
                      : l10n.actionEdit,
                  size: 28,
                  onPressed: () {
                    if (_editingDescription) {
                      _patch(
                        task,
                        (Task t) => t.copyWith(description: _description.text),
                      );
                    } else {
                      _description.text = task.description;
                    }
                    setState(() => _editingDescription = !_editingDescription);
                  },
                ),
              ),
              const SizedBox(height: Spacing.sm),
              if (_editingDescription)
                RichTextEditor(controller: _description, minLines: 4)
              else
                DescriptionView(
                  markdown: task.description,
                  onEdit: () {
                    _description.text = task.description;
                    setState(() => _editingDescription = true);
                  },
                ),

              const SizedBox(height: Spacing.xxl),
              SubtaskSection(task: task),

              if (task.dependsOnIds.isNotEmpty ||
                  _hasBlocked(task)) ...<Widget>[
                const SizedBox(height: Spacing.xxl),
                DependencySection(task: task),
              ],

              if (task.attachments.isNotEmpty) ...<Widget>[
                const SizedBox(height: Spacing.xxl),
                _AttachmentSection(task: task),
              ],

              const SizedBox(height: Spacing.xxl),
              AppTabs(
                selectedIndex: _tab,
                onChanged: (int index) => setState(() => _tab = index),
                tabs: <({String label, IconData? icon, int? count})>[
                  (
                    label: l10n.fieldComments,
                    icon: AppIcons.comment,
                    count: ref.watch(commentsProvider(task.id)).value?.length,
                  ),
                  (
                    label: l10n.fieldActivity,
                    icon: AppIcons.activity,
                    count: null,
                  ),
                ],
              ),
              const SizedBox(height: Spacing.lg),
              AnimatedSwitcher(
                duration: context.motion(Motion.base),
                child: _tab == 0
                    ? CommentThread(
                        key: const ValueKey<int>(0),
                        taskId: task.id,
                      )
                    : _ActivityTab(
                        key: const ValueKey<int>(1),
                        taskId: task.id,
                      ),
              ),
            ],
          ),
        ),
        _Footer(task: task),
      ],
    );
  }

  bool _hasBlocked(Task task) {
    final List<Task> tasks = ref.watch(tasksProvider).value ?? const <Task>[];
    return tasks.any((Task t) => t.dependsOnIds.contains(task.id));
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.task,
    required this.onClose,
    required this.showCloseButton,
  });

  final Task task;
  final VoidCallback onClose;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final AppL10n l10n = context.l10n;
    final Map<String, Project> projects = ref.watch(projectsByIdProvider);
    final Project? project = task.projectId == null
        ? null
        : projects[task.projectId!];
    final TaskActions actions = ref.read(taskActionsProvider);

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      decoration: BoxDecoration(
        color: colors.canvas,
        border: Border(bottom: BorderSide(color: colors.hairline)),
      ),
      child: Row(
        children: <Widget>[
          if (project != null) ...<Widget>[
            Text(project.iconEmoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: Spacing.sm),
            Flexible(
              child: Text(
                project.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.labelMedium?.copyWith(
                  color: colors.inkMuted,
                ),
              ),
            ),
          ] else
            Text(
              l10n.fieldNoProject,
              style: context.textStyles.labelMedium?.copyWith(
                color: colors.inkFaint,
              ),
            ),
          const Spacer(),
          AppIconButton(
            icon: AppIcons.favorites,
            tooltip: task.isFavorite
                ? l10n.projectsUnfavorite
                : l10n.projectsFavorite,
            isActive: task.isFavorite,
            color: task.isFavorite ? colors.warning : null,
            onPressed: () => actions.toggleFavorite(task.id),
          ),
          AppOverflowMenu(
            options: <MenuOption<String>>[
              MenuOption<String>(
                value: 'duplicate',
                label: l10n.actionDuplicate,
                icon: AppIcons.duplicate,
              ),
              MenuOption<String>(
                value: 'archive',
                label: task.isArchived
                    ? l10n.actionRestore
                    : l10n.actionArchive,
                icon: AppIcons.archive,
              ),
              MenuOption<String>(
                value: 'delete',
                label: l10n.actionDelete,
                icon: AppIcons.delete,
                isDestructive: true,
              ),
            ],
            onSelected: (String value) async {
              switch (value) {
                case 'duplicate':
                  await actions.duplicate(l10n: l10n, task: task);
                case 'archive':
                  await actions.setArchived(
                    l10n: l10n,
                    task: task,
                    archived: !task.isArchived,
                  );
                case 'delete':
                  final bool confirmed = await confirmAction(
                    context: context,
                    title: l10n.tasksDeleteConfirmTitle,
                    message: l10n.tasksDeleteConfirmBody,
                    confirmLabel: l10n.actionDelete,
                  );
                  if (!confirmed) return;
                  await actions.delete(l10n: l10n, task: task);
                  onClose();
              }
            },
          ),
          if (showCloseButton)
            AppIconButton(
              icon: AppIcons.close,
              tooltip: l10n.actionClose,
              onPressed: onClose,
            ),
        ],
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.task,
    required this.isEditing,
    required this.onEditToggle,
    required this.onCommit,
    required this.onToggleComplete,
  });

  final Task task;
  final bool isEditing;
  final ValueChanged<bool> onEditToggle;
  final ValueChanged<String> onCommit;
  final ValueChanged<bool> onToggleComplete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: CompletionCheckbox(
            isCompleted: task.isDone,
            size: 22,
            onChanged: onToggleComplete,
          ),
        ),
        Expanded(
          child: isEditing
              ? InlineEditableText(
                  value: task.title,
                  maxLines: 3,
                  style: context.textStyles.headlineSmall,
                  onCommit: onCommit,
                  onCancel: () => onEditToggle(false),
                )
              : GestureDetector(
                  onTap: () => onEditToggle(true),
                  behavior: HitTestBehavior.opaque,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.text,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        task.title,
                        style: context.textStyles.headlineSmall?.copyWith(
                          color: task.isDone ? colors.inkMuted : colors.ink,
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: colors.inkFaint,
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Label/value rows for every task property.
class _PropertyGrid extends ConsumerWidget {
  const _PropertyGrid({required this.task, required this.onPatch});

  final Task task;
  final ValueChanged<Task> onPatch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l10n = context.l10n;
    final Map<String, Label> labels = ref.watch(labelsByIdProvider);

    return Column(
      children: <Widget>[
        _PropertyRow(
          icon: AppIcons.statusTodo,
          label: l10n.fieldStatus,
          child: StatusPicker(
            value: task.status,
            onChanged: (TaskStatus value) =>
                onPatch(task.copyWith(status: value)),
          ),
        ),
        _PropertyRow(
          icon: AppIcons.priorityMedium,
          label: l10n.fieldPriority,
          child: PriorityPicker(
            value: task.priority,
            onChanged: (TaskPriority value) =>
                onPatch(task.copyWith(priority: value)),
          ),
        ),
        _PropertyRow(
          icon: AppIcons.assignee,
          label: l10n.fieldAssignee,
          child: AssigneePicker(
            value: task.assigneeId,
            onChanged: (String? value) => onPatch(
              task.copyWith(assigneeId: value, clearAssignee: value == null),
            ),
          ),
        ),
        _PropertyRow(
          icon: AppIcons.projects,
          label: l10n.fieldProject,
          child: ProjectPicker(
            value: task.projectId,
            onChanged: (String? value) => onPatch(
              task.copyWith(projectId: value, clearProject: value == null),
            ),
          ),
        ),
        _PropertyRow(
          icon: AppIcons.dueDate,
          label: l10n.fieldDueDate,
          child: DatePickerField(
            value: task.dueDate,
            label: l10n.fieldDueDate,
            onChanged: (DateTime? value) => onPatch(
              task.copyWith(dueDate: value, clearDueDate: value == null),
            ),
          ),
        ),
        _PropertyRow(
          icon: AppIcons.play,
          label: l10n.fieldStartDate,
          child: DatePickerField(
            value: task.startDate,
            label: l10n.fieldStartDate,
            icon: AppIcons.play,
            onChanged: (DateTime? value) => onPatch(
              task.copyWith(startDate: value, clearStartDate: value == null),
            ),
          ),
        ),
        _PropertyRow(
          icon: AppIcons.recurrence,
          label: l10n.fieldRecurrence,
          child: RecurrencePicker(
            value: task.recurrence,
            onChanged: (RecurrenceRule value) =>
                onPatch(task.copyWith(recurrence: value)),
          ),
        ),
        if (task.estimateMinutes != null)
          _PropertyRow(
            icon: AppIcons.estimate,
            label: l10n.fieldEstimate,
            child: AppBadge(
              label: Dates.duration(task.estimateMinutes!),
              icon: AppIcons.estimate,
            ),
          ),
        _PropertyRow(
          icon: AppIcons.label,
          label: l10n.fieldLabels,
          child: Wrap(
            spacing: Spacing.xs + 2,
            runSpacing: Spacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              for (final String id in task.labelIds)
                if (labels[id] != null)
                  LabelChip(
                    label: labels[id]!,
                    compact: false,
                    onRemove: () => onPatch(
                      task.copyWith(
                        labelIds: task.labelIds
                            .where((String l) => l != id)
                            .toList(),
                      ),
                    ),
                  ),
              LabelPicker(
                selectedIds: task.labelIds,
                onChanged: (List<String> value) =>
                    onPatch(task.copyWith(labelIds: value)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PropertyRow extends StatelessWidget {
  const _PropertyRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 116,
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Row(
                children: <Widget>[
                  Icon(icon, size: 14, color: colors.inkFaint),
                  const SizedBox(width: Spacing.sm),
                  Flexible(
                    child: Text(
                      label,
                      style: context.textStyles.labelMedium?.copyWith(
                        color: colors.inkMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtasks with add, complete, rename, delete and drag-to-reorder.
class SubtaskSection extends ConsumerStatefulWidget {
  const SubtaskSection({required this.task, super.key});

  final Task task;

  @override
  ConsumerState<SubtaskSection> createState() => _SubtaskSectionState();
}

class _SubtaskSectionState extends ConsumerState<SubtaskSection> {
  final TextEditingController _controller = TextEditingController();
  String? _editingId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final AppL10n l10n = context.l10n;
    final Task task = widget.task;
    final TaskActions actions = ref.read(taskActionsProvider);
    final List<Subtask> subtasks = <Subtask>[...task.subtasks]
      ..sort((Subtask a, Subtask b) => a.sortIndex.compareTo(b.sortIndex));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          title: l10n.fieldSubtasks,
          icon: AppIcons.subtasks,
          trailing: subtasks.isEmpty
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.tasksSubtaskProgress(
                        task.completedSubtaskCount,
                        subtasks.length,
                      ),
                      style: context.textStyles.labelSmall?.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    ProgressRing(
                      value: task.subtaskProgress,
                      size: 22,
                      strokeWidth: 3,
                      color: colors.success,
                    ),
                  ],
                ),
        ),
        const SizedBox(height: Spacing.sm),
        if (subtasks.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: subtasks.length,
            onReorder: (int oldIndex, int newIndex) {
              final List<Subtask> next = <Subtask>[...subtasks];
              final int target = newIndex > oldIndex ? newIndex - 1 : newIndex;
              next.insert(target, next.removeAt(oldIndex));
              actions.reorderSubtasks(
                l10n: l10n,
                taskId: task.id,
                orderedIds: next.map((Subtask s) => s.id).toList(),
              );
            },
            itemBuilder: (BuildContext context, int index) {
              final Subtask subtask = subtasks[index];
              return _SubtaskRow(
                key: ValueKey<String>(subtask.id),
                index: index,
                subtask: subtask,
                isEditing: _editingId == subtask.id,
                onEdit: () => setState(() => _editingId = subtask.id),
                onEditDone: () => setState(() => _editingId = null),
                onRename: (String title) {
                  actions.upsertSubtask(
                    l10n: l10n,
                    taskId: task.id,
                    subtask: subtask.copyWith(title: title),
                  );
                  setState(() => _editingId = null);
                },
                onToggle: (bool value) => actions.upsertSubtask(
                  l10n: l10n,
                  taskId: task.id,
                  subtask: subtask.copyWith(isDone: value),
                ),
                onDelete: () => actions.deleteSubtask(
                  l10n: l10n,
                  taskId: task.id,
                  subtaskId: subtask.id,
                ),
              );
            },
          ),
        Padding(
          padding: const EdgeInsets.only(top: Spacing.xs),
          child: Row(
            children: <Widget>[
              const SizedBox(width: Spacing.xxl + 2),
              Icon(AppIcons.add, size: 14, color: colors.inkFaint),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: context.textStyles.bodyMedium,
                  onSubmitted: (String value) {
                    if (value.trim().isEmpty) return;
                    actions.upsertSubtask(
                      l10n: l10n,
                      taskId: task.id,
                      subtask: Subtask(
                        id: Ids.subtask(),
                        title: value.trim(),
                        sortIndex: subtasks.length,
                      ),
                    );
                    _controller.clear();
                  },
                  decoration: InputDecoration(
                    hintText: l10n.tasksAddSubtask,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 9),
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

class _SubtaskRow extends StatefulWidget {
  const _SubtaskRow({
    required this.subtask,
    required this.index,
    required this.isEditing,
    required this.onEdit,
    required this.onEditDone,
    required this.onRename,
    required this.onToggle,
    required this.onDelete,
    super.key,
  });

  final Subtask subtask;
  final int index;
  final bool isEditing;
  final VoidCallback onEdit;
  final VoidCallback onEditDone;
  final ValueChanged<String> onRename;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  State<_SubtaskRow> createState() => _SubtaskRowState();
}

class _SubtaskRowState extends State<_SubtaskRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: <Widget>[
            ReorderableDragStartListener(
              index: widget.index,
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: SizedBox(
                  width: 22,
                  child: AnimatedOpacity(
                    opacity: _hovered ? 1 : 0,
                    duration: context.motion(Motion.fast),
                    child: Icon(
                      AppIcons.drag,
                      size: 13,
                      color: colors.inkFaint,
                    ),
                  ),
                ),
              ),
            ),
            CompletionCheckbox(
              isCompleted: widget.subtask.isDone,
              size: 16,
              onChanged: widget.onToggle,
            ),
            Expanded(
              child: widget.isEditing
                  ? InlineEditableText(
                      value: widget.subtask.title,
                      style: context.textStyles.bodyMedium,
                      onCommit: widget.onRename,
                      onCancel: widget.onEditDone,
                    )
                  : GestureDetector(
                      onTap: widget.onEdit,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Text(
                          widget.subtask.title,
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: widget.subtask.isDone
                                ? colors.inkFaint
                                : colors.inkSoft,
                            decoration: widget.subtask.isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ),
            ),
            AnimatedOpacity(
              opacity: _hovered ? 1 : 0,
              duration: context.motion(Motion.fast),
              child: AppIconButton(
                icon: AppIcons.close,
                tooltip: context.l10n.actionRemove,
                size: 24,
                iconSize: 12,
                onPressed: widget.onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Blocking and blocked-by relationships, with a picker that refuses cycles.
class DependencySection extends ConsumerWidget {
  const DependencySection({required this.task, super.key});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l10n = context.l10n;
    final List<Task> all = ref.watch(tasksProvider).value ?? const <Task>[];
    final List<Task> blockers = all
        .where((Task t) => task.dependsOnIds.contains(t.id))
        .toList(growable: false);
    final List<Task> blocked = all
        .where((Task t) => t.dependsOnIds.contains(task.id))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          title: l10n.fieldDependencies,
          icon: AppIcons.dependency,
        ),
        const SizedBox(height: Spacing.sm),
        if (blockers.isNotEmpty) ...<Widget>[
          _DependencyGroup(
            title: l10n.tasksBlockedBy,
            tasks: blockers,
            tone: BadgeTone.warning,
            onRemove: (Task blocker) => ref
                .read(taskActionsProvider)
                .removeDependency(
                  l10n: l10n,
                  taskId: task.id,
                  dependsOnId: blocker.id,
                ),
          ),
          const SizedBox(height: Spacing.md),
        ],
        if (blocked.isNotEmpty)
          _DependencyGroup(
            title: l10n.tasksBlocks,
            tasks: blocked,
            tone: BadgeTone.violet,
          ),
      ],
    );
  }
}

class _DependencyGroup extends StatelessWidget {
  const _DependencyGroup({
    required this.title,
    required this.tasks,
    required this.tone,
    this.onRemove,
  });

  final String title;
  final List<Task> tasks;
  final BadgeTone tone;
  final ValueChanged<Task>? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title.toUpperCase(),
          style: context.textStyles.labelSmall?.copyWith(
            color: colors.inkFaint,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: Spacing.sm - 2),
        for (final Task dependency in tasks)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceSunken,
              borderRadius: Radii.brSm,
              border: Border.all(color: colors.hairline),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  dependency.isDone ? AppIcons.statusDone : AppIcons.statusTodo,
                  size: 14,
                  color: dependency.isDone ? colors.success : colors.inkFaint,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    dependency.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.inkSoft,
                      decoration: dependency.isDone
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                if (onRemove != null)
                  AppIconButton(
                    icon: AppIcons.close,
                    tooltip: context.l10n.actionRemove,
                    size: 24,
                    iconSize: 12,
                    onPressed: () => onRemove!(dependency),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AttachmentSection extends StatelessWidget {
  const _AttachmentSection({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          title: context.l10n.fieldAttachments,
          icon: AppIcons.attachment,
          count: task.attachments.length,
        ),
        const SizedBox(height: Spacing.sm),
        for (final Attachment attachment in task.attachments)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(Spacing.sm),
            decoration: BoxDecoration(
              borderRadius: Radii.brSm,
              border: Border.all(color: colors.hairline),
            ),
            child: Row(
              children: <Widget>[
                Icon(AppIcons.data, size: 15, color: colors.inkMuted),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    attachment.fileName,
                    style: context.textStyles.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  attachment.readableSize,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: colors.inkFaint,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActivityTab extends ConsumerWidget {
  const _ActivityTab({required this.taskId, super.key});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Activity>> activity = ref.watch(
      taskActivityProvider(taskId),
    );
    return ActivityFeed(
      activities: activity.value ?? const <Activity>[],
      isLoading: activity.isLoading,
    );
  }
}

/// Created/updated metadata, pinned to the bottom of the panel.
class _Footer extends ConsumerWidget {
  const _Footer({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final Map<String, User> members = ref.watch(membersByIdProvider);
    final User? creator = members[task.createdById];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.xl,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        border: Border(top: BorderSide(color: colors.hairline)),
      ),
      child: Row(
        children: <Widget>[
          AppAvatar(user: creator, size: 18),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              'Created by ${creator?.firstName ?? '—'} · '
              '${Dates.relative(task.createdAt, context.l10n)}',
              style: context.textStyles.labelSmall?.copyWith(
                color: colors.inkFaint,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (task.completedAt != null)
            AppBadge(
              label: 'Done ${Dates.relative(task.completedAt!, context.l10n)}',
              tone: BadgeTone.success,
              compact: true,
              icon: AppIcons.check,
            ),
        ],
      ),
    );
  }
}
