import 'package:flutter/material.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/responsive/breakpoints.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/app_surfaces.dart';
import 'package:kairo/features/marketing/presentation/widgets/marketing_shell.dart';
import 'package:kairo/features/marketing/presentation/widgets/pricing_table.dart';

/// The pricing page.
class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MarketingShell(
      children: <Widget>[_PricingHero(), _ComparisonTable(), _PricingFaq()],
    );
  }
}

class _PricingHero extends StatelessWidget {
  const _PricingHero();

  @override
  Widget build(BuildContext context) {
    return const MarketingSection(
      child: Column(
        children: <Widget>[
          SectionHeading(
            eyebrow: 'Pricing',
            title: 'Simple plans.\nNo surprise line items.',
            description:
                'Payments are not connected in this build. The plans, the '
                'comparison and the upgrade surface are real UI, structured '
                'so a payment provider can be added without redesigning them.',
            icon: AppIcons.billing,
          ),
          SizedBox(height: Spacing.section),
          PricingTable(),
        ],
      ),
    );
  }
}

/// Feature-by-feature comparison. On narrow screens the table becomes one card
/// per plan rather than a horizontally scrolling grid nobody reads.
class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable();

  static const List<
    ({String group, List<({String feature, List<bool> plans})> rows})
  >
  _groups = <({String group, List<({String feature, List<bool> plans})> rows})>[
    (
      group: 'Planning',
      rows: <({String feature, List<bool> plans})>[
        (
          feature: 'List and board views',
          plans: <bool>[true, true, true, true],
        ),
        (
          feature: 'Calendar and timeline',
          plans: <bool>[false, true, true, true],
        ),
        (feature: 'Dependencies', plans: <bool>[false, true, true, true]),
        (feature: 'Recurring tasks', plans: <bool>[false, true, true, true]),
      ],
    ),
    (
      group: 'Collaboration',
      rows: <({String feature, List<bool> plans})>[
        (
          feature: 'Comments and mentions',
          plans: <bool>[false, false, true, true],
        ),
        (feature: 'Shared labels', plans: <bool>[false, false, true, true]),
        (feature: 'Workspace roles', plans: <bool>[false, false, true, true]),
      ],
    ),
    (
      group: 'Insight',
      rows: <({String feature, List<bool> plans})>[
        (feature: 'Focus Mode', plans: <bool>[true, true, true, true]),
        (
          feature: 'Productivity analytics',
          plans: <bool>[false, true, true, true],
        ),
        (feature: 'Workspace export', plans: <bool>[false, true, true, true]),
      ],
    ),
    (
      group: 'Administration',
      rows: <({String feature, List<bool> plans})>[
        (feature: 'SSO and SCIM', plans: <bool>[false, false, false, true]),
        (feature: 'Audit log', plans: <bool>[false, false, false, true]),
        (feature: 'Priority support', plans: <bool>[false, false, false, true]),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool wide = context.breakpoint.index >= ScreenSize.expanded.index;

    if (!wide) {
      return MarketingSection(
        background: colors.surfaceSunken,
        child: Column(
          children: <Widget>[
            const SectionHeading(
              eyebrow: 'Compare',
              title: 'What is in each plan',
              icon: AppIcons.checkAll,
            ),
            const SizedBox(height: Spacing.xxxl),
            for (
              int planIndex = 0;
              planIndex < PricingPlan.all.length;
              planIndex++
            )
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.lg),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        PricingPlan.all[planIndex].name,
                        style: context.textStyles.titleLarge,
                      ),
                      const SizedBox(height: Spacing.md),
                      for (final ({
                            String group,
                            List<({String feature, List<bool> plans})> rows,
                          })
                          group
                          in _groups)
                        for (final ({String feature, List<bool> plans}) row
                            in group.rows)
                          if (row.plans[planIndex])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    AppIcons.check,
                                    size: 13,
                                    color: colors.success,
                                  ),
                                  const SizedBox(width: Spacing.sm),
                                  // Feature names are full phrases; they wrap
                                  // onto a second line rather than truncate,
                                  // because half a feature name sells nothing.
                                  Expanded(
                                    child: Text(
                                      row.feature,
                                      style: context.textStyles.bodySmall,
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

    return MarketingSection(
      background: colors.surfaceSunken,
      child: Column(
        children: <Widget>[
          const SectionHeading(
            eyebrow: 'Compare',
            title: 'What is in each plan',
            icon: AppIcons.checkAll,
          ),
          const SizedBox(height: Spacing.section),
          AppCard(
            padding: EdgeInsets.zero,
            clip: true,
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.lg,
                    vertical: Spacing.md,
                  ),
                  color: colors.surfaceSunken,
                  child: Row(
                    children: <Widget>[
                      const Expanded(flex: 3, child: SizedBox.shrink()),
                      for (final PricingPlan plan in PricingPlan.all)
                        Expanded(
                          child: Text(
                            plan.name,
                            textAlign: TextAlign.center,
                            style: context.textStyles.titleSmall?.copyWith(
                              color: plan.isFeatured
                                  ? colors.brand
                                  : colors.ink,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                for (final ({
                      String group,
                      List<({String feature, List<bool> plans})> rows,
                    })
                    group
                    in _groups) ...<Widget>[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.lg,
                      vertical: Spacing.sm,
                    ),
                    color: colors.canvas,
                    child: Text(
                      group.group.toUpperCase(),
                      style: context.textStyles.labelSmall?.copyWith(
                        color: colors.inkFaint,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                  for (final ({String feature, List<bool> plans}) row
                      in group.rows)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.lg,
                        vertical: Spacing.md,
                      ),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: colors.hairline)),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            flex: 3,
                            child: Text(
                              row.feature,
                              style: context.textStyles.bodySmall,
                            ),
                          ),
                          for (final bool included in row.plans)
                            Expanded(
                              child: Center(
                                child: Icon(
                                  included ? AppIcons.check : AppIcons.close,
                                  size: 15,
                                  color: included
                                      ? colors.success
                                      : colors.inkFaint.withValues(alpha: 0.45),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingFaq extends StatelessWidget {
  const _PricingFaq();

  @override
  Widget build(BuildContext context) {
    const List<({String question, String answer})> faqs =
        <({String question, String answer})>[
          (
            question: 'Can I try Pro before paying?',
            answer:
                'The demo workspace runs with every feature enabled, so you '
                'can use calendar, timeline, dependencies and analytics before '
                'deciding anything.',
          ),
          (
            question: 'What happens when I hit the Free limits?',
            answer:
                'Nothing is deleted. Views that belong to a paid plan become '
                'read-only and prompt to upgrade; your data stays intact.',
          ),
          (
            question: 'Is billing wired up?',
            answer:
                'No. This is a portfolio build, and pretending to take payment '
                'would be dishonest. The plan model, upgrade surface and '
                'checkout entry point are built so a real provider drops in.',
          ),
        ];

    return MarketingSection(
      child: Column(
        children: <Widget>[
          const SectionHeading(
            eyebrow: 'FAQ',
            title: 'About the plans',
            icon: AppIcons.docs,
          ),
          const SizedBox(height: Spacing.section),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: <Widget>[
                for (final ({String question, String answer}) faq in faqs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.md),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.xl,
                        vertical: Spacing.sm,
                      ),
                      child: AppDisclosure(
                        title: faq.question,
                        initiallyExpanded: false,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: Spacing.lg,
                            left: Spacing.xxl,
                          ),
                          child: Text(
                            faq.answer,
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: context.colors.inkMuted,
                              height: 1.7,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.section),
          const MarketingCtaRow(),
        ],
      ),
    );
  }
}
