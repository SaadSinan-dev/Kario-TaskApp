import 'package:flutter/material.dart';
import 'package:kairo/core/theme/design_tokens.dart';

/// Carries the *effective* reduce-motion decision down the tree.
///
/// Two inputs feed it: the platform accessibility setting
/// ([MediaQuery.disableAnimationsOf]) and the app's own preference. Either one
/// is enough to switch motion off. Every animated widget in Kairo asks this
/// rather than reading the preference directly, so there is exactly one place
/// where "should this move?" is decided.
class MotionScope extends InheritedWidget {
  const MotionScope({
    required this.reduceMotion,
    required super.child,
    super.key,
  });

  final bool reduceMotion;

  static bool of(BuildContext context) {
    final MotionScope? scope = context
        .dependOnInheritedWidgetOfExactType<MotionScope>();
    final bool platform = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return platform || (scope?.reduceMotion ?? false);
  }

  @override
  bool updateShouldNotify(MotionScope oldWidget) =>
      oldWidget.reduceMotion != reduceMotion;
}

extension MotionContext on BuildContext {
  bool get reducedMotion => MotionScope.of(this);

  /// Collapses a duration to zero when motion is reduced. Widgets keep their
  /// animation code; it simply completes instantly.
  Duration motion(Duration duration) =>
      reducedMotion ? Duration.zero : duration;

  /// Curves stay linear when motion is reduced so nothing overshoots on the
  /// single frame it gets.
  Curve motionCurve(Curve curve) => reducedMotion ? Curves.linear : curve;
}

/// Fade-and-rise entrance used by cards, list rows and dashboard tiles.
///
/// Deliberately one widget rather than a scattering of ad-hoc
/// [TweenAnimationBuilder]s: the delay, distance and curve are the same
/// everywhere, which is most of what makes a motion system feel designed.
class Entrance extends StatelessWidget {
  const Entrance({
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.duration = Motion.medium,
    this.offset = 10,
    this.scale,
    super.key,
  });

  final Widget child;

  /// Position in a list — turns into a capped stagger.
  final int index;

  final Duration delay;
  final Duration duration;

  /// Vertical travel in logical pixels.
  final double offset;

  /// Optional starting scale for tiles that should also "pop" slightly.
  final double? scale;

  @override
  Widget build(BuildContext context) {
    if (context.reducedMotion) return child;
    final Duration total = delay + Motion.staggerFor(index);
    return _DelayedEntrance(
      delay: total,
      duration: duration,
      offset: offset,
      scale: scale,
      child: child,
    );
  }
}

class _DelayedEntrance extends StatefulWidget {
  const _DelayedEntrance({
    required this.delay,
    required this.duration,
    required this.offset,
    required this.child,
    this.scale,
  });

  final Duration delay;
  final Duration duration;
  final double offset;
  final double? scale;
  final Widget child;

  @override
  State<_DelayedEntrance> createState() => _DelayedEntranceState();
}

class _DelayedEntranceState extends State<_DelayedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> eased = CurvedAnimation(
      parent: _controller,
      curve: Motion.entrance,
    );
    return AnimatedBuilder(
      animation: eased,
      builder: (BuildContext context, Widget? child) {
        final double t = eased.value;
        Widget result = Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - t)),
            child: child,
          ),
        );
        final double? from = widget.scale;
        if (from != null) {
          result = Transform.scale(scale: from + (1 - from) * t, child: result);
        }
        return result;
      },
      child: widget.child,
    );
  }
}

/// Pointer-driven lift for cards and rows on desktop and web.
///
/// Touch devices never see a hover state, so the widget stays inert there
/// rather than reacting to a tap-and-hold.
class HoverLift extends StatefulWidget {
  const HoverLift({
    required this.child,
    this.enabled = true,
    this.lift = 2,
    this.scale = 1.0,
    this.cursor = SystemMouseCursors.click,
    super.key,
  });

  final Widget child;
  final bool enabled;
  final double lift;
  final double scale;
  final MouseCursor cursor;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final bool active = _hovered && !context.reducedMotion;
    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedSlide(
        offset: Offset(0, active ? -widget.lift / 100 : 0),
        duration: context.motion(Motion.fast),
        curve: Motion.entrance,
        child: AnimatedScale(
          scale: active ? widget.scale : 1,
          duration: context.motion(Motion.fast),
          curve: Motion.entrance,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Scale-down feedback on press. Wraps any tappable surface so the whole app
/// responds to touch the same way.
class PressableScale extends StatefulWidget {
  const PressableScale({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.scale = 0.97,
    this.enabled = true,
    this.borderRadius,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final double scale;
  final bool enabled;
  final BorderRadius? borderRadius;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool interactive = widget.enabled && widget.onTap != null;
    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      onSecondaryTap: widget.enabled ? widget.onSecondaryTap : null,
      onTapDown: interactive ? (_) => _set(true) : null,
      onTapUp: interactive ? (_) => _set(false) : null,
      onTapCancel: interactive ? () => _set(false) : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed && !context.reducedMotion ? widget.scale : 1,
        duration: context.motion(Motion.instant),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
