import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/routing/routes.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/utils/fuzzy_match.dart';
import 'package:kairo/core/widgets/app_badge.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/preferences.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/entities/workspace.dart';
import 'package:kairo/features/command_palette/domain/command.dart';
import 'package:kairo/features/command_palette/presentation/shortcuts_dialog.dart';
import 'package:kairo/features/tasks/presentation/task_composer.dart';

export 'package:kairo/features/command_palette/presentation/shortcuts_dialog.dart'
    show showShortcutsDialog;

/// Opens the command palette.
///
/// Modelled on developer tooling: one input, fuzzy matching over commands *and*
/// content, full keyboard control, and it closes the moment something is
/// chosen. Nothing in here requires the mouse.
Future<void> openCommandPalette(
  BuildContext context, {
  String initialQuery = '',
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Command palette',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: context.motion(Motion.base),
    pageBuilder: (BuildContext context, _, _) =>
        _CommandPalette(initialQuery: initialQuery),
    transitionBuilder:
        (BuildContext context, Animation<double> animation, _, Widget child) {
          final Animation<double> eased = CurvedAnimation(
            parent: animation,
            curve: Motion.emphasized,
            reverseCurve: Curves.easeIn,
          );
          return FadeTransition(
            opacity: eased,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.04),
                end: Offset.zero,
              ).animate(eased),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1).animate(eased),
                child: child,
              ),
            ),
          );
        },
  );
}

class _CommandPalette extends ConsumerStatefulWidget {
  const _CommandPalette({required this.initialQuery});

  final String initialQuery;

  @override
  ConsumerState<_CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<_CommandPalette> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialQuery,
  );
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  String _query = '';
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _move(int delta, int length) {
    if (length == 0) return;
    setState(() => _selected = (_selected + delta) % length);
    if (_selected < 0) _selected += length;
    // Keep the highlighted row on screen as the selection walks the list.
    if (_scrollController.hasClients) {
      const double rowHeight = 44;
      final double target = _selected * rowHeight;
      final double viewport = _scrollController.position.viewportDimension;
      final double offset = _scrollController.offset;
      if (target < offset) {
        _scrollController.jumpTo(target);
      } else if (target + rowHeight > offset + viewport) {
        _scrollController.jumpTo(target + rowHeight - viewport);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final List<Command> commands = _buildCommands(context, ref);
    final List<Command> results = _filter(commands, _query);
    if (_selected >= results.length) _selected = 0;

    return Align(
      alignment: const Alignment(0, -0.55),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.isCompact ? Spacing.lg : Spacing.xxl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Material(
            color: Colors.transparent,
            child: CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                    _move(1, results.length),
                const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                    _move(-1, results.length),
                const SingleActivator(LogicalKeyboardKey.enter): () {
                  if (results.isEmpty) return;
                  Navigator.of(context).pop();
                  results[_selected].run();
                },
                const SingleActivator(LogicalKeyboardKey.escape): () =>
                    Navigator.of(context).pop(),
              },
              child: Focus(
                autofocus: true,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceOverlay,
                    borderRadius: Radii.brXl,
                    border: Border.all(color: colors.hairlineStrong),
                    boxShadow: Shadows.xl(colors.isDark),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _PaletteInput(
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: (String value) => setState(() {
                          _query = value;
                          _selected = 0;
                        }),
                      ),
                      Divider(height: 1, color: colors.hairline),
                      Flexible(
                        child: results.isEmpty
                            ? _EmptyResults(query: _query)
                            : _ResultList(
                                results: results,
                                selected: _selected,
                                query: _query,
                                controller: _scrollController,
                                onHover: (int index) =>
                                    setState(() => _selected = index),
                                onSelect: (Command command) {
                                  Navigator.of(context).pop();
                                  command.run();
                                },
                              ),
                      ),
                      _PaletteFooter(resultCount: results.length),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Command> _filter(List<Command> commands, String query) {
    if (query.trim().isEmpty) {
      return commands.take(12).toList(growable: false);
    }
    final List<({Command command, int score})> scored =
        <({Command command, int score})>[];
    for (final Command command in commands) {
      final FuzzyMatch match = Fuzzy.matchAny(command.haystack, query);
      if (match.isMatch) {
        scored.add((command: command, score: match.score));
      }
    }
    scored.sort(
      (({Command command, int score}) a, ({Command command, int score}) b) =>
          b.score.compareTo(a.score),
    );
    return scored
        .map((({Command command, int score}) e) => e.command)
        .take(24)
        .toList(growable: false);
  }
}

/// Builds the command set from live workspace data, so recent tasks and
/// projects are reachable by name without a separate search step.
List<Command> _buildCommands(BuildContext context, WidgetRef ref) {
  final l10n = context.l10n;
  final List<Task> tasks = ref.watch(tasksProvider).value ?? const <Task>[];
  final List<Project> projects =
      ref.watch(projectsProvider).value ?? const <Project>[];
  final List<Workspace> workspaces =
      ref.watch(workspacesProvider).value ?? const <Workspace>[];
  final ThemePreference theme = ref.watch(
    preferencesProvider.select((UserPreferences p) => p.theme),
  );

  void go(String route) => context.go(route);

  return <Command>[
    Command(
      id: 'new-task',
      title: l10n.actionCreateTask,
      section: CommandSection.actions,
      icon: AppIcons.add,
      shortcut: const <String>['C'],
      keywords: const <String>['add', 'create', 'todo'],
      run: () => openTaskComposer(context, ref),
    ),
    Command(
      id: 'new-project',
      title: l10n.actionCreateProject,
      section: CommandSection.actions,
      icon: AppIcons.projects,
      keywords: const <String>['add', 'create'],
      run: () => go(Routes.projects),
    ),
    Command(
      id: 'start-focus',
      title: l10n.focusStart,
      section: CommandSection.actions,
      icon: AppIcons.focus,
      keywords: const <String>['pomodoro', 'timer', 'deep work'],
      run: () => go(Routes.focus),
    ),
    Command(
      id: 'toggle-theme',
      title: l10n.paletteToggleTheme,
      subtitle: switch (theme) {
        ThemePreference.light => l10n.settingsThemeLight,
        ThemePreference.dark => l10n.settingsThemeDark,
        ThemePreference.system => l10n.settingsThemeSystem,
      },
      section: CommandSection.actions,
      icon: AppIcons.appearance,
      keywords: const <String>['dark', 'light', 'appearance'],
      run: () {
        final ThemePreference next = switch (theme) {
          ThemePreference.light => ThemePreference.dark,
          ThemePreference.dark => ThemePreference.system,
          ThemePreference.system => ThemePreference.light,
        };
        ref
            .read(preferencesProvider.notifier)
            .update((UserPreferences p) => p.copyWith(theme: next));
      },
    ),
    Command(
      id: 'shortcuts',
      title: l10n.paletteOpenShortcuts,
      section: CommandSection.actions,
      icon: AppIcons.command,
      shortcut: const <String>['?'],
      run: () => showShortcutsDialog(context),
    ),

    // Navigation.
    Command(
      id: 'go-dashboard',
      title: l10n.navDashboard,
      section: CommandSection.navigate,
      icon: AppIcons.dashboard,
      shortcut: const <String>['G', 'D'],
      run: () => go(Routes.dashboard),
    ),
    Command(
      id: 'go-tasks',
      title: l10n.navMyTasks,
      section: CommandSection.navigate,
      icon: AppIcons.tasks,
      shortcut: const <String>['G', 'T'],
      run: () => go(Routes.tasks),
    ),
    Command(
      id: 'go-projects',
      title: l10n.navProjects,
      section: CommandSection.navigate,
      icon: AppIcons.projects,
      shortcut: const <String>['G', 'P'],
      run: () => go(Routes.projects),
    ),
    Command(
      id: 'go-calendar',
      title: l10n.navCalendar,
      section: CommandSection.navigate,
      icon: AppIcons.calendar,
      shortcut: const <String>['G', 'C'],
      run: () => go(Routes.calendar),
    ),
    Command(
      id: 'go-timeline',
      title: l10n.navTimeline,
      section: CommandSection.navigate,
      icon: AppIcons.timeline,
      run: () => go(Routes.timeline),
    ),
    Command(
      id: 'go-analytics',
      title: l10n.navAnalytics,
      section: CommandSection.navigate,
      icon: AppIcons.analytics,
      run: () => go(Routes.analytics),
    ),
    Command(
      id: 'go-notifications',
      title: l10n.navNotifications,
      section: CommandSection.navigate,
      icon: AppIcons.notifications,
      run: () => go(Routes.notifications),
    ),
    Command(
      id: 'go-archive',
      title: l10n.navArchive,
      section: CommandSection.navigate,
      icon: AppIcons.archive,
      run: () => go(Routes.archive),
    ),
    Command(
      id: 'go-settings',
      title: l10n.navSettings,
      section: CommandSection.navigate,
      icon: AppIcons.settings,
      run: () => go(Routes.settings),
    ),

    // Content.
    for (final Project project in projects.take(10))
      Command(
        id: 'project-${project.id}',
        title: project.name,
        subtitle: l10n.navProjects,
        section: CommandSection.projects,
        icon: AppIcons.projects,
        accentColorValue: project.colorValue,
        keywords: <String>[project.description],
        run: () => go(Routes.project(project.id)),
      ),
    for (final Task task in tasks.where((Task t) => !t.isArchived).take(40))
      Command(
        id: 'task-${task.id}',
        title: task.title,
        subtitle: task.projectId == null
            ? l10n.fieldNoProject
            : projects
                      .where((Project p) => p.id == task.projectId)
                      .firstOrNull
                      ?.name ??
                  l10n.fieldNoProject,
        section: CommandSection.tasks,
        icon: task.isDone ? AppIcons.statusDone : AppIcons.tasks,
        run: () {
          final String location = GoRouterState.of(context).uri.toString();
          go(Routes.taskOn(location, task.id));
        },
      ),

    // Workspace.
    for (final Workspace workspace in workspaces)
      Command(
        id: 'workspace-${workspace.id}',
        title: workspace.name,
        subtitle: l10n.workspaceSwitch,
        section: CommandSection.workspace,
        icon: AppIcons.home,
        accentColorValue: workspace.colorValue,
        run: () => ref
            .read(workspaceRepositoryProvider)
            .setActiveWorkspace(workspace.id),
      ),
  ];
}

class _PaletteInput extends StatelessWidget {
  const _PaletteInput({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.xs,
      ),
      child: Row(
        children: <Widget>[
          Icon(AppIcons.search, size: 18, color: colors.inkFaint),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              onChanged: onChanged,
              style: context.textStyles.bodyLarge?.copyWith(fontSize: 16),
              decoration: InputDecoration(
                hintText: context.l10n.palettePlaceholder,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: Spacing.lg,
                ),
              ),
            ),
          ),
          const KeycapHint(<String>['esc'], compact: true),
        ],
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({
    required this.results,
    required this.selected,
    required this.query,
    required this.controller,
    required this.onHover,
    required this.onSelect,
  });

  final List<Command> results;
  final int selected;
  final String query;
  final ScrollController controller;
  final ValueChanged<int> onHover;
  final ValueChanged<Command> onSelect;

  @override
  Widget build(BuildContext context) {
    // Group headers are inserted inline rather than as sticky sections; the
    // list is short enough that stickiness would be noise.
    final List<Widget> children = <Widget>[];
    CommandSection? lastSection;

    for (int i = 0; i < results.length; i++) {
      final Command command = results[i];
      if (command.section != lastSection) {
        lastSection = command.section;
        children.add(_SectionHeader(section: command.section));
      }
      children.add(
        _CommandRow(
          command: command,
          isSelected: i == selected,
          query: query,
          onHover: () => onHover(i),
          onTap: () => onSelect(command),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 380),
      child: ListView(
        controller: controller,
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        shrinkWrap: true,
        children: children,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.section});

  final CommandSection section;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final String label = switch (section) {
      CommandSection.actions => l10n.paletteSectionActions,
      CommandSection.navigate => l10n.paletteSectionNavigate,
      CommandSection.tasks => l10n.paletteSectionTasks,
      CommandSection.projects => l10n.paletteSectionProjects,
      CommandSection.workspace => l10n.paletteSectionWorkspace,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.xs,
      ),
      child: Text(
        label.toUpperCase(),
        style: context.textStyles.labelSmall?.copyWith(
          color: context.colors.inkFaint,
          fontSize: 10,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _CommandRow extends StatelessWidget {
  const _CommandRow({
    required this.command,
    required this.isSelected,
    required this.query,
    required this.onHover,
    required this.onTap,
  });

  final Command command;
  final bool isSelected;
  final String query;
  final VoidCallback onHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color accent = command.accentColorValue == null
        ? colors.inkMuted
        : Color(command.accentColorValue!);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: Spacing.sm),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          decoration: BoxDecoration(
            color: isSelected ? colors.brandSoft : Colors.transparent,
            borderRadius: Radii.brSm,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                command.icon,
                size: 16,
                color: isSelected ? colors.brand : accent,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    HighlightedText(
                      text: command.title,
                      query: query,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: colors.ink,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      highlightColor: colors.brand,
                    ),
                    if (command.subtitle != null)
                      Text(
                        command.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.labelSmall?.copyWith(
                          color: colors.inkFaint,
                        ),
                      ),
                  ],
                ),
              ),
              ?command.trailing,
              if (command.shortcut != null) ...<Widget>[
                const SizedBox(width: Spacing.sm),
                KeycapHint(command.shortcut!, compact: true),
              ],
              if (isSelected) ...<Widget>[
                const SizedBox(width: Spacing.sm),
                Icon(AppIcons.enterKey, size: 13, color: colors.brand),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders [text] with the characters matched by [query] emphasised.
class HighlightedText extends StatelessWidget {
  const HighlightedText({
    required this.text,
    required this.query,
    this.style,
    this.highlightColor,
    this.maxLines = 1,
    super.key,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final Color? highlightColor;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = style ?? context.textStyles.bodyMedium!;
    if (query.trim().isEmpty) {
      return Text(
        text,
        style: base,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final Set<int> positions = Fuzzy.match(text, query).positions.toSet();
    if (positions.isEmpty) {
      return Text(
        text,
        style: base,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final Color highlight = highlightColor ?? context.colors.brand;
    final List<TextSpan> spans = <TextSpan>[];
    final StringBuffer buffer = StringBuffer();
    bool? runIsMatch;

    void flush() {
      if (buffer.isEmpty) return;
      spans.add(
        TextSpan(
          text: buffer.toString(),
          style: runIsMatch ?? false
              ? base.copyWith(color: highlight, fontWeight: FontWeight.w700)
              : base,
        ),
      );
      buffer.clear();
    }

    for (int i = 0; i < text.length; i++) {
      final bool isMatch = positions.contains(i);
      if (runIsMatch != isMatch) {
        flush();
        runIsMatch = isMatch;
      }
      buffer.write(text[i]);
    }
    flush();

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xxxl),
      child: Column(
        children: <Widget>[
          Icon(AppIcons.search, size: 22, color: context.colors.inkFaint),
          const SizedBox(height: Spacing.md),
          Text(
            context.l10n.searchNoResults(query),
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletteFooter extends StatelessWidget {
  const _PaletteFooter({required this.resultCount});

  final int resultCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        border: Border(top: BorderSide(color: colors.hairline)),
      ),
      // Keyboard hints are for keyboard users. On a phone there is no keyboard
      // to hint about and no room for the hints, so the footer keeps only the
      // result count — which is the part that is useful on touch.
      child: Row(
        children: <Widget>[
          if (!context.breakpoint.isCompact) ...<Widget>[
            const KeycapHint(<String>['↑', '↓'], compact: true),
            const SizedBox(width: Spacing.sm),
            Flexible(
              child: Text(
                'Navigate',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.labelSmall?.copyWith(
                  color: colors.inkFaint,
                ),
              ),
            ),
            const SizedBox(width: Spacing.lg),
            const KeycapHint(<String>['↵'], compact: true),
            const SizedBox(width: Spacing.sm),
            Flexible(
              child: Text(
                'Select',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.labelSmall?.copyWith(
                  color: colors.inkFaint,
                ),
              ),
            ),
          ],
          const Spacer(),
          Text(
            '$resultCount',
            style: context.textStyles.labelSmall?.copyWith(
              color: colors.inkFaint,
            ),
          ),
        ],
      ),
    );
  }
}
