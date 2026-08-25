import 'package:flutter/material.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/theme/app_typography.dart';
import 'package:kairo/core/theme/design_tokens.dart';

/// Shared vocabulary for Kairo's charts.
///
/// The charts are hand-painted rather than pulled from a package. Three reasons
/// that earn their keep here: they inherit the design system's colours and type
/// exactly, they animate with the same curves as everything else, and there is
/// no third-party styling to fight when the theme changes.

@immutable
class ChartPoint {
  const ChartPoint({required this.label, required this.value, this.meta});

  final String label;
  final double value;

  /// Optional payload surfaced in the tooltip (a date, a task count).
  final String? meta;
}

@immutable
class ChartSeries {
  const ChartSeries({
    required this.name,
    required this.points,
    required this.color,
    this.filled = true,
    this.dashed = false,
  });

  final String name;
  final List<ChartPoint> points;
  final Color color;
  final bool filled;
  final bool dashed;

  double get maxValue => points.isEmpty
      ? 0
      : points
            .map((ChartPoint p) => p.value)
            .reduce((double a, double b) => a > b ? a : b);
}

/// Rounds an axis maximum up to a friendly number so gridlines land on values
/// a person would actually write down.
double niceCeiling(double raw) {
  if (raw <= 0) return 4;
  if (raw <= 4) return 4;
  if (raw <= 10) return (raw / 2).ceil() * 2;
  if (raw <= 50) return (raw / 5).ceil() * 5;
  if (raw <= 200) return (raw / 20).ceil() * 20;
  return (raw / 100).ceil() * 100;
}

/// Paints horizontal gridlines and the y-axis labels shared by the line and bar
/// charts, so the two always align when stacked in a dashboard.
class ChartGrid extends CustomPainter {
  ChartGrid({
    required this.maxValue,
    required this.gridColor,
    required this.labelColor,
    required this.divisions,
    required this.labelWidth,
  });

  final double maxValue;
  final Color gridColor;
  final Color labelColor;
  final int divisions;
  final double labelWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint line = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (int i = 0; i <= divisions; i++) {
      final double t = i / divisions;
      final double y = size.height - size.height * t;
      canvas.drawLine(Offset(labelWidth, y), Offset(size.width, y), line);

      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: _format(maxValue * t),
          style: AppTypography.numeric.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(labelWidth - painter.width - 6, y - painter.height / 2),
      );
    }
  }

  static String _format(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.round().toString();
  }

  @override
  bool shouldRepaint(ChartGrid old) =>
      old.maxValue != maxValue || old.gridColor != gridColor;
}

/// Legend row shared by every multi-series chart.
class ChartLegend extends StatelessWidget {
  const ChartLegend({required this.entries, this.compact = false, super.key});

  final List<({String label, Color color, String? value})> entries;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.lg,
      runSpacing: Spacing.sm,
      children: <Widget>[
        for (final ({String label, Color color, String? value}) entry
            in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: entry.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: Spacing.sm - 2),
              Text(
                entry.label,
                style: context.textStyles.labelSmall?.copyWith(
                  color: context.colors.inkMuted,
                ),
              ),
              if (entry.value != null) ...<Widget>[
                const SizedBox(width: 5),
                Text(
                  entry.value!,
                  style: AppTypography.numeric.copyWith(
                    fontSize: 11,
                    color: context.colors.ink,
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

/// Floating readout shown while a pointer hovers a chart.
class ChartTooltip extends StatelessWidget {
  const ChartTooltip({required this.title, required this.rows, super.key});

  final String title;
  final List<({String label, Color color, String value})> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceOverlay,
        borderRadius: Radii.brSm,
        border: Border.all(color: colors.hairline),
        boxShadow: Shadows.md(colors.isDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: context.textStyles.labelSmall?.copyWith(
              color: colors.inkMuted,
            ),
          ),
          const SizedBox(height: 3),
          for (final ({String label, Color color, String value}) row in rows)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: row.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm - 2),
                  Text(
                    row.label,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: colors.inkSoft,
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Text(
                    row.value,
                    style: AppTypography.numeric.copyWith(
                      fontSize: 11.5,
                      color: colors.ink,
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

/// Wraps a chart with a title, optional trailing control, and a fixed height,
/// so every analytics panel has the same anatomy.
class ChartPanel extends StatelessWidget {
  const ChartPanel({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.legend,
    this.height = 240,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final Widget? legend;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.brLg,
        border: Border.all(color: colors.hairline),
        boxShadow: Shadows.xs(colors.isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: context.textStyles.titleMedium),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: Spacing.lg),
          SizedBox(height: height, child: child),
          if (legend != null) ...<Widget>[
            const SizedBox(height: Spacing.md),
            legend!,
          ],
        ],
      ),
    );
  }
}
