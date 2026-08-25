import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/app_avatar.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/core/widgets/app_overlays.dart';
import 'package:kairo/core/widgets/app_text_field.dart';
import 'package:kairo/core/widgets/app_toast.dart';
import 'package:kairo/domain/entities/workspace.dart';

/// The sidebar's identity block: current workspace, plan badge, and a menu to
/// switch or create one.
class WorkspaceSwitcher extends ConsumerWidget {
  const WorkspaceSwitcher({this.collapsed = false, super.key});

  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final Workspace? active = ref.watch(activeWorkspaceProvider).value;
    final List<Workspace> all =
        ref.watch(workspacesProvider).value ?? const <Workspace>[];

    if (active == null) {
      return SizedBox(
        height: 44,
        child: Row(
          children: <Widget>[
            EmojiTile(emoji: '·', colorValue: colors.brand.toARGB32()),
          ],
        ),
      );
    }

    return MenuAnchor(
      alignmentOffset: const Offset(0, 6),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll<Color>(colors.surfaceOverlay),
        surfaceTintColor: const WidgetStatePropertyAll<Color>(
          Colors.transparent,
        ),
        elevation: const WidgetStatePropertyAll<double>(0),
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.symmetric(vertical: Spacing.sm),
        ),
        shape: WidgetStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(
            borderRadius: Radii.brLg,
            side: BorderSide(color: colors.hairline),
          ),
        ),
      ),
      menuChildren: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.md,
            Spacing.xs,
            Spacing.md,
            Spacing.sm,
          ),
          child: Text(
            context.l10n.workspaceSwitch.toUpperCase(),
            style: context.textStyles.labelSmall?.copyWith(
              color: colors.inkFaint,
              fontSize: 10,
              letterSpacing: 0.7,
            ),
          ),
        ),
        for (final Workspace workspace in all)
          MenuItemButton(
            onPressed: () => ref
                .read(workspaceRepositoryProvider)
                .setActiveWorkspace(workspace.id),
            style: const ButtonStyle(
              padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
                EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 2),
              ),
              minimumSize: WidgetStatePropertyAll<Size>(Size(250, 42)),
            ),
            child: Row(
              children: <Widget>[
                EmojiTile(
                  emoji: workspace.iconEmoji,
                  colorValue: workspace.colorValue,
                  size: 26,
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        workspace.name,
                        style: context.textStyles.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${workspace.memberCount} ${context.l10n.workspaceMembers.toLowerCase()}',
                        style: context.textStyles.labelSmall?.copyWith(
                          color: colors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                if (workspace.id == active.id)
                  Icon(AppIcons.check, size: 15, color: colors.brand),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.md,
            Spacing.sm,
            Spacing.md,
            Spacing.xs,
          ),
          child: Divider(color: colors.hairline, height: 1),
        ),
        MenuItemButton(
          onPressed: () => _createWorkspace(context, ref),
          style: const ButtonStyle(
            padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
              EdgeInsets.symmetric(horizontal: Spacing.md),
            ),
            minimumSize: WidgetStatePropertyAll<Size>(Size(250, 36)),
          ),
          child: Row(
            children: <Widget>[
              Icon(AppIcons.add, size: 15, color: colors.inkMuted),
              const SizedBox(width: Spacing.md),
              Text(
                context.l10n.workspaceCreate,
                style: context.textStyles.bodyMedium,
              ),
            ],
          ),
        ),
      ],
      builder: (BuildContext context, MenuController controller, Widget? _) {
        return _SwitcherTrigger(
          workspace: active,
          collapsed: collapsed,
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
        );
      },
    );
  }

  Future<void> _createWorkspace(BuildContext context, WidgetRef ref) async {
    final String createdMessage = context.l10n.toastWorkspaceCreated;
    final TextEditingController controller = TextEditingController();
    final String? name = await showAppDialog<String>(
      context: context,
      maxWidth: 420,
      child: Builder(
        builder: (BuildContext context) => AppDialogShell(
          title: context.l10n.workspaceCreate,
          subtitle: 'Workspaces keep separate projects, people and labels.',
          icon: AppIcons.projects,
          scrollable: false,
          actions: <Widget>[
            AppButton(
              label: context.l10n.actionCancel,
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(),
            ),
            AppButton.primary(
              label: context.l10n.actionCreate,
              onPressed: () => Navigator.of(context).pop(controller.text),
            ),
          ],
          child: AppTextField(
            controller: controller,
            label: 'Workspace name',
            hint: 'Acme Product',
            autofocus: true,
            onSubmitted: (String value) => Navigator.of(context).pop(value),
          ),
        ),
      ),
    );
    controller.dispose();

    if (name == null || name.trim().isEmpty) return;
    final String? ownerId = ref.read(currentUserValueProvider)?.id;
    if (ownerId == null) return;

    await ref
        .read(workspaceRepositoryProvider)
        .createWorkspace(name: name, ownerId: ownerId);
    ref.toasts.success(createdMessage);
  }
}

class _SwitcherTrigger extends StatefulWidget {
  const _SwitcherTrigger({
    required this.workspace,
    required this.collapsed,
    required this.onTap,
  });

  final Workspace workspace;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  State<_SwitcherTrigger> createState() => _SwitcherTriggerState();
}

class _SwitcherTriggerState extends State<_SwitcherTrigger> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: context.motion(Motion.fast),
          padding: const EdgeInsets.all(Spacing.sm - 2),
          decoration: BoxDecoration(
            color: _hovered ? colors.surfaceSunken : Colors.transparent,
            borderRadius: Radii.brMd,
          ),
          child: Row(
            children: <Widget>[
              EmojiTile(
                emoji: widget.workspace.iconEmoji,
                colorValue: widget.workspace.colorValue,
                size: 30,
              ),
              if (!widget.collapsed) ...<Widget>[
                const SizedBox(width: Spacing.md - 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        widget.workspace.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.titleSmall,
                      ),
                      Text(
                        widget.workspace.plan == 'free'
                            ? 'Free plan'
                            : '${widget.workspace.plan[0].toUpperCase()}'
                                  '${widget.workspace.plan.substring(1)} plan',
                        style: context.textStyles.labelSmall?.copyWith(
                          color: colors.inkFaint,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(AppIcons.chevronDown, size: 14, color: colors.inkFaint),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
