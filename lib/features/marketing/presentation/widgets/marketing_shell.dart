import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/responsive/breakpoints.dart';
import 'package:kairo/core/routing/routes.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/core/widgets/app_overlays.dart';
import 'package:kairo/features/auth/application/auth_controller.dart';
import 'package:kairo/features/marketing/presentation/widgets/brand.dart';
import 'package:kairo/features/shell/presentation/widgets/app_top_bar.dart';

/// The public site's frame: sticky header, content, footer.
class MarketingShell extends StatelessWidget {
  const MarketingShell({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          const MarketingHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[...children, const MarketingFooter()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MarketingHeader extends ConsumerWidget {
  const MarketingHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final bool wide = context.breakpoint.index >= ScreenSize.expanded.index;
    final bool narrow = context.breakpoint.isCompact;
    final String location = GoRouterState.of(context).uri.path;

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: colors.canvas.withValues(alpha: 0.92),
        border: Border(bottom: BorderSide(color: colors.hairline)),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.gutter),
              child: Row(
                children: <Widget>[
                  InkWell(
                    onTap: () => context.go(Routes.landing),
                    borderRadius: Radii.brSm,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: BrandMark(size: 30),
                    ),
                  ),
                  // The generous gap between the mark and the navigation is a
                  // wide-screen luxury; on a phone it is the difference
                  // between the sign-up button fitting and not.
                  SizedBox(width: wide ? Spacing.xxl : Spacing.md),
                  if (wide) ...<Widget>[
                    _NavLink(
                      label: 'Product',
                      isActive: location == Routes.landing,
                      onTap: () => context.go(Routes.landing),
                    ),
                    _NavLink(
                      label: 'Pricing',
                      isActive: location == Routes.pricing,
                      onTap: () => context.go(Routes.pricing),
                    ),
                    _NavLink(
                      label: 'About',
                      isActive: location == Routes.about,
                      onTap: () => context.go(Routes.about),
                    ),
                  ],
                  const Spacer(),
                  // The theme toggle is the least essential control in a
                  // marketing header and the first to go: on a phone the row
                  // has to hold a call to action and a menu, and the theme
                  // still follows the system by default.
                  if (!narrow) ...<Widget>[
                    const ThemeToggleButton(),
                    const SizedBox(width: Spacing.sm),
                  ],
                  if (wide) ...<Widget>[
                    AppButton(
                      label: context.l10n.authSignIn,
                      variant: AppButtonVariant.ghost,
                      size: AppButtonSize.small,
                      onPressed: () => context.go(Routes.login),
                    ),
                    const SizedBox(width: Spacing.sm),
                  ],
                  Flexible(
                    child: AppButton.primary(
                      label: narrow ? 'Start free' : 'Start for free',
                      size: AppButtonSize.small,
                      onPressed: () => context.go(Routes.signup),
                    ),
                  ),
                  if (!wide) ...<Widget>[
                    const SizedBox(width: Spacing.xs),
                    AppIconButton(
                      icon: AppIcons.more,
                      tooltip: context.l10n.navMore,
                      onPressed: () => _openMenu(context),
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

  Future<void> _openMenu(BuildContext context) {
    return showAppSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SheetHeader(title: 'Kairo'),
            ListTile(
              leading: const Icon(AppIcons.launch, size: 18),
              title: const Text('Product'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.go(Routes.landing);
              },
            ),
            ListTile(
              leading: const Icon(AppIcons.billing, size: 18),
              title: const Text('Pricing'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.go(Routes.pricing);
              },
            ),
            ListTile(
              leading: const Icon(AppIcons.docs, size: 18),
              title: const Text('About'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.go(Routes.about);
              },
            ),
            ListTile(
              leading: const Icon(AppIcons.assignee, size: 18),
              title: Text(context.l10n.authSignIn),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.go(Routes.login);
              },
            ),
            const SizedBox(height: Spacing.md),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          child: Text(
            widget.label,
            style: context.textStyles.labelLarge?.copyWith(
              color: widget.isActive
                  ? colors.ink
                  : (_hovered ? colors.inkSoft : colors.inkMuted),
              fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class MarketingFooter extends StatelessWidget {
  const MarketingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool wide = context.breakpoint.index >= ScreenSize.expanded.index;

    final List<({String title, List<String> links})>
    columns = <({String title, List<String> links})>[
      (
        title: 'Product',
        links: <String>['Tasks', 'Board', 'Calendar', 'Timeline', 'Focus Mode'],
      ),
      (
        title: 'Company',
        links: <String>['About', 'Careers', 'Blog', 'Contact'],
      ),
      (
        title: 'Resources',
        links: <String>['Docs', 'Changelog', 'Keyboard shortcuts', 'Status'],
      ),
      (title: 'Legal', links: <String>['Privacy', 'Terms', 'Security', 'DPA']),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        border: Border(top: BorderSide(color: colors.hairline)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.gutter,
              vertical: Spacing.section,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Expanded(flex: 2, child: _FooterBrand()),
                      for (final ({String title, List<String> links}) column
                          in columns)
                        Expanded(child: _FooterColumn(column: column)),
                    ],
                  )
                else ...<Widget>[
                  const _FooterBrand(),
                  const SizedBox(height: Spacing.xxl),
                  Wrap(
                    spacing: Spacing.section,
                    runSpacing: Spacing.xl,
                    children: <Widget>[
                      for (final ({String title, List<String> links}) column
                          in columns)
                        SizedBox(
                          width: 150,
                          child: _FooterColumn(column: column),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: Spacing.section),
                Divider(color: colors.hairline),
                const SizedBox(height: Spacing.lg),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: Spacing.sm,
                  children: <Widget>[
                    Text(
                      '© ${DateTime.now().year} Kairo. A portfolio project built '
                      'with Flutter.',
                      style: context.textStyles.labelSmall?.copyWith(
                        color: colors.inkFaint,
                      ),
                    ),
                    Text(
                      'Built for web, iOS, Android and desktop from one codebase.',
                      style: context.textStyles.labelSmall?.copyWith(
                        color: colors.inkFaint,
                      ),
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

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const BrandMark(size: 30),
        const SizedBox(height: Spacing.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Text(
            'The command center for focused work. Plan, prioritise and protect '
            'the time you need to finish things.',
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.inkMuted,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({required this.column});

  final ({String title, List<String> links}) column;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          column.title,
          style: context.textStyles.labelMedium?.copyWith(color: colors.ink),
        ),
        const SizedBox(height: Spacing.md),
        for (final String link in column.links)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: Text(
              link,
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.inkMuted,
              ),
            ),
          ),
      ],
    );
  }
}

/// Centred section wrapper used by every marketing block.
class MarketingSection extends StatelessWidget {
  const MarketingSection({
    required this.child,
    this.background,
    this.verticalPadding = Spacing.page,
    this.maxWidth = 1200,
    super.key,
  });

  final Widget child;
  final Color? background;
  final double verticalPadding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: background,
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.gutter),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Eyebrow + headline + supporting sentence, centred.
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    required this.eyebrow,
    required this.title,
    this.description,
    this.icon,
    this.align = TextAlign.center,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String? description;
  final IconData? icon;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final bool centred = align == TextAlign.center;
    return Column(
      crossAxisAlignment: centred
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: <Widget>[
        BrandEyebrowChip(label: eyebrow, icon: icon),
        const SizedBox(height: Spacing.lg),
        Text(
          title,
          textAlign: align,
          style: context.isCompact
              ? context.textStyles.headlineLarge
              : context.textStyles.displayMedium,
        ),
        if (description != null) ...<Widget>[
          const SizedBox(height: Spacing.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              description!,
              textAlign: align,
              style: context.textStyles.bodyLarge?.copyWith(
                color: context.colors.inkMuted,
                height: 1.65,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The two primary calls to action, used in the hero and the closing block.
class MarketingCtaRow extends ConsumerWidget {
  const MarketingCtaRow({this.large = true, super.key});

  final bool large;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: Spacing.md,
      runSpacing: Spacing.md,
      alignment: WrapAlignment.center,
      children: <Widget>[
        AppButton.primary(
          label: 'Start for free',
          size: large ? AppButtonSize.large : AppButtonSize.medium,
          trailingIcon: AppIcons.arrowRight,
          onPressed: () => context.go(Routes.signup),
        ),
        AppButton(
          label: 'Explore demo',
          icon: AppIcons.play,
          size: large ? AppButtonSize.large : AppButtonSize.medium,
          onPressed: () async {
            await ref
                .read(authControllerProvider.notifier)
                .signInAsDemo(context.l10n);
            if (context.mounted) context.go(Routes.dashboard);
          },
        ),
      ],
    );
  }
}

/// Entrance wrapper for marketing content, so sections reveal as they mount.
class RevealOnMount extends StatelessWidget {
  const RevealOnMount({required this.child, this.index = 0, super.key});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Entrance(index: index, offset: 18, child: child);
  }
}
