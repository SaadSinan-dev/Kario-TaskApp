/// Every route in the product, in one place.
///
/// Paths are constants and links are built through [Routes] helpers rather than
/// string interpolation at call sites, so a rename is a compile error instead
/// of a dead link.
abstract final class Routes {
  /// The application entry point. Owns initialisation and the first routing
  /// decision, so no product screen ever renders against an unloaded store.
  static const String splash = '/';

  // Marketing (unauthenticated, indexable). Deliberately *not* mounted at the
  // root: the root belongs to the application, and the marketing site is a
  // separate zone you navigate to, never one the app can land in by default.
  static const String landing = '/welcome';
  static const String pricing = '/pricing';
  static const String about = '/about';

  // Authentication.
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verifyEmail = '/verify-email';

  // Onboarding.
  static const String onboarding = '/onboarding';

  // Application shell.
  static const String dashboard = '/dashboard';
  static const String tasks = '/tasks';
  static const String inbox = '/inbox';
  static const String projects = '/projects';
  static const String projectDetail = '/projects/:projectId';
  static const String calendar = '/calendar';
  static const String timeline = '/timeline';
  static const String focus = '/focus';
  static const String analytics = '/analytics';
  static const String notifications = '/notifications';
  static const String search = '/search';
  static const String favorites = '/favorites';
  static const String archive = '/archive';
  static const String settings = '/settings';
  static const String settingsSection = '/settings/:section';

  static String project(String projectId) => '/projects/$projectId';

  static String settingsFor(String section) => '/settings/$section';

  /// Deep link to a task. Tasks open as an overlay on top of whatever view is
  /// showing, so the task id travels as a query parameter rather than a path
  /// segment — the underlying route stays addressable.
  static String taskOn(String location, String taskId) {
    final Uri uri = Uri.parse(location);
    return uri
        .replace(
          queryParameters: <String, String>{
            ...uri.queryParameters,
            'task': taskId,
          },
        )
        .toString();
  }

  static const String taskQueryParam = 'task';

  /// The five destinations that get a shell branch, in navigation order.
  static const List<String> shellBranches = <String>[
    dashboard,
    tasks,
    projects,
    calendar,
    focus,
  ];

  /// Routes that render the marketing chrome instead of the app shell.
  static const Set<String> marketingRoutes = <String>{landing, pricing, about};

  /// Routes reachable without a session.
  static const Set<String> publicRoutes = <String>{
    splash,
    landing,
    pricing,
    about,
    login,
    signup,
    forgotPassword,
    resetPassword,
  };

  static bool isPublic(String location) {
    final String path = Uri.parse(location).path;
    return publicRoutes.contains(path);
  }
}

/// Named settings sections, used by both the router and the settings sidebar.
enum SettingsSection {
  profile,
  workspace,
  appearance,
  notifications,
  shortcuts,
  preferences,
  security,
  data;

  String get slug => name;

  static SettingsSection fromSlug(String? slug) {
    for (final SettingsSection section in SettingsSection.values) {
      if (section.slug == slug) return section;
    }
    return SettingsSection.profile;
  }
}
