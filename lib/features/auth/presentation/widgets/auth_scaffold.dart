import 'package:flutter/material.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/responsive/breakpoints.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/app_badge.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/features/marketing/presentation/widgets/brand.dart';

/// The frame shared by every authentication screen.
///
/// Two panes on desktop: the form on the left, and on the right a quiet brand
/// panel that says what the product is. Auth is often someone's first screen —
/// leaving half of it empty wastes the only guaranteed impression.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool wide = context.breakpoint.index >= ScreenSize.expanded.index;

    final Widget form = Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: context.gutter,
          vertical: Spacing.xxxl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Entrance(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (!wide) ...<Widget>[
                  const BrandMark(size: 40),
                  const SizedBox(height: Spacing.xl),
                ],
                Text(title, style: context.textStyles.displaySmall),
                const SizedBox(height: Spacing.sm),
                Text(
                  subtitle,
                  style: context.textStyles.bodyLarge?.copyWith(
                    color: colors.inkMuted,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: Spacing.xxxl),
                child,
                if (footer != null) ...<Widget>[
                  const SizedBox(height: Spacing.xxl),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (!wide) return Scaffold(body: SafeArea(child: form));

    return Scaffold(
      body: Row(
        children: <Widget>[
          Expanded(child: SafeArea(child: form)),
          const Expanded(child: _BrandPanel()),
        ],
      ),
    );
  }
}

/// The right-hand pane: gradient, product promise, and three concrete reasons.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colors.brand,
            Color.lerp(colors.brand, colors.accent, 0.6)!,
            Color.lerp(colors.accent, Colors.black, 0.25)!,
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          const Positioned.fill(child: BrandGridPattern()),
          Padding(
            padding: const EdgeInsets.all(Spacing.section),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const BrandMark(size: 44, onDark: true),
                const SizedBox(height: Spacing.xxxl),
                Text(
                  'The command center\nfor focused work.',
                  style: context.textStyles.displayMedium?.copyWith(
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                Text(
                  'Plan in list, board, calendar and timeline. Protect deep '
                  'work with Focus Mode. Drive all of it from the keyboard.',
                  style: context.textStyles.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: Spacing.section),
                const _Point(
                  icon: AppIcons.viewBoard,
                  text: 'Four views of the same plan',
                ),
                const _Point(
                  icon: AppIcons.focus,
                  text: 'A focus timer that keeps score',
                ),
                const _Point(
                  icon: AppIcons.command,
                  text: 'Command palette on ⌘K',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.lg),
      child: Row(
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: Radii.brSm,
            ),
            child: Icon(icon, size: 15, color: Colors.white),
          ),
          const SizedBox(width: Spacing.md),
          // A selling point is a full sentence: it wraps onto another line
          // rather than being cut off half-way through.
          Expanded(
            child: Text(
              text,
              style: context.textStyles.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Social sign-in buttons.
///
/// These are UI only: wiring them needs OAuth client ids, which are deployment
/// configuration rather than something to fake. Pressing one says so.
class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({required this.onUnavailable, super.key});

  final VoidCallback onUnavailable;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AppButton(
          label: context.l10n.authContinueWithGoogle,
          icon: AppIcons.email,
          isFullWidth: true,
          onPressed: onUnavailable,
        ),
        const SizedBox(height: Spacing.sm),
        AppButton(
          label: context.l10n.authContinueWithApple,
          icon: AppIcons.security,
          isFullWidth: true,
          onPressed: onUnavailable,
        ),
      ],
    );
  }
}

/// "or" rule between the credential form and the social buttons.
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: <Widget>[
        Expanded(child: Divider(color: colors.hairline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          child: Text(
            context.l10n.authOrDivider,
            style: context.textStyles.labelSmall?.copyWith(
              color: colors.inkFaint,
            ),
          ),
        ),
        Expanded(child: Divider(color: colors.hairline)),
      ],
    );
  }
}

/// The demo-account hint shown on sign in.
class DemoCredentialsCard extends StatelessWidget {
  const DemoCredentialsCard({required this.onUseDemo, super.key});

  final VoidCallback onUseDemo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colors.brandSoft,
        borderRadius: Radii.brMd,
        border: Border.all(color: colors.brandBorder),
      ),
      child: Row(
        children: <Widget>[
          Icon(AppIcons.brandSpark, size: 16, color: colors.brand),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.l10n.authTryDemo,
                  style: context.textStyles.labelLarge?.copyWith(
                    color: colors.brand,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.authDemoHint,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: colors.brand.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          AppButton(
            label: 'Open',
            size: AppButtonSize.small,
            variant: AppButtonVariant.primary,
            onPressed: onUseDemo,
          ),
        ],
      ),
    );
  }
}

/// Inline form-level error, shown above the submit button.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({required this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedSize(
      duration: context.motion(Motion.base),
      curve: Motion.entrance,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: Spacing.md),
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: colors.dangerSoft,
                borderRadius: Radii.brMd,
                border: Border.all(
                  color: colors.danger.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(AppIcons.error, size: 15, color: colors.danger),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      message!,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: colors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Success confirmation used by the password-reset and verification flows.
class AuthSuccessPanel extends StatelessWidget {
  const AuthSuccessPanel({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Entrance(
      scale: 0.96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors.successSoft,
              borderRadius: Radii.brXl,
            ),
            child: Icon(AppIcons.success, size: 22, color: colors.success),
          ),
          const SizedBox(height: Spacing.lg),
          Text(title, style: context.textStyles.headlineSmall),
          const SizedBox(height: Spacing.sm),
          Text(
            message,
            style: context.textStyles.bodyMedium?.copyWith(
              color: colors.inkMuted,
              height: 1.55,
            ),
          ),
          if (actionLabel != null) ...<Widget>[
            const SizedBox(height: Spacing.xl),
            AppButton.primary(
              label: actionLabel!,
              isFullWidth: true,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

/// Password strength meter shown under the signup password field.
class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({required this.password, super.key});

  final String password;

  /// 0–3. Deliberately simple and explainable: length, a digit, and a symbol
  /// or mixed case. A score nobody can predict is a score nobody trusts.
  int get _score {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp('[0-9]').hasMatch(password)) score++;
    if (RegExp('[A-Z]').hasMatch(password) ||
        RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]').hasMatch(password)) {
      score++;
    }
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (password.isEmpty) return const SizedBox.shrink();

    final int score = _score;
    final Color color = switch (score) {
      0 || 1 => colors.danger,
      2 => colors.warning,
      _ => colors.success,
    };
    final String label = switch (score) {
      0 || 1 => 'Weak',
      2 => 'Fair',
      _ => 'Strong',
    };

    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < 3; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: AnimatedContainer(
                duration: context.motion(Motion.base),
                height: 3,
                decoration: BoxDecoration(
                  color: i < score ? color : colors.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
          const SizedBox(width: Spacing.sm),
          SizedBox(
            width: 46,
            child: Text(
              label,
              style: context.textStyles.labelSmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small link row under an auth form ("New to Kairo? Create account").
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    required this.prompt,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    // A prompt and its link are two pieces of a sentence, so when they no
    // longer fit on one line the right answer is a second line — not an
    // ellipsis that would eat either half of the sentence.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Spacing.xs,
      children: <Widget>[
        Text(
          prompt,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.inkMuted,
          ),
        ),
        AppButton(
          label: actionLabel,
          variant: AppButtonVariant.link,
          size: AppButtonSize.small,
          onPressed: onAction,
        ),
      ],
    );
  }
}

/// Legal footnote under the signup form.
class AuthTermsNotice extends StatelessWidget {
  const AuthTermsNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.authTermsNotice,
      textAlign: TextAlign.center,
      style: context.textStyles.labelSmall?.copyWith(
        color: context.colors.inkFaint,
        height: 1.5,
      ),
    );
  }
}

/// Keyboard hint chip reused by the auth screens.
class SubmitHint extends StatelessWidget {
  const SubmitHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          'Press',
          style: context.textStyles.labelSmall?.copyWith(
            color: context.colors.inkFaint,
          ),
        ),
        const SizedBox(width: Spacing.xs + 1),
        const KeycapHint(<String>['↵'], compact: true),
        const SizedBox(width: Spacing.xs + 1),
        Text(
          'to continue',
          style: context.textStyles.labelSmall?.copyWith(
            color: context.colors.inkFaint,
          ),
        ),
      ],
    );
  }
}
