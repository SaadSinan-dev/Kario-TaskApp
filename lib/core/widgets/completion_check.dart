import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/theme/design_tokens.dart';

/// The task completion control.
///
/// The interaction people perform most, so it gets the most care: the ring
/// fills, the tick draws itself along its own path, the whole control pops
/// once, and a soft ring expands outward. It reads as *finishing* something
/// rather than toggling a boolean — and it all collapses to an instant state
/// change when motion is reduced.
class CompletionCheckbox extends StatefulWidget {
  const CompletionCheckbox({
    required this.isCompleted,
    required this.onChanged,
    this.size = 20,
    this.color,
    this.enabled = true,
    this.semanticLabel,
    super.key,
  });

  final bool isCompleted;
  final ValueChanged<bool> onChanged;
  final double size;
  final Color? color;
  final bool enabled;
  final String? semanticLabel;

  @override
  State<CompletionCheckbox> createState() => _CompletionCheckboxState();
}

class _CompletionCheckboxState extends State<CompletionCheckbox>
    with TickerProviderStateMixin {
  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: Motion.medium,
    value: widget.isCompleted ? 1 : 0,
  );

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  bool _hovered = false;

  @override
  void didUpdateWidget(covariant CompletionCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCompleted != widget.isCompleted) {
      if (widget.isCompleted) {
        _fill.forward();
        if (!context.reducedMotion) _pulse.forward(from: 0);
      } else {
        _fill.reverse();
      }
    }
  }

  @override
  void dispose() {
    _fill.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color accent = widget.color ?? colors.success;

    return Semantics(
      checked: widget.isCompleted,
      enabled: widget.enabled,
      label:
          widget.semanticLabel ??
          (widget.isCompleted
              ? context.l10n.tasksMarkIncomplete
              : context.l10n.tasksMarkComplete),
      child: Tooltip(
        message: widget.isCompleted
            ? context.l10n.tasksMarkIncomplete
            : context.l10n.tasksMarkComplete,
        waitDuration: const Duration(milliseconds: 600),
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.enabled
                ? () => widget.onChanged(!widget.isCompleted)
                : null,
            child: SizedBox(
              // Padded to a 40dp target while the glyph stays small.
              width: math.max(widget.size + 14, 32),
              height: math.max(widget.size + 14, 32),
              child: Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge(<Listenable>[_fill, _pulse]),
                  builder: (BuildContext context, _) {
                    final double fill = Curves.easeOutBack
                        .transform(_fill.value.clamp(0, 1))
                        .clamp(0.0, 1.0);
                    return CustomPaint(
                      size: Size.square(widget.size),
                      painter: _CheckPainter(
                        progress: fill,
                        pulse: _pulse.value,
                        accent: accent,
                        idleBorder: _hovered
                            ? colors.hairlineStrong
                            : colors.hairline,
                        hovered: _hovered,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({
    required this.progress,
    required this.pulse,
    required this.accent,
    required this.idleBorder,
    required this.hovered,
  });

  final double progress;
  final double pulse;
  final Color accent;
  final Color idleBorder;
  final bool hovered;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.shortestSide / 2;

    // Expanding ring on completion.
    if (pulse > 0 && pulse < 1) {
      canvas.drawCircle(
        center,
        radius * (1 + pulse * 0.9),
        Paint()
          ..color = accent.withValues(alpha: (1 - pulse) * 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * (1 - pulse),
      );
    }

    // Track.
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..color = Color.lerp(idleBorder, accent, progress)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    if (hovered && progress < 0.05) {
      canvas.drawCircle(
        center,
        radius - 2,
        Paint()..color = accent.withValues(alpha: 0.08),
      );
    }

    if (progress <= 0) return;

    // Filled disc grows from the centre.
    canvas.drawCircle(center, (radius - 1) * progress, Paint()..color = accent);

    // Tick, drawn as a two-segment path revealed left to right.
    final double tick = ((progress - 0.35) / 0.65).clamp(0, 1);
    if (tick <= 0) return;

    final Path path = Path();
    final Offset a = center + Offset(-radius * 0.40, radius * 0.02);
    final Offset b = center + Offset(-radius * 0.10, radius * 0.32);
    final Offset c = center + Offset(radius * 0.42, -radius * 0.30);

    if (tick < 0.5) {
      final double t = tick / 0.5;
      path
        ..moveTo(a.dx, a.dy)
        ..lineTo(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);
    } else {
      final double t = (tick - 0.5) / 0.5;
      path
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(b.dx + (c.dx - b.dx) * t, b.dy + (c.dy - b.dy) * t);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.progress != progress ||
      old.pulse != pulse ||
      old.hovered != hovered ||
      old.accent != accent;
}

/// A restrained particle burst for completion moments.
///
/// Fourteen small brand-coloured shards, 900ms, gravity applied. Enough to
/// register as a reward; short enough that it never blocks the next action, and
/// suppressed entirely under reduced motion or if the user turns effects off.
class CompletionBurst extends StatefulWidget {
  const CompletionBurst({
    required this.controller,
    this.particleCount = 14,
    super.key,
  });

  /// Call `forward(from: 0)` to fire the burst.
  final AnimationController controller;

  final int particleCount;

  @override
  State<CompletionBurst> createState() => _CompletionBurstState();
}

class _CompletionBurstState extends State<CompletionBurst> {
  late final List<_Particle> _particles = _build();

  List<_Particle> _build() {
    final math.Random random = math.Random();
    return <_Particle>[
      for (int i = 0; i < widget.particleCount; i++)
        _Particle(
          angle:
              (i / widget.particleCount) * math.pi * 2 +
              random.nextDouble() * 0.4,
          distance: 26 + random.nextDouble() * 34,
          size: 3 + random.nextDouble() * 3.5,
          spin: (random.nextDouble() - 0.5) * 6,
          colorIndex: i % 4,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (context.reducedMotion) return const SizedBox.shrink();
    final colors = context.colors;
    final List<Color> palette = <Color>[
      colors.success,
      colors.brand,
      colors.accent,
      colors.teal,
    ];

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (BuildContext context, _) {
          if (widget.controller.value == 0 || widget.controller.isCompleted) {
            return const SizedBox.shrink();
          }
          return CustomPaint(
            painter: _BurstPainter(
              progress: widget.controller.value,
              particles: _particles,
              palette: palette,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.spin,
    required this.colorIndex,
  });

  final double angle;
  final double distance;
  final double size;
  final double spin;
  final int colorIndex;
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter({
    required this.progress,
    required this.particles,
    required this.palette,
  });

  final double progress;
  final List<_Particle> particles;
  final List<Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset origin = size.center(Offset.zero);
    final double eased = Curves.easeOutCubic.transform(progress);
    final double fade = (1 - progress).clamp(0, 1);

    for (final _Particle particle in particles) {
      final double travel = particle.distance * eased;
      // A little gravity so the shards fall rather than float.
      final double gravity = 26 * progress * progress;
      final Offset position =
          origin +
          Offset(
            math.cos(particle.angle) * travel,
            math.sin(particle.angle) * travel + gravity,
          );

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(particle.spin * progress);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 1.7,
          ),
          const Radius.circular(1),
        ),
        Paint()..color = palette[particle.colorIndex].withValues(alpha: fade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.progress != progress;
}
