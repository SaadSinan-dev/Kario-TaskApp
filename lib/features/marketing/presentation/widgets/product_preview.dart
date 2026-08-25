import 'package:flutter/material.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/app_typography.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/app_avatar.dart';
import 'package:kairo/core/widgets/app_badge.dart';
import 'package:kairo/core/widgets/app_progress.dart';
import 'package:kairo/core/widgets/app_segmented.dart';
import 'package:kairo/core/widgets/app_surfaces.dart';
import 'package:kairo/features/marketing/presentation/widgets/brand.dart';

/// Product previews for the marketing page.
///
/// These are built from the real design-system widgets — the same cards,
/// badges, rings and typography the app uses — rather than screenshots. It
/// means the page can never drift from the product, and it stays sharp at any
/// size and in either theme.

/// A browser-chrome frame around a miniature of the app shell.
class AppPreviewFrame extends StatelessWidget {
  const AppPreviewFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.brXl,
        border: Border.all(color: colors.hairline),
        boxShadow: Shadows.xl(colors.isDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          _WindowChrome(),
          SizedBox(
            height: context.isCompact ? 320 : 420,
            child: const _MiniApp(),
          ),
        ],
      ),
    );
  }
}

class _WindowChrome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        border: Border(bottom: BorderSide(color: colors.hairline)),
      ),
      child: Row(
        children: <Widget>[
          for (final Color dot in <Color>[
            const Color(0xFFFF5F57),
            const Color(0xFFFEBC2E),
            const Color(0xFF28C840),
          ])
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
            ),
          const SizedBox(width: Spacing.lg),
          Expanded(
            child: Container(
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: Radii.brXs,
                border: Border.all(color: colors.hairline),
              ),
              child: Text(
                'kairo.app/dashboard',
                style: AppTypography.mono.copyWith(
                  fontSize: 10,
                  color: colors.inkFaint,
                ),
              ),
            ),
          ),
          const SizedBox(width: Spacing.lg),
          const KeycapHint(<String>['⌘', 'K'], compact: true),
        ],
      ),
    );
  }
}

/// A miniature of the application shell: sidebar, top bar, dashboard content.
class _MiniApp extends StatelessWidget {
  const _MiniApp();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool compact = context.isCompact;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!compact)
          Container(
            width: 168,
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: colors.surface,
              border: BorderDirectional(
                end: BorderSide(color: colors.hairline),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    EmojiTile(
                      emoji: '🚀',
                      colorValue: colors.brand.toARGB32(),
                      size: 24,
                    ),
                    const SizedBox(width: Spacing.sm),
                    Flexible(
                      child: Text(
                        'Launchpad',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.titleSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                Container(
                  height: 26,
                  decoration: BoxDecoration(
                    color: colors.brand,
                    borderRadius: Radii.brSm,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'New task',
                    style: context.textStyles.labelSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.md),
                for (final ({IconData icon, String label, bool active}) item
                    in const <({IconData icon, String label, bool active})>[
                      (
                        icon: AppIcons.dashboard,
                        label: 'Dashboard',
                        active: true,
                      ),
                      (icon: AppIcons.tasks, label: 'My Tasks', active: false),
                      (icon: AppIcons.inbox, label: 'Inbox', active: false),
                      (
                        icon: AppIcons.calendar,
                        label: 'Calendar',
                        active: false,
                      ),
                      (icon: AppIcons.focus, label: 'Focus', active: false),
                      (
                        icon: AppIcons.analytics,
                        label: 'Analytics',
                        active: false,
                      ),
                    ])
                  Container(
                    height: 26,
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                    decoration: BoxDecoration(
                      color: item.active
                          ? colors.brandSoft
                          : Colors.transparent,
                      borderRadius: Radii.brSm,
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          item.icon,
                          size: 13,
                          color: item.active ? colors.brand : colors.inkMuted,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          item.label,
                          style: context.textStyles.labelSmall?.copyWith(
                            color: item.active ? colors.brand : colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: Container(
            color: colors.canvas,
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        'Good morning, Jordan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.titleMedium,
                      ),
                    ),
                    const Spacer(),
                    if (!compact)
                      const KeycapHint(<String>['C'], compact: true),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ScoreDial(score: 87, size: compact ? 96 : 118),
                    const SizedBox(width: Spacing.lg),
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Expanded(
                                child: _MiniStat(
                                  label: 'Completed',
                                  value: '38',
                                ),
                              ),
                              const SizedBox(width: Spacing.sm),
                              const Expanded(
                                child: _MiniStat(label: 'Open', value: '14'),
                              ),
                              if (!compact) ...<Widget>[
                                const SizedBox(width: Spacing.sm),
                                const Expanded(
                                  child: _MiniStat(
                                    label: 'Overdue',
                                    value: '2',
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: Spacing.sm),
                          const _MiniTaskRow(
                            title: 'Finalize onboarding flow',
                            done: false,
                            badge: 'Urgent',
                          ),
                          const _MiniTaskRow(
                            title: 'Review mobile navigation',
                            done: false,
                            badge: 'Today',
                          ),
                          const _MiniTaskRow(
                            title: 'Implement authentication',
                            done: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.brSm,
        border: Border.all(color: colors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: context.textStyles.labelSmall?.copyWith(
              color: colors.inkFaint,
              fontSize: 9.5,
            ),
          ),
          Text(
            value,
            style: AppTypography.numeric.copyWith(
              fontSize: 16,
              color: colors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTaskRow extends StatelessWidget {
  const _MiniTaskRow({required this.title, required this.done, this.badge});

  final String title;
  final bool done;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.sm - 2,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Radii.brSm,
        border: Border.all(color: colors.hairline),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            done ? AppIcons.statusDone : AppIcons.statusTodo,
            size: 12,
            color: done ? colors.success : colors.hairlineStrong,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.labelSmall?.copyWith(
                color: done ? colors.inkFaint : colors.inkSoft,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (badge != null)
            AppBadge(
              label: badge!,
              compact: true,
              tone: badge == 'Urgent' ? BadgeTone.danger : BadgeTone.warning,
            ),
        ],
      ),
    );
  }
}

/// An interactive preview that switches between miniature list, board,
/// calendar and timeline renderings.
class ViewSwitcherPreview extends StatefulWidget {
  const ViewSwitcherPreview({super.key});

  @override
  State<ViewSwitcherPreview> createState() => _ViewSwitcherPreviewState();
}

class _ViewSwitcherPreviewState extends State<ViewSwitcherPreview> {
  int _index = 1;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: <Widget>[
        AppSegmentedControl<int>(
          value: _index,
          options: const <SegmentOption<int>>[
            SegmentOption<int>(
              value: 0,
              label: 'List',
              icon: AppIcons.viewList,
            ),
            SegmentOption<int>(
              value: 1,
              label: 'Board',
              icon: AppIcons.viewBoard,
            ),
            SegmentOption<int>(
              value: 2,
              label: 'Calendar',
              icon: AppIcons.viewCalendar,
            ),
            SegmentOption<int>(
              value: 3,
              label: 'Timeline',
              icon: AppIcons.viewTimeline,
            ),
          ],
          onChanged: (int value) => setState(() => _index = value),
        ),
        const SizedBox(height: Spacing.xl),
        AppCard(
          elevation: 2,
          padding: const EdgeInsets.all(Spacing.lg),
          child: SizedBox(
            height: 300,
            child: AnimatedSwitcher(
              duration: context.motion(Motion.medium),
              switchInCurve: Motion.emphasized,
              child: switch (_index) {
                0 => const _ListPreview(key: ValueKey<int>(0)),
                1 => const _BoardPreview(key: ValueKey<int>(1)),
                2 => const _CalendarPreview(key: ValueKey<int>(2)),
                _ => const _TimelinePreview(key: ValueKey<int>(3)),
              },
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        Text(
          'Same tasks, same filters — only the layout changes.',
          style: context.textStyles.labelSmall?.copyWith(
            color: colors.inkFaint,
          ),
        ),
      ],
    );
  }
}

const List<({String title, String status, String priority})> _sampleTasks =
    <({String title, String status, String priority})>[
      (
        title: 'Finalize onboarding flow',
        status: 'In Progress',
        priority: 'Urgent',
      ),
      (title: 'Create pricing page', status: 'In Progress', priority: 'High'),
      (title: 'Review mobile navigation', status: 'Review', priority: 'High'),
      (title: 'Write launch-day runbook', status: 'To Do', priority: 'High'),
      (
        title: 'Draft getting-started docs',
        status: 'To Do',
        priority: 'Medium',
      ),
      (title: 'Implement authentication', status: 'Done', priority: 'Urgent'),
      (title: 'Ship the command palette', status: 'Done', priority: 'High'),
    ];

class _ListPreview extends StatelessWidget {
  const _ListPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < _sampleTasks.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.hairline)),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  _sampleTasks[i].status == 'Done'
                      ? AppIcons.statusDone
                      : AppIcons.statusTodo,
                  size: 14,
                  color: _sampleTasks[i].status == 'Done'
                      ? colors.success
                      : colors.hairlineStrong,
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(
                    _sampleTasks[i].title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodySmall?.copyWith(
                      decoration: _sampleTasks[i].status == 'Done'
                          ? TextDecoration.lineThrough
                          : null,
                      color: _sampleTasks[i].status == 'Done'
                          ? colors.inkFaint
                          : colors.ink,
                    ),
                  ),
                ),
                if (!context.isCompact) ...<Widget>[
                  AppBadge(label: _sampleTasks[i].status, compact: true),
                  const SizedBox(width: Spacing.sm),
                ],
                AppBadge(
                  label: _sampleTasks[i].priority,
                  compact: true,
                  tone: _sampleTasks[i].priority == 'Urgent'
                      ? BadgeTone.danger
                      : BadgeTone.warning,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BoardPreview extends StatelessWidget {
  const _BoardPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const List<String> columns = <String>[
      'To Do',
      'In Progress',
      'Review',
      'Done',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final String column in columns)
            Container(
              width: 176,
              margin: const EdgeInsets.only(right: Spacing.md),
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: colors.surfaceSunken,
                borderRadius: Radii.brMd,
                border: Border.all(color: colors.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: Spacing.sm),
                    child: Text(
                      column,
                      style: context.textStyles.labelMedium?.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                  ),
                  for (final ({String title, String status, String priority})
                      task
                      in _sampleTasks.where(
                        (({String title, String status, String priority}) t) =>
                            t.status == column,
                      ))
                    Container(
                      margin: const EdgeInsets.only(bottom: Spacing.sm - 2),
                      padding: const EdgeInsets.all(Spacing.sm),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: Radii.brSm,
                        border: Border.all(color: colors.hairline),
                        boxShadow: Shadows.xs(colors.isDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            task.title,
                            maxLines: 2,
                            style: context.textStyles.labelMedium?.copyWith(
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: Spacing.sm - 2),
                          Row(
                            children: <Widget>[
                              AppBadge(
                                label: task.priority,
                                compact: true,
                                tone: task.priority == 'Urgent'
                                    ? BadgeTone.danger
                                    : BadgeTone.warning,
                              ),
                              const Spacer(),
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: colors.brand.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
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

class _CalendarPreview extends StatelessWidget {
  const _CalendarPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            for (final String day in const <String>[
              'MON',
              'TUE',
              'WED',
              'THU',
              'FRI',
              'SAT',
              'SUN',
            ])
              Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: colors.inkFaint,
                    fontSize: 9.5,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.05,
            ),
            itemCount: 28,
            itemBuilder: (BuildContext context, int index) {
              final bool isToday = index == 10;
              final bool hasTask = <int>[
                3,
                8,
                10,
                11,
                15,
                18,
                22,
              ].contains(index);
              return Container(
                margin: const EdgeInsets.all(1.5),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isToday ? colors.brandSoft : colors.surface,
                  borderRadius: Radii.brXs,
                  border: Border.all(
                    color: isToday ? colors.brandBorder : colors.hairline,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${index + 1}',
                      style: AppTypography.numeric.copyWith(
                        fontSize: 9,
                        color: isToday ? colors.brand : colors.inkFaint,
                      ),
                    ),
                    if (hasTask) ...<Widget>[
                      const SizedBox(height: 2),
                      Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: index.isEven ? colors.brand : colors.violet,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TimelinePreview extends StatelessWidget {
  const _TimelinePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const List<({String title, double start, double width, double progress})>
    bars = <({String title, double start, double width, double progress})>[
      (title: 'Discovery', start: 0.02, width: 0.28, progress: 1),
      (title: 'Design system', start: 0.16, width: 0.34, progress: 0.8),
      (title: 'Onboarding flow', start: 0.34, width: 0.30, progress: 0.55),
      (title: 'Pricing page', start: 0.46, width: 0.24, progress: 0.3),
      (title: 'Launch runbook', start: 0.62, width: 0.30, progress: 0),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            for (final String label in const <String>[
              'Week 1',
              'Week 2',
              'Week 3',
              'Week 4',
            ])
              Expanded(
                child: Text(
                  label,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: colors.inkFaint,
                    fontSize: 9.5,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double width = constraints.maxWidth;
              return Stack(
                children: <Widget>[
                  for (int i = 0; i < 4; i++)
                    Positioned(
                      left: width * (i / 4),
                      top: 0,
                      bottom: 0,
                      child: Container(width: 1, color: colors.chartGrid),
                    ),
                  for (int i = 0; i < bars.length; i++)
                    Positioned(
                      left: width * bars[i].start,
                      top: i * 44.0 + 4,
                      width: width * bars[i].width,
                      height: 26,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors
                              .chartSeries[i % colors.chartSeries.length]
                              .withValues(alpha: 0.18),
                          borderRadius: Radii.brSm,
                          border: Border.all(
                            color: colors
                                .chartSeries[i % colors.chartSeries.length]
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: <Widget>[
                            FractionallySizedBox(
                              widthFactor: bars[i].progress,
                              heightFactor: 1,
                              child: ColoredBox(
                                color: colors
                                    .chartSeries[i % colors.chartSeries.length]
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  bars[i].title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textStyles.labelSmall
                                      ?.copyWith(fontSize: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The focus-mode preview used on the landing page.
class FocusPreview extends StatelessWidget {
  const FocusPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      elevation: 2,
      padding: const EdgeInsets.all(Spacing.xxl),
      background: colors.surface,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: colors.sheenGradient,
                borderRadius: Radii.brLg,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const BrandEyebrowChip(label: 'Focus', icon: AppIcons.focus),
              const SizedBox(height: Spacing.xl),
              ProgressRing(
                value: 0.62,
                size: 168,
                strokeWidth: 10,
                color: colors.brand,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '15:24',
                      style: AppTypography.numeric.copyWith(
                        fontSize: 34,
                        color: colors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Round 2 of 4',
                      style: context.textStyles.labelSmall?.copyWith(
                        color: colors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.xl),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.md,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: Radii.brMd,
                  border: Border.all(color: colors.hairline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(AppIcons.tasks, size: 14, color: colors.inkMuted),
                    const SizedBox(width: Spacing.sm),
                    Flexible(
                      child: Text(
                        'Finalize onboarding flow',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.titleSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
