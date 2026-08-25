import 'package:flutter/material.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/theme/design_tokens.dart';

/// A shimmering placeholder block.
///
/// Skeletons instead of spinners: they hold the shape of what is coming, so the
/// page does not jump when data lands. The shimmer stops entirely when motion
/// is reduced, leaving a static block.
class Skeleton extends StatefulWidget {
  const Skeleton({
    this.width,
    this.height = 14,
    this.radius = Radii.sm,
    this.margin,
    super.key,
  });

  /// Convenience for a circular avatar placeholder.
  const Skeleton.circle({double size = 32, super.key})
    : width = size,
      height = size,
      radius = size / 2,
      margin = null;

  final double? width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  // Created eagerly, and only *running* when motion is allowed. A lazily
  // created controller would be constructed inside `dispose()` on a reduced
  // motion build — which needs a live element to attach its ticker to.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    _controller.value = 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MotionScope.of(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color base = colors.isDark
        ? colors.surfaceRaised
        : colors.surfaceSunken;
    final Color highlight = colors.isDark
        ? colors.surfaceOverlay
        : Colors.white;

    final Widget block = Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    );

    if (context.reducedMotion) return block;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) {
            final double t = _controller.value;
            return LinearGradient(
              begin: Alignment(-1 - 2 * (1 - t), 0),
              end: Alignment(1 - 2 * (1 - t), 0),
              colors: <Color>[
                base,
                highlight.withValues(alpha: colors.isDark ? 0.35 : 0.9),
                base,
              ],
              stops: const <double>[0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: block,
    );
  }
}

/// Placeholder matching the shape of a task row.
class TaskRowSkeleton extends StatelessWidget {
  const TaskRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.md,
      ),
      child: Row(
        children: <Widget>[
          Skeleton(width: 18, height: 18, radius: Radii.xs),
          SizedBox(width: Spacing.md),
          Expanded(child: Skeleton(height: 13)),
          SizedBox(width: Spacing.xxl),
          Skeleton(width: 62, height: 11),
          SizedBox(width: Spacing.lg),
          Skeleton(width: 48, height: 11),
          SizedBox(width: Spacing.lg),
          Skeleton.circle(size: 24),
        ],
      ),
    );
  }
}

/// Placeholder for a dashboard metric tile.
class MetricCardSkeleton extends StatelessWidget {
  const MetricCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: Radii.brLg,
        border: Border.all(color: context.colors.hairline),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Skeleton(width: 84, height: 11),
          SizedBox(height: Spacing.md),
          Skeleton(width: 56, height: 26, radius: Radii.sm),
          SizedBox(height: Spacing.sm),
          Skeleton(width: 110, height: 10),
        ],
      ),
    );
  }
}

/// Placeholder for a chart panel.
class ChartSkeleton extends StatelessWidget {
  const ChartSkeleton({this.height = 220, super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: Radii.brLg,
        border: Border.all(color: context.colors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Skeleton(width: 130, height: 13),
          const SizedBox(height: Spacing.xl),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (final double factor in <double>[
                  0.4,
                  0.7,
                  0.55,
                  0.85,
                  0.6,
                  0.95,
                  0.5,
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FractionallySizedBox(
                        heightFactor: factor,
                        alignment: Alignment.bottomCenter,
                        child: const Skeleton(height: double.infinity),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder for a project card.
class ProjectCardSkeleton extends StatelessWidget {
  const ProjectCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: Radii.brLg,
        border: Border.all(color: context.colors.hairline),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Skeleton(width: 34, height: 34, radius: Radii.md),
              SizedBox(width: Spacing.md),
              Expanded(child: Skeleton(height: 13)),
            ],
          ),
          SizedBox(height: Spacing.lg),
          Skeleton(height: 10),
          SizedBox(height: Spacing.sm),
          Skeleton(width: 160, height: 10),
          SizedBox(height: Spacing.lg),
          Skeleton(height: 6, radius: Radii.pill),
        ],
      ),
    );
  }
}

/// Repeats a skeleton [count] times with the list's own spacing.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    required this.itemBuilder,
    this.count = 6,
    this.separator = 1,
    super.key,
  });

  final WidgetBuilder itemBuilder;
  final int count;
  final double separator;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < count; i++) ...<Widget>[
          if (i > 0) SizedBox(height: separator),
          itemBuilder(context),
        ],
      ],
    );
  }
}
