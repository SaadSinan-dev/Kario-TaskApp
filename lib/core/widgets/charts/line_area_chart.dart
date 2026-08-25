import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/charts/chart_core.dart';

/// Smoothed line chart with an optional gradient area fill.
///
/// Curves use a monotone cubic so the line never overshoots below zero — an
/// artefact that makes "tasks completed" charts look wrong even when the data
/// is right.
class LineAreaChart extends StatefulWidget {
  const LineAreaChart({
    required this.series,
    this.maxLabels = 7,
    this.showGrid = true,
    this.valueFormatter,
    super.key,
  });

  final List<ChartSeries> series;
  final int maxLabels;
  final bool showGrid;
  final String Function(double value)? valueFormatter;

  @override
  State<LineAreaChart> createState() => _LineAreaChartState();
}

class _LineAreaChartState extends State<LineAreaChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: Motion.deliberate,
  );

  int? _hoverIndex;

  @override
  void initState() {
    super.initState();
    _reveal.forward();
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  int get _pointCount =>
      widget.series.isEmpty ? 0 : widget.series.first.points.length;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (widget.series.isEmpty || _pointCount == 0) {
      return const SizedBox.shrink();
    }

    final double rawMax = widget.series
        .map((ChartSeries s) => s.maxValue)
        .reduce(math.max);
    final double maxValue = niceCeiling(rawMax);
    const double labelWidth = 30;
    const double axisHeight = 20;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double plotWidth = constraints.maxWidth - labelWidth;
        final double plotHeight = constraints.maxHeight - axisHeight;

        return MouseRegion(
          onHover: (PointerHoverEvent event) {
            final double x = event.localPosition.dx - labelWidth;
            if (x < 0 || plotWidth <= 0) {
              if (_hoverIndex != null) setState(() => _hoverIndex = null);
              return;
            }
            final int index = ((x / plotWidth) * (_pointCount - 1))
                .round()
                .clamp(0, _pointCount - 1);
            if (index != _hoverIndex) setState(() => _hoverIndex = index);
          },
          onExit: (_) => setState(() => _hoverIndex = null),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                bottom: axisHeight,
                // The line chart is a hand-painted layer that animates on
                // reveal and on hover. Isolating it means those repaints stay
                // inside the chart instead of dirtying the panel, the legend
                // and the surrounding page.
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _reveal,
                    builder: (BuildContext context, _) => CustomPaint(
                      painter: _LinePainter(
                        series: widget.series,
                        maxValue: maxValue,
                        progress: context.reducedMotion ? 1 : _reveal.value,
                        labelWidth: labelWidth,
                        gridColor: colors.chartGrid,
                        labelColor: colors.inkFaint,
                        showGrid: widget.showGrid,
                        hoverIndex: _hoverIndex,
                        surfaceColor: colors.surface,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: labelWidth,
                right: 0,
                bottom: 0,
                height: axisHeight,
                child: _AxisLabels(
                  points: widget.series.first.points,
                  maxLabels: widget.maxLabels,
                  highlight: _hoverIndex,
                ),
              ),
              if (_hoverIndex != null)
                _HoverTooltip(
                  index: _hoverIndex!,
                  series: widget.series,
                  plotWidth: plotWidth,
                  labelWidth: labelWidth,
                  plotHeight: plotHeight,
                  formatter: widget.valueFormatter,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HoverTooltip extends StatelessWidget {
  const _HoverTooltip({
    required this.index,
    required this.series,
    required this.plotWidth,
    required this.labelWidth,
    required this.plotHeight,
    this.formatter,
  });

  final int index;
  final List<ChartSeries> series;
  final double plotWidth;
  final double labelWidth;
  final double plotHeight;
  final String Function(double)? formatter;

  @override
  Widget build(BuildContext context) {
    final int count = series.first.points.length;
    final double step = count <= 1 ? 0 : plotWidth / (count - 1);
    final double x = labelWidth + step * index;
    final bool flip = x > plotWidth * 0.65;

    return Positioned(
      left: flip ? null : x + 10,
      right: flip ? plotWidth + labelWidth - x + 10 : null,
      top: 4,
      child: ChartTooltip(
        title:
            series.first.points[index].meta ?? series.first.points[index].label,
        rows: <({String label, Color color, String value})>[
          for (final ChartSeries s in series)
            if (index < s.points.length)
              (
                label: s.name,
                color: s.color,
                value:
                    formatter?.call(s.points[index].value) ??
                    s.points[index].value.round().toString(),
              ),
        ],
      ),
    );
  }
}

class _AxisLabels extends StatelessWidget {
  const _AxisLabels({
    required this.points,
    required this.maxLabels,
    this.highlight,
  });

  final List<ChartPoint> points;
  final int maxLabels;
  final int? highlight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final int stride = math.max(1, (points.length / maxLabels).ceil());
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            for (int i = 0; i < points.length; i++)
              if (i % stride == 0 || i == points.length - 1)
                Positioned(
                  left: points.length <= 1
                      ? 0
                      : (i / (points.length - 1)) * width,
                  top: 4,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, 0),
                    child: Text(
                      points[i].label,
                      style: context.textStyles.labelSmall?.copyWith(
                        fontSize: 10,
                        color: i == highlight ? colors.ink : colors.inkFaint,
                        fontWeight: i == highlight
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({
    required this.series,
    required this.maxValue,
    required this.progress,
    required this.labelWidth,
    required this.gridColor,
    required this.labelColor,
    required this.showGrid,
    required this.surfaceColor,
    this.hoverIndex,
  });

  final List<ChartSeries> series;
  final double maxValue;
  final double progress;
  final double labelWidth;
  final Color gridColor;
  final Color labelColor;
  final Color surfaceColor;
  final bool showGrid;
  final int? hoverIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) {
      ChartGrid(
        maxValue: maxValue,
        gridColor: gridColor,
        labelColor: labelColor,
        divisions: 4,
        labelWidth: labelWidth,
      ).paint(canvas, size);
    }

    final double plotWidth = size.width - labelWidth;
    final int count = series.first.points.length;
    if (count == 0 || plotWidth <= 0) return;

    for (final ChartSeries s in series) {
      final List<Offset> pts = <Offset>[
        for (int i = 0; i < s.points.length; i++)
          Offset(
            labelWidth + (count == 1 ? 0 : plotWidth * (i / (count - 1))),
            size.height -
                (s.points[i].value / (maxValue == 0 ? 1 : maxValue)) *
                    size.height *
                    progress,
          ),
      ];
      if (pts.isEmpty) continue;

      final Path line = _monotonePath(pts);

      if (s.filled) {
        final Path area = Path.from(line)
          ..lineTo(pts.last.dx, size.height)
          ..lineTo(pts.first.dx, size.height)
          ..close();
        canvas.drawPath(
          area,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                s.color.withValues(alpha: 0.26),
                s.color.withValues(alpha: 0.02),
              ],
            ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
        );
      }

      canvas.drawPath(
        line,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      final int? hover = hoverIndex;
      if (hover != null && hover < pts.length) {
        final Offset point = pts[hover];
        canvas.drawLine(
          Offset(point.dx, 0),
          Offset(point.dx, size.height),
          Paint()
            ..color = gridColor
            ..strokeWidth = 1,
        );
        canvas.drawCircle(point, 5.5, Paint()..color = surfaceColor);
        canvas.drawCircle(
          point,
          4.5,
          Paint()
            ..color = s.color
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  /// Monotone cubic interpolation: smooth, but guaranteed not to overshoot
  /// between data points.
  Path _monotonePath(List<Offset> points) {
    final Path path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length < 3) {
      for (final Offset point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      return path;
    }
    for (int i = 0; i < points.length - 1; i++) {
      final Offset current = points[i];
      final Offset next = points[i + 1];
      final double dx = (next.dx - current.dx) * 0.42;
      path.cubicTo(
        current.dx + dx,
        current.dy,
        next.dx - dx,
        next.dy,
        next.dx,
        next.dy,
      );
    }
    return path;
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.progress != progress ||
      old.hoverIndex != hoverIndex ||
      old.maxValue != maxValue ||
      old.series != series;
}

/// A tiny trend line with no axes, for metric tiles.
class Sparkline extends StatelessWidget {
  const Sparkline({
    required this.values,
    required this.color,
    this.height = 32,
    this.filled = true,
    super.key,
  });

  final List<double> values;
  final Color color;
  final double height;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return SizedBox(height: height);
    return SizedBox(
      height: height,
      width: double.infinity,
      // Sparklines sit inside metric tiles whose counters animate on every
      // data change; the boundary keeps the two from repainting each other.
      child: RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: context.motion(Motion.slow),
          curve: Motion.entrance,
          builder: (BuildContext context, double t, _) => CustomPaint(
            painter: _SparklinePainter(
              values: values,
              color: color,
              progress: t,
              filled: filled,
            ),
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.values,
    required this.color,
    required this.progress,
    required this.filled,
  });

  final List<double> values;
  final Color color;
  final double progress;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final double maxValue = values.reduce(math.max);
    final double range = maxValue == 0 ? 1 : maxValue;
    final Path path = Path();

    for (int i = 0; i < values.length; i++) {
      final double x = size.width * (i / (values.length - 1));
      final double y =
          size.height - (values[i] / range) * size.height * progress;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    if (filled) {
      final Path area = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              color.withValues(alpha: 0.24),
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.progress != progress || old.values != values;
}
