import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/utils/date_utils.dart';
import 'package:kairo/core/utils/id_generator.dart';
import 'package:kairo/core/utils/validators.dart';
import 'package:kairo/core/widgets/app_badge.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/core/widgets/app_overlays.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/recurrence.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/features/tasks/application/task_actions.dart';
import 'package:kairo/features/tasks/presentation/widgets/property_pickers.dart';
import 'package:kairo/features/tasks/presentation/widgets/recurrence_picker.dart';
import 'package:kairo/features/tasks/presentation/widgets/rich_text_editor.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';

/// Opens the create/edit form — a dialog on desktop, a sheet on mobile.
///
/// One entry point for every create affordance in the app (sidebar button, top
/// bar, command palette, board column, calendar day, keyboard shortcut) so the
/// creation experience never diverges.
Future<void> openTaskComposer(
  BuildContext context,
  WidgetRef ref, {
  Task? task,
  String? projectId,
  TaskStatus? status,
  DateTime? dueDate,
  String? assigneeId,
}) {
  final Task initial =
      task ??
      draftTask(
        ref,
        projectId: projectId,
        status: status ?? TaskStatus.todo,
        dueDate: dueDate,
        assigneeId: assigneeId,
      );

  if (context.isCompact) {
    return showAppSheet<void>(
      context: context,
      expand: true,
      initialSize: 0.9,
      builder: (BuildContext context) =>
          TaskComposer(initial: initial, isEditing: task != null),
    );
  }

  return showAppDialog<void>(
    context: context,
    maxWidth: 660,
    child: TaskComposer(initial: initial, isEditing: task != null),
  );
}

class TaskComposer extends ConsumerStatefulWidget {
  const TaskComposer({
    required this.initial,
    required this.isEditing,
    super.key,
  });

  final Task initial;
  final bool isEditing;

  @override
  ConsumerState<TaskComposer> createState() => _TaskComposerState();
}

class _TaskComposerState extends ConsumerState<TaskComposer> {
  late final TextEditingController _title = TextEditingController(
    text: widget.initial.title,
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.initial.description,
  );
  late final TextEditingController _estimate = TextEditingController(
    text: widget.initial.estimateMinutes == null
        ? ''
        : Dates.duration(widget.initial.estimateMinutes!),
  );

  final FocusNode _titleFocus = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late Task _task = widget.initial;
  bool _showDescription = false;
  bool _submitting = false;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    _showDescription = widget.initial.description.isNotEmpty;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _estimate.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _patch(Task Function(Task task) transform) =>
      setState(() => _task = transform(_task));

  Future<void> _submit() async {
    final String title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = context.l10n.validationRequired);
      _titleFocus.requestFocus();
      return;
    }
    if (title.length > Validators.maxTitleLength) {
      setState(
        () => _titleError = context.l10n.validationTooLong(
          Validators.maxTitleLength,
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _titleError = null;
    });

    final Task payload = _task.copyWith(
      title: title,
      description: _description.text,
      estimateMinutes: Validators.parseEstimateMinutes(_estimate.text),
      clearEstimate: _estimate.text.trim().isEmpty,
    );

    final AppL10n l10n = context.l10n;
    final TaskActions actions = ref.read(taskActionsProvider);
    final Task? result = widget.isEditing
        ? await actions.update(l10n: l10n, task: payload)
        : await actions.create(l10n: l10n, draft: payload);

    if (!mounted) return;
    setState(() => _submitting = false);
    if (result != null) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    final Widget body = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _title,
            focusNode: _titleFocus,
            autofocus: true,
            textInputAction: TextInputAction.next,
            maxLines: 2,
            minLines: 1,
            style: context.textStyles.headlineSmall,
            onChanged: (_) {
              if (_titleError != null) setState(() => _titleError = null);
            },
            decoration: InputDecoration(
              hintText: l10n.tasksQuickAddHint,
              hintStyle: context.textStyles.headlineSmall?.copyWith(
                color: colors.inkFaint,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              errorText: _titleError,
            ),
          ),
          const SizedBox(height: Spacing.md),

          if (_showDescription)
            RichTextEditor(
              controller: _description,
              minLines: 3,
              maxLines: 10,
              hint: l10n.editorPlaceholder,
            )
          else
            AppButton(
              label: l10n.fieldDescription,
              icon: AppIcons.docs,
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.small,
              onPressed: () => setState(() => _showDescription = true),
            ),

          const SizedBox(height: Spacing.lg),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: <Widget>[
              StatusPicker(
                value: _task.status,
                onChanged: (TaskStatus value) =>
                    _patch((Task t) => t.copyWith(status: value)),
              ),
              PriorityPicker(
                value: _task.priority,
                onChanged: (TaskPriority value) =>
                    _patch((Task t) => t.copyWith(priority: value)),
              ),
              AssigneePicker(
                value: _task.assigneeId,
                onChanged: (String? value) => _patch(
                  (Task t) => t.copyWith(
                    assigneeId: value,
                    clearAssignee: value == null,
                  ),
                ),
              ),
              ProjectPicker(
                value: _task.projectId,
                onChanged: (String? value) => _patch(
                  (Task t) =>
                      t.copyWith(projectId: value, clearProject: value == null),
                ),
              ),
              DatePickerField(
                value: _task.dueDate,
                label: l10n.fieldDueDate,
                onChanged: (DateTime? value) => _patch(
                  (Task t) =>
                      t.copyWith(dueDate: value, clearDueDate: value == null),
                ),
              ),
              DatePickerField(
                value: _task.startDate,
                label: l10n.fieldStartDate,
                icon: AppIcons.play,
                onChanged: (DateTime? value) => _patch(
                  (Task t) => t.copyWith(
                    startDate: value,
                    clearStartDate: value == null,
                  ),
                ),
              ),
              LabelPicker(
                selectedIds: _task.labelIds,
                onChanged: (List<String> value) =>
                    _patch((Task t) => t.copyWith(labelIds: value)),
              ),
              RecurrencePicker(
                value: _task.recurrence,
                onChanged: (RecurrenceRule value) =>
                    _patch((Task t) => t.copyWith(recurrence: value)),
              ),
              _EstimateField(controller: _estimate),
            ],
          ),

          const SizedBox(height: Spacing.xl),
          _SubtaskEditor(
            subtasks: _task.subtasks,
            onChanged: (List<Subtask> value) =>
                _patch((Task t) => t.copyWith(subtasks: value)),
          ),
        ],
      ),
    );

    final List<Widget> actions = <Widget>[
      AppButton(
        label: l10n.actionCancel,
        variant: AppButtonVariant.ghost,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      AppButton.primary(
        label: widget.isEditing
            ? l10n.actionSaveChanges
            : l10n.actionCreateTask,
        isLoading: _submitting,
        trailingIcon: AppIcons.enterKey,
        onPressed: _submit,
      ),
    ];

    // ⌘/Ctrl + Enter submits from anywhere in the form.
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _submit,
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _submit,
      },
      child: context.isCompact
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SheetHeader(
                  title: widget.isEditing
                      ? l10n.actionEdit
                      : l10n.actionCreateTask,
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
            )
          : AppDialogShell(
              title: widget.isEditing ? l10n.actionEdit : l10n.actionCreateTask,
              icon: AppIcons.tasks,
              actions: actions,
              child: body,
            ),
    );
  }
}

class _EstimateField extends StatelessWidget {
  const _EstimateField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 118,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      decoration: BoxDecoration(
        borderRadius: Radii.brSm,
        border: Border.all(color: colors.hairline),
      ),
      child: Row(
        children: <Widget>[
          Icon(AppIcons.estimate, size: 14, color: colors.inkMuted),
          const SizedBox(width: Spacing.sm - 2),
          Expanded(
            child: TextField(
              controller: controller,
              style: context.textStyles.labelMedium,
              decoration: InputDecoration(
                hintText: context.l10n.fieldEstimate,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintStyle: context.textStyles.labelMedium?.copyWith(
                  color: colors.inkFaint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline subtask list used while composing. The detail panel has its own
/// version that writes through to the repository per change.
class _SubtaskEditor extends StatefulWidget {
  const _SubtaskEditor({required this.subtasks, required this.onChanged});

  final List<Subtask> subtasks;
  final ValueChanged<List<Subtask>> onChanged;

  @override
  State<_SubtaskEditor> createState() => _SubtaskEditorState();
}

class _SubtaskEditorState extends State<_SubtaskEditor> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final String title = _controller.text.trim();
    if (title.isEmpty) return;
    widget.onChanged(<Subtask>[
      ...widget.subtasks,
      Subtask(
        id: Ids.subtask(),
        title: title,
        sortIndex: widget.subtasks.length,
      ),
    ]);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final int done = widget.subtasks.where((Subtask s) => s.isDone).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(AppIcons.subtasks, size: 14, color: colors.inkMuted),
            const SizedBox(width: Spacing.sm),
            Text(
              context.l10n.fieldSubtasks,
              style: context.textStyles.labelMedium,
            ),
            if (widget.subtasks.isNotEmpty) ...<Widget>[
              const SizedBox(width: Spacing.sm),
              AppBadge(
                label: context.l10n.tasksSubtaskProgress(
                  done,
                  widget.subtasks.length,
                ),
                compact: true,
              ),
            ],
          ],
        ),
        const SizedBox(height: Spacing.sm),
        for (final Subtask subtask in widget.subtasks)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: <Widget>[
                Checkbox(
                  value: subtask.isDone,
                  visualDensity: VisualDensity.compact,
                  onChanged: (bool? value) => widget.onChanged(
                    widget.subtasks
                        .map(
                          (Subtask s) => s.id == subtask.id
                              ? s.copyWith(isDone: value ?? false)
                              : s,
                        )
                        .toList(),
                  ),
                ),
                Expanded(
                  child: Text(
                    subtask.title,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: subtask.isDone ? colors.inkFaint : colors.ink,
                      decoration: subtask.isDone
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(AppIcons.close, size: 13),
                  splashRadius: 14,
                  color: colors.inkFaint,
                  tooltip: context.l10n.actionRemove,
                  onPressed: () => widget.onChanged(
                    widget.subtasks
                        .where((Subtask s) => s.id != subtask.id)
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: <Widget>[
            const SizedBox(width: Spacing.xs),
            Icon(AppIcons.add, size: 14, color: colors.inkFaint),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _add(),
                style: context.textStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: context.l10n.tasksAddSubtask,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
