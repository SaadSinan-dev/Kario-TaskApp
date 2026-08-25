import 'package:kairo/domain/entities/json_support.dart';
import 'package:meta/meta.dart';

/// A person who can sign in and be assigned work.
@immutable
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.jobTitle = '',
    this.avatarUrl,
    this.accentColorValue,
    this.timezone = 'Europe/London',
    this.locale = 'en',
    this.isEmailVerified = true,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String jobTitle;

  /// Remote avatar. When null the UI falls back to generated initials, which is
  /// what the demo workspace uses so it works fully offline.
  final String? avatarUrl;

  /// Stable per-person colour for the initials avatar.
  final int? accentColorValue;

  final String timezone;
  final String locale;
  final bool isEmailVerified;
  final DateTime? createdAt;

  /// Up to two initials, derived rather than stored.
  String get initials {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters2(2).toUpperCase();
    }
    return '${parts.first.characters2(1)}${parts.last.characters2(1)}'
        .toUpperCase();
  }

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  User copyWith({
    String? name,
    String? email,
    String? jobTitle,
    String? avatarUrl,
    bool clearAvatar = false,
    int? accentColorValue,
    String? timezone,
    String? locale,
    bool? isEmailVerified,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      jobTitle: jobTitle ?? this.jobTitle,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      accentColorValue: accentColorValue ?? this.accentColorValue,
      timezone: timezone ?? this.timezone,
      locale: locale ?? this.locale,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt,
    );
  }

  JsonMap toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'email': email,
    'jobTitle': jobTitle,
    'avatarUrl': avatarUrl,
    'accentColorValue': accentColorValue,
    'timezone': timezone,
    'locale': locale,
    'isEmailVerified': isEmailVerified,
    'createdAt': writeDate(createdAt),
  };

  factory User.fromJson(JsonMap json) => User(
    id: readString(json['id']),
    name: readString(json['name']),
    email: readString(json['email']),
    jobTitle: readString(json['jobTitle']),
    avatarUrl: json['avatarUrl'] as String?,
    accentColorValue: readIntOrNull(json['accentColorValue']),
    timezone: readString(json['timezone'], 'Europe/London'),
    locale: readString(json['locale'], 'en'),
    isEmailVerified: readBool(json['isEmailVerified'], true),
    createdAt: readDate(json['createdAt']),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is User && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

extension _SafeSubstring on String {
  String characters2(int count) => length <= count ? this : substring(0, count);
}
