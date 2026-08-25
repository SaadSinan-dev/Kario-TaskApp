import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kairo/core/theme/app_palette.dart';
import 'package:kairo/core/theme/app_typography.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/theme/kairo_colors.dart';

/// Builds the two [ThemeData] objects the product ships with.
///
/// Every Material component is themed here exactly once. Feature code never
/// styles a button, input or card locally — it composes the design-system
/// widgets in `core/widgets`, which in turn read from this theme.
abstract final class AppTheme {
  static ThemeData light() => _build(KairoColors.light());
  static ThemeData dark() => _build(KairoColors.dark());

  static ThemeData _build(KairoColors k) {
    final Brightness brightness = k.isDark ? Brightness.dark : Brightness.light;
    final ColorScheme scheme = _scheme(k, brightness);
    final TextTheme text = AppTypography.textTheme(k.ink, k.inkSoft);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: k.canvas,
      canvasColor: k.canvas,
      splashFactory: InkSparkle.splashFactory,
      textTheme: text,
      fontFamily: AppTypography.fontFamily,
      visualDensity: VisualDensity.standard,
      extensions: <ThemeExtension<dynamic>>[k],

      // Route transitions: a restrained fade-through on every platform, so the
      // app feels identical on Android, iOS, web and desktop.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: k.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: k.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: k.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: k.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.brLg,
          side: BorderSide(color: k.hairline),
        ),
      ),

      dividerTheme: DividerThemeData(color: k.hairline, thickness: 1, space: 1),

      iconTheme: IconThemeData(color: k.inkMuted, size: 18),

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return k.brand.withValues(alpha: 0.35);
            }
            if (states.contains(WidgetState.pressed)) return k.brandStrong;
            if (states.contains(WidgetState.hovered)) {
              return Color.lerp(k.brand, k.brandStrong, 0.4)!;
            }
            return k.brand;
          }),
          foregroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
          overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
          elevation: const WidgetStatePropertyAll<double>(0),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
          ),
          minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 40)),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: Radii.brMd),
          ),
          textStyle: WidgetStatePropertyAll<TextStyle?>(text.labelLarge),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return k.inkFaint;
            return k.ink;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return k.surfaceSunken;
            if (states.contains(WidgetState.hovered)) return k.surfaceSunken;
            return k.surface;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return BorderSide(color: k.hairlineStrong);
            }
            return BorderSide(color: k.hairline);
          }),
          overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
          ),
          minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 40)),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: Radii.brMd),
          ),
          textStyle: WidgetStatePropertyAll<TextStyle?>(text.labelLarge),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return k.inkFaint;
            return k.brand;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return k.brandSoft;
            return Colors.transparent;
          }),
          overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
          ),
          minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 36)),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: Radii.brSm),
          ),
          textStyle: WidgetStatePropertyAll<TextStyle?>(text.labelLarge),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: k.isDark ? k.surfaceSunken : k.surface,
        hintStyle: text.bodyMedium?.copyWith(color: k.inkFaint),
        labelStyle: text.labelMedium?.copyWith(color: k.inkMuted),
        floatingLabelStyle: text.labelMedium?.copyWith(color: k.brand),
        helperStyle: text.bodySmall?.copyWith(color: k.inkMuted),
        errorStyle: text.bodySmall?.copyWith(color: k.danger),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.md,
        ),
        prefixIconColor: k.inkFaint,
        suffixIconColor: k.inkFaint,
        border: OutlineInputBorder(
          borderRadius: Radii.brMd,
          borderSide: BorderSide(color: k.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Radii.brMd,
          borderSide: BorderSide(color: k.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.brMd,
          borderSide: BorderSide(color: k.brand, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Radii.brMd,
          borderSide: BorderSide(color: k.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Radii.brMd,
          borderSide: BorderSide(color: k.danger, width: 1.6),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: Radii.brMd,
          borderSide: BorderSide(color: k.hairline.withValues(alpha: 0.6)),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: k.surfaceSunken,
        selectedColor: k.brandSoft,
        disabledColor: k.surfaceSunken,
        side: BorderSide(color: k.hairline),
        labelStyle: text.labelMedium!,
        secondaryLabelStyle: text.labelMedium!,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xs,
        ),
        shape: const RoundedRectangleBorder(borderRadius: Radii.brSm),
        showCheckmark: false,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: k.surfaceOverlay,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.brXl,
          side: BorderSide(color: k.hairline),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: k.surfaceOverlay,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: k.hairlineStrong,
        dragHandleSize: const Size(36, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xxl)),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: k.surfaceOverlay,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        textStyle: text.bodyMedium?.copyWith(color: k.ink),
        shape: RoundedRectangleBorder(
          borderRadius: Radii.brMd,
          side: BorderSide(color: k.hairline),
        ),
      ),

      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll<Color>(k.surfaceOverlay),
          surfaceTintColor: const WidgetStatePropertyAll<Color>(
            Colors.transparent,
          ),
          elevation: const WidgetStatePropertyAll<double>(0),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: Radii.brMd,
              side: BorderSide(color: k.hairline),
            ),
          ),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: k.isDark ? k.surfaceOverlay : const Color(0xFF111A2E),
          borderRadius: Radii.brSm,
          border: Border.all(
            color: k.isDark ? k.hairlineStrong : Colors.transparent,
          ),
        ),
        textStyle: text.labelSmall?.copyWith(color: Colors.white),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xs + 2,
        ),
        waitDuration: const Duration(milliseconds: 420),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: k.ink,
        unselectedLabelColor: k.inkMuted,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: k.brand,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: k.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: k.brandSoft,
        elevation: 0,
        height: ShellMetrics.bottomNavHeight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return text.labelSmall?.copyWith(
            color: selected ? k.brand : k.inkMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 20,
            color: selected ? k.brand : k.inkMuted,
          );
        }),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: k.surface,
        indicatorColor: k.brandSoft,
        selectedIconTheme: IconThemeData(color: k.brand, size: 20),
        unselectedIconTheme: IconThemeData(color: k.inkMuted, size: 20),
        selectedLabelTextStyle: text.labelSmall?.copyWith(color: k.brand),
        unselectedLabelTextStyle: text.labelSmall?.copyWith(color: k.inkMuted),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return k.isDark ? k.inkMuted : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return k.hairline.withValues(alpha: 0.5);
          }
          if (states.contains(WidgetState.selected)) return k.brand;
          return k.isDark ? k.surfaceSunken : k.hairlineStrong;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return k.hairlineStrong;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return k.brand;
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll<Color>(Colors.white),
        side: BorderSide(color: k.hairlineStrong, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: Radii.brXs),
        visualDensity: VisualDensity.compact,
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return k.brand;
          return k.hairlineStrong;
        }),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: k.brand,
        inactiveTrackColor: k.hairline,
        thumbColor: k.brand,
        overlayColor: k.brand.withValues(alpha: 0.12),
        trackHeight: 4,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: k.brand,
        linearTrackColor: k.hairline,
        circularTrackColor: k.hairline,
        linearMinHeight: 6,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: k.surfaceOverlay,
        contentTextStyle: text.bodyMedium?.copyWith(color: k.ink),
        actionTextColor: k.brand,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.brMd,
          side: BorderSide(color: k.hairline),
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: k.inkMuted,
        textColor: k.ink,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall?.copyWith(color: k.inkMuted),
        shape: const RoundedRectangleBorder(borderRadius: Radii.brMd),
        contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        minVerticalPadding: Spacing.sm,
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: k.brand,
        selectionColor: k.brand.withValues(alpha: 0.24),
        selectionHandleColor: k.brand,
      ),

      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll<Color>(
          k.inkFaint.withValues(alpha: 0.4),
        ),
        thickness: const WidgetStatePropertyAll<double>(8),
        radius: const Radius.circular(4),
        crossAxisMargin: 2,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: k.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: Radii.brXl),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return k.brandSoft;
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return k.brand;
            return k.inkMuted;
          }),
          side: WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: k.hairline),
          ),
          textStyle: WidgetStatePropertyAll<TextStyle?>(text.labelMedium),
        ),
      ),
    );
  }

  static ColorScheme _scheme(KairoColors k, Brightness brightness) {
    return ColorScheme(
      brightness: brightness,
      primary: k.brand,
      onPrimary: Colors.white,
      primaryContainer: k.brandSoft,
      onPrimaryContainer: k.isDark ? AppPalette.blue200 : AppPalette.blue900,
      secondary: k.accent,
      onSecondary: Colors.white,
      secondaryContainer: k.accent.withValues(alpha: k.isDark ? 0.20 : 0.12),
      onSecondaryContainer: k.isDark
          ? AppPalette.indigoBright
          : AppPalette.indigo,
      tertiary: k.teal,
      onTertiary: Colors.white,
      error: k.danger,
      onError: Colors.white,
      errorContainer: k.dangerSoft,
      onErrorContainer: k.danger,
      surface: k.surface,
      onSurface: k.ink,
      surfaceContainerLowest: k.canvas,
      surfaceContainerLow: k.surfaceSunken,
      surfaceContainer: k.surface,
      surfaceContainerHigh: k.surfaceRaised,
      surfaceContainerHighest: k.surfaceOverlay,
      onSurfaceVariant: k.inkMuted,
      outline: k.hairlineStrong,
      outlineVariant: k.hairline,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: k.isDark
          ? AppPalette.surfaceLight
          : AppPalette.surfaceDark,
      onInverseSurface: k.isDark ? AppPalette.inkLight : AppPalette.inkDark,
      inversePrimary: k.isDark ? AppPalette.blue700 : AppPalette.blue300,
    );
  }
}
