import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/app_typography.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/utils/date_utils.dart';
import 'package:kairo/core/widgets/app_badge.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/core/widgets/app_overlays.dart';
import 'package:kairo/core/widgets/app_progress.dart';
import 'package:kairo/core/widgets/app_states.dart';
import 'package:kairo/core/widgets/app_surfaces.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/focus_session.dart';
import 'package:kairo/domain/entities/preferences.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/features/focus/application/focus_controller.dart';
import 'package:kairo/features/shell/presentation/app_shell.dart';
import 'package:kairo/features/tasks/application/task_view_controller.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';

/// Focus Mode.
///
/// The chrome recedes deliberately: the timer is the only thing with weight,
/// the palette cools, and a slow ambient gradient drifts behind it. Everything
/// else on this screen exists to answer one question — what am I working on —
/// and then get out of the way.
class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l10n = context.l10n;
    final FocusState focus = ref.watch(focusControllerProvider);
    final List<Task> candidates = ref.watch(myOpenTasksProvider);
    final Task? selected = focus.taskId == null
        ? null
        : (ref.watch(tasksProvider).value ?? const <Task>[])
              .where((Task t) => t.id == focus.taskId)
              .firstOrNull;

    return ShellPage(
      title: l10n.focusTitle,
      subtitle: focus.phase.isBreak
          ? l10n.focusModeShortBreak
          : l10n.focusRoundLabel(
              focus.round,
              focus.settings.roundsBeforeLongBreak,
            ),
      padded: false,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 980;
          final Widget stage = _FocusStage(
            focus: focus,
            task: selected,
            onPickTask: () => _pickTask(context, ref, candidates),
          );
          final Widget aside = _FocusAside(focus: focus, task: selected);

          if (!wide) {
            return ListView(
              padding: EdgeInsets.symmetric(
                horizontal: context.gutter,
                vertical: Spacing.lg,
              ),
              children: <Widget>[
                stage,
                const SizedBox(height: Spacing.xl),
                aside,
              ],
            );
          }

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.gutter,
              vertical: Spacing.lg,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(flex: 3, child: stage),
                const SizedBox(width: Spacing.xl),
                SizedBox(
                  width: 340,
                  child: SingleChildScrollView(child: aside),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickTask(
    BuildContext context,
    WidgetRef ref,
    List<Task> candidates,
  ) async {
    final Map<String, Project> projects = ref.read(projectsByIdProvider);
    await showAppSheet<void>(
      context: context,
      expand: true,
      initialSize: 0.7,
      builder: (BuildContext sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SheetHeader(title: context.l10n.focusSelectTask),
          Flexible(
            child: candidates.isEmpty
                ? AppEmptyState(
                    icon: AppIcons.focus,
                    title: context.l10n.emptyFocusTitle,
                    message: context.l10n.emptyFocusBody,
                    compact: true,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(Spacing.sm),
                    itemCount: candidates.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Task task = candidates[index];
                      final Project? project = task.projectId == null
                          ? null
                          : projects[task.projectId!];
                      return ListTile(
                        title: Text(task.title),
                        subtitle: project == null
                            ? null
                            : Text('${project.iconEmoji}  ${project.name}'),
                        trailing: task.dueDate == null
                            ? null
                            : Text(
                                Dates.dueLabel(task.dueDate, context.l10n),
                                style: context.textStyles.labelSmall,
                              ),
                        onTap: () {
                          ref
                              .read(focusControllerProvider.notifier)
                              .selectTask(task.id);
                          Navigator.of(sheetContext).pop();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// The timer itself, on an ambient background.
class _FocusStage extends ConsumerStatefulWidget {
  const _FocusStage({
    required this.focus,
    required this.task,
    required this.onPickTask,
  });

  final FocusState focus;
  final Task? task;
  final VoidCallback onPickTask;

  @override
  ConsumerState<_FocusStage> createState() => _FocusStageState();
}

class _FocusStageState extends ConsumerState<_FocusStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A slow gradient drift that nobody can see is still a repainting ticker,
    // so it is stopped outright when motion is reduced or the preference is
    // off — not merely frozen at a fixed value.
    final bool wanted =
        widget.focus.settings.ambientMotion && !context.reducedMotion;
    if (wanted && !_ambient.isAnimating) {
      _ambient.repeat(reverse: true);
    } else if (!wanted && _ambient.isAnimating) {
      _ambient.stop();
    }
  }

  @override
  void didUpdateWidget(covariant _FocusStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focus.settings.ambientMotion !=
        widget.focus.settings.ambientMotion) {
      didChangeDependencies();
    }
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final AppL10n l10n = context.l10n;
    final FocusState focus = widget.focus;
    final FocusController controller = ref.read(
      focusControllerProvider.notifier,
    );

    final Color accent = switch (focus.phase) {
      FocusPhase.focus => colors.brand,
      FocusPhase.shortBreak => colors.teal,
      FocusPhase.longBreak => colors.violet,
    };

    final bool animate = focus.settings.ambientMotion && !context.reducedMotion;

    return AnimatedBuilder(
      animation: _ambient,
      builder: (BuildContext context, Widget? child) {
        final double t = animate ? _ambient.value : 0.5;
        return Container(
          decoration: BoxDecoration(
            borderRadius: Radii.brXxl,
            border: Border.all(color: colors.hairline),
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 0.6, -1),
              end: Alignment(1 - t * 0.4, 1),
              colors: <Color>[
                accent.withValues(alpha: colors.isDark ? 0.20 : 0.11),
                colors.surface,
                accent.withValues(alpha: colors.isDark ? 0.10 : 0.05),
              ],
              stops: <double>[0, 0.45 + t * 0.15, 1],
            ),
          ),
          child: child,
        );
      },
      // The timer stack is tall — dial, current task, transport controls — and
      // a phone in landscape or a short window simply does not have the height
      // for it. Centred while it fits, scrollable when it does not, so the
      // start button is always reachable.
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: context.breakpoint.isCompact ? Spacing.lg : Spacing.xl,
          vertical: Spacing.section,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _PhaseSwitcher(
              phase: focus.phase,
              onChanged: controller.switchPhase,
            ),
            const SizedBox(height: Spacing.section),
            _TimerDial(focus: focus, accent: accent, animate: animate),
            const SizedBox(height: Spacing.xxl),
            _CurrentTask(task: widget.task, onPick: widget.onPickTask),
            const SizedBox(height: Spacing.xxl),
            _Controls(
              focus: focus,
              accent: accent,
              onStart: controller.start,
              onPause: controller.pause,
              onResume: controller.start,
              onStop: controller.stop,
              onSkip: controller.skip,
            ),
            const SizedBox(height: Spacing.xl),
            Text(
              focus.isRunning
                  ? (focus.phase.isBreak
                        ? 'Step away. The work will still be here.'
                        : 'One task. Everything else can wait.')
                  : l10n.focusCompleteHint,
              textAlign: TextAlign.center,
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.inkFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseSwitcher extends StatelessWidget {
  const _PhaseSwitcher({required this.phase, required this.onChanged});

  final FocusPhase phase;
  final ValueChanged<FocusPhase> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppL10n l10n = context.l10n;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: context.colors.surface.withValues(alpha: 0.7),
          borderRadius: Radii.brPill,
          border: Border.all(color: context.colors.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final FocusPhase option in FocusPhase.values)
              // "Long break" is a wide label and there are three of these; on
              // a phone they have to share whatever the row has rather than
              // each taking their natural width.
              Flexible(
                child: _PhaseChip(
                  label: switch (option) {
                    FocusPhase.focus => l10n.focusModeFocus,
                    FocusPhase.shortBreak => l10n.focusModeShortBreak,
                    FocusPhase.longBreak => l10n.focusModeLongBreak,
                  },
                  selected: option == phase,
                  onTap: () => onChanged(option),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhaseChip extends StatelessWidget {
  const _PhaseChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: context.motion(Motion.base),
        curve: Motion.emphasized,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.brand : Colors.transparent,
          borderRadius: Radii.brPill,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: context.textStyles.labelMedium?.copyWith(
            color: selected ? Colors.white : colors.inkMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _TimerDial extends StatelessWidget {
  const _TimerDial({
    required this.focus,
    required this.accent,
    required this.animate,
  });

  final FocusState focus;
  final Color accent;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final double size = context.isCompact ? 240 : 300;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          if (focus.isRunning && animate) _Breather(color: accent, size: size),
          CustomPaint(
            size: Size.square(size),
            painter: _TimerPainter(
              progress: focus.progress,
              accent: accent,
              track: colors.hairline,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                Dates.clock(focus.remaining),
                style: AppTypography.numeric.copyWith(
                  fontSize: size * 0.21,
                  height: 1,
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                '${focus.settings.minutesFor(focus.phase)} min',
                style: context.textStyles.labelMedium?.copyWith(
                  color: colors.inkFaint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A slow expanding halo — the only ornamental motion in the product, and it
/// exists to give a running timer a pulse you can feel without watching it.
class _Breather extends StatefulWidget {
  const _Breather({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  State<_Breather> createState() => _BreatherState();
}

class _BreatherState extends State<_Breather>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        final double t = Curves.easeInOut.transform(_controller.value);
        return Container(
          width: widget.size * (0.86 + t * 0.16),
          height: widget.size * (0.86 + t * 0.16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[
                widget.color.withValues(alpha: 0.16 * (1 - t)),
                widget.color.withValues(alpha: 0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimerPainter extends CustomPainter {
  const _TimerPainter({
    required this.progress,
    required this.accent,
    required this.track,
  });

  final double progress;
  final Color accent;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double stroke = size.width * 0.035;
    final double radius = (size.width - stroke) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    if (progress <= 0) return;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: <Color>[accent.withValues(alpha: 0.55), accent],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TimerPainter old) =>
      old.progress != progress || old.accent != accent;
}

class _CurrentTask extends StatelessWidget {
  const _CurrentTask({required this.task, required this.onPick});

  final Task? task;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: PressableScale(
        onTap: onPick,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.75),
            borderRadius: Radii.brLg,
            border: Border.all(color: colors.hairline),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                task == null ? AppIcons.target : AppIcons.tasks,
                size: 16,
                color: colors.inkMuted,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      task?.title ?? context.l10n.focusSelectTask,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.titleSmall?.copyWith(
                        color: task == null ? colors.inkMuted : colors.ink,
                      ),
                    ),
                    if (task != null && task!.hasSubtasks) ...<Widget>[
                      const SizedBox(height: Spacing.sm - 2),
                      SegmentedProgress(
                        total: task!.subtasks.length,
                        completed: task!.completedSubtaskCount,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Icon(AppIcons.chevronRight, size: 15, color: colors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.focus,
    required this.accent,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onSkip,
  });

  final FocusState focus;
  final Color accent;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final AppL10n l10n = context.l10n;
    // The gap between the transport controls is the first thing to give up on
    // a narrow phone — 24px either side of the primary button is a luxury at
    // 320px, and the buttons themselves must keep their 44px touch targets.
    final double gap = context.breakpoint.isCompact ? Spacing.md : Spacing.lg;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (focus.isRunning || focus.isPaused) ...<Widget>[
          AppIconButton(
            icon: AppIcons.stop,
            tooltip: l10n.focusStop,
            size: 44,
            iconSize: 18,
            onPressed: onStop,
          ),
          SizedBox(width: gap),
        ],
        Flexible(
          child: AppButton.primary(
            label: focus.isRunning
                ? l10n.focusPause
                : (focus.isPaused ? l10n.focusResume : l10n.focusStart),
            icon: focus.isRunning ? AppIcons.pause : AppIcons.play,
            size: AppButtonSize.large,
            onPressed: focus.isRunning
                ? onPause
                : (focus.isPaused ? onResume : onStart),
          ),
        ),
        SizedBox(width: gap),
        AppIconButton(
          icon: AppIcons.skip,
          tooltip: l10n.focusSkip,
          size: 44,
          iconSize: 18,
          onPressed: onSkip,
        ),
      ],
    );
  }
}

/// Session stats and history beside the timer.
class _FocusAside extends ConsumerWidget {
  const _FocusAside({required this.focus, required this.task});

  final FocusState focus;
  final Task? task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l10n = context.l10n;
    final colors = context.colors;
    final String? workspaceId = ref.watch(activeWorkspaceIdProvider);
    final AsyncValue<List<FocusSession>> sessions = workspaceId == null
        ? const AsyncValue<List<FocusSession>>.data(<FocusSession>[])
        : ref.watch(focusSessionsProvider);

    final List<FocusSession> today = (sessions.value ?? const <FocusSession>[])
        .where(
          (FocusSession s) =>
              s.phase == FocusPhase.focus &&
              Dates.isSameDay(s.startedAt, DateTime.now()),
        )
        .toList(growable: false);
    final int minutesToday = today.fold<int>(
      0,
      (int sum, FocusSession s) => sum + s.actualMinutes,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _MiniStat(
                label: l10n.focusSessionsToday,
                value: '${today.length}',
                icon: AppIcons.focus,
                color: colors.brand,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: _MiniStat(
                label: l10n.focusMinutesToday,
                value: '$minutesToday',
                icon: AppIcons.estimate,
                color: colors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppSectionHeader(
                title: l10n.settingsPreferences,
                icon: AppIcons.settings,
              ),
              const SizedBox(height: Spacing.md),
              _DurationRow(
                label: l10n.settingsPomodoroLength,
                value: focus.settings.focusMinutes,
                options: const <int>[15, 20, 25, 30, 45, 50],
                onChanged: (int value) => _updateSettings(
                  ref,
                  focus.settings.copyWith(focusMinutes: value),
                ),
              ),
              _DurationRow(
                label: l10n.settingsShortBreakLength,
                value: focus.settings.shortBreakMinutes,
                options: const <int>[3, 5, 8, 10],
                onChanged: (int value) => _updateSettings(
                  ref,
                  focus.settings.copyWith(shortBreakMinutes: value),
                ),
              ),
              _DurationRow(
                label: l10n.settingsLongBreakLength,
                value: focus.settings.longBreakMinutes,
                options: const <int>[10, 15, 20, 30],
                onChanged: (int value) => _updateSettings(
                  ref,
                  focus.settings.copyWith(longBreakMinutes: value),
                ),
              ),
              SwitchListTile(
                value: focus.settings.autoStartBreaks,
                onChanged: (bool value) => _updateSettings(
                  ref,
                  focus.settings.copyWith(autoStartBreaks: value),
                ),
                title: Text(
                  'Start breaks automatically',
                  style: context.textStyles.bodyMedium,
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              SwitchListTile(
                value: focus.settings.ambientMotion,
                onChanged: (bool value) => _updateSettings(
                  ref,
                  focus.settings.copyWith(ambientMotion: value),
                ),
                title: Text(
                  'Ambient background',
                  style: context.textStyles.bodyMedium,
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppSectionHeader(
                title: l10n.focusHistory,
                icon: AppIcons.activity,
                count: today.length,
              ),
              const SizedBox(height: Spacing.sm),
              if (today.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                  child: Text(
                    'No sessions yet today.',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.inkFaint,
                    ),
                  ),
                )
              else
                for (final FocusSession session in today.take(8))
                  _SessionRow(session: session),
            ],
          ),
        ),
      ],
    );
  }

  void _updateSettings(WidgetRef ref, FocusSettings next) {
    ref
        .read(preferencesProvider.notifier)
        .update((UserPreferences p) => p.copyWith(focus: next));
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: color),
          const SizedBox(height: Spacing.sm),
          Text(
            value,
            style: AppTypography.numeric.copyWith(
              fontSize: 22,
              color: colors.ink,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.labelSmall?.copyWith(
              color: colors.inkFaint,
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationRow extends StatelessWidget {
  const _DurationRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: context.textStyles.bodyMedium)),
          AppSelectMenu<int>(
            selected: value,
            options: <MenuOption<int>>[
              for (final int option in options)
                MenuOption<int>(value: option, label: '$option min'),
            ],
            onSelected: onChanged,
            builder: (BuildContext context, VoidCallback open) => AppButton(
              label: '$value min',
              size: AppButtonSize.small,
              variant: AppButtonVariant.secondary,
              onPressed: open,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionRow extends ConsumerWidget {
  const _SessionRow({required this.session});

  final FocusSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final Task? task = session.taskId == null
        ? null
        : (ref.watch(tasksProvider).value ?? const <Task>[])
              .where((Task t) => t.id == session.taskId)
              .firstOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: session.wasCompleted ? colors.success : colors.inkFaint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              task?.title ?? 'Focus session',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.inkSoft,
              ),
            ),
          ),
          AppBadge(
            label: '${session.actualMinutes}m',
            compact: true,
            tone: session.wasCompleted ? BadgeTone.success : BadgeTone.neutral,
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            Dates.time(session.startedAt),
            style: context.textStyles.labelSmall?.copyWith(
              color: colors.inkFaint,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sessions for the active workspace.
final focusSessionsProvider = StreamProvider<List<FocusSession>>((Ref ref) {
  final String? workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return Stream<List<FocusSession>>.value(const <FocusSession>[]);
  }
  return ref.watch(focusRepositoryProvider).watchSessions(workspaceId);
});
