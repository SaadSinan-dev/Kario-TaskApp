import 'package:kairo/l10n/generated/app_localizations.dart';

/// Reusable form validation.
///
/// Validators return a localised message or `null`, matching Flutter's
/// [FormFieldValidator] contract so they drop straight into `TextFormField`.
/// Composition via [Validators.compose] keeps field declarations to one line.
abstract final class Validators {
  static const int maxTitleLength = 140;
  static const int maxDescriptionLength = 20000;
  static const int minPasswordLength = 8;

  static final RegExp _email = RegExp(
    r"^[\w.!#$%&'*+/=?^`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?"
    r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
  );

  static final RegExp _hasLetter = RegExp('[A-Za-z]');
  static final RegExp _hasDigit = RegExp('[0-9]');

  static String? Function(String?) required(AppL10n l10n) {
    return (String? value) => (value == null || value.trim().isEmpty)
        ? l10n.validationRequired
        : null;
  }

  static String? Function(String?) email(AppL10n l10n) {
    return (String? value) {
      final String v = value?.trim() ?? '';
      if (v.isEmpty) return l10n.validationRequired;
      return _email.hasMatch(v) ? null : l10n.validationEmail;
    };
  }

  static String? Function(String?) password(AppL10n l10n) {
    return (String? value) {
      final String v = value ?? '';
      if (v.isEmpty) return l10n.validationRequired;
      if (v.length < minPasswordLength) return l10n.validationPasswordShort;
      if (!_hasLetter.hasMatch(v) || !_hasDigit.hasMatch(v)) {
        return l10n.validationPasswordWeak;
      }
      return null;
    };
  }

  static String? Function(String?) matches(
    AppL10n l10n,
    String Function() other,
  ) {
    return (String? value) =>
        value == other() ? null : l10n.validationPasswordMismatch;
  }

  static String? Function(String?) maxLength(AppL10n l10n, int max) {
    return (String? value) => (value != null && value.characters().length > max)
        ? l10n.validationTooLong(max)
        : null;
  }

  static String? Function(String?) minLength(AppL10n l10n, int min) {
    return (String? value) => (value == null || value.trim().length < min)
        ? l10n.validationNameShort
        : null;
  }

  static String? Function(String?) verificationCode(AppL10n l10n) {
    return (String? value) {
      final String v = value?.trim() ?? '';
      if (v.length != 6 || int.tryParse(v) == null) {
        return l10n.validationCodeLength;
      }
      return null;
    };
  }

  /// Title of a task or project: required, and short enough to stay on one
  /// line in dense list views.
  static String? Function(String?) title(AppL10n l10n) =>
      compose(<String? Function(String?)>[
        required(l10n),
        maxLength(l10n, maxTitleLength),
      ]);

  /// Runs validators in order and returns the first message produced.
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final String? Function(String?) validator in validators) {
        final String? message = validator(value);
        if (message != null) return message;
      }
      return null;
    };
  }

  /// Cross-field rule used by the task form.
  static String? dateOrder(AppL10n l10n, DateTime? start, DateTime? due) {
    if (start == null || due == null) return null;
    return due.isBefore(start) ? l10n.validationDateOrder : null;
  }

  /// Estimates are entered as free text ("2", "1.5", "90m"). Returns minutes,
  /// or null when the input is not a duration.
  static int? parseEstimateMinutes(String raw) {
    final String v = raw.trim().toLowerCase();
    if (v.isEmpty) return null;
    if (v.endsWith('m')) return int.tryParse(v.substring(0, v.length - 1));
    final String hours = v.endsWith('h') ? v.substring(0, v.length - 1) : v;
    final double? parsed = double.tryParse(hours);
    if (parsed == null || parsed <= 0) return null;
    return (parsed * 60).round();
  }
}

extension _Characters on String {
  /// Counts user-perceived characters closely enough for a length limit
  /// without pulling in the `characters` package for one call site.
  List<int> characters() => runes.toList(growable: false);
}
