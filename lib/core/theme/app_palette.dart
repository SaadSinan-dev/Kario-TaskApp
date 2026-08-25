import 'package:flutter/material.dart';

/// Raw brand colour ramps for Kairo.
///
/// Nothing in the UI reads from this file directly. Colours enter the app
/// through [ColorScheme] and the `KairoColors` theme extension so that a single
/// switch of [ThemeData] restyles the entire product.
///
/// The identity is blue: an electric mid-range for actions and focus, a deep
/// navy for dark surfaces, and an indigo accent used only for gradients and
/// secondary emphasis.
abstract final class AppPalette {
  // --- Kairo Blue -----------------------------------------------------------
  static const Color blue50 = Color(0xFFEEF4FF);
  static const Color blue100 = Color(0xFFDBE6FE);
  static const Color blue200 = Color(0xFFBFD3FE);
  static const Color blue300 = Color(0xFF93B4FD);
  static const Color blue400 = Color(0xFF608EFA);
  static const Color blue500 = Color(0xFF3B6BF5);
  static const Color blue600 = Color(0xFF2451E6);
  static const Color blue700 = Color(0xFF1B3FC4);
  static const Color blue800 = Color(0xFF1B369E);
  static const Color blue900 = Color(0xFF1C327D);
  static const Color blue950 = Color(0xFF131F4C);

  /// Indigo accent. Used for gradients and secondary emphasis only — never as
  /// a second "primary", which would dilute the blue identity.
  static const Color indigo = Color(0xFF6D5EF8);
  static const Color indigoBright = Color(0xFF8274FA);

  // --- Neutrals: light ------------------------------------------------------
  static const Color canvasLight = Color(0xFFF6F8FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceRaisedLight = Color(0xFFFFFFFF);
  static const Color surfaceSunkenLight = Color(0xFFF1F5FB);
  static const Color surfaceOverlayLight = Color(0xFFFFFFFF);
  static const Color hairlineLight = Color(0xFFE2E8F0);
  static const Color hairlineStrongLight = Color(0xFFCBD5E1);

  static const Color inkLight = Color(0xFF0B1220);
  static const Color inkSoftLight = Color(0xFF334155);
  static const Color inkMutedLight = Color(0xFF64748B);
  static const Color inkFaintLight = Color(0xFF94A3B8);

  // --- Neutrals: dark (navy, not grey) --------------------------------------
  static const Color canvasDark = Color(0xFF070B18);
  static const Color surfaceDark = Color(0xFF0D1424);
  static const Color surfaceRaisedDark = Color(0xFF121A2D);
  static const Color surfaceSunkenDark = Color(0xFF0A0F1D);
  static const Color surfaceOverlayDark = Color(0xFF141D32);
  static const Color hairlineDark = Color(0xFF1E2941);
  static const Color hairlineStrongDark = Color(0xFF2F3E5C);

  static const Color inkDark = Color(0xFFE6EDF7);
  static const Color inkSoftDark = Color(0xFFC5D1E4);
  static const Color inkMutedDark = Color(0xFF8DA1BE);
  static const Color inkFaintDark = Color(0xFF677995);

  // --- Semantic: light ------------------------------------------------------
  static const Color successLight = Color(0xFF059669);
  static const Color warningLight = Color(0xFFD97706);
  static const Color dangerLight = Color(0xFFE12D39);
  static const Color violetLight = Color(0xFF7C3AED);
  static const Color tealLight = Color(0xFF0D9488);

  // --- Semantic: dark -------------------------------------------------------
  static const Color successDark = Color(0xFF2DC78F);
  static const Color warningDark = Color(0xFFFAB02E);
  static const Color dangerDark = Color(0xFFF86069);
  static const Color violetDark = Color(0xFF9E7AFA);
  static const Color tealDark = Color(0xFF2DC5B8);

  /// Colours offered when creating a project or label. Chosen to stay legible
  /// as a small dot, a filled chip and a chart series in both themes.
  static const List<Color> selectable = <Color>[
    blue500,
    indigo,
    Color(0xFF0EA5E9), // sky
    Color(0xFF14B8A6), // teal
    Color(0xFF22C55E), // green
    Color(0xFFEAB308), // amber
    Color(0xFFF97316), // orange
    Color(0xFFEF4444), // red
    Color(0xFFEC4899), // pink
    Color(0xFF8B5CF6), // violet
    Color(0xFF64748B), // slate
    Color(0xFF0F766E), // deep teal
  ];
}
