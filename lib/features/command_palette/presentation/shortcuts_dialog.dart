import 'package:flutter/material.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/widgets/app_badge.dart';
import 'package:kairo/core/widgets/app_overlays.dart';

/// One row of the shortcut reference.
@immutable
class ShortcutEntry {
  const ShortcutEntry(this.keys, this.description);

  final List<String> keys;
  final String description;
}

/// The shortcut map, defined once and consumed by both this dialog and the
/// settings screen so the documentation cannot drift from the bindings.
List<({String title, List<ShortcutEntry> entries})> shortcutGroups(
  BuildContext context,
) {
  final l10n = context.l10n;
  return <({String title, List<ShortcutEntry> entries})>[
    (
      title: l10n.shortcutsGeneral,
      entries: <ShortcutEntry>[
        ShortcutEntry(const <String>['⌘', 'K'], l10n.shortcutCommandPalette),
        ShortcutEntry(const <String>['/'], l10n.shortcutSearch),
        ShortcutEntry(const <String>['C'], l10n.shortcutCreateTask),
        ShortcutEntry(const <String>['?'], l10n.shortcutsTitle),
        ShortcutEntry(const <String>['⌘', 'J'], l10n.shortcutToggleTheme),
        ShortcutEntry(const <String>['⌘', 'B'], l10n.paletteToggleSidebar),
        ShortcutEntry(const <String>['Esc'], l10n.shortcutCloseOverlay),
      ],
    ),
    (
      title: l10n.shortcutsNavigation,
      entries: <ShortcutEntry>[
        ShortcutEntry(const <String>['G', 'D'], l10n.shortcutGoDashboard),
        ShortcutEntry(const <String>['G', 'T'], l10n.shortcutGoTasks),
        ShortcutEntry(const <String>['G', 'P'], l10n.shortcutGoProjects),
        ShortcutEntry(const <String>['G', 'C'], l10n.shortcutGoCalendar),
        ShortcutEntry(const <String>['G', 'F'], l10n.shortcutGoFocus),
      ],
    ),
    (
      title: l10n.shortcutsTasks,
      entries: <ShortcutEntry>[
        const ShortcutEntry(<String>['↑', '↓'], 'Move between tasks'),
        ShortcutEntry(const <String>['Space'], l10n.shortcutCompleteTask),
        ShortcutEntry(const <String>['E'], l10n.shortcutEditTask),
        const ShortcutEntry(<String>['↵'], 'Open task detail'),
      ],
    ),
  ];
}

Future<void> showShortcutsDialog(BuildContext context) {
  return showAppDialog<void>(
    context: context,
    maxWidth: 620,
    child: Builder(
      builder: (BuildContext context) => AppDialogShell(
        title: context.l10n.shortcutsTitle,
        subtitle: 'Kairo is built to be driven from the keyboard.',
        icon: AppIcons.command,
        child: const ShortcutReference(),
      ),
    ),
  );
}

/// Reusable shortcut table. Rendered in the dialog and again inside
/// Settings → Keyboard shortcuts.
class ShortcutReference extends StatelessWidget {
  const ShortcutReference({this.columns = 2, super.key});

  final int columns;

  @override
  Widget build(BuildContext context) {
    final groups = shortcutGroups(context);
    final bool twoColumn = columns > 1 && !context.isCompact;

    final List<Widget> sections = <Widget>[
      for (final ({String title, List<ShortcutEntry> entries}) group in groups)
        _ShortcutGroup(title: group.title, entries: group.entries),
    ];

    if (!twoColumn) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final Widget section in sections) ...<Widget>[
            section,
            const SizedBox(height: Spacing.xl),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[sections.first],
          ),
        ),
        const SizedBox(width: Spacing.xxxl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final Widget section in sections.skip(1)) ...<Widget>[
                section,
                const SizedBox(height: Spacing.xl),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ShortcutGroup extends StatelessWidget {
  const _ShortcutGroup({required this.title, required this.entries});

  final String title;
  final List<ShortcutEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title.toUpperCase(),
          style: context.textStyles.labelSmall?.copyWith(
            color: colors.inkFaint,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        for (final ShortcutEntry entry in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    entry.description,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: colors.inkSoft,
                    ),
                  ),
                ),
                KeycapHint(entry.keys),
              ],
            ),
          ),
      ],
    );
  }
}
