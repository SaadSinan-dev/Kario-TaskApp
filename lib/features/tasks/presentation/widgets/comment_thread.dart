import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/utils/date_utils.dart';
import 'package:kairo/core/widgets/app_avatar.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/core/widgets/app_overlays.dart';
import 'package:kairo/core/widgets/app_skeleton.dart';
import 'package:kairo/core/widgets/app_states.dart';
import 'package:kairo/domain/entities/collaboration.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/features/tasks/presentation/widgets/markdown_renderer.dart';
import 'package:kairo/features/tasks/presentation/widgets/rich_text_editor.dart';

/// The conversation on a task.
///
/// One level of threading, inline editing, and emoji reactions. Replies render
/// indented under their parent rather than as a tree — task discussions are
/// short, and a deep tree makes them harder to read, not easier.
class CommentThread extends ConsumerWidget {
  const CommentThread({required this.taskId, super.key});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Comment>> comments = ref.watch(
      commentsProvider(taskId),
    );
    final Map<String, User> members = ref.watch(membersByIdProvider);

    return comments.when(
      loading: () => SkeletonList(
        count: 2,
        separator: Spacing.lg,
        itemBuilder: (BuildContext context) => const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Skeleton.circle(size: 28),
            SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Skeleton(width: 120, height: 11),
                  SizedBox(height: Spacing.sm),
                  Skeleton(height: 11),
                  SizedBox(height: 6),
                  Skeleton(width: 220, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
      error: (Object error, _) => InlineError(
        message: context.l10n.errorGenericBody,
        onRetry: () => ref.invalidate(commentsProvider(taskId)),
      ),
      data: (List<Comment> all) {
        final List<Comment> roots = all
            .where((Comment c) => c.replyToId == null)
            .toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (all.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                child: Text(
                  context.l10n.emptyCommentsBody,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.inkFaint,
                  ),
                ),
              ),
            for (int i = 0; i < roots.length; i++)
              Entrance(
                index: i,
                child: _CommentBranch(
                  comment: roots[i],
                  replies: all
                      .where((Comment c) => c.replyToId == roots[i].id)
                      .toList(growable: false),
                  members: members,
                  taskId: taskId,
                ),
              ),
            const SizedBox(height: Spacing.md),
            CommentComposer(taskId: taskId),
          ],
        );
      },
    );
  }
}

class _CommentBranch extends StatelessWidget {
  const _CommentBranch({
    required this.comment,
    required this.replies,
    required this.members,
    required this.taskId,
  });

  final Comment comment;
  final List<Comment> replies;
  final Map<String, User> members;
  final String taskId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          CommentTile(comment: comment, members: members, taskId: taskId),
          for (final Comment reply in replies)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: Spacing.huge,
                top: Spacing.md,
              ),
              child: CommentTile(
                comment: reply,
                members: members,
                taskId: taskId,
                isReply: true,
              ),
            ),
        ],
      ),
    );
  }
}

class CommentTile extends ConsumerStatefulWidget {
  const CommentTile({
    required this.comment,
    required this.members,
    required this.taskId,
    this.isReply = false,
    super.key,
  });

  final Comment comment;
  final Map<String, User> members;
  final String taskId;
  final bool isReply;

  @override
  ConsumerState<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends ConsumerState<CommentTile> {
  bool _editing = false;
  bool _replying = false;
  bool _hovered = false;
  late final TextEditingController _editController = TextEditingController(
    text: widget.comment.body,
  );

  static const List<String> _quickReactions = <String>[
    '👍',
    '🎯',
    '🔥',
    '👏',
    '🙌',
    '🤔',
  ];

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Comment comment = widget.comment;
    final User? author = widget.members[comment.authorId];
    final String? currentUserId = ref.watch(currentUserValueProvider)?.id;
    final bool isMine = currentUserId == comment.authorId;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppAvatar(user: author, size: widget.isReply ? 24 : 28),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          author?.name ?? 'Unknown',
                          style: context.textStyles.titleSmall,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          Dates.relative(comment.createdAt, context.l10n),
                          style: context.textStyles.labelSmall?.copyWith(
                            color: colors.inkFaint,
                          ),
                        ),
                        if (comment.isEdited) ...<Widget>[
                          const SizedBox(width: Spacing.xs),
                          Text(
                            '· edited',
                            style: context.textStyles.labelSmall?.copyWith(
                              color: colors.inkFaint,
                            ),
                          ),
                        ],
                        const Spacer(),
                        AnimatedOpacity(
                          opacity: _hovered ? 1 : 0,
                          duration: context.motion(Motion.fast),
                          child: _CommentActions(
                            canModify: isMine,
                            onReply: () => setState(() => _replying = true),
                            onEdit: () => setState(() => _editing = true),
                            onDelete: () => _confirmDelete(context),
                            onReact: () => _showReactionPicker(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xs + 1),
                    if (_editing)
                      _EditBox(
                        controller: _editController,
                        onCancel: () => setState(() {
                          _editing = false;
                          _editController.text = comment.body;
                        }),
                        onSave: () async {
                          await ref
                              .read(commentRepositoryProvider)
                              .editComment(comment.id, _editController.text);
                          if (mounted) setState(() => _editing = false);
                        },
                      )
                    else
                      MarkdownBody(
                        comment.body,
                        compact: true,
                        baseStyle: context.textStyles.bodyMedium?.copyWith(
                          color: colors.inkSoft,
                          height: 1.55,
                        ),
                      ),
                    if (comment.reactions.isNotEmpty) ...<Widget>[
                      const SizedBox(height: Spacing.sm),
                      Wrap(
                        spacing: Spacing.xs + 2,
                        children: <Widget>[
                          for (final Reaction reaction in comment.reactions)
                            _ReactionPill(
                              reaction: reaction,
                              isMine:
                                  currentUserId != null &&
                                  reaction.reactedBy(currentUserId),
                              onTap: () => _toggleReaction(reaction.emoji),
                            ),
                          _AddReactionButton(
                            onTap: () => _showReactionPicker(context),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (_replying)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: Spacing.huge,
                top: Spacing.md,
              ),
              child: CommentComposer(
                taskId: widget.taskId,
                replyToId: comment.id,
                autofocus: true,
                onDone: () => setState(() => _replying = false),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleReaction(String emoji) {
    final String? userId = ref.read(currentUserValueProvider)?.id;
    if (userId == null) return;
    ref
        .read(commentRepositoryProvider)
        .toggleReaction(
          commentId: widget.comment.id,
          emoji: emoji,
          userId: userId,
        );
  }

  Future<void> _showReactionPicker(BuildContext context) async {
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final Offset origin = box.localToGlobal(Offset.zero);
    final String? emoji = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        origin.dx + 40,
        origin.dy,
        origin.dx + 240,
        origin.dy + 40,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          height: 40,
          child: Row(
            children: <Widget>[
              for (final String emoji in _quickReactions)
                InkWell(
                  onTap: () => Navigator.of(context).pop(emoji),
                  borderRadius: Radii.brSm,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(emoji, style: const TextStyle(fontSize: 18)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    if (emoji != null) _toggleReaction(emoji);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bool confirmed = await confirmAction(
      context: context,
      title: 'Delete this comment?',
      message: 'It will be removed for everyone on this task.',
      confirmLabel: context.l10n.actionDelete,
    );
    if (!confirmed) return;
    await ref.read(commentRepositoryProvider).deleteComment(widget.comment.id);
  }
}

class _EditBox extends StatelessWidget {
  const _EditBox({
    required this.controller,
    required this.onCancel,
    required this.onSave,
  });

  final TextEditingController controller;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        RichTextEditor(
          controller: controller,
          minLines: 2,
          maxLines: 8,
          showPreviewToggle: false,
        ),
        const SizedBox(height: Spacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            AppButton(
              label: context.l10n.actionCancel,
              size: AppButtonSize.small,
              variant: AppButtonVariant.ghost,
              onPressed: onCancel,
            ),
            const SizedBox(width: Spacing.sm),
            AppButton.primary(
              label: context.l10n.actionSave,
              size: AppButtonSize.small,
              onPressed: onSave,
            ),
          ],
        ),
      ],
    );
  }
}

class _CommentActions extends StatelessWidget {
  const _CommentActions({
    required this.canModify,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    required this.onReact,
  });

  final bool canModify;
  final VoidCallback onReply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppIconButton(
          icon: AppIcons.reaction,
          tooltip: 'React',
          size: 26,
          iconSize: 14,
          onPressed: onReact,
        ),
        AppIconButton(
          icon: AppIcons.comment,
          tooltip: 'Reply',
          size: 26,
          iconSize: 14,
          onPressed: onReply,
        ),
        if (canModify) ...<Widget>[
          AppIconButton(
            icon: AppIcons.edit,
            tooltip: context.l10n.actionEdit,
            size: 26,
            iconSize: 14,
            onPressed: onEdit,
          ),
          AppIconButton(
            icon: AppIcons.delete,
            tooltip: context.l10n.actionDelete,
            size: 26,
            iconSize: 14,
            onPressed: onDelete,
          ),
        ],
      ],
    );
  }
}

class _ReactionPill extends StatelessWidget {
  const _ReactionPill({
    required this.reaction,
    required this.isMine,
    required this.onTap,
  });

  final Reaction reaction;
  final bool isMine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PressableScale(
      onTap: onTap,
      scale: 0.9,
      child: AnimatedContainer(
        duration: context.motion(Motion.fast),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isMine ? colors.brandSoft : colors.surfaceSunken,
          borderRadius: Radii.brPill,
          border: Border.all(
            color: isMine ? colors.brandBorder : colors.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(reaction.emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              '${reaction.count}',
              style: context.textStyles.labelSmall?.copyWith(
                color: isMine ? colors.brand : colors.inkMuted,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddReactionButton extends StatelessWidget {
  const _AddReactionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PressableScale(
      onTap: onTap,
      scale: 0.9,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: Radii.brPill,
          border: Border.all(color: colors.hairline),
        ),
        child: Icon(AppIcons.reaction, size: 12, color: colors.inkFaint),
      ),
    );
  }
}

/// The write box. Parses `@Name` mentions against workspace members so the
/// notification targets are real people rather than raw text.
class CommentComposer extends ConsumerStatefulWidget {
  const CommentComposer({
    required this.taskId,
    this.replyToId,
    this.autofocus = false,
    this.onDone,
    super.key,
  });

  final String taskId;
  final String? replyToId;
  final bool autofocus;
  final VoidCallback? onDone;

  @override
  ConsumerState<CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends ConsumerState<CommentComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _expanded = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.autofocus;
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && !_expanded) setState(() => _expanded = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String body = _controller.text.trim();
    if (body.isEmpty || _sending) return;

    final String? authorId = ref.read(currentUserValueProvider)?.id;
    if (authorId == null) return;

    setState(() => _sending = true);
    final List<User> members =
        ref.read(membersProvider).value ?? const <User>[];
    final List<String> mentioned = members
        .where(
          (User m) =>
              body.toLowerCase().contains('@${m.name.toLowerCase()}') ||
              body.toLowerCase().contains('@${m.firstName.toLowerCase()}'),
        )
        .map((User m) => m.id)
        .toList(growable: false);

    await ref
        .read(commentRepositoryProvider)
        .addComment(
          taskId: widget.taskId,
          authorId: authorId,
          body: body,
          replyToId: widget.replyToId,
          mentionedUserIds: mentioned,
        );

    if (!mounted) return;
    _controller.clear();
    setState(() {
      _sending = false;
      _expanded = widget.autofocus;
    });
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final User? me = ref.watch(currentUserValueProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppAvatar(user: me, size: 28, showTooltip: false),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              if (_expanded)
                RichTextEditor(
                  controller: _controller,
                  focusNode: _focusNode,
                  minLines: 2,
                  maxLines: 8,
                  showPreviewToggle: false,
                  hint: context.l10n.tasksAddComment,
                )
              else
                _CollapsedField(
                  onTap: () => setState(() {
                    _expanded = true;
                    _focusNode.requestFocus();
                  }),
                ),
              if (_expanded) ...<Widget>[
                const SizedBox(height: Spacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      'Markdown supported · @ to mention',
                      style: monoHint(context),
                    ),
                    const Spacer(),
                    if (widget.onDone != null) ...<Widget>[
                      AppButton(
                        label: context.l10n.actionCancel,
                        size: AppButtonSize.small,
                        variant: AppButtonVariant.ghost,
                        onPressed: widget.onDone,
                      ),
                      const SizedBox(width: Spacing.sm),
                    ],
                    AppButton.primary(
                      label: 'Comment',
                      size: AppButtonSize.small,
                      isLoading: _sending,
                      onPressed: _send,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CollapsedField extends StatelessWidget {
  const _CollapsedField({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: Radii.brMd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.md - 2,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: Radii.brMd,
          border: Border.all(color: colors.hairline),
        ),
        child: Text(
          context.l10n.tasksAddComment,
          style: context.textStyles.bodyMedium?.copyWith(
            color: colors.inkFaint,
          ),
        ),
      ),
    );
  }
}
