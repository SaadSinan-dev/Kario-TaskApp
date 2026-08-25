import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/presentation/enum_presentation.dart';
import 'package:kairo/core/responsive/breakpoints.dart';
import 'package:kairo/core/routing/routes.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/utils/validators.dart';
import 'package:kairo/core/widgets/app_avatar.dart';
import 'package:kairo/core/widgets/app_badge.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/core/widgets/app_overlays.dart';
import 'package:kairo/core/widgets/app_states.dart';
import 'package:kairo/core/widgets/app_text_field.dart';
import 'package:kairo/core/widgets/app_toast.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/preferences.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/domain/entities/workspace.dart';
import 'package:kairo/features/command_palette/presentation/shortcuts_dialog.dart';
import 'package:kairo/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:kairo/features/shell/presentation/app_shell.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';

/// Settings.
///
/// A left rail of sections on wide screens, a single scrolling list of sections
/// on narrow ones. The URL carries the section (`/settings/appearance`) so a
/// specific setting is linkable — which is what makes "see Settings → Data"
/// a useful sentence in documentation.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({required this.section, super.key});

  final SettingsSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l10n = context.l10n;
    final bool wide = context.breakpoint.index >= ScreenSize.expanded.index;

    final Widget content = _SectionBody(section: section);

    return ShellPage(
      title: l10n.settingsTitle,
      subtitle: _title(section, l10n),
      padded: false,
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(width: 232, child: _SectionRail(active: section)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(Spacing.xxl),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: content,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                context.gutter,
                Spacing.lg,
                context.gutter,
                Spacing.huge,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _SectionChips(active: section),
                  const SizedBox(height: Spacing.lg),
                  content,
                ],
              ),
            ),
    );
  }

  static String _title(SettingsSection section, AppL10n l10n) =>
      switch (section) {
        SettingsSection.profile => l10n.settingsProfile,
        SettingsSection.workspace => l10n.settingsWorkspace,
        SettingsSection.appearance => l10n.settingsAppearance,
        SettingsSection.notifications => l10n.settingsNotifications,
        SettingsSection.shortcuts => l10n.settingsShortcuts,
        SettingsSection.preferences => l10n.settingsPreferences,
        SettingsSection.security => l10n.settingsSecurity,
        SettingsSection.data => l10n.settingsData,
      };

  static IconData _icon(SettingsSection section) => switch (section) {
    SettingsSection.profile => AppIcons.assignee,
    SettingsSection.workspace => AppIcons.projects,
    SettingsSection.appearance => AppIcons.appearance,
    SettingsSection.notifications => AppIcons.notifications,
    SettingsSection.shortcuts => AppIcons.command,
    SettingsSection.preferences => AppIcons.settings,
    SettingsSection.security => AppIcons.security,
    SettingsSection.data => AppIcons.data,
  };
}

class _SectionRail extends StatelessWidget {
  const _SectionRail({required this.active});

  final SettingsSection active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        border: BorderDirectional(end: BorderSide(color: colors.hairline)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: <Widget>[
          for (final SettingsSection section in SettingsSection.values)
            _RailItem(
              section: section,
              isActive: section == active,
              onTap: () => context.go(Routes.settingsFor(section.slug)),
            ),
        ],
      ),
    );
  }
}

class _RailItem extends StatefulWidget {
  const _RailItem({
    required this.section,
    required this.isActive,
    required this.onTap,
  });

  final SettingsSection section;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
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
        child: Container(
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? colors.brandSoft
                : (_hovered ? colors.surfaceSunken : Colors.transparent),
            borderRadius: Radii.brSm,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                SettingsScreen._icon(widget.section),
                size: 15,
                color: widget.isActive ? colors.brand : colors.inkMuted,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  SettingsScreen._title(widget.section, context.l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.labelLarge?.copyWith(
                    color: widget.isActive ? colors.brand : colors.inkSoft,
                    fontWeight: widget.isActive
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionChips extends StatelessWidget {
  const _SectionChips({required this.active});

  final SettingsSection active;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (final SettingsSection section in SettingsSection.values)
            Padding(
              padding: const EdgeInsets.only(right: Spacing.sm),
              child: AppFilterChip(
                label: SettingsScreen._title(section, context.l10n),
                icon: SettingsScreen._icon(section),
                selected: section == active,
                onTap: () => context.go(Routes.settingsFor(section.slug)),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionBody extends ConsumerWidget {
  const _SectionBody({required this.section});

  final SettingsSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (section) {
      SettingsSection.profile => const _ProfileSection(),
      SettingsSection.workspace => const _WorkspaceSection(),
      SettingsSection.appearance => const _AppearanceSection(),
      SettingsSection.notifications => const _NotificationsSection(),
      SettingsSection.shortcuts => const _ShortcutsSection(),
      SettingsSection.preferences => const _PreferencesSection(),
      SettingsSection.security => const _SecuritySection(),
      SettingsSection.data => const _DataSection(),
    };
  }
}

// --- Profile ---------------------------------------------------------------

class _ProfileSection extends ConsumerStatefulWidget {
  const _ProfileSection();

  @override
  ConsumerState<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends ConsumerState<_ProfileSection> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController? _name;
  TextEditingController? _email;
  TextEditingController? _jobTitle;
  bool _saving = false;

  @override
  void dispose() {
    _name?.dispose();
    _email?.dispose();
    _jobTitle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l10n = context.l10n;
    final User? user = ref.watch(currentUserValueProvider);
    if (user == null) {
      return AppEmptyState(
        icon: AppIcons.assignee,
        title: l10n.errorUnauthorizedTitle,
        message: l10n.errorUnauthorizedBody,
        compact: true,
      );
    }

    _name ??= TextEditingController(text: user.name);
    _email ??= TextEditingController(text: user.email);
    _jobTitle ??= TextEditingController(text: user.jobTitle);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SettingsSectionCard(
            title: l10n.settingsProfile,
            description: 'How you appear to everyone in the workspace.',
            icon: AppIcons.assignee,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Row(
                  children: <Widget>[
                    AppAvatar(user: user, size: 64, showTooltip: false),
                    const SizedBox(width: Spacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(user.name, style: context.textStyles.titleLarge),
                          Text(
                            user.email,
                            style: context.textStyles.bodySmall?.copyWith(
                              color: context.colors.inkMuted,
                            ),
                          ),
                          const SizedBox(height: Spacing.sm),
                          Text(
                            'Avatars are generated from your initials and '
                            'accent colour — no upload needed.',
                            style: context.textStyles.labelSmall?.copyWith(
                              color: context.colors.inkFaint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Column(
                  children: <Widget>[
                    AppTextField(
                      controller: _name,
                      label: l10n.fieldFullName,
                      validator: Validators.compose(<String? Function(String?)>[
                        Validators.required(l10n),
                        Validators.minLength(l10n, 2),
                      ]),
                    ),
                    const SizedBox(height: Spacing.md),
                    AppTextField(
                      controller: _email,
                      label: l10n.fieldEmail,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email(l10n),
                    ),
                    const SizedBox(height: Spacing.md),
                    AppTextField(
                      controller: _jobTitle,
                      label: l10n.fieldRole,
                      hint: 'Product Lead',
                    ),
                  ],
                ),
              ),
              SettingsRow(
                label: l10n.fieldTimezone,
                description: user.timezone,
                trailing: AppBadge(
                  label: user.timezone,
                  icon: AppIcons.estimate,
                ),
              ),
              SettingsRow(
                label: l10n.fieldLanguage,
                description:
                    'English. The interface is fully localised through ARB '
                    'resources — adding a language is a translation file, not '
                    'a code change.',
                trailing: const AppBadge(label: 'English'),
              ),
              Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    AppButton.primary(
                      label: l10n.actionSaveChanges,
                      isLoading: _saving,
                      onPressed: () => _save(user),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save(User user) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final String message = context.l10n.toastSettingsSaved;
    setState(() => _saving = true);
    await ref
        .read(authRepositoryProvider)
        .updateProfile(
          user.copyWith(
            name: _name!.text.trim(),
            email: _email!.text.trim(),
            jobTitle: _jobTitle!.text.trim(),
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    ref.toasts.success(message);
  }
}

// --- Workspace -------------------------------------------------------------

class _WorkspaceSection extends ConsumerWidget {
  const _WorkspaceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l10n = context.l10n;
    final Workspace? workspace = ref.watch(activeWorkspaceProvider).value;
    final List<User> members =
        ref.watch(membersProvider).value ?? const <User>[];
    final List<Label> labels =
        ref.watch(labelsProvider).value ?? const <Label>[];

    if (workspace == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SettingsSectionCard(
          title: l10n.settingsWorkspace,
          description: workspace.description,
          icon: AppIcons.projects,
          children: <Widget>[
            SettingsRow(
              label: 'Name',
              description: workspace.name,
              trailing: AppButton(
                label: l10n.actionEdit,
                size: AppButtonSize.small,
                onPressed: () => _rename(context, ref, workspace),
              ),
            ),
            SettingsRow(
              label: 'Plan',
              description: 'Billing is not connected in this build.',
              trailing: AppBadge(
                label: workspace.plan.toUpperCase(),
                tone: BadgeTone.brand,
                icon: AppIcons.billing,
              ),
            ),
          ],
        ),
        SettingsSectionCard(
          index: 1,
          title: l10n.workspaceMembers,
          description: '${members.length} people can see this workspace.',
          icon: AppIcons.members,
          children: <Widget>[
            for (final User member in members)
              SettingsRow(
                label: member.name,
                description: member.email,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AppBadge(
                      label: workspace.roleOf(member.id).label(l10n),
                      tone: workspace.ownerId == member.id
                          ? BadgeTone.brand
                          : BadgeTone.neutral,
                      compact: true,
                    ),
                    const SizedBox(width: Spacing.md),
                    AppAvatar(user: member, size: 26),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: AppButton(
                label: l10n.actionInvite,
                icon: AppIcons.invite,
                size: AppButtonSize.small,
                onPressed: () => _invite(context, ref, workspace),
              ),
            ),
          ],
        ),
        SettingsSectionCard(
          index: 2,
          title: l10n.workspaceLabels,
          description: 'Labels are shared across every project.',
          icon: AppIcons.labels,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: <Widget>[
                  for (final Label label in labels)
                    LabelChip(
                      label: label,
                      compact: false,
                      onRemove: () async {
                        final bool confirmed = await confirmAction(
                          context: context,
                          title: 'Delete “${label.name}”?',
                          message:
                              'The label is removed from every task that uses '
                              'it. Tasks themselves are unaffected.',
                          confirmLabel: l10n.actionDelete,
                        );
                        if (!confirmed) return;
                        await ref
                            .read(workspaceRepositoryProvider)
                            .deleteLabel(label.id);
                      },
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: AppButton(
                label: l10n.actionCreateLabel,
                icon: AppIcons.add,
                size: AppButtonSize.small,
                onPressed: () => _createLabel(context, ref, workspace.id),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    Workspace workspace,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: workspace.name,
    );
    final String? name = await showAppDialog<String>(
      context: context,
      maxWidth: 420,
      child: Builder(
        builder: (BuildContext context) => AppDialogShell(
          title: context.l10n.workspaceRename,
          icon: AppIcons.projects,
          scrollable: false,
          actions: <Widget>[
            AppButton(
              label: context.l10n.actionCancel,
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(),
            ),
            AppButton.primary(
              label: context.l10n.actionSave,
              onPressed: () => Navigator.of(context).pop(controller.text),
            ),
          ],
          child: AppTextField(controller: controller, autofocus: true),
        ),
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;
    await ref
        .read(workspaceRepositoryProvider)
        .updateWorkspace(workspace.copyWith(name: name.trim()));
  }

  Future<void> _invite(
    BuildContext context,
    WidgetRef ref,
    Workspace workspace,
  ) async {
    final TextEditingController controller = TextEditingController();
    final AppL10n l10n = context.l10n;
    final String? email = await showAppDialog<String>(
      context: context,
      maxWidth: 440,
      child: Builder(
        builder: (BuildContext context) => AppDialogShell(
          title: l10n.actionInvite,
          subtitle: l10n.workspaceInviteHint,
          icon: AppIcons.invite,
          scrollable: false,
          actions: <Widget>[
            AppButton(
              label: l10n.actionCancel,
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(),
            ),
            AppButton.primary(
              label: l10n.actionInvite,
              onPressed: () => Navigator.of(context).pop(controller.text),
            ),
          ],
          child: AppTextField(
            controller: controller,
            label: l10n.fieldEmail,
            hint: 'teammate@company.com',
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
          ),
        ),
      ),
    );
    controller.dispose();
    if (email == null || email.trim().isEmpty) return;

    await ref
        .read(workspaceRepositoryProvider)
        .inviteMember(
          workspaceId: workspace.id,
          email: email.trim(),
          role: WorkspaceRole.member,
        );
    ref.toasts.success('Invitation sent', description: email.trim());
  }

  Future<void> _createLabel(
    BuildContext context,
    WidgetRef ref,
    String workspaceId,
  ) async {
    final TextEditingController controller = TextEditingController();
    final String? name = await showAppDialog<String>(
      context: context,
      maxWidth: 420,
      child: Builder(
        builder: (BuildContext context) => AppDialogShell(
          title: context.l10n.actionCreateLabel,
          icon: AppIcons.label,
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
            label: 'Label name',
            hint: 'Needs review',
            autofocus: true,
          ),
        ),
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;

    await ref
        .read(workspaceRepositoryProvider)
        .createLabel(
          workspaceId: workspaceId,
          name: name.trim(),
          colorValue: 0xFF3B6BF5,
        );
  }
}

// --- Appearance ------------------------------------------------------------

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l10n = context.l10n;
    final UserPreferences prefs = ref.watch(preferencesProvider);
    final PreferencesController controller = ref.read(
      preferencesProvider.notifier,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SettingsSectionCard(
          title: l10n.settingsAppearance,
          description: 'Both themes are designed, not inverted.',
          icon: AppIcons.appearance,
          children: <Widget>[
            SettingsChoice<ThemePreference>(
              label: l10n.settingsTheme,
              value: prefs.theme,
              options:
                  <({ThemePreference value, String label, IconData? icon})>[
                    (
                      value: ThemePreference.light,
                      label: l10n.settingsThemeLight,
                      icon: AppIcons.themeLight,
                    ),
                    (
                      value: ThemePreference.dark,
                      label: l10n.settingsThemeDark,
                      icon: AppIcons.themeDark,
                    ),
                    (
                      value: ThemePreference.system,
                      label: l10n.settingsThemeSystem,
                      icon: AppIcons.themeSystem,
                    ),
                  ],
              onChanged: (ThemePreference value) => controller.update(
                (UserPreferences p) => p.copyWith(theme: value),
              ),
            ),
            SettingsChoice<InterfaceDensity>(
              label: l10n.settingsAccentDensity,
              value: prefs.density,
              options:
                  <({InterfaceDensity value, String label, IconData? icon})>[
                    (
                      value: InterfaceDensity.comfortable,
                      label: l10n.settingsDensityComfortable,
                      icon: null,
                    ),
                    (
                      value: InterfaceDensity.compact,
                      label: l10n.settingsDensityCompact,
                      icon: null,
                    ),
                  ],
              onChanged: (InterfaceDensity value) => controller.update(
                (UserPreferences p) => p.copyWith(density: value),
              ),
            ),
            SettingsToggle(
              label: l10n.settingsReduceMotion,
              description: l10n.settingsReduceMotionHint,
              value: prefs.reduceMotion,
              onChanged: (bool value) => controller.update(
                (UserPreferences p) => p.copyWith(reduceMotion: value),
              ),
            ),
            SettingsToggle(
              label: 'Completion effects',
              description:
                  'A short particle burst when a task is completed. Turned off '
                  'automatically when motion is reduced.',
              value: prefs.taskCompletionEffects,
              onChanged: (bool value) => controller.update(
                (UserPreferences p) => p.copyWith(taskCompletionEffects: value),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// --- Notifications ---------------------------------------------------------

class _NotificationsSection extends ConsumerWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l10n = context.l10n;
    final NotificationPreferences prefs = ref.watch(
      preferencesProvider.select((UserPreferences p) => p.notifications),
    );
    final PreferencesController controller = ref.read(
      preferencesProvider.notifier,
    );

    void set(NotificationPreferences next) => controller.update(
      (UserPreferences p) => p.copyWith(notifications: next),
    );

    return SettingsSectionCard(
      title: l10n.settingsNotifications,
      description: 'Choose what reaches your inbox.',
      icon: AppIcons.notifications,
      children: <Widget>[
        SettingsToggle(
          label: l10n.settingsNotifyMentions,
          description: 'When someone writes @your name in a comment.',
          value: prefs.mentions,
          onChanged: (bool v) => set(prefs.copyWith(mentions: v)),
        ),
        SettingsToggle(
          label: l10n.settingsNotifyAssignments,
          value: prefs.assignments,
          onChanged: (bool v) => set(prefs.copyWith(assignments: v)),
        ),
        SettingsToggle(
          label: l10n.settingsNotifyComments,
          description: 'Comments on tasks assigned to you.',
          value: prefs.comments,
          onChanged: (bool v) => set(prefs.copyWith(comments: v)),
        ),
        SettingsToggle(
          label: l10n.settingsNotifyDeadlines,
          value: prefs.deadlines,
          onChanged: (bool v) => set(prefs.copyWith(deadlines: v)),
        ),
        SettingsToggle(
          label: l10n.settingsNotifyProjects,
          description: 'Milestones and status changes on projects you follow.',
          value: prefs.projectUpdates,
          onChanged: (bool v) => set(prefs.copyWith(projectUpdates: v)),
        ),
        SettingsToggle(
          label: l10n.settingsNotifyDigest,
          description: 'A Monday summary of last week.',
          value: prefs.weeklyDigest,
          onChanged: (bool v) => set(prefs.copyWith(weeklyDigest: v)),
        ),
      ],
    );
  }
}

// --- Shortcuts -------------------------------------------------------------

class _ShortcutsSection extends StatelessWidget {
  const _ShortcutsSection();

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: context.l10n.shortcutsTitle,
      description:
          'Every primary action has a key. Press ? anywhere to see it.',
      icon: AppIcons.command,
      children: const <Widget>[
        Padding(
          padding: EdgeInsets.all(Spacing.lg),
          child: ShortcutReference(columns: 1),
        ),
      ],
    );
  }
}

// --- Preferences -----------------------------------------------------------

class _PreferencesSection extends ConsumerWidget {
  const _PreferencesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l10n = context.l10n;
    final UserPreferences prefs = ref.watch(preferencesProvider);
    final PreferencesController controller = ref.read(
      preferencesProvider.notifier,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SettingsSectionCard(
          title: l10n.settingsPreferences,
          icon: AppIcons.settings,
          children: <Widget>[
            SettingsChoice<int>(
              label: l10n.settingsStartOfWeek,
              value: prefs.weekStartsOn,
              options: const <({int value, String label, IconData? icon})>[
                (value: DateTime.monday, label: 'Monday', icon: null),
                (value: DateTime.sunday, label: 'Sunday', icon: null),
              ],
              onChanged: (int value) => controller.update(
                (UserPreferences p) => p.copyWith(weekStartsOn: value),
              ),
            ),
            SettingsChoice<TaskViewType>(
              label: l10n.settingsDefaultView,
              value: prefs.defaultTaskView,
              options: <({TaskViewType value, String label, IconData? icon})>[
                (
                  value: TaskViewType.list,
                  label: l10n.tasksViewList,
                  icon: AppIcons.viewList,
                ),
                (
                  value: TaskViewType.board,
                  label: l10n.tasksViewBoard,
                  icon: AppIcons.viewBoard,
                ),
                (
                  value: TaskViewType.calendar,
                  label: l10n.tasksViewCalendar,
                  icon: AppIcons.viewCalendar,
                ),
              ],
              onChanged: (TaskViewType value) => controller.update(
                (UserPreferences p) => p.copyWith(defaultTaskView: value),
              ),
            ),
            SettingsChoice<String>(
              label: l10n.settingsLandingRoute,
              value: prefs.landingRoute,
              options: <({String value, String label, IconData? icon})>[
                (
                  value: Routes.dashboard,
                  label: l10n.navDashboard,
                  icon: AppIcons.dashboard,
                ),
                (
                  value: Routes.tasks,
                  label: l10n.navMyTasks,
                  icon: AppIcons.tasks,
                ),
                (
                  value: Routes.focus,
                  label: l10n.navFocus,
                  icon: AppIcons.focus,
                ),
              ],
              onChanged: (String value) => controller.update(
                (UserPreferences p) => p.copyWith(landingRoute: value),
              ),
            ),
          ],
        ),
        SettingsSectionCard(
          index: 1,
          title: l10n.focusTitle,
          description: 'Defaults for the Pomodoro timer.',
          icon: AppIcons.focus,
          children: <Widget>[
            SettingsChoice<int>(
              label: l10n.settingsPomodoroLength,
              value: prefs.focus.focusMinutes,
              options: const <({int value, String label, IconData? icon})>[
                (value: 20, label: '20', icon: null),
                (value: 25, label: '25', icon: null),
                (value: 45, label: '45', icon: null),
                (value: 50, label: '50', icon: null),
              ],
              onChanged: (int value) => controller.update(
                (UserPreferences p) =>
                    p.copyWith(focus: p.focus.copyWith(focusMinutes: value)),
              ),
            ),
            SettingsChoice<int>(
              label: l10n.settingsRoundsBeforeLongBreak,
              value: prefs.focus.roundsBeforeLongBreak,
              options: const <({int value, String label, IconData? icon})>[
                (value: 2, label: '2', icon: null),
                (value: 3, label: '3', icon: null),
                (value: 4, label: '4', icon: null),
                (value: 5, label: '5', icon: null),
              ],
              onChanged: (int value) => controller.update(
                (UserPreferences p) => p.copyWith(
                  focus: p.focus.copyWith(roundsBeforeLongBreak: value),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// --- Security --------------------------------------------------------------

class _SecuritySection extends ConsumerWidget {
  const _SecuritySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SettingsSectionCard(
          title: l10n.settingsSecurity,
          description:
              'Session tokens are stored in the platform keychain, never in '
              'plain preferences.',
          icon: AppIcons.security,
          children: <Widget>[
            SettingsRow(
              label: l10n.settingsChangePassword,
              description: 'At least 8 characters, mixing letters and numbers.',
              trailing: AppButton(
                label: l10n.actionEdit,
                size: AppButtonSize.small,
                onPressed: () => _changePassword(context, ref),
              ),
            ),
            SettingsRow(
              label: l10n.settingsTwoFactor,
              description:
                  'Requires an identity provider. Not enabled in this build.',
              trailing: const AppBadge(label: 'Not configured'),
            ),
            SettingsRow(
              label: l10n.settingsActiveSessions,
              description: 'This device',
              trailing: const AppBadge(
                label: '1 session',
                tone: BadgeTone.success,
              ),
            ),
          ],
        ),
        SettingsSectionCard(
          index: 1,
          title: l10n.settingsDangerZone,
          isDanger: true,
          icon: AppIcons.warning,
          children: <Widget>[
            SettingsRow(
              label: l10n.settingsDeleteAccount,
              description: l10n.settingsDeleteAccountHint,
              isDanger: true,
              trailing: AppButton(
                label: l10n.actionDelete,
                variant: AppButtonVariant.danger,
                size: AppButtonSize.small,
                onPressed: () => _deleteAccount(context, ref),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final TextEditingController current = TextEditingController();
    final TextEditingController next = TextEditingController();
    final AppL10n l10n = context.l10n;

    final bool? submitted = await showAppDialog<bool>(
      context: context,
      maxWidth: 440,
      child: Builder(
        builder: (BuildContext context) => AppDialogShell(
          title: l10n.settingsChangePassword,
          icon: AppIcons.password,
          actions: <Widget>[
            AppButton(
              label: l10n.actionCancel,
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            AppButton.primary(
              label: l10n.actionSave,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
          child: Column(
            children: <Widget>[
              AppTextField(
                controller: current,
                label: 'Current password',
                obscure: true,
                autofocus: true,
              ),
              const SizedBox(height: Spacing.md),
              AppTextField(
                controller: next,
                label: 'New password',
                obscure: true,
                helper: 'At least 8 characters with a number.',
              ),
            ],
          ),
        ),
      ),
    );

    if (submitted ?? false) {
      try {
        await ref
            .read(authRepositoryProvider)
            .changePassword(
              currentPassword: current.text,
              newPassword: next.text,
            );
        ref.toasts.success('Password updated');
      } catch (_) {
        ref.toasts.error(
          'Could not update password',
          description: 'Check your current password and try again.',
        );
      }
    }
    current.dispose();
    next.dispose();
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await confirmAction(
      context: context,
      title: context.l10n.settingsDeleteAccount,
      message:
          'This signs you out and clears the local workspace on this device. '
          'In a deployed build it would also delete the server-side account.',
      confirmLabel: context.l10n.actionDelete,
    );
    if (!confirmed) return;
    await ref.read(authRepositoryProvider).signOut();
  }
}

// --- Data ------------------------------------------------------------------

class _DataSection extends ConsumerWidget {
  const _DataSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l10n = context.l10n;
    final String? workspaceId = ref.watch(activeWorkspaceIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SettingsSectionCard(
          title: l10n.settingsData,
          description:
              'Everything lives on this device in an embedded database. '
              'Nothing is uploaded.',
          icon: AppIcons.data,
          children: <Widget>[
            SettingsRow(
              label: l10n.settingsExportData,
              description: l10n.settingsExportHint,
              trailing: AppButton(
                label: l10n.actionCopyLink,
                icon: AppIcons.download,
                size: AppButtonSize.small,
                onPressed: workspaceId == null
                    ? null
                    : () => _export(context, ref, workspaceId),
              ),
            ),
            SettingsRow(
              label: l10n.settingsResetDemo,
              description: l10n.settingsResetDemoHint,
              trailing: AppButton(
                label: l10n.actionRestore,
                icon: AppIcons.retry,
                size: AppButtonSize.small,
                onPressed: () => _reset(context, ref),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    String workspaceId,
  ) async {
    final String copied = context.l10n.toastCopied;
    final Map<String, dynamic> data = await ref
        .read(workspaceRepositoryProvider)
        .exportWorkspace(workspaceId);
    final String json = const JsonEncoder.withIndent('  ').convert(data);
    await Clipboard.setData(ClipboardData(text: json));
    ref.toasts.success(
      copied,
      description: '${(json.length / 1024).toStringAsFixed(1)} KB of JSON',
    );
  }

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final String message = context.l10n.toastDemoReset;
    final bool confirmed = await confirmAction(
      context: context,
      title: context.l10n.settingsResetDemo,
      message:
          'Local changes to the Launchpad workspace are discarded and the '
          'original demo content is restored.',
      confirmLabel: context.l10n.actionRestore,
      destructive: false,
      icon: AppIcons.retry,
    );
    if (!confirmed) return;
    await ref.read(workspaceRepositoryProvider).resetDemoData();
    ref.toasts.success(message);
  }
}
