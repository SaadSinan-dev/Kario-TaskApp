import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kairo/core/extensions/context_extensions.dart';

/// The Kairo mark.
///
/// An orbit that has not quite closed, with a solid dot at its leading end: the
/// moment work arrives at the right point. Drawn rather than shipped as an
/// asset so it scales cleanly, follows the theme, and needs no image decoding
/// before the first frame.
class BrandMark extends StatelessWidget {
  const BrandMark({
    this.size = 32,
    this.showWordmark = true,
    this.onDark = false,
    super.key,
  });

  final double size;
  final bool showWordmark;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Widget mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: onDark
            ? LinearGradient(
                colors: <Color>[
                  Colors.white.withValues(alpha: 0.95),
                  Colors.white.withValues(alpha: 0.75),
                ],
              )
            : colors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.27),
      ),
      child: CustomPaint(
        painter: _MarkPainter(color: onDark ? colors.brand : Colors.white),
      ),
    );

    if (!showWordmark) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        mark,
        SizedBox(width: size * 0.32),
        Text(
          'Kairo',
          style: TextStyle(
            fontSize: size * 0.62,
            fontWeight: FontWeight.w800,
            letterSpacing: -size * 0.028,
            height: 1,
            color: onDark ? Colors.white : colors.ink,
          ),
        ),
      ],
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.shortestSide * 0.28;
    final double stroke = size.shortestSide * 0.115;

    // A 250° arc, leaving the gap that the dot then closes.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.72,
      math.pi * 1.39,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    const double angle = math.pi * 0.72 + math.pi * 1.39;
    canvas.drawCircle(
      center + Offset(math.cos(angle) * radius, math.sin(angle) * radius),
      stroke * 0.92,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color;
}

/// A faint grid used behind hero and auth panels. Cheap, on-brand texture that
/// keeps large flat areas from looking unfinished.
class BrandGridPattern extends StatelessWidget {
  const BrandGridPattern({
    this.spacing = 44,
    this.opacity = 0.10,
    this.color,
    super.key,
  });

  final double spacing;
  final double opacity;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GridPainter(
          spacing: spacing,
          color: (color ?? Colors.white).withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.spacing, required this.color});

  final double spacing;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.spacing != spacing || old.color != color;
}
