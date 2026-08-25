import 'package:flutter/material.dart';

/// Kairo's typographic system.
///
/// One family — Plus Jakarta Sans — carries the whole product, with JetBrains
/// Mono reserved for code blocks and tabular figures. The scale is deliberately
/// tight: display sizes are for marketing, headline/title for app chrome, and
/// three body sizes cover everything else.
///
/// Negative tracking increases with size, which is what keeps large headings
/// from looking loose next to dense data tables.
abstract final class AppTypography {
  static const String fontFamily = 'PlusJakartaSans';
  static const String monoFamily = 'JetBrainsMono';

  static TextTheme textTheme(Color ink, Color inkSoft) {
    TextStyle s(
      double size,
      double height,
      FontWeight weight, {
      double tracking = 0,
      Color? color,
    }) {
      return TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        height: height / size,
        fontWeight: weight,
        letterSpacing: tracking,
        color: color ?? ink,
      );
    }

    return TextTheme(
      // Marketing scale.
      displayLarge: s(44, 48, FontWeight.w800, tracking: -1.6),
      displayMedium: s(36, 42, FontWeight.w800, tracking: -1.2),
      displaySmall: s(30, 36, FontWeight.w700, tracking: -0.8),

      // Application headings.
      headlineLarge: s(26, 32, FontWeight.w700, tracking: -0.6),
      headlineMedium: s(22, 28, FontWeight.w700, tracking: -0.4),
      headlineSmall: s(19, 26, FontWeight.w600, tracking: -0.2),

      // Section and card titles.
      titleLarge: s(17, 24, FontWeight.w600, tracking: -0.15),
      titleMedium: s(15, 22, FontWeight.w600, tracking: -0.1),
      titleSmall: s(13.5, 20, FontWeight.w600),

      // Body copy.
      bodyLarge: s(15, 23, FontWeight.w400, color: ink),
      bodyMedium: s(14, 21, FontWeight.w400, color: inkSoft),
      bodySmall: s(13, 19, FontWeight.w400, color: inkSoft),

      // Controls and metadata.
      labelLarge: s(14, 20, FontWeight.w600),
      labelMedium: s(12.5, 16, FontWeight.w600, tracking: 0.1),
      labelSmall: s(11, 14, FontWeight.w600, tracking: 0.3),
    );
  }

  /// Tabular figures for metrics, timers and chart axes. Fixed-width digits
  /// stop counters from jittering as they animate.
  static const TextStyle numeric = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  /// Monospace for code blocks, keyboard hints and IDs.
  static const TextStyle mono = TextStyle(
    fontFamily: monoFamily,
    fontSize: 12.5,
    height: 1.5,
  );

  /// All-caps micro label used for section eyebrows.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );
}
