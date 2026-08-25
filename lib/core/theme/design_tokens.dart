import 'package:flutter/material.dart';

/// Spacing scale. A 4pt base with a small number of steps keeps rhythm
/// consistent; anything outside the scale should be a deliberate exception.
abstract final class Spacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double section = 56;
  static const double page = 72;

  /// Horizontal page gutter per breakpoint.
  static const double gutterCompact = 16;
  static const double gutterMedium = 24;
  static const double gutterExpanded = 32;
}

/// Corner radii. Kairo uses generous, consistent rounding — cards and sheets
/// share a family so nested surfaces never look mismatched.
abstract final class Radii {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 18;
  static const double xxl = 24;
  static const double pill = 999;

  static const BorderRadius brXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius brPill = BorderRadius.all(Radius.circular(pill));
}

/// Motion tokens.
///
/// The rule of the system: small feedback is fast (120–220ms), layout and
/// navigation are slower (260–420ms), and anything physical (drag, sheets,
/// score dials) uses spring-like curves rather than linear easing.
abstract final class Motion {
  static const Duration instant = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration deliberate = Duration(milliseconds: 620);

  /// Decelerating curve used for almost every entrance.
  static const Curve entrance = Curves.easeOutCubic;

  /// Sharper deceleration for overlays and sheets.
  static const Curve emphasized = Cubic(0.16, 1, 0.3, 1);

  /// Accelerating curve for exits.
  static const Curve exit = Curves.easeInCubic;

  /// Slight overshoot for confirmation moments (checkboxes, badges, counters).
  static const Curve overshoot = Curves.easeOutBack;

  /// Standard both-ways curve for state changes that stay on screen.
  static const Curve standard = Curves.easeInOutCubic;

  /// Stagger delay used by list and grid entrances.
  static const Duration stagger = Duration(milliseconds: 40);

  /// Caps a stagger so long lists never feel slow to appear.
  static Duration staggerFor(int index, {int max = 10}) =>
      stagger * (index > max ? max : index);
}

/// Elevation is expressed as explicit shadow recipes rather than Material
/// elevation numbers so light and dark can diverge — dark surfaces need deeper,
/// tighter shadows to read at all.
abstract final class Shadows {
  static List<BoxShadow> xs(bool dark) => <BoxShadow>[
    BoxShadow(
      color: Colors.black.withValues(alpha: dark ? 0.40 : 0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> sm(bool dark) => <BoxShadow>[
    BoxShadow(
      color: Colors.black.withValues(alpha: dark ? 0.48 : 0.06),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: dark ? 0.32 : 0.04),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> md(bool dark) => <BoxShadow>[
    BoxShadow(
      color: Colors.black.withValues(alpha: dark ? 0.52 : 0.08),
      blurRadius: 16,
      spreadRadius: -4,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: dark ? 0.36 : 0.04),
      blurRadius: 6,
      spreadRadius: -2,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> lg(bool dark) => <BoxShadow>[
    BoxShadow(
      color: Colors.black.withValues(alpha: dark ? 0.62 : 0.12),
      blurRadius: 34,
      spreadRadius: -12,
      offset: const Offset(0, 16),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: dark ? 0.42 : 0.06),
      blurRadius: 12,
      spreadRadius: -4,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> xl(bool dark) => <BoxShadow>[
    BoxShadow(
      color: Colors.black.withValues(alpha: dark ? 0.72 : 0.18),
      blurRadius: 64,
      spreadRadius: -20,
      offset: const Offset(0, 30),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: dark ? 0.48 : 0.08),
      blurRadius: 24,
      spreadRadius: -10,
      offset: const Offset(0, 10),
    ),
  ];

  /// Brand-tinted glow used sparingly: the primary CTA on the landing hero and
  /// the active focus timer.
  static List<BoxShadow> glow(Color color, {double strength = 0.42}) =>
      <BoxShadow>[
        BoxShadow(
          color: color.withValues(alpha: strength),
          blurRadius: 40,
          spreadRadius: -10,
          offset: const Offset(0, 14),
        ),
      ];
}

/// Named z-order bands. Overlay ordering bugs are hard to debug, so the few
/// stacked surfaces in the app all read their priority from here.
abstract final class ZIndex {
  static const int base = 0;
  static const int raised = 10;
  static const int sticky = 20;
  static const int drawer = 40;
  static const int overlay = 50;
  static const int modal = 60;
  static const int popover = 70;
  static const int toast = 80;
  static const int palette = 90;
}

/// Fixed layout dimensions for the application shell.
abstract final class ShellMetrics {
  static const double sidebarWidth = 268;
  static const double sidebarCollapsedWidth = 72;
  static const double topBarHeight = 60;
  static const double bottomNavHeight = 64;
  static const double detailPanelWidth = 440;
  static const double detailPanelWideWidth = 520;
  static const double maxContentWidth = 1440;
  static const double maxReadingWidth = 760;
}
