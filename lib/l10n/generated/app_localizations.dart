import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Kairo'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'The command center for focused work.'**
  String get appTagline;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navMyTasks.
  ///
  /// In en, this message translates to:
  /// **'My Tasks'**
  String get navMyTasks;

  /// No description provided for @navInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get navInbox;

  /// No description provided for @navProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get navProjects;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get navTimeline;

  /// No description provided for @navFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get navFocus;

  /// No description provided for @navAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get navAnalytics;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @navArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get navArchive;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @actionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get actionCreate;

  /// No description provided for @actionCreateTask.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get actionCreateTask;

  /// No description provided for @actionCreateProject.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get actionCreateProject;

  /// No description provided for @actionCreateLabel.
  ///
  /// In en, this message translates to:
  /// **'New label'**
  String get actionCreateLabel;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get actionSaveChanges;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get actionDuplicate;

  /// No description provided for @actionArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get actionArchive;

  /// No description provided for @actionRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get actionRestore;

  /// No description provided for @actionComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get actionComplete;

  /// No description provided for @actionReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get actionReopen;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionRetry;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get actionApply;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @actionClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get actionClearAll;

  /// No description provided for @actionSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get actionSelectAll;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// No description provided for @actionInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get actionInvite;

  /// No description provided for @actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// No description provided for @actionCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get actionCopyLink;

  /// No description provided for @actionViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get actionViewAll;

  /// No description provided for @actionLearnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get actionLearnMore;

  /// No description provided for @statusBacklog.
  ///
  /// In en, this message translates to:
  /// **'Backlog'**
  String get statusBacklog;

  /// No description provided for @statusTodo.
  ///
  /// In en, this message translates to:
  /// **'To Do'**
  String get statusTodo;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get statusReview;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @priorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @fieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get fieldTitle;

  /// No description provided for @fieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get fieldDescription;

  /// No description provided for @fieldStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get fieldStatus;

  /// No description provided for @fieldPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get fieldPriority;

  /// No description provided for @fieldAssignee.
  ///
  /// In en, this message translates to:
  /// **'Assignee'**
  String get fieldAssignee;

  /// No description provided for @fieldProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get fieldProject;

  /// No description provided for @fieldLabels.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get fieldLabels;

  /// No description provided for @fieldDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get fieldDueDate;

  /// No description provided for @fieldStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get fieldStartDate;

  /// No description provided for @fieldEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimate'**
  String get fieldEstimate;

  /// No description provided for @fieldRecurrence.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get fieldRecurrence;

  /// No description provided for @fieldDependencies.
  ///
  /// In en, this message translates to:
  /// **'Dependencies'**
  String get fieldDependencies;

  /// No description provided for @fieldSubtasks.
  ///
  /// In en, this message translates to:
  /// **'Subtasks'**
  String get fieldSubtasks;

  /// No description provided for @fieldComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get fieldComments;

  /// No description provided for @fieldActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get fieldActivity;

  /// No description provided for @fieldAttachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get fieldAttachments;

  /// No description provided for @fieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @fieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fieldFullName;

  /// No description provided for @fieldRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get fieldRole;

  /// No description provided for @fieldTimezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get fieldTimezone;

  /// No description provided for @fieldLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get fieldLanguage;

  /// No description provided for @fieldUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get fieldUnassigned;

  /// No description provided for @fieldNoProject.
  ///
  /// In en, this message translates to:
  /// **'No project'**
  String get fieldNoProject;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSignUp;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to pick up where you left off.'**
  String get authLoginSubtitle;

  /// No description provided for @authSignupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your workspace'**
  String get authSignupTitle;

  /// No description provided for @authSignupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start free. No credit card required.'**
  String get authSignupSubtitle;

  /// No description provided for @authForgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get authForgotTitle;

  /// No description provided for @authForgotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you a secure link to choose a new password.'**
  String get authForgotSubtitle;

  /// No description provided for @authResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get authResetTitle;

  /// No description provided for @authResetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick something you haven\'t used before.'**
  String get authResetSubtitle;

  /// No description provided for @authVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get authVerifyTitle;

  /// No description provided for @authVerifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a six-digit code to {email}.'**
  String authVerifySubtitle(String email);

  /// No description provided for @authForgotLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotLink;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'New to Kairo?'**
  String get authNoAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccount;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authContinueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueWithApple;

  /// No description provided for @authOrDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOrDivider;

  /// No description provided for @authSendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get authSendResetLink;

  /// No description provided for @authResetSent.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox — a reset link is on its way.'**
  String get authResetSent;

  /// No description provided for @authTryDemo.
  ///
  /// In en, this message translates to:
  /// **'Explore the demo workspace'**
  String get authTryDemo;

  /// No description provided for @authDemoHint.
  ///
  /// In en, this message translates to:
  /// **'Use demo@kairo.app / demo1234 to sign in instantly.'**
  String get authDemoHint;

  /// No description provided for @authRememberMe.
  ///
  /// In en, this message translates to:
  /// **'Keep me signed in'**
  String get authRememberMe;

  /// No description provided for @authTermsNotice.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our Terms and Privacy Policy.'**
  String get authTermsNotice;

  /// No description provided for @authResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authResendCode;

  /// No description provided for @authVerifyCta.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get authVerifyCta;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get validationRequired;

  /// No description provided for @validationEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get validationEmail;

  /// No description provided for @validationPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get validationPasswordShort;

  /// No description provided for @validationPasswordWeak.
  ///
  /// In en, this message translates to:
  /// **'Mix letters and numbers for a stronger password.'**
  String get validationPasswordWeak;

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match.'**
  String get validationPasswordMismatch;

  /// No description provided for @validationTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep it under {max} characters.'**
  String validationTooLong(int max);

  /// No description provided for @validationNameShort.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 2 characters.'**
  String get validationNameShort;

  /// No description provided for @validationCodeLength.
  ///
  /// In en, this message translates to:
  /// **'Enter the six-digit code.'**
  String get validationCodeLength;

  /// No description provided for @validationDateOrder.
  ///
  /// In en, this message translates to:
  /// **'The due date can\'t be before the start date.'**
  String get validationDateOrder;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Kairo'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'A calm, fast home for everything you\'re working on. Six quick steps and your workspace is ready.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'What are you here to manage?'**
  String get onboardingGoalsTitle;

  /// No description provided for @onboardingGoalsBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll tune your default views around this. You can change it any time.'**
  String get onboardingGoalsBody;

  /// No description provided for @onboardingWorkspaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Name your workspace'**
  String get onboardingWorkspaceTitle;

  /// No description provided for @onboardingWorkspaceBody.
  ///
  /// In en, this message translates to:
  /// **'This is the shared home for your projects, people and labels.'**
  String get onboardingWorkspaceBody;

  /// No description provided for @onboardingProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first project'**
  String get onboardingProjectTitle;

  /// No description provided for @onboardingProjectBody.
  ///
  /// In en, this message translates to:
  /// **'Projects group related work and give you progress at a glance.'**
  String get onboardingProjectBody;

  /// No description provided for @onboardingTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first task'**
  String get onboardingTaskTitle;

  /// No description provided for @onboardingTaskBody.
  ///
  /// In en, this message translates to:
  /// **'Start with something small you can finish today.'**
  String get onboardingTaskBody;

  /// No description provided for @onboardingPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Set your rhythm'**
  String get onboardingPreferencesTitle;

  /// No description provided for @onboardingPreferencesBody.
  ///
  /// In en, this message translates to:
  /// **'Defaults for theme, focus sessions and where Kairo opens.'**
  String get onboardingPreferencesBody;

  /// No description provided for @onboardingStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingStepLabel(int current, int total);

  /// No description provided for @onboardingFinish.
  ///
  /// In en, this message translates to:
  /// **'Enter workspace'**
  String get onboardingFinish;

  /// No description provided for @dashboardGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String dashboardGreetingMorning(String name);

  /// No description provided for @dashboardGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}'**
  String dashboardGreetingAfternoon(String name);

  /// No description provided for @dashboardGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}'**
  String dashboardGreetingEvening(String name);

  /// No description provided for @dashboardProductivityScore.
  ///
  /// In en, this message translates to:
  /// **'Productivity score'**
  String get dashboardProductivityScore;

  /// No description provided for @dashboardCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get dashboardCompleted;

  /// No description provided for @dashboardRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get dashboardRemaining;

  /// No description provided for @dashboardOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get dashboardOverdue;

  /// No description provided for @dashboardDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dashboardDueToday;

  /// No description provided for @dashboardThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Completed this week'**
  String get dashboardThisWeek;

  /// No description provided for @dashboardTrend.
  ///
  /// In en, this message translates to:
  /// **'Completion trend'**
  String get dashboardTrend;

  /// No description provided for @dashboardWorkload.
  ///
  /// In en, this message translates to:
  /// **'Workload by day'**
  String get dashboardWorkload;

  /// No description provided for @dashboardUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming deadlines'**
  String get dashboardUpcoming;

  /// No description provided for @dashboardRecentlyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get dashboardRecentlyUpdated;

  /// No description provided for @dashboardActiveProjects.
  ///
  /// In en, this message translates to:
  /// **'Active projects'**
  String get dashboardActiveProjects;

  /// No description provided for @dashboardTodaysFocus.
  ///
  /// In en, this message translates to:
  /// **'Today\'s focus'**
  String get dashboardTodaysFocus;

  /// No description provided for @dashboardInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get dashboardInsights;

  /// No description provided for @tasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTitle;

  /// No description provided for @tasksGroupBy.
  ///
  /// In en, this message translates to:
  /// **'Group by'**
  String get tasksGroupBy;

  /// No description provided for @tasksSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get tasksSortBy;

  /// No description provided for @tasksFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get tasksFilter;

  /// No description provided for @tasksViewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get tasksViewList;

  /// No description provided for @tasksViewBoard.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get tasksViewBoard;

  /// No description provided for @tasksViewCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get tasksViewCalendar;

  /// No description provided for @tasksViewTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get tasksViewTimeline;

  /// No description provided for @tasksSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String tasksSelectedCount(int count);

  /// No description provided for @tasksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No tasks} =1{1 task} other{{count} tasks}}'**
  String tasksCount(int count);

  /// No description provided for @tasksSubtaskProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} completed'**
  String tasksSubtaskProgress(int done, int total);

  /// No description provided for @tasksAddSubtask.
  ///
  /// In en, this message translates to:
  /// **'Add a subtask'**
  String get tasksAddSubtask;

  /// No description provided for @tasksAddComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment…'**
  String get tasksAddComment;

  /// No description provided for @tasksBlockedBy.
  ///
  /// In en, this message translates to:
  /// **'Blocked by'**
  String get tasksBlockedBy;

  /// No description provided for @tasksBlocks.
  ///
  /// In en, this message translates to:
  /// **'Blocks'**
  String get tasksBlocks;

  /// No description provided for @tasksNewInColumn.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get tasksNewInColumn;

  /// No description provided for @tasksQuickAddHint.
  ///
  /// In en, this message translates to:
  /// **'What needs doing?'**
  String get tasksQuickAddHint;

  /// No description provided for @tasksMarkComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get tasksMarkComplete;

  /// No description provided for @tasksMarkIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Mark incomplete'**
  String get tasksMarkIncomplete;

  /// No description provided for @tasksDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this task?'**
  String get tasksDeleteConfirmTitle;

  /// No description provided for @tasksDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone. Consider archiving instead if you might need it later.'**
  String get tasksDeleteConfirmBody;

  /// No description provided for @tasksGroupNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get tasksGroupNone;

  /// No description provided for @tasksGroupStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get tasksGroupStatus;

  /// No description provided for @tasksGroupPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get tasksGroupPriority;

  /// No description provided for @tasksGroupProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get tasksGroupProject;

  /// No description provided for @tasksGroupAssignee.
  ///
  /// In en, this message translates to:
  /// **'Assignee'**
  String get tasksGroupAssignee;

  /// No description provided for @tasksGroupDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get tasksGroupDueDate;

  /// No description provided for @tasksSortManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get tasksSortManual;

  /// No description provided for @tasksSortDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get tasksSortDueDate;

  /// No description provided for @tasksSortPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get tasksSortPriority;

  /// No description provided for @tasksSortCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get tasksSortCreated;

  /// No description provided for @tasksSortUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get tasksSortUpdated;

  /// No description provided for @tasksSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get tasksSortTitle;

  /// No description provided for @projectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projectsTitle;

  /// No description provided for @projectsOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get projectsOverview;

  /// No description provided for @projectsProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get projectsProgress;

  /// No description provided for @projectsMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get projectsMembers;

  /// No description provided for @projectsStatusPlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get projectsStatusPlanning;

  /// No description provided for @projectsStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get projectsStatusActive;

  /// No description provided for @projectsStatusOnHold.
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get projectsStatusOnHold;

  /// No description provided for @projectsStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get projectsStatusCompleted;

  /// No description provided for @projectsStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get projectsStatusArchived;

  /// No description provided for @projectsTaskCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No tasks} =1{1 task} other{{count} tasks}}'**
  String projectsTaskCount(int count);

  /// No description provided for @projectsAddMember.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get projectsAddMember;

  /// No description provided for @projectsFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get projectsFavorite;

  /// No description provided for @projectsUnfavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get projectsUnfavorite;

  /// No description provided for @calendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// No description provided for @calendarMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get calendarMonth;

  /// No description provided for @calendarWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get calendarWeek;

  /// No description provided for @calendarDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get calendarDay;

  /// No description provided for @calendarNoTasksOnDay.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled'**
  String get calendarNoTasksOnDay;

  /// No description provided for @calendarDropHint.
  ///
  /// In en, this message translates to:
  /// **'Drop to reschedule'**
  String get calendarDropHint;

  /// No description provided for @timelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timelineTitle;

  /// No description provided for @timelineMilestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get timelineMilestones;

  /// No description provided for @timelineZoomDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get timelineZoomDays;

  /// No description provided for @timelineZoomWeeks.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get timelineZoomWeeks;

  /// No description provided for @timelineZoomMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get timelineZoomMonths;

  /// No description provided for @focusTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focusTitle;

  /// No description provided for @focusStart.
  ///
  /// In en, this message translates to:
  /// **'Start focus'**
  String get focusStart;

  /// No description provided for @focusPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get focusPause;

  /// No description provided for @focusResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get focusResume;

  /// No description provided for @focusStop.
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get focusStop;

  /// No description provided for @focusSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get focusSkip;

  /// No description provided for @focusModeFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focusModeFocus;

  /// No description provided for @focusModeShortBreak.
  ///
  /// In en, this message translates to:
  /// **'Short break'**
  String get focusModeShortBreak;

  /// No description provided for @focusModeLongBreak.
  ///
  /// In en, this message translates to:
  /// **'Long break'**
  String get focusModeLongBreak;

  /// No description provided for @focusSelectTask.
  ///
  /// In en, this message translates to:
  /// **'Choose something to focus on'**
  String get focusSelectTask;

  /// No description provided for @focusSessionsToday.
  ///
  /// In en, this message translates to:
  /// **'Sessions today'**
  String get focusSessionsToday;

  /// No description provided for @focusMinutesToday.
  ///
  /// In en, this message translates to:
  /// **'Minutes today'**
  String get focusMinutesToday;

  /// No description provided for @focusHistory.
  ///
  /// In en, this message translates to:
  /// **'Session history'**
  String get focusHistory;

  /// No description provided for @focusRoundLabel.
  ///
  /// In en, this message translates to:
  /// **'Round {current} of {total}'**
  String focusRoundLabel(int current, int total);

  /// No description provided for @focusCompleteHint.
  ///
  /// In en, this message translates to:
  /// **'Session complete. Take a breath.'**
  String get focusCompleteHint;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @analyticsCompletionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion rate'**
  String get analyticsCompletionRate;

  /// No description provided for @analyticsOverdueRate.
  ///
  /// In en, this message translates to:
  /// **'Overdue rate'**
  String get analyticsOverdueRate;

  /// No description provided for @analyticsAvgCompletion.
  ///
  /// In en, this message translates to:
  /// **'Average time to complete'**
  String get analyticsAvgCompletion;

  /// No description provided for @analyticsTasksByPriority.
  ///
  /// In en, this message translates to:
  /// **'Tasks by priority'**
  String get analyticsTasksByPriority;

  /// No description provided for @analyticsTasksByProject.
  ///
  /// In en, this message translates to:
  /// **'Tasks by project'**
  String get analyticsTasksByProject;

  /// No description provided for @analyticsWeeklyProductivity.
  ///
  /// In en, this message translates to:
  /// **'Weekly productivity'**
  String get analyticsWeeklyProductivity;

  /// No description provided for @analyticsFocusTime.
  ///
  /// In en, this message translates to:
  /// **'Focus time'**
  String get analyticsFocusTime;

  /// No description provided for @analyticsWorkload.
  ///
  /// In en, this message translates to:
  /// **'Workload'**
  String get analyticsWorkload;

  /// No description provided for @analyticsRangeWeek.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get analyticsRangeWeek;

  /// No description provided for @analyticsRangeMonth.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get analyticsRangeMonth;

  /// No description provided for @analyticsRangeQuarter.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get analyticsRangeQuarter;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get notificationsMarkRead;

  /// No description provided for @notificationsUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationsUnread;

  /// No description provided for @notificationsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notificationsAll;

  /// No description provided for @notificationsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get notificationsToday;

  /// No description provided for @notificationsEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get notificationsEarlier;

  /// No description provided for @notificationsUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unread} other{{count} unread}}'**
  String notificationsUnreadCount(int count);

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search tasks, projects, people…'**
  String get searchPlaceholder;

  /// No description provided for @searchRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get searchRecent;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matches for \"{query}\"'**
  String searchNoResults(String query);

  /// No description provided for @searchResultsTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get searchResultsTasks;

  /// No description provided for @searchResultsProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get searchResultsProjects;

  /// No description provided for @searchResultsPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get searchResultsPeople;

  /// No description provided for @searchResultsLabels.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get searchResultsLabels;

  /// No description provided for @searchResultsComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get searchResultsComments;

  /// No description provided for @paletteTitle.
  ///
  /// In en, this message translates to:
  /// **'Command palette'**
  String get paletteTitle;

  /// No description provided for @palettePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type a command or search…'**
  String get palettePlaceholder;

  /// No description provided for @paletteSectionActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get paletteSectionActions;

  /// No description provided for @paletteSectionNavigate.
  ///
  /// In en, this message translates to:
  /// **'Go to'**
  String get paletteSectionNavigate;

  /// No description provided for @paletteSectionWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get paletteSectionWorkspace;

  /// No description provided for @paletteSectionTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get paletteSectionTasks;

  /// No description provided for @paletteSectionProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get paletteSectionProjects;

  /// No description provided for @paletteToggleTheme.
  ///
  /// In en, this message translates to:
  /// **'Toggle theme'**
  String get paletteToggleTheme;

  /// No description provided for @paletteToggleSidebar.
  ///
  /// In en, this message translates to:
  /// **'Toggle sidebar'**
  String get paletteToggleSidebar;

  /// No description provided for @paletteOpenShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get paletteOpenShortcuts;

  /// No description provided for @shortcutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get shortcutsTitle;

  /// No description provided for @shortcutsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get shortcutsGeneral;

  /// No description provided for @shortcutsNavigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get shortcutsNavigation;

  /// No description provided for @shortcutsTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get shortcutsTasks;

  /// No description provided for @shortcutCommandPalette.
  ///
  /// In en, this message translates to:
  /// **'Open command palette'**
  String get shortcutCommandPalette;

  /// No description provided for @shortcutSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get shortcutSearch;

  /// No description provided for @shortcutCreateTask.
  ///
  /// In en, this message translates to:
  /// **'Create task'**
  String get shortcutCreateTask;

  /// No description provided for @shortcutEditTask.
  ///
  /// In en, this message translates to:
  /// **'Edit selected task'**
  String get shortcutEditTask;

  /// No description provided for @shortcutCompleteTask.
  ///
  /// In en, this message translates to:
  /// **'Complete selected task'**
  String get shortcutCompleteTask;

  /// No description provided for @shortcutCloseOverlay.
  ///
  /// In en, this message translates to:
  /// **'Close overlay'**
  String get shortcutCloseOverlay;

  /// No description provided for @shortcutGoDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to dashboard'**
  String get shortcutGoDashboard;

  /// No description provided for @shortcutGoProjects.
  ///
  /// In en, this message translates to:
  /// **'Go to projects'**
  String get shortcutGoProjects;

  /// No description provided for @shortcutGoTasks.
  ///
  /// In en, this message translates to:
  /// **'Go to tasks'**
  String get shortcutGoTasks;

  /// No description provided for @shortcutGoCalendar.
  ///
  /// In en, this message translates to:
  /// **'Go to calendar'**
  String get shortcutGoCalendar;

  /// No description provided for @shortcutGoFocus.
  ///
  /// In en, this message translates to:
  /// **'Go to focus'**
  String get shortcutGoFocus;

  /// No description provided for @shortcutToggleTheme.
  ///
  /// In en, this message translates to:
  /// **'Toggle theme'**
  String get shortcutToggleTheme;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get settingsWorkspace;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get settingsShortcuts;

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecurity;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// No description provided for @settingsDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get settingsDangerZone;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsAccentDensity.
  ///
  /// In en, this message translates to:
  /// **'Interface density'**
  String get settingsAccentDensity;

  /// No description provided for @settingsDensityComfortable.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get settingsDensityComfortable;

  /// No description provided for @settingsDensityCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get settingsDensityCompact;

  /// No description provided for @settingsReduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get settingsReduceMotion;

  /// No description provided for @settingsReduceMotionHint.
  ///
  /// In en, this message translates to:
  /// **'Minimise animation. Also follows your system setting.'**
  String get settingsReduceMotionHint;

  /// No description provided for @settingsStartOfWeek.
  ///
  /// In en, this message translates to:
  /// **'Start of week'**
  String get settingsStartOfWeek;

  /// No description provided for @settingsDefaultView.
  ///
  /// In en, this message translates to:
  /// **'Default task view'**
  String get settingsDefaultView;

  /// No description provided for @settingsLandingRoute.
  ///
  /// In en, this message translates to:
  /// **'Open Kairo on'**
  String get settingsLandingRoute;

  /// No description provided for @settingsPomodoroLength.
  ///
  /// In en, this message translates to:
  /// **'Focus length'**
  String get settingsPomodoroLength;

  /// No description provided for @settingsShortBreakLength.
  ///
  /// In en, this message translates to:
  /// **'Short break'**
  String get settingsShortBreakLength;

  /// No description provided for @settingsLongBreakLength.
  ///
  /// In en, this message translates to:
  /// **'Long break'**
  String get settingsLongBreakLength;

  /// No description provided for @settingsRoundsBeforeLongBreak.
  ///
  /// In en, this message translates to:
  /// **'Rounds before long break'**
  String get settingsRoundsBeforeLongBreak;

  /// No description provided for @settingsExportData.
  ///
  /// In en, this message translates to:
  /// **'Export workspace data'**
  String get settingsExportData;

  /// No description provided for @settingsExportHint.
  ///
  /// In en, this message translates to:
  /// **'Download everything in this workspace as JSON.'**
  String get settingsExportHint;

  /// No description provided for @settingsResetDemo.
  ///
  /// In en, this message translates to:
  /// **'Reset demo data'**
  String get settingsResetDemo;

  /// No description provided for @settingsResetDemoHint.
  ///
  /// In en, this message translates to:
  /// **'Restore the Launchpad workspace to its original state.'**
  String get settingsResetDemoHint;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your account and all workspace data.'**
  String get settingsDeleteAccountHint;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePassword;

  /// No description provided for @settingsActiveSessions.
  ///
  /// In en, this message translates to:
  /// **'Active sessions'**
  String get settingsActiveSessions;

  /// No description provided for @settingsTwoFactor.
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication'**
  String get settingsTwoFactor;

  /// No description provided for @settingsNotifyMentions.
  ///
  /// In en, this message translates to:
  /// **'Mentions'**
  String get settingsNotifyMentions;

  /// No description provided for @settingsNotifyAssignments.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get settingsNotifyAssignments;

  /// No description provided for @settingsNotifyComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get settingsNotifyComments;

  /// No description provided for @settingsNotifyDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Deadline reminders'**
  String get settingsNotifyDeadlines;

  /// No description provided for @settingsNotifyProjects.
  ///
  /// In en, this message translates to:
  /// **'Project updates'**
  String get settingsNotifyProjects;

  /// No description provided for @settingsNotifyDigest.
  ///
  /// In en, this message translates to:
  /// **'Weekly digest'**
  String get settingsNotifyDigest;

  /// No description provided for @workspaceSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch workspace'**
  String get workspaceSwitch;

  /// No description provided for @workspaceCreate.
  ///
  /// In en, this message translates to:
  /// **'Create workspace'**
  String get workspaceCreate;

  /// No description provided for @workspaceRename.
  ///
  /// In en, this message translates to:
  /// **'Rename workspace'**
  String get workspaceRename;

  /// No description provided for @workspaceMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get workspaceMembers;

  /// No description provided for @workspaceLabels.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get workspaceLabels;

  /// No description provided for @workspaceInviteHint.
  ///
  /// In en, this message translates to:
  /// **'Invite by email address'**
  String get workspaceInviteHint;

  /// No description provided for @workspaceRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get workspaceRoleOwner;

  /// No description provided for @workspaceRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get workspaceRoleAdmin;

  /// No description provided for @workspaceRoleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get workspaceRoleMember;

  /// No description provided for @workspaceRoleGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get workspaceRoleGuest;

  /// No description provided for @emptyTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'No loose ends'**
  String get emptyTasksTitle;

  /// No description provided for @emptyTasksBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing is waiting on you here. Enjoy the clarity — or line up what\'s next.'**
  String get emptyTasksBody;

  /// No description provided for @emptyProjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready for its first project'**
  String get emptyProjectsTitle;

  /// No description provided for @emptyProjectsBody.
  ///
  /// In en, this message translates to:
  /// **'Projects group related work and give you progress at a glance.'**
  String get emptyProjectsBody;

  /// No description provided for @emptyNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get emptyNotificationsTitle;

  /// No description provided for @emptyNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'Mentions, assignments and deadline reminders will land here.'**
  String get emptyNotificationsBody;

  /// No description provided for @emptySearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search everything'**
  String get emptySearchTitle;

  /// No description provided for @emptySearchBody.
  ///
  /// In en, this message translates to:
  /// **'Find tasks, projects, people, labels and comments across the workspace.'**
  String get emptySearchBody;

  /// No description provided for @emptyArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing archived yet'**
  String get emptyArchiveTitle;

  /// No description provided for @emptyArchiveBody.
  ///
  /// In en, this message translates to:
  /// **'Archived work stays searchable and can be restored at any time.'**
  String get emptyArchiveBody;

  /// No description provided for @emptyFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get emptyFavoritesTitle;

  /// No description provided for @emptyFavoritesBody.
  ///
  /// In en, this message translates to:
  /// **'Star the projects and tasks you return to most and they\'ll live here.'**
  String get emptyFavoritesBody;

  /// No description provided for @emptyCommentsTitle.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get emptyCommentsTitle;

  /// No description provided for @emptyCommentsBody.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation — context beats a status meeting.'**
  String get emptyCommentsBody;

  /// No description provided for @emptyFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick something to focus on'**
  String get emptyFocusTitle;

  /// No description provided for @emptyFocusBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a single task, start the timer, and let everything else wait.'**
  String get emptyFocusBody;

  /// No description provided for @emptyCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled'**
  String get emptyCalendarTitle;

  /// No description provided for @emptyCalendarBody.
  ///
  /// In en, this message translates to:
  /// **'Tasks with a due date appear here. Drag one to reschedule it.'**
  String get emptyCalendarBody;

  /// No description provided for @emptyTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'No dated work yet'**
  String get emptyTimelineTitle;

  /// No description provided for @emptyTimelineBody.
  ///
  /// In en, this message translates to:
  /// **'Give tasks a start and due date to see them laid out over time.'**
  String get emptyTimelineBody;

  /// No description provided for @errorGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGenericTitle;

  /// No description provided for @errorGenericBody.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error stopped that from finishing.'**
  String get errorGenericBody;

  /// No description provided for @errorNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get errorNetworkTitle;

  /// No description provided for @errorNetworkBody.
  ///
  /// In en, this message translates to:
  /// **'Kairo is showing cached data. Changes will sync when you reconnect.'**
  String get errorNetworkBody;

  /// No description provided for @errorUnauthorizedTitle.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get errorUnauthorizedTitle;

  /// No description provided for @errorUnauthorizedBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to continue where you left off.'**
  String get errorUnauthorizedBody;

  /// No description provided for @errorNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find that'**
  String get errorNotFoundTitle;

  /// No description provided for @errorNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'It may have been deleted, archived, or moved to another workspace.'**
  String get errorNotFoundBody;

  /// No description provided for @errorValidationTitle.
  ///
  /// In en, this message translates to:
  /// **'Check the form'**
  String get errorValidationTitle;

  /// No description provided for @errorRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get errorRouteTitle;

  /// No description provided for @errorRouteBody.
  ///
  /// In en, this message translates to:
  /// **'The link you followed doesn\'t lead anywhere in Kairo.'**
  String get errorRouteBody;

  /// No description provided for @errorGoHome.
  ///
  /// In en, this message translates to:
  /// **'Back to dashboard'**
  String get errorGoHome;

  /// No description provided for @toastTaskCreated.
  ///
  /// In en, this message translates to:
  /// **'Task created'**
  String get toastTaskCreated;

  /// No description provided for @toastTaskUpdated.
  ///
  /// In en, this message translates to:
  /// **'Task updated'**
  String get toastTaskUpdated;

  /// No description provided for @toastTaskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Nice — task completed'**
  String get toastTaskCompleted;

  /// No description provided for @toastTaskReopened.
  ///
  /// In en, this message translates to:
  /// **'Task reopened'**
  String get toastTaskReopened;

  /// No description provided for @toastTaskDeleted.
  ///
  /// In en, this message translates to:
  /// **'Task deleted'**
  String get toastTaskDeleted;

  /// No description provided for @toastTaskArchived.
  ///
  /// In en, this message translates to:
  /// **'Task archived'**
  String get toastTaskArchived;

  /// No description provided for @toastTaskRestored.
  ///
  /// In en, this message translates to:
  /// **'Task restored'**
  String get toastTaskRestored;

  /// No description provided for @toastTaskDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Task duplicated'**
  String get toastTaskDuplicated;

  /// No description provided for @toastProjectCreated.
  ///
  /// In en, this message translates to:
  /// **'Project created'**
  String get toastProjectCreated;

  /// No description provided for @toastProjectUpdated.
  ///
  /// In en, this message translates to:
  /// **'Project updated'**
  String get toastProjectUpdated;

  /// No description provided for @toastProjectArchived.
  ///
  /// In en, this message translates to:
  /// **'Project archived'**
  String get toastProjectArchived;

  /// No description provided for @toastWorkspaceCreated.
  ///
  /// In en, this message translates to:
  /// **'Workspace created'**
  String get toastWorkspaceCreated;

  /// No description provided for @toastCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get toastCopied;

  /// No description provided for @toastSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get toastSettingsSaved;

  /// No description provided for @toastDemoReset.
  ///
  /// In en, this message translates to:
  /// **'Demo workspace restored'**
  String get toastDemoReset;

  /// No description provided for @toastUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get toastUndo;

  /// No description provided for @toastOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — changes are saved locally'**
  String get toastOffline;

  /// No description provided for @toastBackOnline.
  ///
  /// In en, this message translates to:
  /// **'Back online'**
  String get toastBackOnline;

  /// No description provided for @timeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get timeToday;

  /// No description provided for @timeTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get timeTomorrow;

  /// No description provided for @timeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get timeYesterday;

  /// No description provided for @timeNoDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get timeNoDate;

  /// No description provided for @timeOverdueBy.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day overdue} other{{days} days overdue}}'**
  String timeOverdueBy(int days);

  /// No description provided for @timeDueIn.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Due in 1 day} other{Due in {days} days}}'**
  String timeDueIn(int days);

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String timeMinutesAgo(int minutes);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String timeHoursAgo(int hours);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String timeDaysAgo(int days);

  /// No description provided for @timeEstimateHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String timeEstimateHours(String hours);

  /// No description provided for @recurrenceNone.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t repeat'**
  String get recurrenceNone;

  /// No description provided for @recurrenceDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get recurrenceDaily;

  /// No description provided for @recurrenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get recurrenceWeekly;

  /// No description provided for @recurrenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get recurrenceMonthly;

  /// No description provided for @recurrenceCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get recurrenceCustom;

  /// No description provided for @recurrenceEveryN.
  ///
  /// In en, this message translates to:
  /// **'Every {n} {unit}'**
  String recurrenceEveryN(int n, String unit);

  /// No description provided for @editorBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get editorBold;

  /// No description provided for @editorItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get editorItalic;

  /// No description provided for @editorHeading.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get editorHeading;

  /// No description provided for @editorBulletList.
  ///
  /// In en, this message translates to:
  /// **'Bulleted list'**
  String get editorBulletList;

  /// No description provided for @editorNumberedList.
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get editorNumberedList;

  /// No description provided for @editorQuote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get editorQuote;

  /// No description provided for @editorCode.
  ///
  /// In en, this message translates to:
  /// **'Code block'**
  String get editorCode;

  /// No description provided for @editorLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get editorLink;

  /// No description provided for @editorPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get editorPreview;

  /// No description provided for @editorWrite.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get editorWrite;

  /// No description provided for @editorPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add context, links, acceptance criteria…'**
  String get editorPlaceholder;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get commonLoading;

  /// No description provided for @commonOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get commonOffline;

  /// No description provided for @commonOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get commonOnline;

  /// No description provided for @commonYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get commonYou;

  /// No description provided for @commonMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// No description provided for @commonOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get commonOptions;

  /// No description provided for @commonNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get commonNone;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
