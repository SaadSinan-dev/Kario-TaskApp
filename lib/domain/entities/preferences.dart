import 'package:flutter/foundation.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/focus_session.dart';
import 'package:kairo/domain/entities/json_support.dart';

/// Which notification categories reach the user.
@immutable
class NotificationPreferences {
  const NotificationPreferences({
    this.mentions = true,
    this.assignments = true,
    this.comments = true,
    this.deadlines = true,
    this.projectUpdates = false,
    this.weeklyDigest = true,
  });

  final bool mentions;
  final bool assignments;
  final bool comments;
  final bool deadlines;
  final bool projectUpdates;
  final bool weeklyDigest;

  bool allows(NotificationType type) => switch (type) {
    NotificationType.mention => mentions,
    NotificationType.assignment => assignments,
    NotificationType.comment => comments,
    NotificationType.deadline => deadlines,
    NotificationType.projectUpdate => projectUpdates,
    NotificationType.taskCompleted => true,
  };

  NotificationPreferences copyWith({
    bool? mentions,
    bool? assignments,
    bool? comments,
    bool? deadlines,
    bool? projectUpdates,
    bool? weeklyDigest,
  }) {
    return NotificationPreferences(
      mentions: mentions ?? this.mentions,
      assignments: assignments ?? this.assignments,
      comments: comments ?? this.comments,
      deadlines: deadlines ?? this.deadlines,
      projectUpdates: projectUpdates ?? this.projectUpdates,
      weeklyDigest: weeklyDigest ?? this.weeklyDigest,
    );
  }

  JsonMap toJson() => <String, dynamic>{
    'mentions': mentions,
    'assignments': assignments,
    'comments': comments,
    'deadlines': deadlines,
    'projectUpdates': projectUpdates,
    'weeklyDigest': weeklyDigest,
  };

  factory NotificationPreferences.fromJson(JsonMap json) =>
      NotificationPreferences(
        mentions: readBool(json['mentions'], true),
        assignments: readBool(json['assignments'], true),
        comments: readBool(json['comments'], true),
        deadlines: readBool(json['deadlines'], true),
        projectUpdates: readBool(json['projectUpdates']),
        weeklyDigest: readBool(json['weeklyDigest'], true),
      );
}

/// Everything the user can tune about how Kairo behaves.
///
/// Persisted as a single document in key/value storage — it is small, always
/// read together, and never queried by field.
@immutable
class UserPreferences {
  const UserPreferences({
    this.theme = ThemePreference.system,
    this.density = InterfaceDensity.comfortable,
    this.reduceMotion = false,
    this.weekStartsOn = DateTime.monday,
    this.defaultTaskView = TaskViewType.list,
    this.landingRoute = '/dashboard',
    this.focus = const FocusSettings(),
    this.notifications = const NotificationPreferences(),
    this.hasCompletedOnboarding = false,
    this.goal = ProductivityGoal.teamProjects,
    this.sidebarCollapsed = false,
    this.taskCompletionEffects = true,
  });

  final ThemePreference theme;
  final InterfaceDensity density;

  /// The app's own reduce-motion switch. The effective value also honours the
  /// platform setting — see `MotionScope`.
  final bool reduceMotion;

  final int weekStartsOn;
  final TaskViewType defaultTaskView;

  /// Where Kairo opens after sign-in.
  final String landingRoute;

  final FocusSettings focus;
  final NotificationPreferences notifications;
  final bool hasCompletedOnboarding;
  final ProductivityGoal goal;
  final bool sidebarCollapsed;

  /// The confetti burst on task completion. On by default, off for anyone who
  /// finds it noisy.
  final bool taskCompletionEffects;

  UserPreferences copyWith({
    ThemePreference? theme,
    InterfaceDensity? density,
    bool? reduceMotion,
    int? weekStartsOn,
    TaskViewType? defaultTaskView,
    String? landingRoute,
    FocusSettings? focus,
    NotificationPreferences? notifications,
    bool? hasCompletedOnboarding,
    ProductivityGoal? goal,
    bool? sidebarCollapsed,
    bool? taskCompletionEffects,
  }) {
    return UserPreferences(
      theme: theme ?? this.theme,
      density: density ?? this.density,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      weekStartsOn: weekStartsOn ?? this.weekStartsOn,
      defaultTaskView: defaultTaskView ?? this.defaultTaskView,
      landingRoute: landingRoute ?? this.landingRoute,
      focus: focus ?? this.focus,
      notifications: notifications ?? this.notifications,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      goal: goal ?? this.goal,
      sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
      taskCompletionEffects:
          taskCompletionEffects ?? this.taskCompletionEffects,
    );
  }

  JsonMap toJson() => <String, dynamic>{
    'theme': theme.name,
    'density': density.name,
    'reduceMotion': reduceMotion,
    'weekStartsOn': weekStartsOn,
    'defaultTaskView': defaultTaskView.name,
    'landingRoute': landingRoute,
    'focus': focus.toJson(),
    'notifications': notifications.toJson(),
    'hasCompletedOnboarding': hasCompletedOnboarding,
    'goal': goal.name,
    'sidebarCollapsed': sidebarCollapsed,
    'taskCompletionEffects': taskCompletionEffects,
  };

  factory UserPreferences.fromJson(JsonMap json) {
    final Object? focusRaw = json['focus'];
    final Object? notificationsRaw = json['notifications'];
    return UserPreferences(
      theme: enumFromName(
        ThemePreference.values,
        json['theme'],
        ThemePreference.system,
      ),
      density: enumFromName(
        InterfaceDensity.values,
        json['density'],
        InterfaceDensity.comfortable,
      ),
      reduceMotion: readBool(json['reduceMotion']),
      weekStartsOn: readInt(json['weekStartsOn'], DateTime.monday).clamp(1, 7),
      defaultTaskView: enumFromName(
        TaskViewType.values,
        json['defaultTaskView'],
        TaskViewType.list,
      ),
      landingRoute: readString(json['landingRoute'], '/dashboard'),
      focus: focusRaw is Map<dynamic, dynamic>
          ? FocusSettings.fromJson(asJsonMap(focusRaw))
          : const FocusSettings(),
      notifications: notificationsRaw is Map<dynamic, dynamic>
          ? NotificationPreferences.fromJson(asJsonMap(notificationsRaw))
          : const NotificationPreferences(),
      hasCompletedOnboarding: readBool(json['hasCompletedOnboarding']),
      goal: enumFromName(
        ProductivityGoal.values,
        json['goal'],
        ProductivityGoal.teamProjects,
      ),
      sidebarCollapsed: readBool(json['sidebarCollapsed']),
      taskCompletionEffects: readBool(json['taskCompletionEffects'], true),
    );
  }
}
