// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Kairo';

  @override
  String get appTagline => 'The command center for focused work.';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navMyTasks => 'My Tasks';

  @override
  String get navInbox => 'Inbox';

  @override
  String get navProjects => 'Projects';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navTimeline => 'Timeline';

  @override
  String get navFocus => 'Focus';

  @override
  String get navAnalytics => 'Analytics';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navArchive => 'Archive';

  @override
  String get navSettings => 'Settings';

  @override
  String get navSearch => 'Search';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navMore => 'More';

  @override
  String get actionCreate => 'Create';

  @override
  String get actionCreateTask => 'New task';

  @override
  String get actionCreateProject => 'New project';

  @override
  String get actionCreateLabel => 'New label';

  @override
  String get actionSave => 'Save';

  @override
  String get actionSaveChanges => 'Save changes';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionDuplicate => 'Duplicate';

  @override
  String get actionArchive => 'Archive';

  @override
  String get actionRestore => 'Restore';

  @override
  String get actionComplete => 'Complete';

  @override
  String get actionReopen => 'Reopen';

  @override
  String get actionClose => 'Close';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionBack => 'Back';

  @override
  String get actionNext => 'Next';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionDone => 'Done';

  @override
  String get actionApply => 'Apply';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionClearAll => 'Clear all';

  @override
  String get actionSelectAll => 'Select all';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionInvite => 'Invite';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionCopyLink => 'Copy link';

  @override
  String get actionViewAll => 'View all';

  @override
  String get actionLearnMore => 'Learn more';

  @override
  String get statusBacklog => 'Backlog';

  @override
  String get statusTodo => 'To Do';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusReview => 'Review';

  @override
  String get statusDone => 'Done';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityLow => 'Low';

  @override
  String get fieldTitle => 'Title';

  @override
  String get fieldDescription => 'Description';

  @override
  String get fieldStatus => 'Status';

  @override
  String get fieldPriority => 'Priority';

  @override
  String get fieldAssignee => 'Assignee';

  @override
  String get fieldProject => 'Project';

  @override
  String get fieldLabels => 'Labels';

  @override
  String get fieldDueDate => 'Due date';

  @override
  String get fieldStartDate => 'Start date';

  @override
  String get fieldEstimate => 'Estimate';

  @override
  String get fieldRecurrence => 'Repeats';

  @override
  String get fieldDependencies => 'Dependencies';

  @override
  String get fieldSubtasks => 'Subtasks';

  @override
  String get fieldComments => 'Comments';

  @override
  String get fieldActivity => 'Activity';

  @override
  String get fieldAttachments => 'Attachments';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldFullName => 'Full name';

  @override
  String get fieldRole => 'Role';

  @override
  String get fieldTimezone => 'Timezone';

  @override
  String get fieldLanguage => 'Language';

  @override
  String get fieldUnassigned => 'Unassigned';

  @override
  String get fieldNoProject => 'No project';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignUp => 'Create account';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get authLoginTitle => 'Welcome back';

  @override
  String get authLoginSubtitle => 'Sign in to pick up where you left off.';

  @override
  String get authSignupTitle => 'Create your workspace';

  @override
  String get authSignupSubtitle => 'Start free. No credit card required.';

  @override
  String get authForgotTitle => 'Reset your password';

  @override
  String get authForgotSubtitle =>
      'We\'ll email you a secure link to choose a new password.';

  @override
  String get authResetTitle => 'Choose a new password';

  @override
  String get authResetSubtitle => 'Pick something you haven\'t used before.';

  @override
  String get authVerifyTitle => 'Verify your email';

  @override
  String authVerifySubtitle(String email) {
    return 'We sent a six-digit code to $email.';
  }

  @override
  String get authForgotLink => 'Forgot password?';

  @override
  String get authNoAccount => 'New to Kairo?';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueWithApple => 'Continue with Apple';

  @override
  String get authOrDivider => 'or';

  @override
  String get authSendResetLink => 'Send reset link';

  @override
  String get authResetSent => 'Check your inbox — a reset link is on its way.';

  @override
  String get authTryDemo => 'Explore the demo workspace';

  @override
  String get authDemoHint =>
      'Use demo@kairo.app / demo1234 to sign in instantly.';

  @override
  String get authRememberMe => 'Keep me signed in';

  @override
  String get authTermsNotice =>
      'By continuing you agree to our Terms and Privacy Policy.';

  @override
  String get authResendCode => 'Resend code';

  @override
  String get authVerifyCta => 'Verify email';

  @override
  String get validationRequired => 'This field is required.';

  @override
  String get validationEmail => 'Enter a valid email address.';

  @override
  String get validationPasswordShort => 'Use at least 8 characters.';

  @override
  String get validationPasswordWeak =>
      'Mix letters and numbers for a stronger password.';

  @override
  String get validationPasswordMismatch => 'Passwords don\'t match.';

  @override
  String validationTooLong(int max) {
    return 'Keep it under $max characters.';
  }

  @override
  String get validationNameShort => 'Enter at least 2 characters.';

  @override
  String get validationCodeLength => 'Enter the six-digit code.';

  @override
  String get validationDateOrder =>
      'The due date can\'t be before the start date.';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Kairo';

  @override
  String get onboardingWelcomeBody =>
      'A calm, fast home for everything you\'re working on. Six quick steps and your workspace is ready.';

  @override
  String get onboardingGoalsTitle => 'What are you here to manage?';

  @override
  String get onboardingGoalsBody =>
      'We\'ll tune your default views around this. You can change it any time.';

  @override
  String get onboardingWorkspaceTitle => 'Name your workspace';

  @override
  String get onboardingWorkspaceBody =>
      'This is the shared home for your projects, people and labels.';

  @override
  String get onboardingProjectTitle => 'Create your first project';

  @override
  String get onboardingProjectBody =>
      'Projects group related work and give you progress at a glance.';

  @override
  String get onboardingTaskTitle => 'Add your first task';

  @override
  String get onboardingTaskBody =>
      'Start with something small you can finish today.';

  @override
  String get onboardingPreferencesTitle => 'Set your rhythm';

  @override
  String get onboardingPreferencesBody =>
      'Defaults for theme, focus sessions and where Kairo opens.';

  @override
  String onboardingStepLabel(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingFinish => 'Enter workspace';

  @override
  String dashboardGreetingMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String dashboardGreetingAfternoon(String name) {
    return 'Good afternoon, $name';
  }

  @override
  String dashboardGreetingEvening(String name) {
    return 'Good evening, $name';
  }

  @override
  String get dashboardProductivityScore => 'Productivity score';

  @override
  String get dashboardCompleted => 'Completed';

  @override
  String get dashboardRemaining => 'Remaining';

  @override
  String get dashboardOverdue => 'Overdue';

  @override
  String get dashboardDueToday => 'Due today';

  @override
  String get dashboardThisWeek => 'Completed this week';

  @override
  String get dashboardTrend => 'Completion trend';

  @override
  String get dashboardWorkload => 'Workload by day';

  @override
  String get dashboardUpcoming => 'Upcoming deadlines';

  @override
  String get dashboardRecentlyUpdated => 'Recently updated';

  @override
  String get dashboardActiveProjects => 'Active projects';

  @override
  String get dashboardTodaysFocus => 'Today\'s focus';

  @override
  String get dashboardInsights => 'Insights';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get tasksGroupBy => 'Group by';

  @override
  String get tasksSortBy => 'Sort by';

  @override
  String get tasksFilter => 'Filter';

  @override
  String get tasksViewList => 'List';

  @override
  String get tasksViewBoard => 'Board';

  @override
  String get tasksViewCalendar => 'Calendar';

  @override
  String get tasksViewTimeline => 'Timeline';

  @override
  String tasksSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String tasksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
      zero: 'No tasks',
    );
    return '$_temp0';
  }

  @override
  String tasksSubtaskProgress(int done, int total) {
    return '$done / $total completed';
  }

  @override
  String get tasksAddSubtask => 'Add a subtask';

  @override
  String get tasksAddComment => 'Write a comment…';

  @override
  String get tasksBlockedBy => 'Blocked by';

  @override
  String get tasksBlocks => 'Blocks';

  @override
  String get tasksNewInColumn => 'Add task';

  @override
  String get tasksQuickAddHint => 'What needs doing?';

  @override
  String get tasksMarkComplete => 'Mark complete';

  @override
  String get tasksMarkIncomplete => 'Mark incomplete';

  @override
  String get tasksDeleteConfirmTitle => 'Delete this task?';

  @override
  String get tasksDeleteConfirmBody =>
      'This can\'t be undone. Consider archiving instead if you might need it later.';

  @override
  String get tasksGroupNone => 'None';

  @override
  String get tasksGroupStatus => 'Status';

  @override
  String get tasksGroupPriority => 'Priority';

  @override
  String get tasksGroupProject => 'Project';

  @override
  String get tasksGroupAssignee => 'Assignee';

  @override
  String get tasksGroupDueDate => 'Due date';

  @override
  String get tasksSortManual => 'Manual';

  @override
  String get tasksSortDueDate => 'Due date';

  @override
  String get tasksSortPriority => 'Priority';

  @override
  String get tasksSortCreated => 'Created';

  @override
  String get tasksSortUpdated => 'Updated';

  @override
  String get tasksSortTitle => 'Title';

  @override
  String get projectsTitle => 'Projects';

  @override
  String get projectsOverview => 'Overview';

  @override
  String get projectsProgress => 'Progress';

  @override
  String get projectsMembers => 'Members';

  @override
  String get projectsStatusPlanning => 'Planning';

  @override
  String get projectsStatusActive => 'Active';

  @override
  String get projectsStatusOnHold => 'On hold';

  @override
  String get projectsStatusCompleted => 'Completed';

  @override
  String get projectsStatusArchived => 'Archived';

  @override
  String projectsTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
      zero: 'No tasks',
    );
    return '$_temp0';
  }

  @override
  String get projectsAddMember => 'Add member';

  @override
  String get projectsFavorite => 'Add to favorites';

  @override
  String get projectsUnfavorite => 'Remove from favorites';

  @override
  String get calendarToday => 'Today';

  @override
  String get calendarMonth => 'Month';

  @override
  String get calendarWeek => 'Week';

  @override
  String get calendarDay => 'Day';

  @override
  String get calendarNoTasksOnDay => 'Nothing scheduled';

  @override
  String get calendarDropHint => 'Drop to reschedule';

  @override
  String get timelineTitle => 'Timeline';

  @override
  String get timelineMilestones => 'Milestones';

  @override
  String get timelineZoomDays => 'Days';

  @override
  String get timelineZoomWeeks => 'Weeks';

  @override
  String get timelineZoomMonths => 'Months';

  @override
  String get focusTitle => 'Focus';

  @override
  String get focusStart => 'Start focus';

  @override
  String get focusPause => 'Pause';

  @override
  String get focusResume => 'Resume';

  @override
  String get focusStop => 'End session';

  @override
  String get focusSkip => 'Skip';

  @override
  String get focusModeFocus => 'Focus';

  @override
  String get focusModeShortBreak => 'Short break';

  @override
  String get focusModeLongBreak => 'Long break';

  @override
  String get focusSelectTask => 'Choose something to focus on';

  @override
  String get focusSessionsToday => 'Sessions today';

  @override
  String get focusMinutesToday => 'Minutes today';

  @override
  String get focusHistory => 'Session history';

  @override
  String focusRoundLabel(int current, int total) {
    return 'Round $current of $total';
  }

  @override
  String get focusCompleteHint => 'Session complete. Take a breath.';

  @override
  String get analyticsTitle => 'Analytics';

  @override
  String get analyticsCompletionRate => 'Completion rate';

  @override
  String get analyticsOverdueRate => 'Overdue rate';

  @override
  String get analyticsAvgCompletion => 'Average time to complete';

  @override
  String get analyticsTasksByPriority => 'Tasks by priority';

  @override
  String get analyticsTasksByProject => 'Tasks by project';

  @override
  String get analyticsWeeklyProductivity => 'Weekly productivity';

  @override
  String get analyticsFocusTime => 'Focus time';

  @override
  String get analyticsWorkload => 'Workload';

  @override
  String get analyticsRangeWeek => '7 days';

  @override
  String get analyticsRangeMonth => '30 days';

  @override
  String get analyticsRangeQuarter => '90 days';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsMarkRead => 'Mark as read';

  @override
  String get notificationsUnread => 'Unread';

  @override
  String get notificationsAll => 'All';

  @override
  String get notificationsToday => 'Today';

  @override
  String get notificationsEarlier => 'Earlier';

  @override
  String notificationsUnreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread',
      one: '1 unread',
    );
    return '$_temp0';
  }

  @override
  String get searchTitle => 'Search';

  @override
  String get searchPlaceholder => 'Search tasks, projects, people…';

  @override
  String get searchRecent => 'Recent searches';

  @override
  String searchNoResults(String query) {
    return 'No matches for \"$query\"';
  }

  @override
  String get searchResultsTasks => 'Tasks';

  @override
  String get searchResultsProjects => 'Projects';

  @override
  String get searchResultsPeople => 'People';

  @override
  String get searchResultsLabels => 'Labels';

  @override
  String get searchResultsComments => 'Comments';

  @override
  String get paletteTitle => 'Command palette';

  @override
  String get palettePlaceholder => 'Type a command or search…';

  @override
  String get paletteSectionActions => 'Actions';

  @override
  String get paletteSectionNavigate => 'Go to';

  @override
  String get paletteSectionWorkspace => 'Workspace';

  @override
  String get paletteSectionTasks => 'Tasks';

  @override
  String get paletteSectionProjects => 'Projects';

  @override
  String get paletteToggleTheme => 'Toggle theme';

  @override
  String get paletteToggleSidebar => 'Toggle sidebar';

  @override
  String get paletteOpenShortcuts => 'Keyboard shortcuts';

  @override
  String get shortcutsTitle => 'Keyboard shortcuts';

  @override
  String get shortcutsGeneral => 'General';

  @override
  String get shortcutsNavigation => 'Navigation';

  @override
  String get shortcutsTasks => 'Tasks';

  @override
  String get shortcutCommandPalette => 'Open command palette';

  @override
  String get shortcutSearch => 'Search';

  @override
  String get shortcutCreateTask => 'Create task';

  @override
  String get shortcutEditTask => 'Edit selected task';

  @override
  String get shortcutCompleteTask => 'Complete selected task';

  @override
  String get shortcutCloseOverlay => 'Close overlay';

  @override
  String get shortcutGoDashboard => 'Go to dashboard';

  @override
  String get shortcutGoProjects => 'Go to projects';

  @override
  String get shortcutGoTasks => 'Go to tasks';

  @override
  String get shortcutGoCalendar => 'Go to calendar';

  @override
  String get shortcutGoFocus => 'Go to focus';

  @override
  String get shortcutToggleTheme => 'Toggle theme';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsWorkspace => 'Workspace';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsShortcuts => 'Keyboard shortcuts';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsSecurity => 'Security';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsDangerZone => 'Danger zone';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsAccentDensity => 'Interface density';

  @override
  String get settingsDensityComfortable => 'Comfortable';

  @override
  String get settingsDensityCompact => 'Compact';

  @override
  String get settingsReduceMotion => 'Reduce motion';

  @override
  String get settingsReduceMotionHint =>
      'Minimise animation. Also follows your system setting.';

  @override
  String get settingsStartOfWeek => 'Start of week';

  @override
  String get settingsDefaultView => 'Default task view';

  @override
  String get settingsLandingRoute => 'Open Kairo on';

  @override
  String get settingsPomodoroLength => 'Focus length';

  @override
  String get settingsShortBreakLength => 'Short break';

  @override
  String get settingsLongBreakLength => 'Long break';

  @override
  String get settingsRoundsBeforeLongBreak => 'Rounds before long break';

  @override
  String get settingsExportData => 'Export workspace data';

  @override
  String get settingsExportHint =>
      'Download everything in this workspace as JSON.';

  @override
  String get settingsResetDemo => 'Reset demo data';

  @override
  String get settingsResetDemoHint =>
      'Restore the Launchpad workspace to its original state.';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteAccountHint =>
      'Permanently remove your account and all workspace data.';

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsActiveSessions => 'Active sessions';

  @override
  String get settingsTwoFactor => 'Two-factor authentication';

  @override
  String get settingsNotifyMentions => 'Mentions';

  @override
  String get settingsNotifyAssignments => 'Assignments';

  @override
  String get settingsNotifyComments => 'Comments';

  @override
  String get settingsNotifyDeadlines => 'Deadline reminders';

  @override
  String get settingsNotifyProjects => 'Project updates';

  @override
  String get settingsNotifyDigest => 'Weekly digest';

  @override
  String get workspaceSwitch => 'Switch workspace';

  @override
  String get workspaceCreate => 'Create workspace';

  @override
  String get workspaceRename => 'Rename workspace';

  @override
  String get workspaceMembers => 'Members';

  @override
  String get workspaceLabels => 'Labels';

  @override
  String get workspaceInviteHint => 'Invite by email address';

  @override
  String get workspaceRoleOwner => 'Owner';

  @override
  String get workspaceRoleAdmin => 'Admin';

  @override
  String get workspaceRoleMember => 'Member';

  @override
  String get workspaceRoleGuest => 'Guest';

  @override
  String get emptyTasksTitle => 'No loose ends';

  @override
  String get emptyTasksBody =>
      'Nothing is waiting on you here. Enjoy the clarity — or line up what\'s next.';

  @override
  String get emptyProjectsTitle => 'Ready for its first project';

  @override
  String get emptyProjectsBody =>
      'Projects group related work and give you progress at a glance.';

  @override
  String get emptyNotificationsTitle => 'You\'re all caught up';

  @override
  String get emptyNotificationsBody =>
      'Mentions, assignments and deadline reminders will land here.';

  @override
  String get emptySearchTitle => 'Search everything';

  @override
  String get emptySearchBody =>
      'Find tasks, projects, people, labels and comments across the workspace.';

  @override
  String get emptyArchiveTitle => 'Nothing archived yet';

  @override
  String get emptyArchiveBody =>
      'Archived work stays searchable and can be restored at any time.';

  @override
  String get emptyFavoritesTitle => 'No favorites yet';

  @override
  String get emptyFavoritesBody =>
      'Star the projects and tasks you return to most and they\'ll live here.';

  @override
  String get emptyCommentsTitle => 'No comments yet';

  @override
  String get emptyCommentsBody =>
      'Start the conversation — context beats a status meeting.';

  @override
  String get emptyFocusTitle => 'Pick something to focus on';

  @override
  String get emptyFocusBody =>
      'Choose a single task, start the timer, and let everything else wait.';

  @override
  String get emptyCalendarTitle => 'Nothing scheduled';

  @override
  String get emptyCalendarBody =>
      'Tasks with a due date appear here. Drag one to reschedule it.';

  @override
  String get emptyTimelineTitle => 'No dated work yet';

  @override
  String get emptyTimelineBody =>
      'Give tasks a start and due date to see them laid out over time.';

  @override
  String get errorGenericTitle => 'Something went wrong';

  @override
  String get errorGenericBody =>
      'An unexpected error stopped that from finishing.';

  @override
  String get errorNetworkTitle => 'You\'re offline';

  @override
  String get errorNetworkBody =>
      'Kairo is showing cached data. Changes will sync when you reconnect.';

  @override
  String get errorUnauthorizedTitle => 'Session expired';

  @override
  String get errorUnauthorizedBody =>
      'Sign in again to continue where you left off.';

  @override
  String get errorNotFoundTitle => 'We couldn\'t find that';

  @override
  String get errorNotFoundBody =>
      'It may have been deleted, archived, or moved to another workspace.';

  @override
  String get errorValidationTitle => 'Check the form';

  @override
  String get errorRouteTitle => 'Page not found';

  @override
  String get errorRouteBody =>
      'The link you followed doesn\'t lead anywhere in Kairo.';

  @override
  String get errorGoHome => 'Back to dashboard';

  @override
  String get toastTaskCreated => 'Task created';

  @override
  String get toastTaskUpdated => 'Task updated';

  @override
  String get toastTaskCompleted => 'Nice — task completed';

  @override
  String get toastTaskReopened => 'Task reopened';

  @override
  String get toastTaskDeleted => 'Task deleted';

  @override
  String get toastTaskArchived => 'Task archived';

  @override
  String get toastTaskRestored => 'Task restored';

  @override
  String get toastTaskDuplicated => 'Task duplicated';

  @override
  String get toastProjectCreated => 'Project created';

  @override
  String get toastProjectUpdated => 'Project updated';

  @override
  String get toastProjectArchived => 'Project archived';

  @override
  String get toastWorkspaceCreated => 'Workspace created';

  @override
  String get toastCopied => 'Copied to clipboard';

  @override
  String get toastSettingsSaved => 'Settings saved';

  @override
  String get toastDemoReset => 'Demo workspace restored';

  @override
  String get toastUndo => 'Undo';

  @override
  String get toastOffline => 'You\'re offline — changes are saved locally';

  @override
  String get toastBackOnline => 'Back online';

  @override
  String get timeToday => 'Today';

  @override
  String get timeTomorrow => 'Tomorrow';

  @override
  String get timeYesterday => 'Yesterday';

  @override
  String get timeNoDate => 'No date';

  @override
  String timeOverdueBy(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String timeDueIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Due in $days days',
      one: 'Due in 1 day',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String timeHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String timeDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String timeEstimateHours(String hours) {
    return '${hours}h';
  }

  @override
  String get recurrenceNone => 'Doesn\'t repeat';

  @override
  String get recurrenceDaily => 'Every day';

  @override
  String get recurrenceWeekly => 'Every week';

  @override
  String get recurrenceMonthly => 'Every month';

  @override
  String get recurrenceCustom => 'Custom';

  @override
  String recurrenceEveryN(int n, String unit) {
    return 'Every $n $unit';
  }

  @override
  String get editorBold => 'Bold';

  @override
  String get editorItalic => 'Italic';

  @override
  String get editorHeading => 'Heading';

  @override
  String get editorBulletList => 'Bulleted list';

  @override
  String get editorNumberedList => 'Numbered list';

  @override
  String get editorQuote => 'Quote';

  @override
  String get editorCode => 'Code block';

  @override
  String get editorLink => 'Link';

  @override
  String get editorPreview => 'Preview';

  @override
  String get editorWrite => 'Write';

  @override
  String get editorPlaceholder => 'Add context, links, acceptance criteria…';

  @override
  String get commonLoading => 'Loading';

  @override
  String get commonOffline => 'Offline';

  @override
  String get commonOnline => 'Online';

  @override
  String get commonYou => 'You';

  @override
  String get commonMore => 'More';

  @override
  String get commonOptions => 'Options';

  @override
  String get commonNone => 'None';

  @override
  String get commonAll => 'All';
}
