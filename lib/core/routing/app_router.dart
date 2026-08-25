import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/routing/routes.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/app_states.dart';
import 'package:kairo/features/analytics/presentation/analytics_screen.dart';
import 'package:kairo/features/auth/presentation/auth_screens.dart';
import 'package:kairo/features/calendar/presentation/calendar_screen.dart';
import 'package:kairo/features/dashboard/presentation/dashboard_screen.dart';
import 'package:kairo/features/focus/presentation/focus_screen.dart';
import 'package:kairo/features/notifications/presentation/notifications_screen.dart';
import 'package:kairo/features/projects/presentation/project_detail_screen.dart';
import 'package:kairo/features/projects/presentation/projects_screen.dart';
import 'package:kairo/features/search/presentation/search_screen.dart';
import 'package:kairo/features/settings/presentation/settings_screen.dart';
import 'package:kairo/features/shell/presentation/app_shell.dart';
import 'package:kairo/features/splash/presentation/splash_screen.dart';
import 'package:kairo/features/tasks/presentation/collections_screens.dart';
import 'package:kairo/features/tasks/presentation/tasks_screen.dart';
import 'package:kairo/features/timeline/presentation/timeline_screen.dart';

/// The router.
///
/// Three zones: the splash that owns startup, the authentication flow, and the
/// application shell. `redirect` is the only place that decides which zone you
/// belong in, so there is never a screen that pushes you somewhere behind the
/// router's back.
///
/// The application always enters at [Routes.splash].
final Provider<GoRouter> routerProvider = Provider<GoRouter>((Ref ref) {
  final GlobalKey<NavigatorState> rootKey = GlobalKey<NavigatorState>(
    debugLabel: 'root',
  );
  final GlobalKey<NavigatorState> shellKey = GlobalKey<NavigatorState>(
    debugLabel: 'shell',
  );

  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: Routes.splash,
    debugLogDiagnostics: false,
    refreshListenable: _RouterRefresh(ref),
    redirect: (BuildContext context, GoRouterState state) {
      final String location = state.uri.path;

      // The splash owns the first routing decision and is never redirected
      // away from. Without this exemption the guards below would fire against
      // a store that has not finished loading and bounce the user to sign-in
      // before the session has been restored.
      if (location == Routes.splash) return null;

      final bool signedIn = ref.read(isSignedInProvider);

      // Signed out: only the public site and the auth flow are reachable.
      if (!signedIn) {
        return Routes.isPublic(location) ? null : Routes.login;
      }

      // Signed in and landing on an auth screen: send them into the app.
      const Set<String> authRoutes = <String>{
        Routes.login,
        Routes.signup,
        Routes.forgotPassword,
        Routes.resetPassword,
      };
      if (authRoutes.contains(location)) {
        return ref.read(preferencesProvider).landingRoute;
      }

      return null;
    },
    errorBuilder: (BuildContext context, GoRouterState state) =>
        _RouteNotFound(location: state.uri.toString()),
    routes: <RouteBase>[
      // --- Startup ----------------------------------------------------------
      // No transition: the splash is already continuous with the native launch
      // window, and fading it in would show a seam.
      GoRoute(
        path: Routes.splash,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            NoTransitionPage<void>(
              key: state.pageKey,
              child: const SplashScreen(),
            ),
      ),

      // --- Authentication ---------------------------------------------------
      GoRoute(
        path: Routes.login,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fade(state, const LoginScreen()),
      ),
      GoRoute(
        path: Routes.signup,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fade(state, const SignupScreen()),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fade(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: Routes.resetPassword,
        pageBuilder: (BuildContext context, GoRouterState state) => _fade(
          state,
          ResetPasswordScreen(token: state.uri.queryParameters['token'] ?? ''),
        ),
      ),
      GoRoute(
        path: Routes.verifyEmail,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fade(state, const VerifyEmailScreen()),
      ),

      // --- Application ------------------------------------------------------
      ShellRoute(
        navigatorKey: shellKey,
        builder: (BuildContext context, GoRouterState state, Widget child) =>
            AppShell(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: Routes.dashboard,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _shellPage(state, const DashboardScreen()),
          ),
          GoRoute(
            path: Routes.tasks,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _shellPage(state, const TasksScreen()),
          ),
          GoRoute(
            path: Routes.inbox,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _shellPage(state, const InboxScreen()),
          ),
          GoRoute(
            path: Routes.projects,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _shellPage(state, const ProjectsScreen()),
            routes: <RouteBase>[
              GoRoute(
                path: ':projectId',
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    _shellPage(
                      state,
                      ProjectDetailScreen(
                        projectId: state.pathParameters['projectId'] ?? '',
                      ),
                    ),
              ),
            ],
          ),
          GoRoute(
            path: Routes.calendar,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _shellPage(state, const CalendarScreen()),
          ),
          GoRoute(
            path: Routes.timeline,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _shellPage(state, const TimelineScreen()),
          ),
          GoRoute(
            path: Routes.focus,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _shellPage(state, const FocusScreen()),
          ),
          GoRoute(
            path: Routes.analytics,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _shellPage(state, const AnalyticsScreen()),
          ),
          GoRoute(
            path: Routes.notifications,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _shellPage(state, const NotificationsScreen()),
          ),
          GoRoute(
            path: Routes.search,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _shellPage(
                  state,
                  SearchScreen(
                    initialQuery: state.uri.queryParameters['q'] ?? '',
                  ),
                ),
          ),
          GoRoute(
            path: Routes.favorites,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _shellPage(state, const FavoritesScreen()),
          ),
          GoRoute(
            path: Routes.archive,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _shellPage(state, const ArchiveScreen()),
          ),
          GoRoute(
            path: Routes.settings,
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _shellPage(
                  state,
                  const SettingsScreen(section: SettingsSection.profile),
                ),
            routes: <RouteBase>[
              GoRoute(
                path: ':section',
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    _shellPage(
                      state,
                      SettingsScreen(
                        section: SettingsSection.fromSlug(
                          state.pathParameters['section'],
                        ),
                      ),
                    ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

/// Cross-fade between top-level destinations. Slide transitions imply a
/// hierarchy that a flat set of destinations does not have.
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: Motion.medium,
    reverseTransitionDuration: Motion.fast,
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondary,
          Widget child,
        ) {
          if (context.reducedMotion) return child;
          final Animation<double> eased = CurvedAnimation(
            parent: animation,
            curve: Motion.entrance,
          );
          return FadeTransition(
            opacity: eased,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.012),
                end: Offset.zero,
              ).animate(eased),
              child: child,
            ),
          );
        },
  );
}

/// Pages inside the shell keep the chrome still and only cross-fade content,
/// so switching sections does not make the sidebar flicker.
CustomTransitionPage<void> _shellPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: ValueKey<String>(state.uri.path),
    child: child,
    transitionDuration: Motion.base,
    reverseTransitionDuration: Motion.fast,
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondary,
          Widget child,
        ) {
          if (context.reducedMotion) return child;
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Motion.entrance),
            child: child,
          );
        },
  );
}

/// Rebuilds the router when the session changes, which is what makes
/// `redirect` re-run after sign in and sign out.
///
/// The session is the only input `redirect` reads that can change while the
/// app is running, so it is the only thing worth listening to.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen<bool>(isSignedInProvider, (_, _) => notifyListeners());
  }
}

class _RouteNotFound extends StatelessWidget {
  const _RouteNotFound({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xxl),
          child: AppEmptyState(
            icon: AppIcons.error,
            title: context.l10n.errorRouteTitle,
            message: '${context.l10n.errorRouteBody}\n\n$location',
            actionLabel: context.l10n.errorGoHome,
            onAction: () => GoRouter.of(context).go(Routes.dashboard),
          ),
        ),
      ),
    );
  }
}
