import 'package:flutter/material.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/responsive/breakpoints.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/app_typography.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/app_surfaces.dart';
import 'package:kairo/features/marketing/presentation/widgets/brand.dart';
import 'package:kairo/features/marketing/presentation/widgets/marketing_shell.dart';

/// About Kairo — what it is, how it was built, and what is honestly not there.
///
/// A portfolio product benefits from saying plainly what is real. This page is
/// where the engineering story lives.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MarketingShell(
      children: <Widget>[
        _AboutHero(),
        _Principles(),
        _HowItIsBuilt(),
        _Honesty(),
        _Closing(),
      ],
    );
  }
}

class _AboutHero extends StatelessWidget {
  const _AboutHero();

  @override
  Widget build(BuildContext context) {
    return const MarketingSection(
      child: Column(
        children: <Widget>[
          SectionHeading(
            eyebrow: 'About',
            title: 'A task app built around\nthe hard part',
            description:
                'Kairo is named after kairos — the opportune moment. The whole '
                'product is arranged around one question: what is the right '
                'thing to work on now, and how do you protect the time to do '
                'it?',
            icon: AppIcons.brandSpark,
          ),
          SizedBox(height: Spacing.section),
          BrandMark(size: 56, showWordmark: false),
        ],
      ),
    );
  }
}

class _Principles extends StatelessWidget {
  const _Principles();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool wide = context.breakpoint.index >= ScreenSize.expanded.index;

    const List<({IconData icon, String title, String body})> principles =
        <({IconData icon, String title, String body})>[
          (
            icon: AppIcons.speed,
            title: 'Fast beats featureful',
            body:
                'Every interaction has a keyboard route and an optimistic '
                'update. If an action needs a spinner to feel finished, it is '
                'the wrong shape.',
          ),
          (
            icon: AppIcons.target,
            title: 'One source of truth',
            body:
                'Four views read the same filtered query. The dashboard and '
                'analytics read the same snapshot. Two screens can never '
                'disagree about a number.',
          ),
          (
            icon: AppIcons.security,
            title: 'Honest by default',
            body:
                'No invented metrics, no fabricated customers, no fake '
                'checkout. Where something is not built, the product says so.',
          ),
        ];

    return MarketingSection(
      background: colors.surfaceSunken,
      child: Column(
        children: <Widget>[
          const SectionHeading(
            eyebrow: 'Principles',
            title: 'Three rules the product follows',
            icon: AppIcons.workflow,
          ),
          const SizedBox(height: Spacing.section),
          Wrap(
            spacing: Spacing.lg,
            runSpacing: Spacing.lg,
            children: <Widget>[
              for (int i = 0; i < principles.length; i++)
                SizedBox(
                  width: wide ? 340 : double.infinity,
                  child: RevealOnMount(
                    index: i,
                    child: AppCard(
                      padding: const EdgeInsets.all(Spacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            principles[i].icon,
                            size: 20,
                            color: colors.brand,
                          ),
                          const SizedBox(height: Spacing.lg),
                          Text(
                            principles[i].title,
                            style: context.textStyles.titleLarge,
                          ),
                          const SizedBox(height: Spacing.sm),
                          Text(
                            principles[i].body,
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: colors.inkMuted,
                              height: 1.65,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HowItIsBuilt extends StatelessWidget {
  const _HowItIsBuilt();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const List<({String label, String value})> stack =
        <({String label, String value})>[
          (label: 'Framework', value: 'Flutter · Material 3'),
          (label: 'State', value: 'Riverpod notifiers and providers'),
          (label: 'Routing', value: 'go_router with guards and deep links'),
          (label: 'Storage', value: 'Hive documents · secure token storage'),
          (label: 'Charts', value: 'Hand-painted with CustomPainter'),
          (label: 'Localisation', value: 'ARB resources via gen-l10n'),
        ];

    return MarketingSection(
      child: Column(
        children: <Widget>[
          const SectionHeading(
            eyebrow: 'Engineering',
            title: 'How it is put together',
            description:
                'Feature-first architecture with a strict boundary between '
                'domain, data and presentation. The UI talks to repository '
                'interfaces, never to storage.',
            icon: AppIcons.code,
          ),
          const SizedBox(height: Spacing.section),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: AppCard(
              padding: EdgeInsets.zero,
              clip: true,
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < stack.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.xl,
                        vertical: Spacing.md,
                      ),
                      decoration: BoxDecoration(
                        border: i == 0
                            ? null
                            : Border(top: BorderSide(color: colors.hairline)),
                      ),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: 130,
                            child: Text(
                              stack[i].label,
                              style: context.textStyles.labelMedium?.copyWith(
                                color: colors.inkMuted,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              stack[i].value,
                              style: AppTypography.mono.copyWith(
                                color: colors.inkSoft,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Honesty extends StatelessWidget {
  const _Honesty();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const List<String> notBuilt = <String>[
      'A server. Everything runs against a local repository implementation.',
      'Payments. Plans and the upgrade surface exist; no provider is wired.',
      'Social sign-in. The buttons are real UI awaiting OAuth client ids.',
      'File uploads. Attachment metadata is modelled; bytes need storage.',
    ];

    return MarketingSection(
      background: colors.surfaceSunken,
      child: Column(
        children: <Widget>[
          const SectionHeading(
            eyebrow: 'Scope',
            title: 'What is deliberately not here',
            description:
                'Each of these is an integration rather than a redesign — the '
                'interfaces they would plug into already exist.',
            icon: AppIcons.info,
          ),
          const SizedBox(height: Spacing.xxxl),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: <Widget>[
                for (final String item in notBuilt)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(AppIcons.info, size: 15, color: colors.inkFaint),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: Text(
                            item,
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: colors.inkMuted,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Closing extends StatelessWidget {
  const _Closing();

  @override
  Widget build(BuildContext context) {
    return const MarketingSection(
      child: Column(
        children: <Widget>[
          SectionHeading(
            eyebrow: 'Try it',
            title: 'The demo is the product',
            description:
                'Every feature on this site works in the demo workspace, '
                'including the parts that are usually screenshots.',
            icon: AppIcons.play,
          ),
          SizedBox(height: Spacing.xxxl),
          MarketingCtaRow(),
        ],
      ),
    );
  }
}
