import 'package:flutter/material.dart';
import 'package:kairo/core/theme/app_palette.dart';

/// Semantic colour tokens for Kairo, exposed as a [ThemeExtension].
///
/// Material's [ColorScheme] covers buttons, inputs and the standard surfaces.
/// Everything the product needs *beyond* that — the surface ramp, status and
/// priority colours, chart series, soft tinted backgrounds — lives here, so no
/// widget ever hard-codes a hex value.
///
/// Read it with `context.colors` (see `core/extensions/context_extensions.dart`).
@immutable
class KairoColors extends ThemeExtension<KairoColors> {
  const KairoColors({
    required this.isDark,
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.surfaceOverlay,
    required this.hairline,
    required this.hairlineStrong,
    required this.ink,
    required this.inkSoft,
    required this.inkMuted,
    required this.inkFaint,
    required this.brand,
    required this.brandStrong,
    required this.brandSoft,
    required this.brandBorder,
    required this.accent,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.info,
    required this.infoSoft,
    required this.violet,
    required this.teal,
    required this.statusBacklog,
    required this.statusTodo,
    required this.statusInProgress,
    required this.statusReview,
    required this.statusDone,
    required this.priorityUrgent,
    required this.priorityHigh,
    required this.priorityMedium,
    required this.priorityLow,
    required this.chartSeries,
    required this.chartGrid,
    required this.selectionTint,
    required this.dragTint,
  });

  /// True when the dark palette is active. Widgets that need to pick a shadow
  /// recipe or a gradient strength read this instead of `Theme.of`.
  final bool isDark;

  // Surfaces, from furthest back to closest to the user.
  final Color canvas;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color surfaceOverlay;

  final Color hairline;
  final Color hairlineStrong;

  // Text and icon ink, from strongest to faintest.
  final Color ink;
  final Color inkSoft;
  final Color inkMuted;
  final Color inkFaint;

  // Brand.
  final Color brand;
  final Color brandStrong;
  final Color brandSoft;
  final Color brandBorder;
  final Color accent;

  // Semantic pairs: a saturated colour and a tinted background for it.
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color info;
  final Color infoSoft;
  final Color violet;
  final Color teal;

  // Task workflow.
  final Color statusBacklog;
  final Color statusTodo;
  final Color statusInProgress;
  final Color statusReview;
  final Color statusDone;

  final Color priorityUrgent;
  final Color priorityHigh;
  final Color priorityMedium;
  final Color priorityLow;

  /// Ordered series colours for charts. Index 0 is always the brand blue so a
  /// single-series chart is on-brand by default.
  final List<Color> chartSeries;
  final Color chartGrid;

  /// Fill used for selected rows and multi-select states.
  final Color selectionTint;

  /// Fill used for drop placeholders while dragging.
  final Color dragTint;

  factory KairoColors.light() => const KairoColors(
    isDark: false,
    canvas: AppPalette.canvasLight,
    surface: AppPalette.surfaceLight,
    surfaceRaised: AppPalette.surfaceRaisedLight,
    surfaceSunken: AppPalette.surfaceSunkenLight,
    surfaceOverlay: AppPalette.surfaceOverlayLight,
    hairline: AppPalette.hairlineLight,
    hairlineStrong: AppPalette.hairlineStrongLight,
    ink: AppPalette.inkLight,
    inkSoft: AppPalette.inkSoftLight,
    inkMuted: AppPalette.inkMutedLight,
    inkFaint: AppPalette.inkFaintLight,
    brand: AppPalette.blue600,
    brandStrong: AppPalette.blue700,
    brandSoft: AppPalette.blue50,
    brandBorder: AppPalette.blue200,
    accent: AppPalette.indigo,
    success: AppPalette.successLight,
    successSoft: Color(0xFFE7F7F1),
    warning: AppPalette.warningLight,
    warningSoft: Color(0xFFFDF3E3),
    danger: AppPalette.dangerLight,
    dangerSoft: Color(0xFFFDECEE),
    info: AppPalette.blue600,
    infoSoft: AppPalette.blue50,
    violet: AppPalette.violetLight,
    teal: AppPalette.tealLight,
    statusBacklog: AppPalette.inkMutedLight,
    statusTodo: AppPalette.blue500,
    statusInProgress: AppPalette.warningLight,
    statusReview: AppPalette.violetLight,
    statusDone: AppPalette.successLight,
    priorityUrgent: AppPalette.dangerLight,
    priorityHigh: Color(0xFFEA580C),
    priorityMedium: AppPalette.blue500,
    priorityLow: AppPalette.inkFaintLight,
    chartSeries: <Color>[
      AppPalette.blue500,
      AppPalette.indigo,
      AppPalette.tealLight,
      AppPalette.warningLight,
      AppPalette.violetLight,
      AppPalette.successLight,
    ],
    chartGrid: Color(0xFFE8EDF6),
    selectionTint: AppPalette.blue50,
    dragTint: Color(0xFFE6EEFF),
  );

  factory KairoColors.dark() => const KairoColors(
    isDark: true,
    canvas: AppPalette.canvasDark,
    surface: AppPalette.surfaceDark,
    surfaceRaised: AppPalette.surfaceRaisedDark,
    surfaceSunken: AppPalette.surfaceSunkenDark,
    surfaceOverlay: AppPalette.surfaceOverlayDark,
    hairline: AppPalette.hairlineDark,
    hairlineStrong: AppPalette.hairlineStrongDark,
    ink: AppPalette.inkDark,
    inkSoft: AppPalette.inkSoftDark,
    inkMuted: AppPalette.inkMutedDark,
    inkFaint: AppPalette.inkFaintDark,
    brand: AppPalette.blue500,
    brandStrong: AppPalette.blue400,
    brandSoft: Color(0xFF14203F),
    brandBorder: Color(0xFF25376A),
    accent: AppPalette.indigoBright,
    success: AppPalette.successDark,
    successSoft: Color(0xFF0C2A22),
    warning: AppPalette.warningDark,
    warningSoft: Color(0xFF2C220D),
    danger: AppPalette.dangerDark,
    dangerSoft: Color(0xFF31161B),
    info: AppPalette.blue400,
    infoSoft: Color(0xFF14203F),
    violet: AppPalette.violetDark,
    teal: AppPalette.tealDark,
    statusBacklog: AppPalette.inkMutedDark,
    statusTodo: AppPalette.blue400,
    statusInProgress: AppPalette.warningDark,
    statusReview: AppPalette.violetDark,
    statusDone: AppPalette.successDark,
    priorityUrgent: AppPalette.dangerDark,
    priorityHigh: Color(0xFFFB923C),
    priorityMedium: AppPalette.blue400,
    priorityLow: AppPalette.inkFaintDark,
    chartSeries: <Color>[
      AppPalette.blue400,
      AppPalette.indigoBright,
      AppPalette.tealDark,
      AppPalette.warningDark,
      AppPalette.violetDark,
      AppPalette.successDark,
    ],
    chartGrid: Color(0xFF1B2540),
    selectionTint: Color(0xFF16223F),
    dragTint: Color(0xFF17244A),
  );

  /// The signature gradient: brand blue into indigo, used for the logo mark,
  /// the primary CTA on marketing pages and the focus-mode ambience.
  LinearGradient get brandGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[brand, accent],
  );

  /// A barely-there wash used behind hero sections and empty states.
  LinearGradient get sheenGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      brand.withValues(alpha: isDark ? 0.18 : 0.10),
      accent.withValues(alpha: isDark ? 0.10 : 0.06),
      Colors.transparent,
    ],
    stops: const <double>[0, 0.45, 1],
  );

  @override
  KairoColors copyWith({Color? brand, Color? accent, Color? canvas}) {
    return KairoColors(
      isDark: isDark,
      canvas: canvas ?? this.canvas,
      surface: surface,
      surfaceRaised: surfaceRaised,
      surfaceSunken: surfaceSunken,
      surfaceOverlay: surfaceOverlay,
      hairline: hairline,
      hairlineStrong: hairlineStrong,
      ink: ink,
      inkSoft: inkSoft,
      inkMuted: inkMuted,
      inkFaint: inkFaint,
      brand: brand ?? this.brand,
      brandStrong: brandStrong,
      brandSoft: brandSoft,
      brandBorder: brandBorder,
      accent: accent ?? this.accent,
      success: success,
      successSoft: successSoft,
      warning: warning,
      warningSoft: warningSoft,
      danger: danger,
      dangerSoft: dangerSoft,
      info: info,
      infoSoft: infoSoft,
      violet: violet,
      teal: teal,
      statusBacklog: statusBacklog,
      statusTodo: statusTodo,
      statusInProgress: statusInProgress,
      statusReview: statusReview,
      statusDone: statusDone,
      priorityUrgent: priorityUrgent,
      priorityHigh: priorityHigh,
      priorityMedium: priorityMedium,
      priorityLow: priorityLow,
      chartSeries: chartSeries,
      chartGrid: chartGrid,
      selectionTint: selectionTint,
      dragTint: dragTint,
    );
  }

  @override
  KairoColors lerp(covariant KairoColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return KairoColors(
      isDark: t < 0.5 ? isDark : other.isDark,
      canvas: c(canvas, other.canvas),
      surface: c(surface, other.surface),
      surfaceRaised: c(surfaceRaised, other.surfaceRaised),
      surfaceSunken: c(surfaceSunken, other.surfaceSunken),
      surfaceOverlay: c(surfaceOverlay, other.surfaceOverlay),
      hairline: c(hairline, other.hairline),
      hairlineStrong: c(hairlineStrong, other.hairlineStrong),
      ink: c(ink, other.ink),
      inkSoft: c(inkSoft, other.inkSoft),
      inkMuted: c(inkMuted, other.inkMuted),
      inkFaint: c(inkFaint, other.inkFaint),
      brand: c(brand, other.brand),
      brandStrong: c(brandStrong, other.brandStrong),
      brandSoft: c(brandSoft, other.brandSoft),
      brandBorder: c(brandBorder, other.brandBorder),
      accent: c(accent, other.accent),
      success: c(success, other.success),
      successSoft: c(successSoft, other.successSoft),
      warning: c(warning, other.warning),
      warningSoft: c(warningSoft, other.warningSoft),
      danger: c(danger, other.danger),
      dangerSoft: c(dangerSoft, other.dangerSoft),
      info: c(info, other.info),
      infoSoft: c(infoSoft, other.infoSoft),
      violet: c(violet, other.violet),
      teal: c(teal, other.teal),
      statusBacklog: c(statusBacklog, other.statusBacklog),
      statusTodo: c(statusTodo, other.statusTodo),
      statusInProgress: c(statusInProgress, other.statusInProgress),
      statusReview: c(statusReview, other.statusReview),
      statusDone: c(statusDone, other.statusDone),
      priorityUrgent: c(priorityUrgent, other.priorityUrgent),
      priorityHigh: c(priorityHigh, other.priorityHigh),
      priorityMedium: c(priorityMedium, other.priorityMedium),
      priorityLow: c(priorityLow, other.priorityLow),
      chartSeries: <Color>[
        for (int i = 0; i < chartSeries.length; i++)
          c(chartSeries[i], other.chartSeries[i]),
      ],
      chartGrid: c(chartGrid, other.chartGrid),
      selectionTint: c(selectionTint, other.selectionTint),
      dragTint: c(dragTint, other.dragTint),
    );
  }
}
