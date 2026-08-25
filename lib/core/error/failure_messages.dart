import 'package:flutter/widgets.dart';
import 'package:kairo/core/error/failure.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';

/// Turns a [Failure] into words a person can act on.
///
/// This lives in the presentation layer on purpose: the domain and data layers
/// stay free of localisation and of any opinion about how an error is shown.
@immutable
class FailureMessage {
  const FailureMessage({
    required this.title,
    required this.body,
    this.isRetryable = false,
  });

  final String title;
  final String body;
  final bool isRetryable;
}

extension FailureDescription on Failure {
  FailureMessage describe(AppL10n l10n) {
    return switch (this) {
      NetworkFailure() => FailureMessage(
        title: l10n.errorNetworkTitle,
        body: l10n.errorNetworkBody,
        isRetryable: true,
      ),
      AuthFailure(reason: final AuthFailureReason reason) => FailureMessage(
        title: switch (reason) {
          AuthFailureReason.sessionExpired => l10n.errorUnauthorizedTitle,
          _ => l10n.authSignIn,
        },
        body: switch (reason) {
          AuthFailureReason.invalidCredentials =>
            'That email and password combination doesn’t match an account.',
          AuthFailureReason.emailAlreadyInUse =>
            'An account already exists with that email address.',
          AuthFailureReason.weakPassword => l10n.validationPasswordShort,
          AuthFailureReason.sessionExpired => l10n.errorUnauthorizedBody,
          AuthFailureReason.emailNotVerified =>
            'Verify your email address to continue.',
          AuthFailureReason.unknownAccount =>
            'We couldn’t find an account with that email address.',
        },
      ),
      ValidationFailure(errors: final Map<String, String> errors) =>
        FailureMessage(
          title: l10n.errorValidationTitle,
          body: errors.values.isEmpty
              ? l10n.errorGenericBody
              : errors.values.first,
        ),
      NotFoundFailure() => FailureMessage(
        title: l10n.errorNotFoundTitle,
        body: l10n.errorNotFoundBody,
      ),
      ConflictFailure(reason: final String reason) => FailureMessage(
        title: l10n.errorGenericTitle,
        body: reason,
      ),
      StorageFailure() => FailureMessage(
        title: l10n.errorGenericTitle,
        body: 'Kairo couldn’t reach local storage on this device.',
        isRetryable: true,
      ),
      UnknownFailure() => FailureMessage(
        title: l10n.errorGenericTitle,
        body: l10n.errorGenericBody,
        isRetryable: true,
      ),
    };
  }
}

/// Convenience for any error object, not only [Failure]s — used by the global
/// error boundary where the type is genuinely unknown.
FailureMessage describeError(Object error, AppL10n l10n) {
  if (error is Failure) return error.describe(l10n);
  return FailureMessage(
    title: l10n.errorGenericTitle,
    body: l10n.errorGenericBody,
    isRetryable: true,
  );
}
