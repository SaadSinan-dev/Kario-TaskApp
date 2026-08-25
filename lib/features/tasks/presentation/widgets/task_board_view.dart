import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/presentation/enum_presentation.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/utils/date_utils.dart';
import 'package:kairo/core/widgets/app_avatar.dart';
import 'package:kairo/core/widgets/app_badge.dart';
import 'package:kairo/core/widgets/app_progress.dart';
import 'package:kairo/core/widgets/app_skeleton.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/domain/entities/workspace.dart';
import 'package:kairo/features/tasks/application/task_actions.dart';
import 'package:kairo/features/tasks/presentation/task_composer.dart';
import 'package:kairo/features/tasks/presentation/widgets/recurrence_picker.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';

/// What travels with a dragged card.
@immutable
class _BoardDrag {
  const _BoardDrag({required this.task, required this.fromStatus});

  final Task task;
  final TaskStatus fromStatus;
}

/// The Kanban board.
///
/// Drop targets are the *gaps between cards*, not the cards themselves, which
/// is what makes the insertion point exact and lets the placeholder open
/// smoothly where the card will actually land. Columns keep their own scroll
/// position, and the whole board scrolls horizontally on narrow screens.
class TaskBoardView extends ConsumerStatefulWidget {
  const TaskBoardView({
    required this.tasks,
    required this.onOpenTask,
    this.projectId,
    this.isLoading = false,
    super.key,
  });

  final List<Task> tasks;
  final ValueChanged<Task> onOpenTask;
  final String? projectId;
  final bool isLoading;

  @override
  ConsumerState<TaskBoardView> createState() => _TaskBoardViewState();
}

class _TaskBoardViewState extends ConsumerState<TaskBoardView> {
  final ScrollController _horizontal = ScrollController();
  TaskStatus? _hoveredColumn;

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return const _BoardSkeleton();

    final Map<TaskStatus, List<Task>> byStatus = <TaskStatus, List<Task>>{
      for (final TaskStatus status in TaskStatus.values) status: <Task>[],
    };
    for (final Task task in widget.tasks) {
      byStatus[task.status]!.add(task);
    }
    for (final List<Task> column in byStatus.values) {
      column.sort((Task a, Task b) => a.sortIndex.compareTo(b.sortIndex));
    }

    final bool compact = context.isCompact;
    final double columnWidth = compact ? 268.0 : 300.0;

    return Scrollbar(
      controller: _horizontal,
      child: SingleChildScrollView(
        controller: _horizontal,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? Spacing.md : Spacing.lg,
          vertical: Spacing.md,
        ),
        // `stretch` rather than `start`: the columns are full-height panels,
        // and each one manages its own vertical scrolling.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final TaskStatus status in TaskStatus.values)
              Padding(
                padding: const EdgeInsets.only(right: Spacing.md),
                child: SizedBox(
                  width: columnWidth,
                  child: _BoardColumn(
                    status: status,
                    tasks: byStatus[status]!,
                    isHovered: _hoveredColumn == status,
                    onHoverChanged: (bool hovered) => setState(
                      () => _hoveredColumn = hovered ? status : null,
                    ),
                    onOpenTask: widget.onOpenTask,
                    onDrop: _handleDrop,
                    onCreate: () => openTaskComposer(
                      context,
                      ref,
                      status: status,
                      projectId: widget.projectId,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleDrop(_BoardDrag drag, TaskStatus status, int index) {
    ref
        .read(taskActionsProvider)
        .move(
          l10n: context.l10n,
          taskId: drag.task.id,
          status: status,
          index: index,
        );
  }
}

class _BoardColumn extends ConsumerWidget {
  const _BoardColumn({
    required this.status,
    required this.tasks,
    required this.isHovered,
    required this.onHoverChanged,
    required this.onOpenTask,
    required this.onDrop,
    required this.onCreate,
  });

  final TaskStatus status;
  final List<Task> tasks;
  final bool isHovered;
  final ValueChanged<bool> onHoverChanged;
  final ValueChanged<Task> onOpenTask;
  final void Function(_BoardDrag drag, TaskStatus status, int index) onDrop;
  final VoidCallback onCreate;

  /// Soft limit that turns the count amber. Not enforced — a WIP limit is a
  /// conversation starter, not a permission system.
  static const int wipSoftLimit = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final Color accent = status.color(colors);
    final bool overWip =
        status == TaskStatus.inProgress && tasks.length > wipSoftLimit;

    return AnimatedContainer(
      duration: context.motion(Motion.base),
      decoration: BoxDecoration(
        color: isHovered ? colors.dragTint : colors.surfaceSunken,
        borderRadius: Radii.brLg,
        border: Border.all(
          color: isHovered ? colors.brandBorder : colors.hairline,
        ),
      ),
      // Fills the height available rather than sizing to its cards, so all
      // five columns line up and each scrolls independently.
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.md,
              Spacing.md,
              Spacing.sm,
              Spacing.sm,
            ),
            child: Row(
              children: <Widget>[
                Icon(status.icon, size: 15, color: accent),
                const SizedBox(width: Spacing.sm),
                Flexible(
                  child: Text(
                    status.label(context.l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.titleSmall,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: overWip ? colors.warningSoft : colors.surface,
                    borderRadius: Radii.brXs,
                    border: Border.all(
                      color: overWip ? colors.warning : colors.hairline,
                    ),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: context.textStyles.labelSmall?.copyWith(
                      color: overWip ? colors.warning : colors.inkFaint,
                    ),
                  ),
                ),
                if (overWip) ...<Widget>[
                  const SizedBox(width: Spacing.xs),
                  Tooltip(
                    message:
                        'More than $wipSoftLimit tasks in progress — consider '
                        'finishing before starting.',
                    child: Icon(
                      AppIcons.warning,
                      size: 13,
                      color: colors.warning,
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(AppIcons.add, size: 15),
                  onPressed: onCreate,
                  tooltip: context.l10n.tasksNewInColumn,
                  color: colors.inkFaint,
                  splashRadius: 14,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
              ],
            ),
          ),
          // The column fills the height it is given rather than a fixed 640px.
          // That number was a desktop assumption: on a 568px-tall phone it
          // overflowed the viewport, and on a tall monitor it left the column
          // stranded mid-screen.
          //
          // `ListView.builder` rather than a scrolling `Column`: a board holds
          // every task in the workspace across five columns, and building all
          // of them — each one a `Draggable` with its own gesture recogniser —
          // on every board rebuild is the most expensive thing on this screen.
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                Spacing.sm,
                0,
                Spacing.sm,
                Spacing.sm,
              ),
              // Gaps and cards alternate — gap, card, gap, card … gap — so the
              // list is one longer than twice the task count. An empty column
              // shows its placeholder after the single trailing gap.
              itemCount: tasks.length * 2 + 1 + (tasks.isEmpty ? 1 : 0),
              itemBuilder: (BuildContext context, int index) {
                if (index == tasks.length * 2) {
                  return _DropGap(
                    status: status,
                    index: tasks.length,
                    onDrop: onDrop,
                    onHoverChanged: onHoverChanged,
                    isTrailing: true,
                  );
                }
                if (index > tasks.length * 2) {
                  return _EmptyColumn(status: status, onCreate: onCreate);
                }
                if (index.isEven) {
                  return _DropGap(
                    status: status,
                    index: index ~/ 2,
                    onDrop: onDrop,
                    onHoverChanged: onHoverChanged,
                  );
                }
                final Task task = tasks[index ~/ 2];
                return _DraggableCard(
                  task: task,
                  status: status,
                  onOpen: () => onOpenTask(task),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The insertion point between two cards. Grows into a placeholder when a card
/// hovers over it, so the drop location is never a guess.
class _DropGap extends StatefulWidget {
  const _DropGap({
    required this.status,
    required this.index,
    required this.onDrop,
    required this.onHoverChanged,
    this.isTrailing = false,
  });

  final TaskStatus status;
  final int index;
  final void Function(_BoardDrag drag, TaskStatus status, int index) onDrop;
  final ValueChanged<bool> onHoverChanged;
  final bool isTrailing;

  @override
  State<_DropGap> createState() => _DropGapState();
}

class _DropGapState extends State<_DropGap> {
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DragTarget<_BoardDrag>(
      onWillAcceptWithDetails: (DragTargetDetails<_BoardDrag> details) {
        setState(() => _active = true);
        widget.onHoverChanged(true);
        return true;
      },
      onLeave: (_) {
        setState(() => _active = false);
        widget.onHoverChanged(false);
      },
      onAcceptWithDetails: (DragTargetDetails<_BoardDrag> details) {
        setState(() => _active = false);
        widget.onHoverChanged(false);
        widget.onDrop(details.data, widget.status, widget.index);
      },
      builder: (BuildContext context, List<_BoardDrag?> candidates, _) {
        return AnimatedContainer(
          duration: context.motion(Motion.base),
          curve: Motion.emphasized,
          height: _active ? 62 : (widget.isTrailing ? 24 : 8),
          margin: EdgeInsets.symmetric(vertical: _active ? 4 : 0),
          decoration: _active
              ? BoxDecoration(
                  color: colors.brand.withValues(alpha: 0.10),
                  borderRadius: Radii.brMd,
                  border: Border.all(
                    color: colors.brand.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                )
              : null,
          child: _active
              ? Center(
                  child: Text(
                    context.l10n.calendarDropHint,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: colors.brand,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _DraggableCard extends StatelessWidget {
  const _DraggableCard({
    required this.task,
    required this.status,
    required this.onOpen,
  });

  final Task task;
  final TaskStatus status;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final _BoardDrag payload = _BoardDrag(task: task, fromStatus: status);
    final Widget card = BoardCard(task: task, onOpen: onOpen);

    // Touch devices get a long-press drag so a tap can still open the task;
    // pointer devices drag immediately.
    final Widget feedback = _DragFeedback(child: card);
    final Widget placeholder = Opacity(
      opacity: 0.32,
      child: IgnorePointer(child: card),
    );

    if (context.isTouchFirst) {
      return LongPressDraggable<_BoardDrag>(
        data: payload,
        feedback: feedback,
        childWhenDragging: placeholder,
        hapticFeedbackOnStart: true,
        child: card,
      );
    }

    return Draggable<_BoardDrag>(
      data: payload,
      feedback: feedback,
      childWhenDragging: placeholder,
      child: card,
    );
  }
}

/// The card that follows the pointer: lifted, slightly tilted and scaled, so it
/// reads as picked up rather than teleported.
class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      child: Transform.rotate(
        angle: -0.022,
        child: Transform.scale(
          scale: 1.03,
          child: SizedBox(
            width: 288,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: Radii.brMd,
                boxShadow: Shadows.xl(colors.isDark),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A task as it appears on the board.
class BoardCard extends ConsumerWidget {
  const BoardCard({required this.task, required this.onOpen, super.key});

  final Task task;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final AppL10n l10n = context.l10n;
    final Map<String, Project> projects = ref.watch(projectsByIdProvider);
    final Map<String, User> members = ref.watch(membersByIdProvider);
    final Map<String, Label> labels = ref.watch(labelsByIdProvider);

    final Project? project = task.projectId == null
        ? null
        : projects[task.projectId!];
    final User? assignee = task.assigneeId == null
        ? null
        : members[task.assigneeId!];

    return HoverLift(
      lift: 2,
      child: PressableScale(
        onTap: onOpen,
        scale: 0.985,
        child: Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Radii.brMd,
            border: Border.all(color: colors.hairline),
            boxShadow: Shadows.xs(colors.isDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (task.labelIds.isNotEmpty) ...<Widget>[
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: <Widget>[
                    for (final String id in task.labelIds.take(3))
                      if (labels[id] != null) LabelChip(label: labels[id]!),
                  ],
                ),
                const SizedBox(height: Spacing.sm),
              ],
              Text(
                task.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: task.isDone ? colors.inkFaint : colors.ink,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              if (task.hasSubtasks) ...<Widget>[
                const SizedBox(height: Spacing.sm),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SegmentedProgress(
                        total: task.subtasks.length,
                        completed: task.completedSubtaskCount,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Text(
                      '${task.completedSubtaskCount}/${task.subtasks.length}',
                      style: context.textStyles.labelSmall?.copyWith(
                        color: colors.inkFaint,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: Spacing.md - 2),
              Row(
                children: <Widget>[
                  PriorityPill(priority: task.priority, showLabel: false),
                  const SizedBox(width: Spacing.sm),
                  if (task.dueDate != null)
                    _CardDue(task: task)
                  else if (project != null)
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            project.iconEmoji,
                            style: const TextStyle(fontSize: 10),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              project.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.labelSmall?.copyWith(
                                color: colors.inkFaint,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (task.dependsOnIds.isNotEmpty) ...<Widget>[
                    const SizedBox(width: Spacing.sm - 2),
                    Tooltip(
                      message: l10n.tasksBlockedBy,
                      child: Icon(
                        AppIcons.blockedBy,
                        size: 12,
                        color: colors.violet,
                      ),
                    ),
                  ],
                  if (task.recurrence.isEnabled) ...<Widget>[
                    const SizedBox(width: Spacing.sm - 2),
                    RecurrenceBadge(rule: task.recurrence),
                  ],
                  const Spacer(),
                  AppAvatar(user: assignee, size: 22),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardDue extends StatelessWidget {
  const _CardDue({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool overdue = task.isOverdue;
    final bool today = Dates.isToday(task.dueDate!);
    final Color color = overdue
        ? colors.danger
        : (today ? colors.warning : colors.inkFaint);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          overdue ? AppIcons.overdue : AppIcons.dueDate,
          size: 11,
          color: color,
        ),
        const SizedBox(width: 3),
        Text(
          Dates.dueLabel(task.dueDate, context.l10n),
          style: context.textStyles.labelSmall?.copyWith(
            color: color,
            fontSize: 10.5,
            fontWeight: overdue ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyColumn extends StatelessWidget {
  const _EmptyColumn({required this.status, required this.onCreate});

  final TaskStatus status;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onCreate,
      borderRadius: Radii.brMd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
        decoration: BoxDecoration(
          borderRadius: Radii.brMd,
          border: Border.all(color: colors.hairline),
        ),
        child: Column(
          children: <Widget>[
            Icon(AppIcons.add, size: 16, color: colors.inkFaint),
            const SizedBox(height: Spacing.sm),
            Text(
              context.l10n.tasksNewInColumn,
              style: context.textStyles.labelSmall?.copyWith(
                color: colors.inkFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardSkeleton extends StatelessWidget {
  const _BoardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(Spacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int column = 0; column < 4; column++)
            Container(
              width: 300,
              margin: const EdgeInsets.only(right: Spacing.md),
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: context.colors.surfaceSunken,
                borderRadius: Radii.brLg,
                border: Border.all(color: context.colors.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Skeleton(width: 96, height: 12),
                  const SizedBox(height: Spacing.lg),
                  for (int card = 0; card < 3; card++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Spacing.sm),
                      child: Container(
                        padding: const EdgeInsets.all(Spacing.md),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: Radii.brMd,
                          border: Border.all(color: context.colors.hairline),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Skeleton(height: 12),
                            SizedBox(height: Spacing.sm),
                            Skeleton(width: 140, height: 12),
                            SizedBox(height: Spacing.md),
                            Row(
                              children: <Widget>[
                                Skeleton(width: 40, height: 10),
                                Spacer(),
                                Skeleton.circle(size: 22),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
