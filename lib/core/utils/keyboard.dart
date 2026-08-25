import 'package:flutter/widgets.dart';

/// Keyboard-shortcut guards.
///
/// Kairo binds several *unmodified* keys — `C` to create, `/` to search,
/// `Space` to complete, `G`-chords to navigate. That only works if they stay
/// inert while someone is typing: a task titled "Call Priya" must not open a
/// second composer on its first keystroke.
abstract final class KeyboardGuards {
  /// True while the caret is inside a text field anywhere in the app.
  static bool get isTypingText {
    final BuildContext? focused = FocusManager.instance.primaryFocus?.context;
    if (focused == null) return false;
    return focused.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  /// Wraps a bare-key shortcut so it does nothing while typing.
  static VoidCallback unlessTyping(VoidCallback action) {
    return () {
      if (isTypingText) return;
      action();
    };
  }
}
