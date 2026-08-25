import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/presentation/enum_presentation.dart';
import 'package:kairo/core/responsive/breakpoints.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/utils/date_utils.dart';
import 'package:kairo/core/widgets/app_avatar.dart';
import 'package:kairo/core/widgets/app_badge.dart';
import 'package:kairo/core/widgets/app_overlays.dart';
import 'package:kairo/core/widgets/completion_check.dart';
import 'package:kairo/domain/entities/preferences.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/domain/entities/workspace.dart';
import 'package:kairo/features/tasks/presentation/widgets/recurrence_picker.dart';

/// A single task in the list view.
///
/// Dense by design: the title carries the row, and every other property is a
/// small right-aligned column that a scanning eye can ignore. On compact
/// layouts the columns fold into a second line and the row gains swipe
/// actions instead of hover controls.
class TaskRow extends ConsumerStatefulWidget {
  const TaskRow({
    required this.task,
    required this.onOpen,
    required this.onToggleComplete,
    this.onEdit,
    this.onDelete,
    this.onArchive,
    this.onDuplicate,
    this.onToggleFavorite,
    this.isSelected = false,
    this.isFocused = false,
    this.selectionMode = false,
    this.onSelectionChanged,
    this.showProject = true,
    this.index = 0,
    super.key,
  });

  final Task task;
  final VoidCallback onOpen;
  final ValueChanged<bool> onToggleComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final VoidCallback? onDuplicate;
  final VoidCallback? onToggleFavorite;

  final bool isSelected;

  /// True when the keyboard cursor is on this row.
  final bool isFocused;

  final bool selectionMode;
  final ValueChanged<bool>? onSelectionChanged;
  final bool showProject;
  final int index;

  @override
  ConsumerState<TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends ConsumerState<TaskRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  bool _hovered = false;

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  void _complete(bool value) {
    final bool effectsOn = ref.read(
      preferencesProvider.select(
        (UserPreferences p) => p.taskCompletionEffects,
      ),
    );
    if (value && effectsOn && !context.reducedMotion) {
      _burst.forward(from: 0);
    }
    widget.onToggleComplete(value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Task task = widget.task;
    final bool compact = context.isCompact;

    final Map<String, Project> projects = ref.watch(projectsByIdProvider);
    final Map<String, User> members = ref.watch(membersByIdProvider);
    final Map<String, Label> labels = ref.watch(labelsByIdProvider);

    final Project? project = task.projectId == null
        ? null
        : projects[task.projectId!];
    final User? assignee = task.assigneeId == null
        ? null
        : members[task.assigneeId!];

    final Widget row = Container(
      decoration: BoxDecoration(
        color: widget.isSelected
            ? colors.selectionTint
            : (_hovered ? colors.surfaceSunken : colors.surface),
        border: Border(
          bottom: BorderSide(color: colors.hairline),
          left: BorderSide(
            color: widget.isFocused ? colors.brand : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? Spacing.md : Spacing.md,
        vertical: compact ? Spacing.sm : 0,
      ),
      constraints: BoxConstraints(minHeight: compact ? 64 : 46),
      child: compact
          ? _compactLayout(context, project, assignee, labels)
          : _wideLayout(context, project, assignee, labels),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        selected: widget.isSelected,
        label:
            '${task.title}. ${task.status.label(context.l10n)}. '
            '${task.priority.label(context.l10n)}',
        child: GestureDetector(
          onTap: widget.selectionMode
              ? () => widget.onSelectionChanged?.call(!widget.isSelected)
              : widget.onOpen,
          onSecondaryTapDown: (TapDownDetails details) =>
              _showContextMenu(context, details.globalPosition),
          onLongPress: compact
              ? () => widget.onSelectionChanged?.call(!widget.isSelected)
              : null,
          child: compact ? _withSwipe(context, row) : row,
        ),
      ),
    );
  }

  /// Swipe right completes, swipe left archives — the two actions worth a
  /// gesture. Both are undoable from the toast.
  Widget _withSwipe(BuildContext context, Widget child) {
    final colors = context.colors;
    return Dismissible(
      key: ValueKey<String>('swipe-${widget.task.id}'),
      background: Container(
        color: colors.successSoft,
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
        child: Icon(AppIcons.complete, color: colors.success, size: 20),
      ),
      secondaryBackground: Container(
        color: colors.warningSoft,
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
        child: Icon(AppIcons.archive, color: colors.warning, size: 20),
      ),
      confirmDismiss: (DismissDirection direction) async {
        if (direction == DismissDirection.startToEnd) {
          _complete(!widget.task.isDone);
        } else {
          widget.onArchive?.call();
        }
        // Never actually remove the row — the list rebuilds from state.
        return false;
      },
      child: child,
    );
  }

  /// The dense row. Columns are dropped as width shrinks — a row with six
  /// fixed columns needs roughly 1000px before the title has room to breathe,
  /// so labels and project fall away first, then status.
  Widget _wideLayout(
    BuildContext context,
    Project? project,
    User? assignee,
    Map<String, Label> labels,
  ) {
    final colors = context.colors;
    final Task task = widget.task;
    final ScreenSize size = context.breakpoint;
    final bool showLabels = size == ScreenSize.large;
    final bool showProject = widget.showProject && size.hasSidebar;
    final bool showStatus = size.index >= ScreenSize.medium.index;

    return Row(
      children: <Widget>[
        if (widget.selectionMode)
          SizedBox(
            width: 30,
            child: Checkbox(
              value: widget.isSelected,
              visualDensity: VisualDensity.compact,
              onChanged: (bool? value) =>
                  widget.onSelectionChanged?.call(value ?? false),
            ),
          ),
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(child: CompletionBurst(controller: _burst)),
            CompletionCheckbox(
              isCompleted: task.isDone,
              onChanged: _complete,
              size: 17,
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: Spacing.md),
            child: Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: task.isDone ? colors.inkFaint : colors.ink,
                      fontWeight: FontWeight.w500,
                      decoration: task.isDone
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: colors.inkFaint,
                    ),
                  ),
                ),
                if (task.hasSubtasks) ...<Widget>[
                  const SizedBox(width: Spacing.sm),
                  _MetaChip(
                    icon: AppIcons.subtasks,
                    label:
                        '${task.completedSubtaskCount}/${task.subtasks.length}',
                  ),
                ],
                if (task.dependsOnIds.isNotEmpty) ...<Widget>[
                  const SizedBox(width: Spacing.xs + 2),
                  Tooltip(
                    message: context.l10n.tasksBlockedBy,
                    child: Icon(
                      AppIcons.blockedBy,
                      size: 13,
                      color: colors.violet,
                    ),
                  ),
                ],
                if (task.recurrence.isEnabled) ...<Widget>[
                  const SizedBox(width: Spacing.xs + 2),
                  RecurrenceBadge(rule: task.recurrence),
                ],
              ],
            ),
          ),
        ),

        // Labels.
        if (showLabels && task.labelIds.isNotEmpty) ...<Widget>[
          SizedBox(
            width: 150,
            child: Wrap(
              spacing: 4,
              clipBehavior: Clip.hardEdge,
              children: <Widget>[
                for (final String id in task.labelIds.take(2))
                  if (labels[id] != null) LabelChip(label: labels[id]!),
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
        ],

        if (showProject)
          SizedBox(
            width: 130,
            child: project == null
                ? Text(
                    '—',
                    style: context.textStyles.labelSmall?.copyWith(
                      color: colors.inkFaint,
                    ),
                  )
                : Row(
                    children: <Widget>[
                      Text(
                        project.iconEmoji,
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.labelSmall?.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

        if (showStatus)
          SizedBox(
            width: 108,
            child: StatusPill(status: task.status, compact: true),
          ),
        SizedBox(
          width: 30,
          child: PriorityPill(priority: task.priority, showLabel: false),
        ),
        SizedBox(width: 92, child: _DueLabel(task: task)),
        SizedBox(
          width: 40,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AppAvatar(user: assignee, size: 24),
          ),
        ),

        AnimatedOpacity(
          opacity: _hovered ? 1 : 0,
          duration: context.motion(Motion.fast),
          child: _RowActions(
            task: widget.task,
            onEdit: widget.onEdit,
            onDelete: widget.onDelete,
            onArchive: widget.onArchive,
            onDuplicate: widget.onDuplicate,
            onToggleFavorite: widget.onToggleFavorite,
          ),
        ),
      ],
    );
  }

  Widget _compactLayout(
    BuildContext context,
    Project? project,
    User? assignee,
    Map<String, Label> labels,
  ) {
    final colors = context.colors;
    final Task task = widget.task;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(child: CompletionBurst(controller: _burst)),
              CompletionCheckbox(
                isCompleted: task.isDone,
                onChanged: _complete,
                size: 19,
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.bodyLarge?.copyWith(
                  color: task.isDone ? colors.inkFaint : colors.ink,
                  fontWeight: FontWeight.w500,
                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: Spacing.sm - 2),
              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  PriorityPill(priority: task.priority, compact: true),
                  if (task.dueDate != null)
                    _DueLabel(task: task, compact: true),
                  if (project != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          project.iconEmoji,
                          style: const TextStyle(fontSize: 10),
                        ),
                        const SizedBox(width: 4),
                        // Project names are user-supplied and this metadata row
                        // sits under the title, where width is whatever is
                        // left over.
                        Flexible(
                          child: Text(
                            project.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.labelSmall?.copyWith(
                              color: colors.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (task.hasSubtasks)
                    _MetaChip(
                      icon: AppIcons.subtasks,
                      label:
                          '${task.completedSubtaskCount}/${task.subtasks.length}',
                    ),
                  for (final String id in task.labelIds.take(2))
                    if (labels[id] != null) LabelChip(label: labels[id]!),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: Spacing.sm),
        AppAvatar(user: assignee, size: 26),
      ],
    );
  }

  Future<void> _showContextMenu(BuildContext context, Offset position) async {
    final l10n = context.l10n;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final String? choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(value: 'open', child: Text(l10n.actionEdit)),
        PopupMenuItem<String>(
          value: 'duplicate',
          child: Text(l10n.actionDuplicate),
        ),
        PopupMenuItem<String>(
          value: 'favorite',
          child: Text(
            widget.task.isFavorite
                ? l10n.projectsUnfavorite
                : l10n.projectsFavorite,
          ),
        ),
        PopupMenuItem<String>(
          value: 'archive',
          child: Text(l10n.actionArchive),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(value: 'delete', child: Text(l10n.actionDelete)),
      ],
    );

    switch (choice) {
      case 'open':
        widget.onEdit?.call();
      case 'duplicate':
        widget.onDuplicate?.call();
      case 'favorite':
        widget.onToggleFavorite?.call();
      case 'archive':
        widget.onArchive?.call();
      case 'delete':
        widget.onDelete?.call();
    }
  }
}

class _DueLabel extends StatelessWidget {
  const _DueLabel({required this.task, this.compact = false});

  final Task task;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (task.dueDate == null) {
      return Text(
        '—',
        style: context.textStyles.labelSmall?.copyWith(color: colors.inkFaint),
      );
    }
    final bool overdue = task.isOverdue;
    final bool today = Dates.isToday(task.dueDate!);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          overdue ? AppIcons.overdue : AppIcons.dueDate,
          size: 12,
          color: overdue
              ? colors.danger
              : (today ? colors.warning : colors.inkFaint),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            Dates.dueLabel(task.dueDate, context.l10n),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.labelSmall?.copyWith(
              color: overdue
                  ? colors.danger
                  : (today ? colors.warning : colors.inkMuted),
              fontWeight: overdue || today ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 11, color: colors.inkFaint),
        const SizedBox(width: 3),
        Text(
          label,
          style: context.textStyles.labelSmall?.copyWith(
            color: colors.inkFaint,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.task,
    this.onEdit,
    this.onDelete,
    this.onArchive,
    this.onDuplicate,
    this.onToggleFavorite,
  });

  final Task task;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final VoidCallback? onDuplicate;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppOverflowMenu(
      size: 26,
      options: <MenuOption<String>>[
        MenuOption<String>(
          value: 'edit',
          label: l10n.actionEdit,
          icon: AppIcons.edit,
        ),
        MenuOption<String>(
          value: 'duplicate',
          label: l10n.actionDuplicate,
          icon: AppIcons.duplicate,
        ),
        MenuOption<String>(
          value: 'favorite',
          label: task.isFavorite
              ? l10n.projectsUnfavorite
              : l10n.projectsFavorite,
          icon: AppIcons.favorites,
        ),
        MenuOption<String>(
          value: 'archive',
          label: task.isArchived ? l10n.actionRestore : l10n.actionArchive,
          icon: AppIcons.archive,
        ),
        MenuOption<String>(
          value: 'delete',
          label: l10n.actionDelete,
          icon: AppIcons.delete,
          isDestructive: true,
        ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
          case 'duplicate':
            onDuplicate?.call();
          case 'favorite':
            onToggleFavorite?.call();
          case 'archive':
            onArchive?.call();
          case 'delete':
            onDelete?.call();
        }
      },
    );
  }
}
