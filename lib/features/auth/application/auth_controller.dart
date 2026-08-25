import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/core/error/failure.dart';
import 'package:kairo/core/error/failure_messages.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';

/// Form state for the authentication screens.
@immutable
class AuthFormState {
  const AuthFormState({
    this.isSubmitting = false,
    this.errorMessage,
    this.succeeded = false,
  });

  final bool isSubmitting;
  final String? errorMessage;

  /// True after a flow that ends on a confirmation panel rather than a
  /// navigation (password reset requested, email verified).
  final bool succeeded;

  AuthFormState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    bool? succeeded,
  }) {
    return AuthFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      succeeded: succeeded ?? this.succeeded,
    );
  }
}

/// Drives sign in, sign up and the password flows.
///
/// The screens own their text controllers and validation; this owns the async
/// call, the submitting flag, and the single place a [Failure] becomes a
/// message. Navigation is left to the router's redirect, which reacts to the
/// session rather than being pushed by the form.
class AuthController extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  void clearError() => state = state.copyWith(clearError: true);

  Future<bool> signIn({
    required AppL10n l10n,
    required String email,
    required String password,
  }) {
    return _run(
      l10n,
      () => ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password),
    );
  }

  Future<bool> signUp({
    required AppL10n l10n,
    required String name,
    required String email,
    required String password,
  }) {
    return _run(
      l10n,
      () => ref
          .read(authRepositoryProvider)
          .signUp(name: name, email: email, password: password),
    );
  }

  Future<bool> signInAsDemo(AppL10n l10n) =>
      _run(l10n, () => ref.read(authRepositoryProvider).signInAsDemo());

  Future<bool> requestPasswordReset({
    required AppL10n l10n,
    required String email,
  }) async {
    final bool ok = await _run(
      l10n,
      () => ref.read(authRepositoryProvider).requestPasswordReset(email),
    );
    if (ok) state = state.copyWith(succeeded: true);
    return ok;
  }

  Future<bool> resetPassword({
    required AppL10n l10n,
    required String token,
    required String password,
  }) async {
    final bool ok = await _run(
      l10n,
      () => ref
          .read(authRepositoryProvider)
          .resetPassword(token: token, password: password),
    );
    if (ok) state = state.copyWith(succeeded: true);
    return ok;
  }

  Future<bool> verifyEmail({
    required AppL10n l10n,
    required String code,
  }) async {
    final bool ok = await _run(
      l10n,
      () => ref.read(authRepositoryProvider).verifyEmail(code),
    );
    if (ok) state = state.copyWith(succeeded: true);
    return ok;
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AuthFormState();
  }

  Future<bool> _run(AppL10n l10n, Future<Object?> Function() action) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await action();
      state = state.copyWith(isSubmitting: false);
      return true;
    } on Failure catch (failure) {
      final FailureMessage message = failure.describe(l10n);
      state = state.copyWith(isSubmitting: false, errorMessage: message.body);
      return false;
    }
  }
}

final NotifierProvider<AuthController, AuthFormState> authControllerProvider =
    NotifierProvider<AuthController, AuthFormState>(AuthController.new);
