import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/responsive/adaptive_grid.dart';
import 'package:kairo/core/responsive/breakpoints.dart';
import 'package:kairo/core/routing/routes.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/app_typography.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/app_badge.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/core/widgets/app_segmented.dart';
import 'package:kairo/core/widgets/app_surfaces.dart';
import 'package:kairo/core/widgets/app_toast.dart';

/// A plan definition. Prices are illustrative for this portfolio build; the
/// checkout surface is structured so a payment provider can be added without
/// touching the presentation.
@immutable
class PricingPlan {
  const PricingPlan({
    required this.id,
    required this.name,
    required this.tagline,
    required this.monthly,
    required this.annual,
    required this.features,
    this.isFeatured = false,
    this.customPrice,
  });

  final String id;
  final String name;
  final String tagline;
  final int monthly;
  final int annual;
  final List<String> features;
  final bool isFeatured;
  final String? customPrice;

  static const List<PricingPlan> all = <PricingPlan>[
    PricingPlan(
      id: 'free',
      name: 'Free',
      tagline: 'For one person getting organised.',
      monthly: 0,
      annual: 0,
      features: <String>[
        '1 workspace, unlimited tasks',
        'List and board views',
        'Focus Mode with session history',
        'Command palette and shortcuts',
        'Light and dark themes',
      ],
    ),
    PricingPlan(
      id: 'pro',
      name: 'Pro',
      tagline: 'For people who plan a whole week at a time.',
      monthly: 8,
      annual: 6,
      isFeatured: true,
      features: <String>[
        'Everything in Free',
        'Calendar and timeline views',
        'Dependencies and recurring tasks',
        'Analytics with productivity score',
        'Workspace export',
      ],
    ),
    PricingPlan(
      id: 'team',
      name: 'Team',
      tagline: 'For groups shipping together.',
      monthly: 12,
      annual: 10,
      features: <String>[
        'Everything in Pro',
        'Unlimited members and guests',
        'Comments, mentions and reactions',
        'Shared labels and project roles',
        'Workspace activity feed',
      ],
    ),
    PricingPlan(
      id: 'enterprise',
      name: 'Enterprise',
      tagline: 'For organisations with a procurement team.',
      monthly: 0,
      annual: 0,
      customPrice: 'Custom',
      features: <String>[
        'Everything in Team',
        'SSO and SCIM provisioning',
        'Audit log and data residency',
        'Priority support with an SLA',
        'Onboarding assistance',
      ],
    ),
  ];
}

/// The four plans, with a monthly/annual toggle.
class PricingTable extends StatefulWidget {
  const PricingTable({super.key});

  @override
  State<PricingTable> createState() => _PricingTableState();
}

class _PricingTableState extends State<PricingTable> {
  bool _annual = true;

  @override
  Widget build(BuildContext context) {
    final ScreenSize size = context.breakpoint;
    final int columns = switch (size) {
      ScreenSize.compact => 1,
      ScreenSize.medium => 2,
      ScreenSize.expanded => 2,
      ScreenSize.large => 4,
    };

    return Column(
      children: <Widget>[
        // The billing switch and its savings badge sit side by side when there
        // is room and stack when there is not, instead of the badge being
        // pushed past the edge of a phone.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: Spacing.md,
          runSpacing: Spacing.sm,
          children: <Widget>[
            AppSegmentedControl<bool>(
              value: _annual,
              options: const <SegmentOption<bool>>[
                SegmentOption<bool>(value: false, label: 'Monthly'),
                SegmentOption<bool>(value: true, label: 'Annual'),
              ],
              onChanged: (bool value) => setState(() => _annual = value),
            ),
            const AppBadge(
              label: 'Save 20%',
              tone: BadgeTone.success,
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: Spacing.xxxl),
        // Plan cards differ in how many features they list, so their height is
        // content-driven; an aspect ratio would clip the longest plan.
        AdaptiveCardGrid(
          columns: columns,
          spacing: Spacing.lg,
          runSpacing: Spacing.lg,
          children: <Widget>[
            for (int i = 0; i < PricingPlan.all.length; i++)
              RevealOnMountLocal(
                index: i,
                child: PlanCard(plan: PricingPlan.all[i], annual: _annual),
              ),
          ],
        ),
      ],
    );
  }
}

/// Local reveal wrapper so this file does not depend on the marketing shell.
class RevealOnMountLocal extends StatelessWidget {
  const RevealOnMountLocal({required this.child, this.index = 0, super.key});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) =>
      Entrance(index: index, offset: 14, child: child);
}

class PlanCard extends ConsumerWidget {
  const PlanCard({required this.plan, required this.annual, super.key});

  final PricingPlan plan;
  final bool annual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final int price = annual ? plan.annual : plan.monthly;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        AppCard(
          elevation: plan.isFeatured ? 2 : 1,
          borderColor: plan.isFeatured ? colors.brand : null,
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(plan.name, style: context.textStyles.titleLarge),
              const SizedBox(height: 4),
              Text(
                plan.tagline,
                style: context.textStyles.bodySmall?.copyWith(
                  color: colors.inkMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    plan.customPrice ?? (price == 0 ? '£0' : '£$price'),
                    style: AppTypography.numeric.copyWith(
                      fontSize: 34,
                      height: 1,
                      color: colors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (plan.customPrice == null) ...<Widget>[
                    const SizedBox(width: Spacing.xs),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        price == 0 ? 'forever' : '/user/month',
                        style: context.textStyles.labelSmall?.copyWith(
                          color: colors.inkFaint,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (plan.customPrice == null && annual && price > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'billed annually',
                    style: context.textStyles.labelSmall?.copyWith(
                      color: colors.inkFaint,
                    ),
                  ),
                ),
              const SizedBox(height: Spacing.xl),
              AppButton(
                label: switch (plan.id) {
                  'free' => 'Start for free',
                  'enterprise' => 'Contact sales',
                  _ => 'Choose ${plan.name}',
                },
                variant: plan.isFeatured
                    ? AppButtonVariant.primary
                    : AppButtonVariant.secondary,
                isFullWidth: true,
                onPressed: () => _choose(context, ref),
              ),
              const SizedBox(height: Spacing.xl),
              Divider(color: colors.hairline),
              const SizedBox(height: Spacing.md),
              // A plain column, not an `Expanded` list: a plan has five
              // features, the card is sized by its content, and a non-scrolling
              // `ListView` inside an `Expanded` only made sense while the card
              // had a height imposed on it from outside.
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final String feature in plan.features)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Spacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            AppIcons.check,
                            size: 14,
                            color: plan.isFeatured
                                ? colors.brand
                                : colors.success,
                          ),
                          const SizedBox(width: Spacing.sm),
                          Expanded(
                            child: Text(
                              feature,
                              style: context.textStyles.bodySmall?.copyWith(
                                color: colors.inkSoft,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (plan.isFeatured)
          Positioned(
            top: -11,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  gradient: colors.brandGradient,
                  borderRadius: Radii.brPill,
                ),
                child: Text(
                  'MOST POPULAR',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 9.5,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _choose(BuildContext context, WidgetRef ref) {
    if (plan.id == 'free') {
      context.go(Routes.signup);
      return;
    }
    ref.toasts.show(
      'Checkout is not connected',
      description:
          'Plans and the upgrade surface are built; wiring a payment provider '
          'is the remaining step.',
    );
  }
}
