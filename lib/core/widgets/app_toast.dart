import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/utils/id_generator.dart';

enum ToastKind { success, error, warning, info }

@immutable
class ToastMessage {
  const ToastMessage({
    required this.id,
    required this.kind,
    required this.message,
    required this.duration,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  final String id;
  final ToastKind kind;
  final String message;
  final String? description;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
}

/// The app's transient-feedback queue.
///
/// A queue rather than a single slot so a burst of actions (bulk complete, an
/// undo, then a save) stacks instead of clobbering itself. Newest sits closest
/// to the edge; at most three are shown at once.
class ToastController extends Notifier<List<ToastMessage>> {
  final Map<String, Timer> _timers = <String, Timer>{};

  @override
  List<ToastMessage> build() {
    ref.onDispose(() {
      for (final Timer timer in _timers.values) {
        timer.cancel();
      }
      _timers.clear();
    });
    return const <ToastMessage>[];
  }

  static const int _maxVisible = 3;

  void show(
    String message, {
    ToastKind kind = ToastKind.info,
    String? description,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final ToastMessage toast = ToastMessage(
      id: Ids.create('tst'),
      kind: kind,
      message: message,
      description: description,
      // Errors linger; confirmations get out of the way.
      duration:
          duration ??
          (kind == ToastKind.error
              ? const Duration(seconds: 6)
              : const Duration(seconds: 4)),
      actionLabel: actionLabel,
      onAction: onAction,
    );

    final List<ToastMessage> next = <ToastMessage>[toast, ...state];
    if (next.length > _maxVisible) {
      for (final ToastMessage dropped in next.sublist(_maxVisible)) {
        _timers.remove(dropped.id)?.cancel();
      }
    }
    state = next.take(_maxVisible).toList(growable: false);

    _timers[toast.id] = Timer(toast.duration, () => dismiss(toast.id));
  }

  void success(
    String message, {
    String? description,
    String? actionLabel,
    VoidCallback? onAction,
  }) => show(
    message,
    kind: ToastKind.success,
    description: description,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  void error(String message, {String? description}) =>
      show(message, kind: ToastKind.error, description: description);

  void warning(String message, {String? description}) =>
      show(message, kind: ToastKind.warning, description: description);

  void dismiss(String id) {
    _timers.remove(id)?.cancel();
    state = state.where((ToastMessage t) => t.id != id).toList(growable: false);
  }

  void clear() {
    for (final Timer timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    state = const <ToastMessage>[];
  }
}

final NotifierProvider<ToastController, List<ToastMessage>> toastProvider =
    NotifierProvider<ToastController, List<ToastMessage>>(ToastController.new);

extension ToastRef on WidgetRef {
  ToastController get toasts => read(toastProvider.notifier);
}

/// Renders the queue. Mounted once, above the router, so a toast survives
/// navigation — which matters when an action navigates and reports at once.
class ToastOverlay extends ConsumerWidget {
  const ToastOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ToastMessage> toasts = ref.watch(toastProvider);
    final bool compact = context.isCompact;

    return IgnorePointer(
      ignoring: toasts.isEmpty,
      child: SafeArea(
        child: Align(
          alignment: compact ? Alignment.topCenter : Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.all(compact ? Spacing.md : Spacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                verticalDirection: compact
                    ? VerticalDirection.down
                    : VerticalDirection.up,
                children: <Widget>[
                  for (final ToastMessage toast in toasts)
                    Padding(
                      key: ValueKey<String>(toast.id),
                      padding: const EdgeInsets.only(top: Spacing.sm),
                      child: _ToastCard(
                        toast: toast,
                        fromTop: compact,
                        onDismiss: () => ref.toasts.dismiss(toast.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({
    required this.toast,
    required this.onDismiss,
    required this.fromTop,
  });

  final ToastMessage toast;
  final VoidCallback onDismiss;
  final bool fromTop;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: Motion.medium,
  )..forward();

  late final AnimationController _life = AnimationController(
    vsync: this,
    duration: widget.toast.duration,
  )..forward();

  @override
  void initState() {
    super.initState();
    // Touch the progress controller here rather than letting `build` create it
    // lazily: under reduced motion the progress bar is never built, and a
    // controller first constructed in `dispose()` cannot attach its ticker.
    _life.isAnimating;
  }

  @override
  void dispose() {
    _enter.dispose();
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (Color accent, IconData icon) = switch (widget.toast.kind) {
      ToastKind.success => (colors.success, AppIcons.success),
      ToastKind.error => (colors.danger, AppIcons.error),
      ToastKind.warning => (colors.warning, AppIcons.warning),
      ToastKind.info => (colors.brand, AppIcons.info),
    };

    final Animation<double> eased = CurvedAnimation(
      parent: _enter,
      curve: Motion.emphasized,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, widget.fromTop ? -0.4 : 0.4),
        end: Offset.zero,
      ).animate(eased),
      child: FadeTransition(
        opacity: eased,
        child: Dismissible(
          key: ValueKey<String>('dismiss-${widget.toast.id}'),
          direction: DismissDirection.horizontal,
          onDismissed: (_) => widget.onDismiss(),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surfaceOverlay,
                borderRadius: Radii.brLg,
                border: Border.all(color: colors.hairline),
                boxShadow: Shadows.lg(colors.isDark),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.md,
                      Spacing.md,
                      Spacing.sm,
                      Spacing.md,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.14),
                            borderRadius: Radii.brSm,
                          ),
                          child: Icon(icon, size: 15, color: accent),
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.toast.message,
                                style: context.textStyles.titleSmall,
                              ),
                              if (widget.toast.description != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    widget.toast.description!,
                                    style: context.textStyles.bodySmall
                                        ?.copyWith(color: colors.inkMuted),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (widget.toast.actionLabel != null) ...<Widget>[
                          const SizedBox(width: Spacing.sm),
                          TextButton(
                            onPressed: () {
                              widget.toast.onAction?.call();
                              widget.onDismiss();
                            },
                            child: Text(widget.toast.actionLabel!),
                          ),
                        ],
                        IconButton(
                          icon: const Icon(AppIcons.close, size: 14),
                          onPressed: widget.onDismiss,
                          splashRadius: 14,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 26,
                            minHeight: 26,
                          ),
                          color: colors.inkFaint,
                          tooltip: context.l10n.actionClose,
                        ),
                      ],
                    ),
                  ),
                  // Time-remaining bar: makes the auto-dismiss legible instead
                  // of the toast vanishing without warning.
                  if (!context.reducedMotion)
                    AnimatedBuilder(
                      animation: _life,
                      builder: (BuildContext context, _) =>
                          LinearProgressIndicator(
                            value: 1 - _life.value,
                            minHeight: 2,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              accent.withValues(alpha: 0.55),
                            ),
                          ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
