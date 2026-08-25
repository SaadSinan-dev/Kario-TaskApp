import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/routing/app_router.dart';
import 'package:kairo/core/theme/app_theme.dart';
import 'package:kairo/core/widgets/app_toast.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/preferences.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';

/// The root widget.
///
/// Owns exactly three things: the theme (driven by the stored preference), the
/// motion scope (so every animation honours reduce-motion), and the toast
/// overlay (mounted above the router so a toast survives navigation).
class KairoApp extends ConsumerWidget {
  const KairoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(routerProvider);

    // Only the three preferences this widget actually renders with. Watching
    // the whole object rebuilt `MaterialApp.router` — and therefore every
    // route below it — whenever any unrelated preference changed, including
    // collapsing the sidebar or finishing onboarding.
    final ({ThemePreference theme, InterfaceDensity density, bool reduceMotion})
    preferences = ref.watch(
      preferencesProvider.select(
        (UserPreferences p) =>
            (theme: p.theme, density: p.density, reduceMotion: p.reduceMotion),
      ),
    );

    return MaterialApp.router(
      title: 'Kairo',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (preferences.theme) {
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
        ThemePreference.system => ThemeMode.system,
      },
      themeAnimationDuration: const Duration(milliseconds: 260),
      themeAnimationCurve: Curves.easeOutCubic,
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      builder: (BuildContext context, Widget? child) {
        return MotionScope(
          reduceMotion: preferences.reduceMotion,
          child: _DensityScope(
            density: preferences.density,
            child: Stack(
              children: <Widget>[
                child ?? const SizedBox.shrink(),
                // Toasts are hosted in their own `Overlay`.
                //
                // They are mounted above the router so a toast survives
                // navigation — but that also puts them *outside* the
                // Navigator, and therefore outside the only `Overlay` in the
                // tree. Material widgets that float something (a `Tooltip`, a
                // menu, a text-selection handle) assert on a missing `Overlay`
                // ancestor, and an assertion thrown while building the toast
                // leaves its subtree unlaid-out — which surfaces as a cascade
                // of enormous, nonsensical overflow errors from the toast's
                // own column.
                //
                // Giving the toasts an overlay of their own keeps them above
                // navigation and gives those widgets the ancestor they
                // require. `Positioned.fill` hands it tight constraints; hit
                // testing still falls through everywhere a toast is not drawn.
                Positioned.fill(
                  child: Overlay(
                    initialEntries: <OverlayEntry>[
                      OverlayEntry(
                        builder: (BuildContext context) => const ToastOverlay(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Applies the interface-density preference by nudging Material's visual
/// density, so "compact" tightens list rows and controls everywhere at once.
class _DensityScope extends StatelessWidget {
  const _DensityScope({required this.density, required this.child});

  final InterfaceDensity density;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (density == InterfaceDensity.comfortable) return child;
    return Theme(
      data: Theme.of(context).copyWith(
        visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
      ),
      child: child,
    );
  }
}
