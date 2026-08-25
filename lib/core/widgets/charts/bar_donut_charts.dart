import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/theme/app_typography.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/charts/chart_core.dart';

/// Vertical bars with an animated grow-from-baseline reveal.
///
/// Used for workload by day. Bars are the right mark when the x-axis is a set
/// of discrete buckets rather than a continuum — which is why the completion
/// trend is a line and this is not.
class AppBarChart extends StatefulWidget {
  const AppBarChart({
    required this.points,
    required this.color,
    this.secondaryPoints,
    this.secondaryColor,
    this.highlightToday = true,
    super.key,
  });

  final List<ChartPoint> points;
  final Color color;

  /// Optional second series, drawn stacked behind the first.
  final List<ChartPoint>? secondaryPoints;
  final Color? secondaryColor;

  final bool highlightToday;

  @override
  State<AppBarChart> createState() => _AppBarChartState();
}

class _AppBarChartState extends State<AppBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: Motion.deliberate,
  )..forward();

  int? _hovered;

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (widget.points.isEmpty) return const SizedBox.shrink();

    final double rawMax = <double>[
      ...widget.points.map((ChartPoint p) => p.value),
      ...?widget.secondaryPoints?.map((ChartPoint p) => p.value),
    ].reduce(math.max);
    final double maxValue = niceCeiling(rawMax);

    return Column(
      children: <Widget>[
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int count = widget.points.length;
              final double slot = constraints.maxWidth / count;
              final double barWidth = math.min(slot * 0.52, 26);

              return Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ChartGrid(
                        maxValue: maxValue,
                        gridColor: colors.chartGrid,
                        labelColor: colors.inkFaint,
                        divisions: 4,
                        labelWidth: 26,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    left: 26,
                    child: AnimatedBuilder(
                      animation: _reveal,
                      builder: (BuildContext context, _) => Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          for (int i = 0; i < count; i++)
                            Expanded(
                              child: MouseRegion(
                                onEnter: (_) => setState(() => _hovered = i),
                                onExit: (_) => setState(() => _hovered = null),
                                child: _Bar(
                                  value: widget.points[i].value,
                                  secondary:
                                      widget.secondaryPoints == null ||
                                          i >= widget.secondaryPoints!.length
                                      ? 0
                                      : widget.secondaryPoints![i].value,
                                  maxValue: maxValue,
                                  width: barWidth,
                                  color: widget.color,
                                  secondaryColor:
                                      widget.secondaryColor ?? colors.hairline,
                                  progress: context.reducedMotion
                                      ? 1
                                      : Curves.easeOutCubic.transform(
                                          (_reveal.value * 1.6 -
                                                  i / (count * 1.4))
                                              .clamp(0.0, 1.0),
                                        ),
                                  hovered: _hovered == i,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_hovered != null)
                    Positioned(
                      left: 26 + slot * _hovered! - 30,
                      top: 0,
                      child: ChartTooltip(
                        title:
                            widget.points[_hovered!].meta ??
                            widget.points[_hovered!].label,
                        rows: <({String label, Color color, String value})>[
                          (
                            label: context.l10n.dashboardCompleted,
                            color: widget.color,
                            value: widget.points[_hovered!].value
                                .round()
                                .toString(),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Row(
            children: <Widget>[
              for (int i = 0; i < widget.points.length; i++)
                Expanded(
                  child: Text(
                    widget.points[i].label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: context.textStyles.labelSmall?.copyWith(
                      fontSize: 10,
                      color: _hovered == i ? colors.ink : colors.inkFaint,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.secondary,
    required this.maxValue,
    required this.width,
    required this.color,
    required this.secondaryColor,
    required this.progress,
    required this.hovered,
  });

  final double value;
  final double secondary;
  final double maxValue;
  final double width;
  final Color color;
  final Color secondaryColor;
  final double progress;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final double primaryFactor = maxValue == 0 ? 0 : value / maxValue;
    final double secondaryFactor = maxValue == 0 ? 0 : secondary / maxValue;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: width,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            if (secondary > 0)
              FractionallySizedBox(
                heightFactor: (secondaryFactor * progress).clamp(0.0, 1.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: secondaryColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            FractionallySizedBox(
              heightFactor: (primaryFactor * progress).clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: <Color>[
                      color.withValues(alpha: hovered ? 1 : 0.82),
                      color.withValues(alpha: hovered ? 0.9 : 0.62),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
class DonutSlice {
  const DonutSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

/// Donut chart with a centre readout.
///
/// Kept to four or five slices — beyond that the ranking is easier to read as a
/// bar list, which is what `HorizontalBarList` below is for.
class DonutChart extends StatefulWidget {
  const DonutChart({
    required this.slices,
    this.centerLabel,
    this.centerValue,
    this.thickness = 16,
    super.key,
  });

  final List<DonutSlice> slices;
  final String? centerLabel;
  final String? centerValue;
  final double thickness;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: Motion.deliberate,
  )..forward();

  int? _hovered;

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final double total = widget.slices.fold<double>(
      0,
      (double sum, DonutSlice slice) => sum + slice.value,
    );
    if (total == 0) return const SizedBox.shrink();

    // Hovering a slice repaints the ring; the boundary keeps that off the
    // legend and the panel around it.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _reveal,
        builder: (BuildContext context, _) => CustomPaint(
          painter: _DonutPainter(
            slices: widget.slices,
            total: total,
            progress: context.reducedMotion ? 1 : _reveal.value,
            thickness: widget.thickness,
            hovered: _hovered,
            gapColor: colors.surface,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.centerValue != null)
                  Text(
                    widget.centerValue!,
                    style: AppTypography.numeric.copyWith(
                      fontSize: 24,
                      color: colors.ink,
                    ),
                  ),
                if (widget.centerLabel != null)
                  Text(
                    widget.centerLabel!,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.slices,
    required this.total,
    required this.progress,
    required this.thickness,
    required this.gapColor,
    this.hovered,
  });

  final List<DonutSlice> slices;
  final double total;
  final double progress;
  final double thickness;
  final Color gapColor;
  final int? hovered;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (size.shortestSide - thickness) / 2;
    double start = -math.pi / 2;

    for (int i = 0; i < slices.length; i++) {
      final DonutSlice slice = slices[i];
      final double sweep = (slice.value / total) * math.pi * 2 * progress;
      final double weight = hovered == i ? thickness + 4 : thickness;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        // A hairline gap between slices keeps adjacent colours readable.
        math.max(sweep - 0.03, 0),
        false,
        Paint()
          ..color = slice.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = weight
          ..strokeCap = StrokeCap.butt,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress ||
      old.hovered != hovered ||
      old.slices != slices;
}

/// Ranked horizontal bars — the right mark for "tasks by project", where the
/// labels are long and the ordering is the message.
class HorizontalBarList extends StatelessWidget {
  const HorizontalBarList({
    required this.entries,
    this.maxEntries = 6,
    this.valueSuffix = '',
    super.key,
  });

  final List<({String label, double value, Color color})> entries;
  final int maxEntries;
  final String valueSuffix;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (entries.isEmpty) return const SizedBox.shrink();
    final double max = entries
        .map((({String label, double value, Color color}) e) => e.value)
        .reduce(math.max);
    final List<({String label, double value, Color color})> visible = entries
        .take(maxEntries)
        .toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        for (int i = 0; i < visible.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.xs + 1),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 108,
                  child: Text(
                    visible[i].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.labelMedium?.copyWith(
                      color: colors.inkSoft,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: max == 0 ? 0 : visible[i].value / max,
                    ),
                    duration: context.motion(Motion.slow + Motion.stagger * i),
                    curve: Motion.entrance,
                    builder: (BuildContext context, double t, _) => Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors.surfaceSunken,
                        borderRadius: Radii.brXs,
                      ),
                      child: FractionallySizedBox(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: t.clamp(0.0, 1.0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                visible[i].color,
                                visible[i].color.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: Radii.brXs,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                SizedBox(
                  width: 34,
                  child: Text(
                    '${visible[i].value.round()}$valueSuffix',
                    textAlign: TextAlign.end,
                    style: AppTypography.numeric.copyWith(
                      fontSize: 12,
                      color: colors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
