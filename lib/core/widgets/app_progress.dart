import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/theme/app_typography.dart';
import 'package:kairo/core/theme/design_tokens.dart';

/// A number that counts up to its value when it changes.
///
/// Used for every metric in the product. Tabular figures keep the width stable
/// so the layout does not shiver while the number climbs.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    required this.value,
    this.style,
    this.suffix = '',
    this.prefix = '',
    this.duration = Motion.deliberate,
    this.decimals = 0,
    super.key,
  });

  final num value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final Duration duration;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    final TextStyle resolved = (style ?? context.textStyles.headlineMedium!)
        .merge(
          const TextStyle(
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
          ),
        );

    if (context.reducedMotion) {
      return Text(
        '$prefix${value.toStringAsFixed(decimals)}$suffix',
        style: resolved,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Motion.entrance,
      builder: (BuildContext context, double animated, _) => Text(
        '$prefix${animated.toStringAsFixed(decimals)}$suffix',
        style: resolved,
      ),
    );
  }
}

/// Circular progress with an animated sweep. Used for project completion and
/// subtask progress.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.value,
    this.size = 40,
    this.strokeWidth = 4,
    this.color,
    this.trackColor,
    this.child,
    this.duration = Motion.slow,
    super.key,
  });

  /// 0…1.
  final double value;

  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final Widget? child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value.clamp(0, 1)),
        duration: context.motion(duration),
        curve: Motion.entrance,
        builder: (BuildContext context, double animated, Widget? inner) {
          return CustomPaint(
            painter: _RingPainter(
              value: animated,
              strokeWidth: strokeWidth,
              color: color ?? colors.brand,
              track: trackColor ?? colors.hairline,
            ),
            child: Center(child: inner),
          );
        },
        child: child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.strokeWidth,
    required this.color,
    required this.track,
  });

  final double value;
  final double strokeWidth;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (size.shortestSide - strokeWidth) / 2;

    final Paint trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (value <= 0) return;

    final Paint progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// The dashboard's headline number.
///
/// A gradient arc, a tick scale and a counting figure. Deliberately the only
/// place in the app that gets this much visual weight — it is the one number
/// the whole screen is arranged around.
class ScoreDial extends StatelessWidget {
  const ScoreDial({
    required this.score,
    this.size = 168,
    this.label,
    this.caption,
    super.key,
  });

  /// 0…100.
  final int score;

  final double size;
  final String? label;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: score / 100),
        duration: context.motion(Motion.deliberate),
        curve: Motion.entrance,
        builder: (BuildContext context, double animated, _) {
          return CustomPaint(
            painter: _ScoreDialPainter(
              value: animated,
              start: colors.brand,
              end: colors.accent,
              track: colors.hairline,
              tick: colors.hairlineStrong,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '${(animated * 100).round()}',
                        style: AppTypography.numeric.copyWith(
                          fontSize: size * 0.28,
                          height: 1,
                          color: colors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: size * 0.05),
                        child: Text(
                          '%',
                          style: TextStyle(
                            fontSize: size * 0.11,
                            fontWeight: FontWeight.w700,
                            color: colors.inkFaint,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (label != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        label!,
                        style: context.textStyles.labelSmall?.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                    ),
                  if (caption != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        caption!,
                        style: context.textStyles.labelSmall?.copyWith(
                          color: colors.inkFaint,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScoreDialPainter extends CustomPainter {
  const _ScoreDialPainter({
    required this.value,
    required this.start,
    required this.end,
    required this.track,
    required this.tick,
  });

  final double value;
  final Color start;
  final Color end;
  final Color track;
  final Color tick;

  /// The dial is a 270° arc starting at the lower left, which reads as a gauge
  /// rather than a pie chart.
  static const double _startAngle = math.pi * 0.75;
  static const double _sweep = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double stroke = size.shortestSide * 0.075;
    final double radius = (size.shortestSide - stroke) / 2 - 6;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      _sweep,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    // Tick marks every 10%, so the gauge can be read without the number.
    final Paint tickPaint = Paint()
      ..color = tick
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i <= 10; i++) {
      final double angle = _startAngle + _sweep * (i / 10);
      final double inner = radius + stroke / 2 + 3;
      final double outer = inner + (i % 5 == 0 ? 6 : 3);
      canvas.drawLine(
        center + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
        center + Offset(math.cos(angle) * outer, math.sin(angle) * outer),
        tickPaint,
      );
    }

    if (value <= 0) return;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      _sweep * value,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: _startAngle,
          endAngle: _startAngle + _sweep,
          colors: <Color>[start, end],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    // A soft dot at the head of the arc gives the gauge a sense of direction.
    final double headAngle = _startAngle + _sweep * value;
    final Offset head =
        center +
        Offset(math.cos(headAngle) * radius, math.sin(headAngle) * radius);
    canvas.drawCircle(
      head,
      stroke * 0.62,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
    canvas.drawCircle(head, stroke * 0.30, Paint()..color = end);
  }

  @override
  bool shouldRepaint(_ScoreDialPainter old) =>
      old.value != value || old.start != start || old.track != track;
}

/// Linear progress with a rounded track and animated fill.
class AppLinearProgress extends StatelessWidget {
  const AppLinearProgress({
    required this.value,
    this.height = 6,
    this.color,
    this.trackColor,
    this.duration = Motion.slow,
    super.key,
  });

  final double value;
  final double height;
  final Color? color;
  final Color? trackColor;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value.clamp(0, 1)),
        duration: context.motion(duration),
        curve: Motion.entrance,
        builder: (BuildContext context, double animated, _) => Container(
          height: height,
          color: trackColor ?? colors.hairline,
          child: FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: animated,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    color ?? colors.brand,
                    color ?? colors.accent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Segmented progress used for subtasks: one pip per item, filled as they are
/// completed. Reads faster than a percentage at small counts.
class SegmentedProgress extends StatelessWidget {
  const SegmentedProgress({
    required this.total,
    required this.completed,
    this.height = 4,
    this.gap = 3,
    this.color,
    super.key,
  });

  final int total;
  final int completed;
  final double height;
  final double gap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (total == 0) return const SizedBox.shrink();
    return Row(
      children: <Widget>[
        for (int i = 0; i < total; i++) ...<Widget>[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: AnimatedContainer(
              duration: context.motion(Motion.base),
              curve: Motion.entrance,
              height: height,
              decoration: BoxDecoration(
                color: i < completed
                    ? (color ?? colors.success)
                    : colors.hairline,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
