import 'package:flutter/widgets.dart';
import 'package:kairo/core/responsive/breakpoints.dart';
import 'package:kairo/core/theme/design_tokens.dart';

/// Lays cards out in columns while letting each card keep its own height.
///
/// This exists because `GridView`'s `childAspectRatio` makes a cell's height a
/// function of its *width*, which is precisely the wrong dependency for a card
/// whose height is decided by its content. One column on a phone gives a very
/// wide cell, which the aspect ratio then turns into a very short one, and the
/// card overflows it — the same card being perfectly happy at three columns on
/// a desktop. Every dashboard and analytics tile hit this.
///
/// A `Wrap` of fixed-width children inverts the dependency: the column count
/// sets the width, and each card is as tall as it needs to be. It is also
/// cheaper than the shrink-wrapped `GridView` it replaces, which had to lay out
/// all of its children up front anyway to report its height.
class AdaptiveCardGrid extends StatelessWidget {
  const AdaptiveCardGrid({
    required this.columns,
    required this.children,
    this.spacing = Spacing.md,
    this.runSpacing = Spacing.md,
    super.key,
  });

  /// Column count for the current breakpoint. Clamped to at least one, and
  /// never more columns than there are children.
  final int columns;

  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  /// The column count Kairo uses for card grids, so dashboards, analytics and
  /// project lists all break at the same widths.
  static int columnsFor(ScreenSize size, {int max = 4}) {
    final int natural = switch (size) {
      ScreenSize.compact => 1,
      ScreenSize.medium => 2,
      ScreenSize.expanded => 3,
      ScreenSize.large => 4,
    };
    return natural > max ? max : natural;
  }

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int count = columns.clamp(1, children.length);

        // An unbounded width means the caller put this inside a horizontal
        // scrollable; there is no column width to compute, so the cards simply
        // flow at their natural size rather than throwing.
        if (!constraints.hasBoundedWidth) {
          return Wrap(
            spacing: spacing,
            runSpacing: runSpacing,
            children: children,
          );
        }

        // Floored so rounding can never make the row a fraction of a pixel too
        // wide, which would wrap the last card onto a line of its own.
        final double width =
            ((constraints.maxWidth - spacing * (count - 1)) / count)
                .floorToDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: <Widget>[
            for (final Widget child in children)
              SizedBox(width: width < 0 ? 0 : width, child: child),
          ],
        );
      },
    );
  }
}
