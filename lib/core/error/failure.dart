import 'package:flutter/foundation.dart';

/// The complete set of error shapes the application understands.
///
/// Data sources throw [Failure] subclasses (via [Failure.guard]) instead of
/// leaking transport-specific exceptions upward. The presentation layer is the
/// only place that turns a failure into human words — see
/// `failure_messages.dart`, which needs a [BuildContext] for localisation.
@immutable
sealed class Failure implements Exception {
  const Failure({this.cause, this.stackTrace});

  /// The original error, kept for logging. Never shown to a user.
  final Object? cause;
  final StackTrace? stackTrace;

  /// A short machine-readable code, useful in logs and analytics.
  String get code;

  /// Whether retrying the same operation could plausibly succeed.
  bool get isRetryable => false;

  @override
  String toString() => '$runtimeType($code)${cause == null ? '' : ': $cause'}';

  /// Runs [action], converting anything that escapes into a [Failure].
  ///
  /// This is the single place where unknown errors become known ones, which is
  /// why the repositories contain almost no `try`/`catch` of their own.
  static Future<T> guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Failure {
      rethrow;
    } catch (error, stackTrace) {
      return Future<T>.error(
        UnknownFailure(cause: error, stackTrace: stackTrace),
        stackTrace,
      );
    }
  }

  /// Synchronous counterpart of [guard].
  static T guardSync<T>(T Function() action) {
    try {
      return action();
    } on Failure {
      rethrow;
    } catch (error, stackTrace) {
      throw UnknownFailure(cause: error, stackTrace: stackTrace);
    }
  }
}

/// No usable connection, or the request timed out.
final class NetworkFailure extends Failure {
  const NetworkFailure({super.cause, super.stackTrace});

  @override
  String get code => 'network';

  @override
  bool get isRetryable => true;
}

/// The caller is not signed in, or the credentials were rejected.
final class AuthFailure extends Failure {
  const AuthFailure(this.reason, {super.cause, super.stackTrace});

  final AuthFailureReason reason;

  @override
  String get code => 'auth.${reason.name}';
}

enum AuthFailureReason {
  invalidCredentials,
  emailAlreadyInUse,
  weakPassword,
  sessionExpired,
  emailNotVerified,
  unknownAccount,
}

/// A form or command failed validation before reaching storage.
final class ValidationFailure extends Failure {
  const ValidationFailure(this.errors, {super.cause, super.stackTrace});

  /// Field name to message key. An empty key means "form level".
  final Map<String, String> errors;

  String? get first => errors.values.isEmpty ? null : errors.values.first;

  @override
  String get code => 'validation';
}

/// The requested entity does not exist (or is not visible to this user).
final class NotFoundFailure extends Failure {
  const NotFoundFailure(this.entity, this.id, {super.cause, super.stackTrace});

  final String entity;
  final String id;

  @override
  String get code => 'not_found.$entity';
}

/// The operation is understood but not permitted in the current state — for
/// example creating a dependency cycle between two tasks.
final class ConflictFailure extends Failure {
  const ConflictFailure(this.reason, {super.cause, super.stackTrace});

  final String reason;

  @override
  String get code => 'conflict';
}

/// Local persistence could not be read or written.
final class StorageFailure extends Failure {
  const StorageFailure({super.cause, super.stackTrace});

  @override
  String get code => 'storage';

  @override
  bool get isRetryable => true;
}

/// Anything that escaped the layers below without being classified.
final class UnknownFailure extends Failure {
  const UnknownFailure({super.cause, super.stackTrace});

  @override
  String get code => 'unknown';

  @override
  bool get isRetryable => true;
}
