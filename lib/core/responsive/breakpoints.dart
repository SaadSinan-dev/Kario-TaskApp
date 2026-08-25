import 'package:flutter/widgets.dart';

/// The four layouts Kairo actually designs for.
///
/// These are *layout intents*, not device names — a resized desktop window at
/// 700px gets the same experience as a tablet in portrait, which is the point.
enum ScreenSize {
  /// Phones. Single column, bottom navigation, full-screen detail.
  compact,

  /// Large phones landscape and small tablets. Single column with a rail.
  medium,

  /// Tablets and small laptops. Persistent sidebar, two-column content.
  expanded,

  /// Desktop. Sidebar plus content plus a docked detail panel.
  large;

  bool get isCompact => this == ScreenSize.compact;
  bool get isMedium => this == ScreenSize.medium;
  bool get isExpanded => this == ScreenSize.expanded;
  bool get isLarge => this == ScreenSize.large;

  /// True where a persistent sidebar replaces bottom navigation.
  bool get hasSidebar => index >= ScreenSize.expanded.index;

  /// True where a task can open beside the list instead of on top of it.
  bool get hasDetailPanel => this == ScreenSize.large;

  /// True where touch-first affordances (bottom sheets, swipe, FAB) win.
  bool get isTouchFirst => index <= ScreenSize.medium.index;
}

abstract final class Breakpoints {
  /// Below this width the UI is a single scrolling column.
  static const double compact = 600;

  /// Above this a navigation rail appears.
  static const double medium = 905;

  /// Above this the full sidebar is pinned open.
  static const double expanded = 1280;

  static ScreenSize of(double width) {
    if (width < compact) return ScreenSize.compact;
    if (width < medium) return ScreenSize.medium;
    if (width < expanded) return ScreenSize.expanded;
    return ScreenSize.large;
  }

  static ScreenSize fromContext(BuildContext context) =>
      of(MediaQuery.sizeOf(context).width);
}

/// Rebuilds only when the [ScreenSize] bucket changes, not on every pixel of a
/// window resize — which matters on web where drag-resizing is continuous.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({required this.builder, super.key});

  final Widget Function(BuildContext context, ScreenSize size) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return builder(context, Breakpoints.of(constraints.maxWidth));
      },
    );
  }
}

/// Picks one of four values for the current breakpoint, falling back to the
/// nearest smaller value that was supplied.
T responsiveValue<T>(
  ScreenSize size, {
  required T compact,
  T? medium,
  T? expanded,
  T? large,
}) {
  switch (size) {
    case ScreenSize.compact:
      return compact;
    case ScreenSize.medium:
      return medium ?? compact;
    case ScreenSize.expanded:
      return expanded ?? medium ?? compact;
    case ScreenSize.large:
      return large ?? expanded ?? medium ?? compact;
  }
}
