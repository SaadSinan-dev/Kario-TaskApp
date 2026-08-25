import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/routing/routes.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/app_badge.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/core/widgets/app_skeleton.dart';
import 'package:kairo/core/widgets/app_states.dart';
import 'package:kairo/core/widgets/app_surfaces.dart';
import 'package:kairo/core/widgets/app_text_field.dart';
import 'package:kairo/domain/repositories/repositories.dart';
import 'package:kairo/features/command_palette/presentation/command_palette.dart';
import 'package:kairo/features/search/application/search_controller.dart';
import 'package:kairo/features/shell/presentation/app_shell.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';

/// Full-page search across the workspace.
///
/// The command palette is for speed; this is for browsing — results stay on
/// screen, grouped by kind, with recent queries and recently viewed items when
/// the field is empty.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({this.initialQuery = '', super.key});

  final String initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialQuery,
  );

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchQueryProvider.notifier).setQuery(widget.initialQuery);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l10n = context.l10n;
    final String query = ref.watch(searchQueryProvider);
    final AsyncValue<List<SearchHit>> results = ref.watch(
      searchResultsProvider,
    );

    return ShellPage(
      title: l10n.searchTitle,
      subtitle: query.isEmpty
          ? l10n.emptySearchBody
          : (results.value == null
                ? l10n.commonLoading
                : '${results.value!.length} results'),
      padded: false,
      actions: <Widget>[
        PageAction(
          label: l10n.paletteTitle,
          icon: AppIcons.command,
          variant: AppButtonVariant.ghost,
          onPressed: () => openCommandPalette(context, initialQuery: query),
        ),
      ],
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          context.gutter,
          Spacing.lg,
          context.gutter,
          Spacing.huge,
        ),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppSearchField(
                    controller: _controller,
                    autofocus: true,
                    hint: l10n.searchPlaceholder,
                    onChanged: (String value) =>
                        ref.read(searchQueryProvider.notifier).setQuery(value),
                    onSubmitted: (String value) =>
                        ref.read(searchRepositoryProvider).rememberQuery(value),
                  ),
                  const SizedBox(height: Spacing.xl),
                  if (query.trim().isEmpty)
                    const _SearchLanding()
                  else
                    results.when(
                      loading: () => SkeletonList(
                        count: 5,
                        separator: Spacing.md,
                        itemBuilder: (BuildContext context) => const Row(
                          children: <Widget>[
                            Skeleton(width: 26, height: 26, radius: Radii.sm),
                            SizedBox(width: Spacing.md),
                            Expanded(child: Skeleton(height: 12)),
                          ],
                        ),
                      ),
                      error: (Object error, _) => AppErrorState(
                        error: error,
                        onRetry: () => ref.invalidate(searchResultsProvider),
                        compact: true,
                      ),
                      data: (List<SearchHit> hits) => hits.isEmpty
                          ? AppEmptyState(
                              icon: AppIcons.search,
                              title: l10n.searchNoResults(query),
                              message:
                                  'Try a shorter query, or search for a person '
                                  'or label instead.',
                              compact: true,
                            )
                          : _Results(hits: hits, query: query),
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

/// Recent queries and recently viewed items, shown before anything is typed.
class _SearchLanding extends ConsumerWidget {
  const _SearchLanding();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l10n = context.l10n;
    final AsyncValue<List<String>> recent = ref.watch(recentQueriesProvider);
    final AsyncValue<List<SearchHit>> viewed = ref.watch(
      recentlyViewedProvider,
    );

    final List<String> queries = recent.value ?? const <String>[];
    final List<SearchHit> hits = viewed.value ?? const <SearchHit>[];

    if (queries.isEmpty && hits.isEmpty) {
      return AppEmptyState(
        icon: AppIcons.search,
        title: l10n.emptySearchTitle,
        message: l10n.emptySearchBody,
        compact: true,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (queries.isNotEmpty) ...<Widget>[
          Row(
            children: <Widget>[
              AppEyebrow(l10n.searchRecent),
              const Spacer(),
              AppButton(
                label: l10n.actionClear,
                size: AppButtonSize.small,
                variant: AppButtonVariant.link,
                onPressed: () async {
                  await ref.read(searchRepositoryProvider).clearRecentQueries();
                  ref.invalidate(recentQueriesProvider);
                },
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: <Widget>[
              for (final String query in queries)
                AppFilterChip(
                  label: query,
                  icon: AppIcons.search,
                  selected: false,
                  onTap: () =>
                      ref.read(searchQueryProvider.notifier).setQuery(query),
                ),
            ],
          ),
          const SizedBox(height: Spacing.xxl),
        ],
        if (hits.isNotEmpty) ...<Widget>[
          const AppEyebrow('Recently viewed'),
          const SizedBox(height: Spacing.sm),
          for (int i = 0; i < hits.length; i++)
            _HitRow(hit: hits[i], query: '', index: i),
        ],
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.hits, required this.query});

  final List<SearchHit> hits;
  final String query;

  @override
  Widget build(BuildContext context) {
    final AppL10n l10n = context.l10n;
    final Map<SearchHitKind, List<SearchHit>> grouped =
        <SearchHitKind, List<SearchHit>>{};
    for (final SearchHit hit in hits) {
      grouped.putIfAbsent(hit.kind, () => <SearchHit>[]).add(hit);
    }

    String labelFor(SearchHitKind kind) => switch (kind) {
      SearchHitKind.task => l10n.searchResultsTasks,
      SearchHitKind.project => l10n.searchResultsProjects,
      SearchHitKind.member => l10n.searchResultsPeople,
      SearchHitKind.label => l10n.searchResultsLabels,
      SearchHitKind.comment => l10n.searchResultsComments,
    };

    int index = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final SearchHitKind kind in SearchHitKind.values)
          if (grouped[kind] != null) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(
                top: Spacing.lg,
                bottom: Spacing.sm,
              ),
              child: Row(
                children: <Widget>[
                  AppEyebrow(labelFor(kind)),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    '${grouped[kind]!.length}',
                    style: context.textStyles.labelSmall?.copyWith(
                      color: context.colors.inkFaint,
                    ),
                  ),
                ],
              ),
            ),
            for (final SearchHit hit in grouped[kind]!)
              _HitRow(hit: hit, query: query, index: index++),
          ],
      ],
    );
  }
}

class _HitRow extends ConsumerStatefulWidget {
  const _HitRow({required this.hit, required this.query, required this.index});

  final SearchHit hit;
  final String query;
  final int index;

  @override
  ConsumerState<_HitRow> createState() => _HitRowState();
}

class _HitRowState extends ConsumerState<_HitRow> {
  bool _hovered = false;

  IconData get _icon => switch (widget.hit.kind) {
    SearchHitKind.task => AppIcons.tasks,
    SearchHitKind.project => AppIcons.projects,
    SearchHitKind.member => AppIcons.assignee,
    SearchHitKind.label => AppIcons.label,
    SearchHitKind.comment => AppIcons.comment,
  };

  void _open() {
    final SearchHit hit = widget.hit;
    final String? workspaceId = ref.read(activeWorkspaceIdProvider);

    if (hit.kind == SearchHitKind.project && hit.projectId != null) {
      if (workspaceId != null) {
        ref
            .read(searchRepositoryProvider)
            .rememberViewed(
              workspaceId: workspaceId,
              id: hit.projectId!,
              kind: SearchHitKind.project,
            );
      }
      context.go(Routes.project(hit.projectId!));
      return;
    }

    if (hit.taskId != null) {
      if (workspaceId != null) {
        ref
            .read(searchRepositoryProvider)
            .rememberViewed(
              workspaceId: workspaceId,
              id: hit.taskId!,
              kind: SearchHitKind.task,
            );
      }
      openTaskDetail(context, hit.taskId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color accent = widget.hit.accentColorValue == null
        ? colors.inkMuted
        : Color(widget.hit.accentColorValue!);

    return Entrance(
      index: widget.index,
      offset: 6,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _open,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: context.motion(Motion.fast),
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: _hovered ? colors.surfaceSunken : Colors.transparent,
              borderRadius: Radii.brMd,
              border: Border.all(
                color: _hovered ? colors.hairline : Colors.transparent,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: Radii.brSm,
                  ),
                  child: Icon(_icon, size: 13, color: accent),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      HighlightedText(
                        text: widget.hit.title,
                        query: widget.query,
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.hit.subtitle.isNotEmpty)
                        Text(
                          widget.hit.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.labelSmall?.copyWith(
                            color: colors.inkFaint,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_hovered)
                  Icon(AppIcons.arrowRight, size: 14, color: colors.inkFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
