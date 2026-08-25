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
import 'package:kairo/core/widgets/app_overlays.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/domain/entities/workspace.dart';

/// The pickers used by the task form, the detail panel and inline editing on
/// list rows and board cards.
///
/// They all share one trigger shape — a bordered pill that shows the current
/// value — so changing a property looks the same wherever it happens.

/// A labelled trigger button that opens a picker.
class PropertyTrigger extends StatefulWidget {
  const PropertyTrigger({
    required this.child,
    required this.onTap,
    this.icon,
    this.isPlaceholder = false,
    this.dense = false,
    this.tooltip,
    super.key,
  });

  final Widget child;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isPlaceholder;
  final bool dense;
  final String? tooltip;

  @override
  State<PropertyTrigger> createState() => _PropertyTriggerState();
}

class _PropertyTriggerState extends State<PropertyTrigger> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Widget body = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: context.motion(Motion.fast),
          padding: EdgeInsets.symmetric(
            horizontal: widget.dense ? Spacing.sm : Spacing.md - 2,
            vertical: widget.dense ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: _hovered ? colors.surfaceSunken : Colors.transparent,
            borderRadius: Radii.brSm,
            border: Border.all(
              color: _hovered ? colors.hairlineStrong : colors.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.icon != null) ...<Widget>[
                Icon(
                  widget.icon,
                  size: widget.dense ? 12 : 14,
                  color: widget.isPlaceholder
                      ? colors.inkFaint
                      : colors.inkMuted,
                ),
                const SizedBox(width: Spacing.sm - 2),
              ],
              // Flexible: the value inside a property chip is user data — a
              // project name, an assignee, a label — and these chips sit in a
              // wrap inside a phone-width sheet. A long value has to shrink
              // rather than run past the edge of its own chip.
              Flexible(
                child: DefaultTextStyle.merge(
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style:
                      (widget.dense
                              ? context.textStyles.labelSmall
                              : context.textStyles.labelMedium)!
                          .copyWith(
                            color: widget.isPlaceholder
                                ? colors.inkFaint
                                : colors.inkSoft,
                          ),
                  child: widget.child,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return widget.tooltip == null
        ? body
        : Tooltip(message: widget.tooltip!, child: body);
  }
}

class StatusPicker extends StatelessWidget {
  const StatusPicker({
    required this.value,
    required this.onChanged,
    this.dense = false,
    super.key,
  });

  final TaskStatus value;
  final ValueChanged<TaskStatus> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return AppSelectMenu<TaskStatus>(
      selected: value,
      options: <MenuOption<TaskStatus>>[
        for (final TaskStatus status in TaskStatus.values)
          MenuOption<TaskStatus>(
            value: status,
            label: status.label(context.l10n),
            icon: status.icon,
            color: status.color(context.colors),
          ),
      ],
      onSelected: onChanged,
      builder: (BuildContext context, VoidCallback open) => PropertyTrigger(
        onTap: open,
        dense: dense,
        tooltip: context.l10n.fieldStatus,
        child: StatusPill(status: value, compact: dense),
      ),
    );
  }
}

class PriorityPicker extends StatelessWidget {
  const PriorityPicker({
    required this.value,
    required this.onChanged,
    this.dense = false,
    super.key,
  });

  final TaskPriority value;
  final ValueChanged<TaskPriority> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return AppSelectMenu<TaskPriority>(
      selected: value,
      options: <MenuOption<TaskPriority>>[
        for (final TaskPriority priority in TaskPriority.values)
          MenuOption<TaskPriority>(
            value: priority,
            label: priority.label(context.l10n),
            icon: priority.icon,
            color: priority.color(context.colors),
          ),
      ],
      onSelected: onChanged,
      builder: (BuildContext context, VoidCallback open) => PropertyTrigger(
        onTap: open,
        dense: dense,
        tooltip: context.l10n.fieldPriority,
        child: PriorityPill(priority: value, compact: dense),
      ),
    );
  }
}

class AssigneePicker extends ConsumerWidget {
  const AssigneePicker({
    required this.value,
    required this.onChanged,
    this.dense = false,
    super.key,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<User> members =
        ref.watch(membersProvider).value ?? const <User>[];
    final User? selected = members.where((User u) => u.id == value).firstOrNull;

    return AppSelectMenu<String>(
      selected: value ?? '',
      options: <MenuOption<String>>[
        MenuOption<String>(
          value: '',
          label: context.l10n.fieldUnassigned,
          icon: AppIcons.assignee,
        ),
        for (final User member in members)
          MenuOption<String>(
            value: member.id,
            label: member.name,
            icon: AppIcons.assignee,
            trailing: AppAvatar(user: member, size: 20, showTooltip: false),
          ),
      ],
      onSelected: (String id) => onChanged(id.isEmpty ? null : id),
      builder: (BuildContext context, VoidCallback open) => PropertyTrigger(
        onTap: open,
        dense: dense,
        isPlaceholder: selected == null,
        tooltip: context.l10n.fieldAssignee,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppAvatar(
              user: selected,
              size: dense ? 16 : 18,
              showTooltip: false,
            ),
            const SizedBox(width: Spacing.sm - 2),
            Text(selected?.firstName ?? context.l10n.fieldUnassigned),
          ],
        ),
      ),
    );
  }
}

class ProjectPicker extends ConsumerWidget {
  const ProjectPicker({
    required this.value,
    required this.onChanged,
    this.dense = false,
    super.key,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Project> projects =
        ref.watch(projectsProvider).value ?? const <Project>[];
    final Project? selected = projects
        .where((Project p) => p.id == value)
        .firstOrNull;

    return AppSelectMenu<String>(
      selected: value ?? '',
      options: <MenuOption<String>>[
        MenuOption<String>(
          value: '',
          label: context.l10n.fieldNoProject,
          icon: AppIcons.projects,
        ),
        for (final Project project in projects)
          MenuOption<String>(
            value: project.id,
            label: project.name,
            icon: AppIcons.projects,
            color: Color(project.colorValue),
          ),
      ],
      onSelected: (String id) => onChanged(id.isEmpty ? null : id),
      builder: (BuildContext context, VoidCallback open) => PropertyTrigger(
        onTap: open,
        dense: dense,
        isPlaceholder: selected == null,
        tooltip: context.l10n.fieldProject,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (selected != null) ...<Widget>[
              Text(
                selected.iconEmoji,
                style: TextStyle(fontSize: dense ? 11 : 12),
              ),
              const SizedBox(width: Spacing.xs + 1),
            ] else ...<Widget>[
              Icon(
                AppIcons.projects,
                size: dense ? 12 : 14,
                color: context.colors.inkFaint,
              ),
              const SizedBox(width: Spacing.sm - 2),
            ],
            // Flexible rather than a fixed 130px cap: 130 is fine beside a
            // desktop form and too wide for a 320px sheet, where the emoji and
            // padding leave less than that. Letting the name take what is
            // actually left adapts to both.
            Flexible(
              child: Text(
                selected?.name ?? context.l10n.fieldNoProject,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Multi-select label picker. Opens a sheet rather than a menu because
/// selecting several items from a menu that closes on each tap is miserable.
class LabelPicker extends ConsumerWidget {
  const LabelPicker({
    required this.selectedIds,
    required this.onChanged,
    this.dense = false,
    super.key,
  });

  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Label> labels =
        ref.watch(labelsProvider).value ?? const <Label>[];
    final List<Label> selected = labels
        .where((Label l) => selectedIds.contains(l.id))
        .toList();

    return PropertyTrigger(
      dense: dense,
      isPlaceholder: selected.isEmpty,
      icon: selected.isEmpty ? AppIcons.label : null,
      tooltip: context.l10n.fieldLabels,
      onTap: () => _open(context, labels),
      child: selected.isEmpty
          ? Text(context.l10n.fieldLabels)
          : Wrap(
              spacing: 4,
              children: <Widget>[
                for (final Label label in selected.take(3))
                  LabelChip(label: label),
                if (selected.length > 3)
                  Text(
                    '+${selected.length - 3}',
                    style: context.textStyles.labelSmall?.copyWith(
                      color: context.colors.inkFaint,
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _open(BuildContext context, List<Label> labels) async {
    final List<String> working = <String>[...selectedIds];
    await showAppSheet<void>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SheetHeader(title: context.l10n.fieldLabels),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(Spacing.md),
                children: <Widget>[
                  for (final Label label in labels)
                    CheckboxListTile(
                      value: working.contains(label.id),
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked ?? false) {
                            working.add(label.id);
                          } else {
                            working.remove(label.id);
                          }
                        });
                        onChanged(<String>[...working]);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Row(
                        children: <Widget>[
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: Color(label.colorValue),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Text(label.name),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Date picker trigger with quick options (today, tomorrow, next week) above
/// the calendar — the three choices that cover most scheduling.
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    required this.value,
    required this.onChanged,
    required this.label,
    this.icon = AppIcons.dueDate,
    this.dense = false,
    this.firstDate,
    super.key,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String label;
  final IconData icon;
  final bool dense;
  final DateTime? firstDate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool overdue = value != null && Dates.isPast(value!);

    return AppSelectMenu<String>(
      options: <MenuOption<String>>[
        MenuOption<String>(
          value: 'today',
          label: context.l10n.timeToday,
          icon: AppIcons.dueDate,
        ),
        MenuOption<String>(
          value: 'tomorrow',
          label: context.l10n.timeTomorrow,
          icon: AppIcons.dueDate,
        ),
        const MenuOption<String>(
          value: 'nextWeek',
          label: 'Next week',
          icon: AppIcons.dueDate,
        ),
        const MenuOption<String>(
          value: 'pick',
          label: 'Pick a date…',
          icon: AppIcons.calendar,
        ),
        if (value != null)
          MenuOption<String>(
            value: 'clear',
            label: context.l10n.actionClear,
            icon: AppIcons.close,
            isDestructive: true,
          ),
      ],
      onSelected: (String choice) async {
        final DateTime today = Dates.today();
        switch (choice) {
          case 'today':
            onChanged(today);
          case 'tomorrow':
            onChanged(today.add(const Duration(days: 1)));
          case 'nextWeek':
            onChanged(today.add(const Duration(days: 7)));
          case 'clear':
            onChanged(null);
          case 'pick':
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: value ?? today,
              firstDate: firstDate ?? DateTime(today.year - 2),
              lastDate: DateTime(today.year + 5),
            );
            if (picked != null) onChanged(Dates.dayOf(picked));
        }
      },
      builder: (BuildContext context, VoidCallback open) => PropertyTrigger(
        onTap: open,
        dense: dense,
        icon: icon,
        isPlaceholder: value == null,
        tooltip: label,
        child: Text(
          value == null ? label : Dates.dueLabel(value, context.l10n),
          style: overdue ? TextStyle(color: colors.danger) : null,
        ),
      ),
    );
  }
}
