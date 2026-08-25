import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/responsive/adaptive_grid.dart';
import 'package:kairo/core/responsive/breakpoints.dart';
import 'package:kairo/core/routing/routes.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/core/widgets/app_segmented.dart';
import 'package:kairo/core/widgets/app_skeleton.dart';
import 'package:kairo/core/widgets/app_states.dart';
import 'package:kairo/core/widgets/app_toast.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/services/project_stats_calculator.dart';
import 'package:kairo/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:kairo/features/projects/presentation/widgets/project_editor.dart';
import 'package:kairo/features/shell/presentation/app_shell.dart';

/// All projects in the workspace, as progress cards.
class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  ProjectStatus? _filter;
  bool _includeArchived = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Project>> async = _includeArchived
        ? ref.watch(allProjectsProvider)
        : ref.watch(projectsProvider);
    final List<Task> tasks = ref.watch(tasksProvider).value ?? const <Task>[];

    final List<Project> projects = (async.value ?? const <Project>[])
        .where((Project p) => _filter == null || p.status == _filter)
        .toList(growable: false);

    final int columns = switch (context.breakpoint) {
      ScreenSize.compact => 1,
      ScreenSize.medium => 2,
      ScreenSize.expanded => 2,
      ScreenSize.large => 3,
    };

    return ShellPage(
      title: context.l10n.projectsTitle,
      subtitle: context.l10n.projectsTaskCount(projects.length),
      actions: <Widget>[
        PageAction(
          label: context.l10n.actionCreateProject,
          icon: AppIcons.add,
          variant: AppButtonVariant.primary,
          onPressed: () => openProjectEditor(context, ref),
        ),
      ],
      toolbar: _Toolbar(
        filter: _filter,
        includeArchived: _includeArchived,
        onFilter: (ProjectStatus? value) => setState(() => _filter = value),
        onToggleArchived: (bool value) =>
            setState(() => _includeArchived = value),
      ),
      // Cards keep their own height instead of being forced into an aspect
      // ratio derived from the column width — a one-column phone layout makes
      // that ratio produce a card far shorter than its contents.
      child: async.isLoading
          ? const SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: Spacing.lg),
              child: AdaptiveCardGrid(
                columns: 2,
                spacing: Spacing.lg,
                runSpacing: Spacing.lg,
                children: <Widget>[
                  ProjectCardSkeleton(),
                  ProjectCardSkeleton(),
                  ProjectCardSkeleton(),
                  ProjectCardSkeleton(),
                ],
              ),
            )
          : projects.isEmpty
          ? AppEmptyState(
              icon: AppIcons.projects,
              title: context.l10n.emptyProjectsTitle,
              message: context.l10n.emptyProjectsBody,
              actionLabel: context.l10n.actionCreateProject,
              onAction: () => openProjectEditor(context, ref),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
              child: AdaptiveCardGrid(
                columns: columns,
                spacing: Spacing.lg,
                runSpacing: Spacing.lg,
                children: <Widget>[
                  for (int i = 0; i < projects.length; i++)
                    ProjectProgressCard(
                      index: i,
                      project: projects[i],
                      stats: ProjectStatsCalculator.forProject(
                        projects[i].id,
                        tasks,
                      ),
                      onOpen: () => context.go(Routes.project(projects[i].id)),
                    ),
                ],
              ),
            ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.filter,
    required this.includeArchived,
    required this.onFilter,
    required this.onToggleArchived,
  });

  final ProjectStatus? filter;
  final bool includeArchived;
  final ValueChanged<ProjectStatus?> onFilter;
  final ValueChanged<bool> onToggleArchived;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.hairline)),
      ),
      child: Row(
        children: <Widget>[
          // Four status filters plus an archive switch is more than a phone row
          // holds, so the filters take the space that is left after the switch
          // and shrink their labels rather than pushing it off the edge.
          Flexible(
            child: AppSegmentedControl<ProjectStatus?>(
              value: filter,
              dense: true,
              options: <SegmentOption<ProjectStatus?>>[
                SegmentOption<ProjectStatus?>(
                  value: null,
                  label: context.l10n.commonAll,
                ),
                SegmentOption<ProjectStatus?>(
                  value: ProjectStatus.active,
                  label: context.l10n.projectsStatusActive,
                ),
                SegmentOption<ProjectStatus?>(
                  value: ProjectStatus.planning,
                  label: context.l10n.projectsStatusPlanning,
                ),
                SegmentOption<ProjectStatus?>(
                  value: ProjectStatus.completed,
                  label: context.l10n.projectsStatusCompleted,
                ),
              ],
              onChanged: onFilter,
            ),
          ),
          const SizedBox(width: Spacing.md),
          if (!context.breakpoint.isCompact) ...<Widget>[
            Text(
              context.l10n.navArchive,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.labelMedium?.copyWith(
                color: colors.inkMuted,
              ),
            ),
            const SizedBox(width: Spacing.sm),
          ],
          // On a phone the switch carries the meaning on its own, with the
          // label moved into the tooltip rather than dropped.
          Tooltip(
            message: context.l10n.navArchive,
            child: Switch(value: includeArchived, onChanged: onToggleArchived),
          ),
        ],
      ),
    );
  }
}

/// Removes a project after confirmation, keeping its tasks.
Future<void> confirmDeleteProject(
  BuildContext context,
  WidgetRef ref,
  Project project,
) async {
  final String message =
      'Tasks in “${project.name}” are kept and moved out of the project. '
      'This cannot be undone.';
  final String toast = context.l10n.toastProjectArchived;
  final bool confirmed = await showDeleteConfirmation(
    context,
    project,
    message,
  );
  if (!confirmed) return;
  await ref.read(projectRepositoryProvider).deleteProject(project.id);
  ref.toasts.show(toast, description: project.name);
}
