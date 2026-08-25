import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/routing/routes.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/utils/validators.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/core/widgets/app_text_field.dart';
import 'package:kairo/core/widgets/app_toast.dart';
import 'package:kairo/domain/entities/preferences.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/features/auth/application/auth_controller.dart';
import 'package:kairo/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';

/// Sign in.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _rememberMe = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(authControllerProvider.notifier)
        .signIn(
          l10n: context.l10n,
          email: _email.text,
          password: _password.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l10n = context.l10n;
    final AuthFormState state = ref.watch(authControllerProvider);

    return AuthScaffold(
      title: l10n.authLoginTitle,
      subtitle: l10n.authLoginSubtitle,
      footer: AuthFooterLink(
        prompt: l10n.authNoAccount,
        actionLabel: l10n.authSignUp,
        onAction: () => context.go(Routes.signup),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            DemoCredentialsCard(
              onUseDemo: () =>
                  ref.read(authControllerProvider.notifier).signInAsDemo(l10n),
            ),
            const SizedBox(height: Spacing.xl),
            AppTextField(
              controller: _email,
              label: l10n.fieldEmail,
              hint: 'you@company.com',
              prefixIcon: AppIcons.email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.email],
              validator: Validators.email(l10n),
              onChanged: (_) =>
                  ref.read(authControllerProvider.notifier).clearError(),
            ),
            const SizedBox(height: Spacing.lg),
            AppTextField(
              controller: _password,
              label: l10n.fieldPassword,
              prefixIcon: AppIcons.password,
              obscure: true,
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[AutofillHints.password],
              validator: Validators.required(l10n),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: Spacing.md),
            Row(
              children: <Widget>[
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (bool? value) =>
                        setState(() => _rememberMe = value ?? false),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    l10n.authRememberMe,
                    style: context.textStyles.bodySmall,
                  ),
                ),
                const Spacer(),
                AppButton(
                  label: l10n.authForgotLink,
                  variant: AppButtonVariant.link,
                  size: AppButtonSize.small,
                  onPressed: () => context.go(Routes.forgotPassword),
                ),
              ],
            ),
            const SizedBox(height: Spacing.lg),
            AuthErrorBanner(message: state.errorMessage),
            AppButton.primary(
              label: l10n.authSignIn,
              size: AppButtonSize.large,
              isFullWidth: true,
              isLoading: state.isSubmitting,
              onPressed: _submit,
            ),
            const SizedBox(height: Spacing.md),

            const SizedBox(height: Spacing.xl),
            const AuthDivider(),
            const SizedBox(height: Spacing.xl),
            SocialAuthButtons(
              onUnavailable: () => ref.toasts.show(
                'Social sign-in needs OAuth credentials',
                description:
                    'The buttons are wired to the same repository interface; '
                    'add client ids to enable them.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Create account.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  String _passwordValue = '';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final bool ok = await ref
        .read(authControllerProvider.notifier)
        .signUp(
          l10n: context.l10n,
          name: _name.text,
          email: _email.text,
          password: _password.text,
        );
    // A new account has an empty workspace, so it goes through onboarding
    // rather than landing on a blank dashboard.
    if (ok && mounted) {
      await ref
          .read(preferencesProvider.notifier)
          .update(
            (UserPreferences p) => p.copyWith(hasCompletedOnboarding: false),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l10n = context.l10n;
    final AuthFormState state = ref.watch(authControllerProvider);

    return AuthScaffold(
      title: l10n.authSignupTitle,
      subtitle: l10n.authSignupSubtitle,
      footer: AuthFooterLink(
        prompt: l10n.authHaveAccount,
        actionLabel: l10n.authSignIn,
        onAction: () => context.go(Routes.login),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppTextField(
              controller: _name,
              label: l10n.fieldFullName,
              hint: 'Jordan Avery',
              prefixIcon: AppIcons.assignee,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              autofillHints: const <String>[AutofillHints.name],
              validator: Validators.compose(<String? Function(String?)>[
                Validators.required(l10n),
                Validators.minLength(l10n, 2),
              ]),
            ),
            const SizedBox(height: Spacing.lg),
            AppTextField(
              controller: _email,
              label: l10n.fieldEmail,
              hint: 'you@company.com',
              prefixIcon: AppIcons.email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.email],
              validator: Validators.email(l10n),
            ),
            const SizedBox(height: Spacing.lg),
            AppTextField(
              controller: _password,
              label: l10n.fieldPassword,
              prefixIcon: AppIcons.password,
              obscure: true,
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[AutofillHints.newPassword],
              validator: Validators.password(l10n),
              onChanged: (String value) =>
                  setState(() => _passwordValue = value),
              onSubmitted: (_) => _submit(),
            ),
            PasswordStrengthBar(password: _passwordValue),
            const SizedBox(height: Spacing.xl),
            AuthErrorBanner(message: state.errorMessage),
            AppButton.primary(
              label: l10n.authSignUp,
              size: AppButtonSize.large,
              isFullWidth: true,
              isLoading: state.isSubmitting,
              onPressed: _submit,
            ),
            const SizedBox(height: Spacing.lg),
            const AuthTermsNotice(),
            const SizedBox(height: Spacing.xl),
            const AuthDivider(),
            const SizedBox(height: Spacing.xl),
            SocialAuthButtons(
              onUnavailable: () =>
                  ref.toasts.show('Social sign-up needs OAuth credentials'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Request a password reset link.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l10n = context.l10n;
    final AuthFormState state = ref.watch(authControllerProvider);

    return AuthScaffold(
      title: l10n.authForgotTitle,
      subtitle: l10n.authForgotSubtitle,
      footer: AuthFooterLink(
        prompt: l10n.authHaveAccount,
        actionLabel: l10n.authSignIn,
        onAction: () => context.go(Routes.login),
      ),
      child: state.succeeded
          ? AuthSuccessPanel(
              title: l10n.authResetSent,
              message:
                  'If an account exists for ${_email.text.trim()}, a reset '
                  'link is on its way. The link expires in one hour.',
              actionLabel: l10n.authSignIn,
              onAction: () => context.go(Routes.login),
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppTextField(
                    controller: _email,
                    label: l10n.fieldEmail,
                    prefixIcon: AppIcons.email,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email(l10n),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: Spacing.xl),
                  AuthErrorBanner(message: state.errorMessage),
                  AppButton.primary(
                    label: l10n.authSendResetLink,
                    size: AppButtonSize.large,
                    isFullWidth: true,
                    isLoading: state.isSubmitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(authControllerProvider.notifier)
        .requestPasswordReset(l10n: context.l10n, email: _email.text);
  }
}

/// Choose a new password from a reset link.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({this.token = '', super.key});

  final String token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  String _passwordValue = '';

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l10n = context.l10n;
    final AuthFormState state = ref.watch(authControllerProvider);

    return AuthScaffold(
      title: l10n.authResetTitle,
      subtitle: l10n.authResetSubtitle,
      child: state.succeeded
          ? AuthSuccessPanel(
              title: 'Password updated',
              message: 'Sign in with your new password.',
              actionLabel: l10n.authSignIn,
              onAction: () => context.go(Routes.login),
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppTextField(
                    controller: _password,
                    label: 'New password',
                    prefixIcon: AppIcons.password,
                    obscure: true,
                    autofocus: true,
                    validator: Validators.password(l10n),
                    onChanged: (String value) =>
                        setState(() => _passwordValue = value),
                  ),
                  PasswordStrengthBar(password: _passwordValue),
                  const SizedBox(height: Spacing.lg),
                  AppTextField(
                    controller: _confirm,
                    label: 'Confirm password',
                    prefixIcon: AppIcons.password,
                    obscure: true,
                    validator: Validators.matches(l10n, () => _password.text),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: Spacing.xl),
                  AuthErrorBanner(message: state.errorMessage),
                  AppButton.primary(
                    label: 'Update password',
                    size: AppButtonSize.large,
                    isFullWidth: true,
                    isLoading: state.isSubmitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(authControllerProvider.notifier)
        .resetPassword(
          l10n: context.l10n,
          token: widget.token,
          password: _password.text,
        );
  }
}

/// Six-digit email verification.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l10n = context.l10n;
    final AuthFormState state = ref.watch(authControllerProvider);
    final User? user = ref.watch(currentUserValueProvider);

    return AuthScaffold(
      title: l10n.authVerifyTitle,
      subtitle: l10n.authVerifySubtitle(user?.email ?? 'your inbox'),
      child: state.succeeded
          ? AuthSuccessPanel(
              title: 'Email verified',
              message: 'Your workspace is ready.',
              actionLabel: l10n.actionContinue,
              onAction: () => context.go(Routes.dashboard),
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppTextField(
                    controller: _code,
                    label: 'Verification code',
                    hint: '123456',
                    autofocus: true,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: Validators.verificationCode(l10n),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: Spacing.xl),
                  AuthErrorBanner(message: state.errorMessage),
                  AppButton.primary(
                    label: l10n.authVerifyCta,
                    size: AppButtonSize.large,
                    isFullWidth: true,
                    isLoading: state.isSubmitting,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: Spacing.md),
                  AppButton(
                    label: l10n.authResendCode,
                    variant: AppButtonVariant.ghost,
                    isFullWidth: true,
                    onPressed: () => ref.toasts.show('Code resent'),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(authControllerProvider.notifier)
        .verifyEmail(l10n: context.l10n, code: _code.text);
  }
}
