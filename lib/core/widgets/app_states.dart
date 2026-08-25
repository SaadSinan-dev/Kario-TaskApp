import 'package:flutter/material.dart';
import 'package:kairo/core/error/failure.dart';
import 'package:kairo/core/error/failure_messages.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/app_button.dart';

/// The empty state.
///
/// Three parts, always: an illustration built from the brand's own shapes, a
/// headline that says something specific about *this* emptiness, and one
/// obvious next action. Never "No data".
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.compact = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Centred when it fits, scrollable when it does not. An empty state is the
    // whole content of its area, so on a short viewport — a phone in landscape,
    // a small panel, a large system text scale — the honest behaviour is to let
    // the user reach the action button, not to clip it.
    return Center(
      child: SingleChildScrollView(
        child: Entrance(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: EdgeInsets.all(compact ? Spacing.xl : Spacing.xxxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _EmptyGlyph(icon: icon, compact: compact),
                  SizedBox(height: compact ? Spacing.lg : Spacing.xl),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: compact
                        ? context.textStyles.titleMedium
                        : context.textStyles.headlineSmall,
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: colors.inkMuted,
                      height: 1.55,
                    ),
                  ),
                  if (actionLabel != null ||
                      secondaryActionLabel != null) ...<Widget>[
                    SizedBox(height: compact ? Spacing.lg : Spacing.xxl),
                    Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.sm,
                      alignment: WrapAlignment.center,
                      children: <Widget>[
                        if (actionLabel != null)
                          AppButton.primary(
                            label: actionLabel!,
                            icon: AppIcons.add,
                            onPressed: onAction,
                          ),
                        if (secondaryActionLabel != null)
                          AppButton(
                            label: secondaryActionLabel!,
                            variant: AppButtonVariant.ghost,
                            onPressed: onSecondaryAction,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The illustration: concentric brand-tinted rings around the section's own
/// icon. Cheap to draw, on-brand, and it scales to any screen without assets.
class _EmptyGlyph extends StatelessWidget {
  const _EmptyGlyph({required this.icon, required this.compact});

  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final double size = compact ? 68 : 96;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  colors.brand.withValues(alpha: colors.isDark ? 0.22 : 0.12),
                  colors.brand.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.brand.withValues(alpha: 0.22)),
            ),
          ),
          Container(
            width: size * 0.48,
            height: size * 0.48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.brandSoft,
              border: Border.all(color: colors.brandBorder),
            ),
            child: Icon(icon, size: size * 0.24, color: colors.brand),
          ),
        ],
      ),
    );
  }
}

/// The error state. Always names what went wrong and offers a way forward.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    required this.error,
    this.onRetry,
    this.onGoHome,
    this.compact = false,
    super.key,
  });

  final Object error;
  final VoidCallback? onRetry;
  final VoidCallback? onGoHome;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final FailureMessage message = describeError(error, context.l10n);
    final bool offline = error is NetworkFailure;

    // Scrollable for the same reason as the empty state: the retry button has
    // to stay reachable on a short viewport.
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: EdgeInsets.all(compact ? Spacing.xl : Spacing.xxxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: compact ? 44 : 56,
                  height: compact ? 44 : 56,
                  decoration: BoxDecoration(
                    color: offline ? colors.warningSoft : colors.dangerSoft,
                    borderRadius: Radii.brXl,
                  ),
                  child: Icon(
                    offline ? AppIcons.offline : AppIcons.error,
                    size: compact ? 20 : 24,
                    color: offline ? colors.warning : colors.danger,
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                Text(
                  message.title,
                  textAlign: TextAlign.center,
                  style: compact
                      ? context.textStyles.titleMedium
                      : context.textStyles.headlineSmall,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  message.body,
                  textAlign: TextAlign.center,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: colors.inkMuted,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                Wrap(
                  spacing: Spacing.sm,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    if (onRetry != null && message.isRetryable)
                      AppButton.primary(
                        label: context.l10n.actionRetry,
                        icon: AppIcons.retry,
                        onPressed: onRetry,
                      ),
                    if (onGoHome != null)
                      AppButton(
                        label: context.l10n.errorGoHome,
                        variant: AppButtonVariant.ghost,
                        onPressed: onGoHome,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact inline error for a panel that failed inside an otherwise fine page.
class InlineError extends StatelessWidget {
  const InlineError({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colors.dangerSoft,
        borderRadius: Radii.brMd,
        border: Border.all(color: colors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: <Widget>[
          Icon(AppIcons.error, size: 16, color: colors.danger),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              message,
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.danger,
              ),
            ),
          ),
          if (onRetry != null)
            AppButton(
              label: context.l10n.actionRetry,
              variant: AppButtonVariant.link,
              size: AppButtonSize.small,
              onPressed: onRetry,
            ),
        ],
      ),
    );
  }
}
