import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/presentation/enum_presentation.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/app_badge.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/core/widgets/app_overlays.dart';
import 'package:kairo/core/widgets/app_segmented.dart';
import 'package:kairo/core/widgets/app_text_field.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/task_query.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/domain/entities/workspace.dart';
import 'package:kairo/features/tasks/application/task_view_controller.dart';

/// Search, view switch, grouping, sorting and filters for the task screens.
///
/// One bar drives every view — switching from list to board keeps the filters,
/// which is the behaviour that makes multiple views feel like views of the same
/// thing rather than separate screens.
class TaskFilterBar extends ConsumerWidget {
  const TaskFilterBar({
    this.showViewSwitch = true,
    this.availableViews = TaskViewType.values,
    super.key,
  });

  final bool showViewSwitch;
  final List<TaskViewType> availableViews;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final TaskQuery query = ref.watch(taskQueryProvider);
    final TaskQueryController controller = ref.read(taskQueryProvider.notifier);
    final TaskViewType view = ref.watch(taskViewTypeProvider);
    final bool compact = context.isCompact;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? Spacing.md : Spacing.lg,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.canvas,
        border: Border(bottom: BorderSide(color: colors.hairline)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              if (showViewSwitch)
                // Icon-only on a phone already, but the control still has to
                // be allowed to shrink: four view icons plus a search field
                // plus the filter button is more than 320px of row.
                Flexible(
                  child: AppSegmentedControl<TaskViewType>(
                    value: view,
                    dense: true,
                    showLabels: !compact,
                    options: <SegmentOption<TaskViewType>>[
                      for (final TaskViewType type in availableViews)
                        SegmentOption<TaskViewType>(
                          value: type,
                          label: type.label(context.l10n),
                          icon: type.icon,
                          tooltip: type.label(context.l10n),
                        ),
                    ],
                    onChanged: (TaskViewType type) =>
                        ref.read(taskViewTypeProvider.notifier).set(type),
                  ),
                ),
              SizedBox(width: compact ? Spacing.sm : Spacing.md),
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: AppSearchField(
                    hint: compact ? 'Filter…' : 'Filter tasks…',
                    onChanged: controller.setSearch,
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              if (!compact) ...<Widget>[
                _GroupingMenu(query: query, controller: controller),
                const SizedBox(width: Spacing.sm),
                _SortMenu(query: query, controller: controller),
                const SizedBox(width: Spacing.sm),
              ],
              _FilterButton(query: query),
            ],
          ),
          _ActiveFilters(query: query, controller: controller),
        ],
      ),
    );
  }
}

class _GroupingMenu extends StatelessWidget {
  const _GroupingMenu({required this.query, required this.controller});

  final TaskQuery query;
  final TaskQueryController controller;

  @override
  Widget build(BuildContext context) {
    return AppSelectMenu<TaskGrouping>(
      selected: query.grouping,
      options: <MenuOption<TaskGrouping>>[
        for (final TaskGrouping grouping in TaskGrouping.values)
          MenuOption<TaskGrouping>(
            value: grouping,
            label: grouping.label(context.l10n),
            icon: AppIcons.group,
          ),
      ],
      onSelected: controller.setGrouping,
      builder: (BuildContext context, VoidCallback open) => AppButton(
        label:
            '${context.l10n.tasksGroupBy}: ${query.grouping.label(context.l10n)}',
        icon: AppIcons.group,
        size: AppButtonSize.small,
        variant: AppButtonVariant.ghost,
        onPressed: open,
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.query, required this.controller});

  final TaskQuery query;
  final TaskQueryController controller;

  @override
  Widget build(BuildContext context) {
    return AppSelectMenu<TaskSortField>(
      selected: query.sortField,
      options: <MenuOption<TaskSortField>>[
        for (final TaskSortField field in TaskSortField.values)
          MenuOption<TaskSortField>(
            value: field,
            label: field.label(context.l10n),
            icon: AppIcons.sort,
            trailing: field == query.sortField
                ? Icon(
                    query.sortDirection == SortDirection.ascending
                        ? AppIcons.chevronUp
                        : AppIcons.chevronDown,
                    size: 13,
                    color: context.colors.inkFaint,
                  )
                : null,
          ),
      ],
      onSelected: controller.setSort,
      builder: (BuildContext context, VoidCallback open) => AppButton(
        label: query.sortField.label(context.l10n),
        icon: AppIcons.sort,
        size: AppButtonSize.small,
        variant: AppButtonVariant.ghost,
        onPressed: open,
      ),
    );
  }
}

class _FilterButton extends ConsumerWidget {
  const _FilterButton({required this.query});

  final TaskQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int count = query.activeFilterCount;
    return AppButton(
      label: count == 0
          ? context.l10n.tasksFilter
          : '${context.l10n.tasksFilter} · $count',
      icon: AppIcons.filter,
      size: AppButtonSize.small,
      variant: count == 0
          ? AppButtonVariant.secondary
          : AppButtonVariant.primary,
      onPressed: () => showAppSheet<void>(
        context: context,
        expand: true,
        initialSize: 0.7,
        builder: (BuildContext context) => const TaskFilterSheet(),
      ),
    );
  }
}

/// Removable chips summarising what is currently filtered. Without this the
/// filter state is invisible and people wonder where their tasks went.
class _ActiveFilters extends ConsumerWidget {
  const _ActiveFilters({required this.query, required this.controller});

  final TaskQuery query;
  final TaskQueryController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!query.hasActiveFilters) return const SizedBox.shrink();

    final Map<String, User> members = ref.watch(membersByIdProvider);
    final Map<String, Label> labels = ref.watch(labelsByIdProvider);

    return AnimatedSize(
      duration: context.motion(Motion.base),
      curve: Motion.entrance,
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: Spacing.sm),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Wrap(
                spacing: Spacing.sm - 2,
                runSpacing: Spacing.xs,
                children: <Widget>[
                  for (final TaskStatus status in query.statuses)
                    AppFilterChip(
                      label: status.label(context.l10n),
                      icon: status.icon,
                      color: status.color(context.colors),
                      selected: true,
                      onTap: () => controller.toggleStatus(status),
                    ),
                  for (final TaskPriority priority in query.priorities)
                    AppFilterChip(
                      label: priority.label(context.l10n),
                      icon: priority.icon,
                      color: priority.color(context.colors),
                      selected: true,
                      onTap: () => controller.togglePriority(priority),
                    ),
                  for (final String id in query.assigneeIds)
                    AppFilterChip(
                      label: members[id]?.name ?? id,
                      icon: AppIcons.assignee,
                      selected: true,
                      onTap: () => controller.toggleAssignee(id),
                    ),
                  for (final String id in query.labelIds)
                    AppFilterChip(
                      label: labels[id]?.name ?? id,
                      icon: AppIcons.label,
                      color: labels[id] == null
                          ? null
                          : Color(labels[id]!.colorValue),
                      selected: true,
                      onTap: () => controller.toggleLabel(id),
                    ),
                  if (query.onlyOverdue)
                    AppFilterChip(
                      label: context.l10n.dashboardOverdue,
                      icon: AppIcons.overdue,
                      color: context.colors.danger,
                      selected: true,
                      onTap: () => controller.update(
                        (TaskQuery q) => q.copyWith(onlyOverdue: false),
                      ),
                    ),
                  if (query.onlyFavorites)
                    AppFilterChip(
                      label: context.l10n.navFavorites,
                      icon: AppIcons.favorites,
                      color: context.colors.warning,
                      selected: true,
                      onTap: () => controller.update(
                        (TaskQuery q) => q.copyWith(onlyFavorites: false),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            AppButton(
              label: context.l10n.actionClearAll,
              size: AppButtonSize.small,
              variant: AppButtonVariant.link,
              onPressed: controller.clearFilters,
            ),
          ],
        ),
      ),
    );
  }
}

/// Full filter surface, opened as a sheet on every breakpoint — the option set
/// is long enough that a dropdown would be worse everywhere.
class TaskFilterSheet extends ConsumerWidget {
  const TaskFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TaskQuery query = ref.watch(taskQueryProvider);
    final TaskQueryController controller = ref.read(taskQueryProvider.notifier);
    final List<User> members =
        ref.watch(membersProvider).value ?? const <User>[];
    final List<Label> labels =
        ref.watch(labelsProvider).value ?? const <Label>[];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SheetHeader(
          title: context.l10n.tasksFilter,
          trailing: query.hasActiveFilters
              ? AppButton(
                  label: context.l10n.actionClearAll,
                  size: AppButtonSize.small,
                  variant: AppButtonVariant.link,
                  onPressed: controller.clearFilters,
                )
              : null,
        ),
        Flexible(
          child: ListView(
            padding: const EdgeInsets.all(Spacing.lg),
            children: <Widget>[
              _FilterGroup(
                title: context.l10n.fieldStatus,
                children: <Widget>[
                  for (final TaskStatus status in TaskStatus.values)
                    AppFilterChip(
                      label: status.label(context.l10n),
                      icon: status.icon,
                      color: status.color(context.colors),
                      selected: query.statuses.contains(status),
                      onTap: () => controller.toggleStatus(status),
                    ),
                ],
              ),
              _FilterGroup(
                title: context.l10n.fieldPriority,
                children: <Widget>[
                  for (final TaskPriority priority in TaskPriority.values)
                    AppFilterChip(
                      label: priority.label(context.l10n),
                      icon: priority.icon,
                      color: priority.color(context.colors),
                      selected: query.priorities.contains(priority),
                      onTap: () => controller.togglePriority(priority),
                    ),
                ],
              ),
              _FilterGroup(
                title: context.l10n.fieldAssignee,
                children: <Widget>[
                  AppFilterChip(
                    label: context.l10n.fieldUnassigned,
                    icon: AppIcons.assignee,
                    selected: query.onlyUnassigned,
                    onTap: () => controller.update(
                      (TaskQuery q) =>
                          q.copyWith(onlyUnassigned: !q.onlyUnassigned),
                    ),
                  ),
                  for (final User member in members)
                    AppFilterChip(
                      label: member.firstName,
                      icon: AppIcons.assignee,
                      selected: query.assigneeIds.contains(member.id),
                      onTap: () => controller.toggleAssignee(member.id),
                    ),
                ],
              ),
              _FilterGroup(
                title: context.l10n.fieldLabels,
                children: <Widget>[
                  for (final Label label in labels)
                    AppFilterChip(
                      label: label.name,
                      color: Color(label.colorValue),
                      selected: query.labelIds.contains(label.id),
                      onTap: () => controller.toggleLabel(label.id),
                    ),
                ],
              ),
              _FilterGroup(
                title: context.l10n.commonMore,
                children: <Widget>[
                  AppFilterChip(
                    label: context.l10n.dashboardOverdue,
                    icon: AppIcons.overdue,
                    color: context.colors.danger,
                    selected: query.onlyOverdue,
                    onTap: () => controller.update(
                      (TaskQuery q) => q.copyWith(onlyOverdue: !q.onlyOverdue),
                    ),
                  ),
                  AppFilterChip(
                    label: context.l10n.navFavorites,
                    icon: AppIcons.favorites,
                    color: context.colors.warning,
                    selected: query.onlyFavorites,
                    onTap: () => controller.update(
                      (TaskQuery q) =>
                          q.copyWith(onlyFavorites: !q.onlyFavorites),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: AppButton.primary(
              label: context.l10n.actionDone,
              isFullWidth: true,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title.toUpperCase(),
            style: context.textStyles.labelSmall?.copyWith(
              color: context.colors.inkFaint,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Wrap(spacing: Spacing.sm, runSpacing: Spacing.sm, children: children),
        ],
      ),
    );
  }
}
