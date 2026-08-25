import 'package:flutter/widgets.dart';

/// One entry in the command palette.
///
/// Commands are plain data with a callback, which is what lets the palette,
/// the keyboard shortcut layer and the quick-create sheet all invoke the same
/// action without any of them knowing about the others.
@immutable
class Command {
  const Command({
    required this.id,
    required this.title,
    required this.section,
    required this.icon,
    required this.run,
    this.subtitle,
    this.shortcut,
    this.keywords = const <String>[],
    this.accentColorValue,
    this.trailing,
  });

  final String id;
  final String title;
  final String? subtitle;
  final CommandSection section;
  final IconData icon;

  /// Extra terms that should match this command but are not shown.
  final List<String> keywords;

  /// Displayed as keycaps on the right.
  final List<String>? shortcut;

  final int? accentColorValue;
  final Widget? trailing;

  final VoidCallback run;

  /// Everything the fuzzy matcher scores against.
  Iterable<String> get haystack => <String>[title, ?subtitle, ...keywords];
}

enum CommandSection { actions, navigate, tasks, projects, workspace }
