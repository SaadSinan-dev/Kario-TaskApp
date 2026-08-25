import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/responsive/breakpoints.dart';
import 'package:kairo/core/routing/routes.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/utils/keyboard.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/preferences.dart';
import 'package:kairo/features/command_palette/presentation/command_palette.dart';
import 'package:kairo/features/shell/presentation/widgets/app_sidebar.dart';
import 'package:kairo/features/shell/presentation/widgets/app_top_bar.dart';
import 'package:kairo/features/shell/presentation/widgets/mobile_navigation.dart';
import 'package:kairo/features/tasks/presentation/task_composer.dart';
import 'package:kairo/features/tasks/presentation/task_detail_panel.dart';

/// The frame every signed-in screen renders inside.
///
/// Three layouts from one tree: sidebar + content + optional detail panel on
/// desktop, a collapsed icon rail on tablets, and bottom navigation with a
/// full-screen detail on phones. The task detail is driven by a `?task=` query
/// parameter, which keeps it deep-linkable and means the back button closes it.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// Buffers the first key of a two-key sequence such as `G` then `D`.
  LogicalKeyboardKey? _pendingChord;

  void _closeTaskPanel() {
    final GoRouterState state = GoRouterState.of(context);
    final Map<String, String> params = <String, String>{
      ...state.uri.queryParameters,
    }..remove(Routes.taskQueryParam);
    context.go(state.uri.replace(queryParameters: params).toString());
  }

  void _openRoute(String route) => context.go(route);

  VoidCallback _whenNotTyping(VoidCallback action) =>
      KeyboardGuards.unlessTyping(action);

  /// Global shortcuts. Chords are handled by remembering the leading key
  /// rather than by a separate mode, so `G` on its own is harmless.
  Map<ShortcutActivator, VoidCallback> _shortcuts() {
    void chord(LogicalKeyboardKey key) {
      if (_pendingChord != LogicalKeyboardKey.keyG) return;
      _pendingChord = null;
      switch (key) {
        case LogicalKeyboardKey.keyD:
          _openRoute(Routes.dashboard);
        case LogicalKeyboardKey.keyT:
          _openRoute(Routes.tasks);
        case LogicalKeyboardKey.keyP:
          _openRoute(Routes.projects);
        case LogicalKeyboardKey.keyC:
          _openRoute(Routes.calendar);
        case LogicalKeyboardKey.keyF:
          _openRoute(Routes.focus);
      }
    }

    return <ShortcutActivator, VoidCallback>{
      // Modified shortcuts are safe while typing: no text field claims ⌘K.
      const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
          openCommandPalette(context),
      const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
          openCommandPalette(context),
      const SingleActivator(LogicalKeyboardKey.keyJ, meta: true): _cycleTheme,
      const SingleActivator(LogicalKeyboardKey.keyJ, control: true):
          _cycleTheme,
      const SingleActivator(LogicalKeyboardKey.keyB, meta: true):
          _toggleSidebar,
      const SingleActivator(LogicalKeyboardKey.keyB, control: true):
          _toggleSidebar,

      // Bare keys are gated on the caret not being in a field.
      const SingleActivator(LogicalKeyboardKey.slash): _whenNotTyping(
        () => openCommandPalette(context),
      ),
      const SingleActivator(LogicalKeyboardKey.keyC): _whenNotTyping(
        () => openTaskComposer(context, ref),
      ),
      const SingleActivator(LogicalKeyboardKey.question): _whenNotTyping(
        () => showShortcutsDialog(context),
      ),
      const SingleActivator(LogicalKeyboardKey.keyG): _whenNotTyping(
        () => _pendingChord = LogicalKeyboardKey.keyG,
      ),
      const SingleActivator(LogicalKeyboardKey.keyD): _whenNotTyping(
        () => chord(LogicalKeyboardKey.keyD),
      ),
      const SingleActivator(LogicalKeyboardKey.keyT): _whenNotTyping(
        () => chord(LogicalKeyboardKey.keyT),
      ),
      const SingleActivator(LogicalKeyboardKey.keyP): _whenNotTyping(
        () => chord(LogicalKeyboardKey.keyP),
      ),
      const SingleActivator(LogicalKeyboardKey.keyF): _whenNotTyping(
        () => chord(LogicalKeyboardKey.keyF),
      ),

      const SingleActivator(LogicalKeyboardKey.escape): _closeTaskPanel,
    };
  }

  void _cycleTheme() {
    final ThemePreference current = ref.read(preferencesProvider).theme;
    final ThemePreference next = switch (current) {
      ThemePreference.light => ThemePreference.dark,
      ThemePreference.dark => ThemePreference.system,
      ThemePreference.system => ThemePreference.light,
    };
    ref
        .read(preferencesProvider.notifier)
        .update((UserPreferences p) => p.copyWith(theme: next));
  }

  void _toggleSidebar() {
    ref
        .read(preferencesProvider.notifier)
        .update(
          (UserPreferences p) =>
              p.copyWith(sidebarCollapsed: !p.sidebarCollapsed),
        );
  }

  @override
  Widget build(BuildContext context) {
    final ScreenSize size = context.breakpoint;
    final GoRouterState routerState = GoRouterState.of(context);
    final String? openTaskId =
        routerState.uri.queryParameters[Routes.taskQueryParam];
    final bool collapsed = ref.watch(
      preferencesProvider.select((UserPreferences p) => p.sidebarCollapsed),
    );

    // Tablets always show the rail; desktop honours the preference.
    final bool sidebarCollapsed = size == ScreenSize.expanded || collapsed;

    return CallbackShortcuts(
      bindings: _shortcuts(),
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: SafeArea(
            child: size.hasSidebar
                ? _wideLayout(context, sidebarCollapsed, openTaskId, size)
                : _compactLayout(context, openTaskId),
          ),
          bottomNavigationBar: size.hasSidebar
              ? null
              : const MobileNavigationBar(),
          floatingActionButton: size.hasSidebar || openTaskId != null
              ? null
              : const QuickCreateButton(),
        ),
      ),
    );
  }

  Widget _wideLayout(
    BuildContext context,
    bool collapsed,
    String? openTaskId,
    ScreenSize size,
  ) {
    return Row(
      children: <Widget>[
        AppSidebar(collapsed: collapsed, onToggleCollapse: _toggleSidebar),
        Expanded(child: widget.child),
        // The detail panel slides in beside the content rather than over it, so
        // the list stays visible while a task is being read.
        AnimatedSize(
          duration: context.motion(Motion.medium),
          curve: Motion.emphasized,
          child: openTaskId == null
              ? const SizedBox(width: 0)
              : SizedBox(
                  width: size == ScreenSize.large
                      ? ShellMetrics.detailPanelWideWidth
                      : ShellMetrics.detailPanelWidth,
                  child: TaskDetailPanel(
                    key: ValueKey<String>(openTaskId),
                    taskId: openTaskId,
                    onClose: _closeTaskPanel,
                  ),
                ),
        ),
      ],
    );
  }

  /// On phones the detail takes over the screen entirely — a 440px panel does
  /// not exist here, and a sheet would fight with the task's own scrolling.
  Widget _compactLayout(BuildContext context, String? openTaskId) {
    return Stack(
      children: <Widget>[
        widget.child,
        if (openTaskId != null)
          Positioned.fill(
            child: _SlideUp(
              child: Material(
                color: context.colors.surface,
                child: TaskDetailPanel(
                  key: ValueKey<String>(openTaskId),
                  taskId: openTaskId,
                  onClose: _closeTaskPanel,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SlideUp extends StatefulWidget {
  const _SlideUp({required this.child});

  final Widget child;

  @override
  State<_SlideUp> createState() => _SlideUpState();
}

class _SlideUpState extends State<_SlideUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.medium,
  );

  @override
  void initState() {
    super.initState();
    // Started here so the controller always exists while the element is live —
    // `build` returns early under reduced motion and would otherwise leave it
    // to be constructed during `dispose()`.
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reducedMotion) return widget.child;
    final Animation<double> eased = CurvedAnimation(
      parent: _controller,
      curve: Motion.emphasized,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(eased),
      child: FadeTransition(opacity: eased, child: widget.child),
    );
  }
}

/// Opens the task detail for [taskId] on top of the current route.
void openTaskDetail(BuildContext context, String taskId) {
  final GoRouterState state = GoRouterState.of(context);
  context.go(Routes.taskOn(state.uri.toString(), taskId));
}

/// Standard page frame used by every screen inside the shell: a top bar, an
/// optional toolbar, and the scrolling body.
class ShellPage extends StatelessWidget {
  const ShellPage({
    required this.title,
    required this.child,
    this.subtitle,
    this.toolbar,
    this.actions = const <Widget>[],
    this.padded = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? toolbar;
  final List<Widget> actions;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTopBar(title: title, subtitle: subtitle, actions: actions),
        ?toolbar,
        Expanded(
          child: padded
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.gutter),
                  child: child,
                )
              : child,
        ),
      ],
    );
  }
}

/// Compact floating action button that opens the quick-create sheet.
class QuickCreateButton extends ConsumerWidget {
  const QuickCreateButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => openTaskComposer(context, ref),
      tooltip: context.l10n.actionCreateTask,
      child: const Icon(AppIcons.add, size: 22),
    );
  }
}

/// A top-bar action that collapses to its icon on phones.
///
/// The top bar's trailing cluster is fixed-width, and a labelled button is
/// worth roughly a hundred pixels of it. Rather than every screen re-deriving
/// that trade-off, page actions declare a label and an icon and this decides
/// which to show. The tooltip carries the label when the label is not drawn, so
/// nothing becomes unlabelled — only narrower.
class PageAction extends StatelessWidget {
  const PageAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.variant = AppButtonVariant.secondary,
    super.key,
  });

  final String label;
  final IconData icon;

  /// Null disables the action, exactly as it does on [AppButton].
  final VoidCallback? onPressed;

  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    if (context.breakpoint.isCompact) {
      return AppIconButton(icon: icon, tooltip: label, onPressed: onPressed);
    }
    return AppButton(
      label: label,
      icon: icon,
      size: AppButtonSize.small,
      variant: variant,
      onPressed: onPressed,
    );
  }
}

/// Convenience action used in several page top bars.
///
/// Collapses to the icon alone on phones. The label is worth roughly a hundred
/// pixels, which is the difference between the top bar fitting and not fitting
/// at 320px — and the icon plus tooltip carries the same meaning. The action
/// itself, including the project it creates into, is unchanged.
class CreateTaskAction extends ConsumerWidget {
  const CreateTaskAction({this.projectId, super.key});

  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String label = context.l10n.actionCreateTask;
    void create() => openTaskComposer(context, ref, projectId: projectId);

    if (context.breakpoint.isCompact) {
      return AppIconButton(
        icon: AppIcons.add,
        tooltip: label,
        onPressed: create,
      );
    }
    return AppButton.primary(
      label: label,
      icon: AppIcons.add,
      size: AppButtonSize.small,
      onPressed: create,
    );
  }
}
