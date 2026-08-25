import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/error/failure.dart';
import 'package:kairo/core/error/failure_messages.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/presentation/enum_presentation.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/app_palette.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/app_avatar.dart';
import 'package:kairo/core/widgets/app_badge.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/core/widgets/app_overlays.dart';
import 'package:kairo/core/widgets/app_text_field.dart';
import 'package:kairo/core/widgets/app_toast.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/features/tasks/presentation/widgets/property_pickers.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';

/// Create or edit a project.
Future<void> openProjectEditor(
  BuildContext context,
  WidgetRef ref, {
  Project? project,
}) {
  final String workspaceId = ref.read(activeWorkspaceIdProvider) ?? '';
  final DateTime now = DateTime.now();
  final Project initial =
      project ??
      Project(
        id: '',
        workspaceId: workspaceId,
        name: '',
        createdAt: now,
        updatedAt: now,
        leadId: ref.read(currentUserValueProvider)?.id,
      );

  if (context.isCompact) {
    return showAppSheet<void>(
      context: context,
      expand: true,
      initialSize: 0.86,
      builder: (BuildContext context) =>
          _ProjectEditor(initial: initial, isEditing: project != null),
    );
  }

  return showAppDialog<void>(
    context: context,
    maxWidth: 620,
    child: _ProjectEditor(initial: initial, isEditing: project != null),
  );
}

class _ProjectEditor extends ConsumerStatefulWidget {
  const _ProjectEditor({required this.initial, required this.isEditing});

  final Project initial;
  final bool isEditing;

  @override
  ConsumerState<_ProjectEditor> createState() => _ProjectEditorState();
}

class _ProjectEditorState extends ConsumerState<_ProjectEditor> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial.name,
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.initial.description,
  );

  late Project _project = widget.initial;
  bool _submitting = false;
  String? _error;

  static const List<String> _emojiChoices = <String>[
    '🚀',
    '📱',
    '📣',
    '🌐',
    '📈',
    '🎨',
    '🧪',
    '🛠️',
    '📚',
    '💡',
    '🧭',
    '🏗️',
  ];

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = context.l10n.validationRequired);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final AppL10n l10n = context.l10n;
    final Project payload = _project.copyWith(
      name: name,
      description: _description.text.trim(),
    );

    try {
      if (widget.isEditing) {
        await ref.read(projectRepositoryProvider).updateProject(payload);
        ref.toasts.success(l10n.toastProjectUpdated, description: name);
      } else {
        await ref.read(projectRepositoryProvider).createProject(payload);
        ref.toasts.success(l10n.toastProjectCreated, description: name);
      }
      if (mounted) Navigator.of(context).maybePop();
    } on Failure catch (failure) {
      final FailureMessage message = failure.describe(l10n);
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = message.body;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l10n = context.l10n;
    final List<User> members =
        ref.watch(membersProvider).value ?? const <User>[];

    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            _EmojiPicker(
              value: _project.iconEmoji,
              colorValue: _project.colorValue,
              choices: _emojiChoices,
              onChanged: (String emoji) => setState(
                () => _project = _project.copyWith(iconEmoji: emoji),
              ),
            ),
            const SizedBox(width: Spacing.lg),
            Expanded(
              child: AppTextField(
                controller: _name,
                label: 'Project name',
                hint: 'Mobile App Redesign',
                autofocus: true,
                errorText: _error,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _submit(),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        AppTextField(
          controller: _description,
          label: l10n.fieldDescription,
          hint: 'What is this project for, and what does done look like?',
          maxLines: 3,
          minLines: 2,
        ),
        const SizedBox(height: Spacing.lg),
        Text('Colour', style: context.textStyles.labelMedium),
        const SizedBox(height: Spacing.sm),
        _ColorPicker(
          value: _project.colorValue,
          onChanged: (int value) =>
              setState(() => _project = _project.copyWith(colorValue: value)),
        ),
        const SizedBox(height: Spacing.lg),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: <Widget>[
            AppSelectMenu<ProjectStatus>(
              selected: _project.status,
              options: <MenuOption<ProjectStatus>>[
                for (final ProjectStatus status in ProjectStatus.values)
                  MenuOption<ProjectStatus>(
                    value: status,
                    label: status.label(l10n),
                    icon: AppIcons.projects,
                    color: status.color(context.colors),
                  ),
              ],
              onSelected: (ProjectStatus value) =>
                  setState(() => _project = _project.copyWith(status: value)),
              builder: (BuildContext context, VoidCallback open) =>
                  PropertyTrigger(
                    onTap: open,
                    icon: AppIcons.projects,
                    tooltip: l10n.fieldStatus,
                    child: Text(_project.status.label(l10n)),
                  ),
            ),
            DatePickerField(
              value: _project.startDate,
              label: l10n.fieldStartDate,
              icon: AppIcons.play,
              onChanged: (DateTime? value) => setState(
                () => _project = _project.copyWith(
                  startDate: value,
                  clearStartDate: value == null,
                ),
              ),
            ),
            DatePickerField(
              value: _project.dueDate,
              label: l10n.fieldDueDate,
              onChanged: (DateTime? value) => setState(
                () => _project = _project.copyWith(
                  dueDate: value,
                  clearDueDate: value == null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        Text(l10n.projectsMembers, style: context.textStyles.labelMedium),
        const SizedBox(height: Spacing.sm),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: <Widget>[
            for (final User member in members)
              _MemberToggle(
                member: member,
                selected: _project.memberIds.contains(member.id),
                onTap: () => setState(() {
                  final List<String> next = <String>[..._project.memberIds];
                  if (!next.remove(member.id)) next.add(member.id);
                  _project = _project.copyWith(memberIds: next);
                }),
              ),
          ],
        ),
      ],
    );

    final List<Widget> actions = <Widget>[
      AppButton(
        label: l10n.actionCancel,
        variant: AppButtonVariant.ghost,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      AppButton.primary(
        label: widget.isEditing ? l10n.actionSaveChanges : l10n.actionCreate,
        isLoading: _submitting,
        onPressed: _submit,
      ),
    ];

    if (context.isCompact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SheetHeader(
            title: widget.isEditing
                ? l10n.actionEdit
                : l10n.actionCreateProject,
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.lg),
              child: body,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Row(
                children: <Widget>[
                  Expanded(child: actions[0]),
                  const SizedBox(width: Spacing.sm),
                  Expanded(flex: 2, child: actions[1]),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return AppDialogShell(
      title: widget.isEditing ? l10n.actionEdit : l10n.actionCreateProject,
      subtitle:
          'Projects group related work and give you progress at a glance.',
      icon: AppIcons.projects,
      actions: actions,
      child: body,
    );
  }
}

class _EmojiPicker extends StatelessWidget {
  const _EmojiPicker({
    required this.value,
    required this.colorValue,
    required this.choices,
    required this.onChanged,
  });

  final String value;
  final int colorValue;
  final List<String> choices;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppSelectMenu<String>(
      selected: value,
      options: <MenuOption<String>>[
        for (final String emoji in choices)
          MenuOption<String>(value: emoji, label: emoji),
      ],
      onSelected: onChanged,
      builder: (BuildContext context, VoidCallback open) => Tooltip(
        message: 'Choose an icon',
        child: InkWell(
          onTap: open,
          borderRadius: Radii.brMd,
          child: EmojiTile(emoji: value, colorValue: colorValue, size: 46),
        ),
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: <Widget>[
        for (final Color color in AppPalette.selectable)
          PressableScale(
            onTap: () => onChanged(color.toARGB32()),
            scale: 0.88,
            child: AnimatedContainer(
              duration: context.motion(Motion.fast),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.toARGB32() == value
                      ? context.colors.ink
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: color.toARGB32() == value
                  ? const Icon(AppIcons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ),
      ],
    );
  }
}

class _MemberToggle extends StatelessWidget {
  const _MemberToggle({
    required this.member,
    required this.selected,
    required this.onTap,
  });

  final User member;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: context.motion(Motion.fast),
        padding: const EdgeInsets.fromLTRB(4, 4, Spacing.md, 4),
        decoration: BoxDecoration(
          color: selected ? colors.brandSoft : colors.surface,
          borderRadius: Radii.brPill,
          border: Border.all(
            color: selected ? colors.brandBorder : colors.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppAvatar(user: member, size: 22, showTooltip: false),
            const SizedBox(width: Spacing.sm),
            Text(
              member.firstName,
              style: context.textStyles.labelMedium?.copyWith(
                color: selected ? colors.brand : colors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared confirmation used by the project list and detail screens.
Future<bool> showDeleteConfirmation(
  BuildContext context,
  Project project,
  String message,
) {
  return confirmAction(
    context: context,
    title: 'Delete “${project.name}”?',
    message: message,
    confirmLabel: context.l10n.actionDelete,
    icon: AppIcons.delete,
  );
}

/// Small status chip reused on the project header.
class ProjectStatusBadge extends StatelessWidget {
  const ProjectStatusBadge({required this.status, super.key});

  final ProjectStatus status;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: status.label(context.l10n),
      color: status.color(context.colors),
      icon: AppIcons.projects,
    );
  }
}
