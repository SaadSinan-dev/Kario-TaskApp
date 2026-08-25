import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/logging/app_logger.dart';
import 'package:kairo/core/routing/routes.dart';
import 'package:kairo/data/local/kairo_database.dart';
import 'package:kairo/data/repositories/auth_repository_impl.dart';
import 'package:kairo/domain/entities/preferences.dart';
import 'package:kairo/domain/repositories/repositories.dart';

/// Where the splash should send the user, and why.
///
/// Carrying the reason alongside the route keeps the decision auditable: a test
/// can assert "a returning signed-in user goes to their landing route" without
/// re-deriving the rule from a bare string.
enum StartupDestination { signIn, workspace }

class StartupResult {
  const StartupResult(this.destination, this.route);

  final StartupDestination destination;
  final String route;
}

/// The work that must finish before any product screen can render.
///
/// Deliberately *not* done before `runApp`. Opening storage is cheap and
/// happens in `bootstrap()`; loading the workspace and restoring the session is
/// the expensive part, and running it here means the first frame is the splash
/// rather than a blank window held by the platform.
///
/// Failure is not fatal. If the workspace cannot be loaded the app still starts
/// — at the sign-in screen, with the error logged — because a startup crash is
/// a worse outcome than a session the user can retry.
final startupProvider = FutureProvider<StartupResult>((Ref ref) async {
  const AppLogger log = AppLogger('startup');

  try {
    final KairoDatabase database = ref.read(databaseProvider);
    await database.initialize();

    final AuthRepository auth = ref.read(authRepositoryProvider);
    if (auth is LocalAuthRepository) {
      await auth.restoreSession();
    }
  } on Object catch (error, stackTrace) {
    log.error('Startup failed', error: error, stackTrace: stackTrace);
    return const StartupResult(StartupDestination.signIn, Routes.login);
  }

  // Reading preferences after initialisation, so a restored profile's stored
  // landing route is respected rather than the default.
  final UserPreferences preferences = ref.read(preferencesProvider);
  final bool signedIn = ref.read(isSignedInProvider);

  if (!signedIn) {
    return const StartupResult(StartupDestination.signIn, Routes.login);
  }
  return StartupResult(StartupDestination.workspace, preferences.landingRoute);
});
