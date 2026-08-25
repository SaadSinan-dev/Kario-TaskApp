import 'package:flutter/material.dart';
import 'package:kairo/core/responsive/breakpoints.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/theme/kairo_colors.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';

/// Short, safe accessors for the things almost every widget needs.
///
/// These exist to keep build methods readable: `context.colors.brand` instead
/// of `Theme.of(context).extension<KairoColors>()!.brand`.
extension KairoBuildContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textStyles => Theme.of(this).textTheme;
  ColorScheme get scheme => Theme.of(this).colorScheme;

  /// Kairo's semantic colour tokens.
  KairoColors get colors => Theme.of(this).extension<KairoColors>()!;

  /// Localised strings.
  AppL10n get l10n => AppL10n.of(this);

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Size get screenSize => MediaQuery.sizeOf(this);
  EdgeInsets get safeArea => MediaQuery.paddingOf(this);
  double get keyboardInset => MediaQuery.viewInsetsOf(this).bottom;

  ScreenSize get breakpoint => Breakpoints.fromContext(this);
  bool get isCompact => breakpoint.isCompact;
  bool get hasSidebar => breakpoint.hasSidebar;
  bool get hasDetailPanel => breakpoint.hasDetailPanel;
  bool get isTouchFirst => breakpoint.isTouchFirst;

  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  /// Honours the platform's "reduce motion" accessibility setting. The app's
  /// own preference is layered on top of this in `MotionScope`.
  bool get systemReducesMotion => MediaQuery.disableAnimationsOf(this);

  /// Page gutter appropriate to the current breakpoint.
  double get gutter => responsiveValue<double>(
    breakpoint,
    compact: Spacing.gutterCompact,
    medium: Spacing.gutterMedium,
    expanded: Spacing.gutterExpanded,
  );
}
