import 'dart:math';

import 'package:kairo/domain/entities/collaboration.dart';
import 'package:kairo/domain/entities/enums.dart';
import 'package:kairo/domain/entities/focus_session.dart';
import 'package:kairo/domain/entities/project.dart';
import 'package:kairo/domain/entities/recurrence.dart';
import 'package:kairo/domain/entities/task.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/domain/entities/workspace.dart';

/// Everything the demo workspace contains.
class SeedData {
  const SeedData({
    required this.users,
    required this.workspaces,
    required this.labels,
    required this.projects,
    required this.tasks,
    required this.comments,
    required this.activities,
    required this.notifications,
    required this.focusSessions,
  });

  final List<User> users;
  final List<Workspace> workspaces;
  final List<Label> labels;
  final List<Project> projects;
  final List<Task> tasks;
  final List<Comment> comments;
  final List<Activity> activities;
  final List<AppNotification> notifications;
  final List<FocusSession> focusSessions;
}

/// Builds the "Launchpad" demo workspace.
///
/// The data is written to tell a coherent story: a team three weeks from a
/// product launch, with a design system nearly finished, a mobile redesign in
/// flight, a marketing campaign ramping up, and a couple of things genuinely
/// late. Dates are generated relative to *now* so the dashboard, calendar and
/// timeline always look alive — the demo never ages.
abstract final class DemoSeed {
  /// Bumping this replaces a stale seeded workspace on next launch.
  static const int version = 3;

  static const String workspaceId = 'wsp_launchpad';
  static const String demoUserId = 'usr_jordan';
  static const String demoEmail = 'demo@kairo.app';
  static const String demoPassword = 'demo1234';

  static SeedData build() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    DateTime day(int offset) => today.add(Duration(days: offset));
    DateTime at(int dayOffset, int hour) =>
        day(dayOffset).add(Duration(hours: hour));

    final List<User> users = _users(today);
    final Workspace workspace = Workspace(
      id: workspaceId,
      name: 'Launchpad',
      description: 'Everything the product team is shipping this quarter.',
      ownerId: demoUserId,
      iconEmoji: '🚀',
      colorValue: 0xFF3B6BF5,
      plan: 'pro',
      createdAt: day(-124),
      members: <WorkspaceMember>[
        WorkspaceMember(
          userId: demoUserId,
          role: WorkspaceRole.owner,
          joinedAt: day(-124),
        ),
        WorkspaceMember(
          userId: 'usr_priya',
          role: WorkspaceRole.admin,
          joinedAt: day(-118),
        ),
        WorkspaceMember(
          userId: 'usr_tomas',
          role: WorkspaceRole.member,
          joinedAt: day(-116),
        ),
        WorkspaceMember(
          userId: 'usr_nadia',
          role: WorkspaceRole.member,
          joinedAt: day(-92),
        ),
        WorkspaceMember(
          userId: 'usr_lukas',
          role: WorkspaceRole.member,
          joinedAt: day(-61),
        ),
        WorkspaceMember(
          userId: 'usr_grace',
          role: WorkspaceRole.guest,
          joinedAt: day(-24),
        ),
      ],
    );

    final List<Label> labels = _labels();
    final List<Project> projects = _projects(day);
    final List<Task> tasks = _tasks(day, at);
    final List<Comment> comments = _comments(at);
    final List<AppNotification> notifications = _notifications(at);
    final List<Activity> activities = _activities(tasks, at);
    final List<FocusSession> focusSessions = _focusSessions(at);

    return SeedData(
      users: users,
      workspaces: <Workspace>[workspace, _personalWorkspace(day)],
      labels: labels,
      projects: projects,
      tasks: tasks,
      comments: comments,
      activities: activities,
      notifications: notifications,
      focusSessions: focusSessions,
    );
  }

  static Workspace _personalWorkspace(DateTime Function(int) day) => Workspace(
    id: 'wsp_personal',
    name: 'Personal',
    description: 'Side projects, reading list and everything outside work.',
    ownerId: demoUserId,
    iconEmoji: '🌱',
    colorValue: 0xFF14B8A6,
    createdAt: day(-58),
    members: <WorkspaceMember>[
      WorkspaceMember(
        userId: demoUserId,
        role: WorkspaceRole.owner,
        joinedAt: day(-58),
      ),
    ],
  );

  static List<User> _users(DateTime today) => <User>[
    User(
      id: demoUserId,
      name: 'Jordan Avery',
      email: demoEmail,
      jobTitle: 'Product Lead',
      accentColorValue: 0xFF3B6BF5,
      timezone: 'Europe/London',
      createdAt: today.subtract(const Duration(days: 124)),
    ),
    const User(
      id: 'usr_priya',
      name: 'Priya Raman',
      email: 'priya@kairo.app',
      jobTitle: 'Design Lead',
      accentColorValue: 0xFF7C3AED,
      timezone: 'Asia/Kolkata',
    ),
    const User(
      id: 'usr_tomas',
      name: 'Tomás Ferreira',
      email: 'tomas@kairo.app',
      jobTitle: 'Staff Engineer',
      accentColorValue: 0xFF0D9488,
      timezone: 'Europe/Lisbon',
    ),
    const User(
      id: 'usr_nadia',
      name: 'Nadia Haddad',
      email: 'nadia@kairo.app',
      jobTitle: 'Marketing Manager',
      accentColorValue: 0xFFEA580C,
      timezone: 'Europe/Berlin',
    ),
    const User(
      id: 'usr_lukas',
      name: 'Lukas Brandt',
      email: 'lukas@kairo.app',
      jobTitle: 'Mobile Engineer',
      accentColorValue: 0xFF0EA5E9,
      timezone: 'Europe/Berlin',
    ),
    const User(
      id: 'usr_grace',
      name: 'Grace Whitfield',
      email: 'grace@kairo.app',
      jobTitle: 'Data Analyst',
      accentColorValue: 0xFF22C55E,
      timezone: 'America/New_York',
    ),
  ];

  static List<Label> _labels() => const <Label>[
    Label(
      id: 'lbl_design',
      workspaceId: workspaceId,
      name: 'Design',
      colorValue: 0xFF7C3AED,
    ),
    Label(
      id: 'lbl_eng',
      workspaceId: workspaceId,
      name: 'Engineering',
      colorValue: 0xFF3B6BF5,
    ),
    Label(
      id: 'lbl_research',
      workspaceId: workspaceId,
      name: 'Research',
      colorValue: 0xFF0D9488,
    ),
    Label(
      id: 'lbl_bug',
      workspaceId: workspaceId,
      name: 'Bug',
      colorValue: 0xFFEF4444,
    ),
    Label(
      id: 'lbl_content',
      workspaceId: workspaceId,
      name: 'Content',
      colorValue: 0xFFEA580C,
    ),
    Label(
      id: 'lbl_growth',
      workspaceId: workspaceId,
      name: 'Growth',
      colorValue: 0xFF22C55E,
    ),
    Label(
      id: 'lbl_blocked',
      workspaceId: workspaceId,
      name: 'Blocked',
      colorValue: 0xFFEC4899,
    ),
    Label(
      id: 'lbl_quickwin',
      workspaceId: workspaceId,
      name: 'Quick win',
      colorValue: 0xFFEAB308,
    ),
  ];

  static List<Project> _projects(DateTime Function(int) day) => <Project>[
    Project(
      id: 'prj_launch',
      workspaceId: workspaceId,
      name: 'Product Launch',
      description:
          'Everything that has to be true before we open the doors: pricing, '
          'onboarding, docs, and a launch-day runbook the whole team can follow.',
      iconEmoji: '🚀',
      colorValue: 0xFF3B6BF5,
      status: ProjectStatus.active,
      leadId: demoUserId,
      memberIds: const <String>[
        demoUserId,
        'usr_priya',
        'usr_tomas',
        'usr_nadia',
      ],
      startDate: day(-38),
      dueDate: day(21),
      sortIndex: 0,
      isFavorite: true,
      createdAt: day(-38),
      updatedAt: day(-1),
      milestones: <Milestone>[
        Milestone(
          id: 'mls_beta',
          projectId: 'prj_launch',
          title: 'Private beta',
          date: day(-6),
          isReached: true,
        ),
        Milestone(
          id: 'mls_freeze',
          projectId: 'prj_launch',
          title: 'Feature freeze',
          date: day(9),
        ),
        Milestone(
          id: 'mls_launch',
          projectId: 'prj_launch',
          title: 'Public launch',
          date: day(21),
        ),
      ],
    ),
    Project(
      id: 'prj_mobile',
      workspaceId: workspaceId,
      name: 'Mobile App Redesign',
      description:
          'A ground-up pass on navigation, task creation and the offline story '
          'so the phone app stops feeling like a companion and starts feeling '
          'like the product.',
      iconEmoji: '📱',
      colorValue: 0xFF7C3AED,
      status: ProjectStatus.active,
      leadId: 'usr_priya',
      memberIds: const <String>['usr_priya', 'usr_lukas', demoUserId],
      startDate: day(-24),
      dueDate: day(38),
      sortIndex: 1,
      isFavorite: true,
      createdAt: day(-24),
      updatedAt: day(-2),
      milestones: <Milestone>[
        Milestone(
          id: 'mls_nav',
          projectId: 'prj_mobile',
          title: 'Navigation locked',
          date: day(4),
        ),
        Milestone(
          id: 'mls_beta_ios',
          projectId: 'prj_mobile',
          title: 'TestFlight build',
          date: day(30),
        ),
      ],
    ),
    Project(
      id: 'prj_marketing',
      workspaceId: workspaceId,
      name: 'Marketing Campaign',
      description:
          'Launch-week narrative: landing page, lifecycle emails, a founder '
          'post, and the three case studies that carry the argument.',
      iconEmoji: '📣',
      colorValue: 0xFFEA580C,
      status: ProjectStatus.active,
      leadId: 'usr_nadia',
      memberIds: const <String>['usr_nadia', demoUserId, 'usr_grace'],
      startDate: day(-16),
      dueDate: day(24),
      sortIndex: 2,
      createdAt: day(-16),
      updatedAt: day(-1),
      milestones: <Milestone>[
        Milestone(
          id: 'mls_assets',
          projectId: 'prj_marketing',
          title: 'Assets ready',
          date: day(12),
        ),
      ],
    ),
    Project(
      id: 'prj_website',
      workspaceId: workspaceId,
      name: 'Website Revamp',
      description:
          'Rebuild the marketing site around the new positioning, with a '
          'pricing page that actually explains the plans.',
      iconEmoji: '🌐',
      colorValue: 0xFF0D9488,
      status: ProjectStatus.planning,
      leadId: 'usr_priya',
      memberIds: const <String>['usr_priya', 'usr_nadia'],
      startDate: day(6),
      dueDate: day(62),
      sortIndex: 3,
      createdAt: day(-9),
      updatedAt: day(-4),
    ),
    Project(
      id: 'prj_growth',
      workspaceId: workspaceId,
      name: 'Q4 Growth',
      description:
          'Activation and retention experiments. Every item here has a metric '
          'attached or it does not belong in the project.',
      iconEmoji: '📈',
      colorValue: 0xFF22C55E,
      status: ProjectStatus.active,
      leadId: 'usr_grace',
      memberIds: const <String>['usr_grace', 'usr_nadia', demoUserId],
      startDate: day(-11),
      dueDate: day(74),
      sortIndex: 4,
      createdAt: day(-11),
      updatedAt: day(-3),
    ),
    Project(
      id: 'prj_designsys',
      workspaceId: workspaceId,
      name: 'Design System v2',
      description:
          'Shipped in September. Kept for reference — the token pipeline lives '
          'here.',
      iconEmoji: '🎨',
      colorValue: 0xFF64748B,
      status: ProjectStatus.completed,
      leadId: 'usr_priya',
      memberIds: const <String>['usr_priya', 'usr_tomas'],
      startDate: day(-96),
      dueDate: day(-30),
      sortIndex: 5,
      isArchived: true,
      createdAt: day(-96),
      updatedAt: day(-30),
    ),
  ];

  /// The task set. Ordering within each status is the manual board order.
  static List<Task> _tasks(
    DateTime Function(int) day,
    DateTime Function(int, int) at,
  ) {
    int index = 0;
    Task t({
      required String id,
      required String title,
      required String projectId,
      required TaskStatus status,
      required TaskPriority priority,
      String description = '',
      String? assigneeId,
      List<String> labels = const <String>[],
      int? due,
      int? start,
      int? estimate,
      List<String> subtasks = const <String>[],
      int subtasksDone = 0,
      List<String> dependsOn = const <String>[],
      int createdDaysAgo = 14,
      int? completedDaysAgo,
      bool favorite = false,
      bool archived = false,
      RecurrenceRule recurrence = RecurrenceRule.none,
    }) {
      final int order = index++;
      return Task(
        id: id,
        workspaceId: workspaceId,
        projectId: projectId,
        title: title,
        description: description,
        status: status,
        priority: priority,
        assigneeId: assigneeId,
        labelIds: labels,
        dueDate: due == null ? null : day(due),
        startDate: start == null ? null : day(start),
        estimateMinutes: estimate,
        subtasks: <Subtask>[
          for (int i = 0; i < subtasks.length; i++)
            Subtask(
              id: '${id}_s$i',
              title: subtasks[i],
              isDone: i < subtasksDone,
              sortIndex: i,
            ),
        ],
        dependsOnIds: dependsOn,
        recurrence: recurrence,
        isArchived: archived,
        isFavorite: favorite,
        sortIndex: order,
        createdAt: at(-createdDaysAgo, 9),
        updatedAt: at(-(completedDaysAgo ?? 1), 16),
        completedAt: completedDaysAgo == null
            ? null
            : at(-completedDaysAgo, 16),
        createdById: demoUserId,
      );
    }

    return <Task>[
      // --- Product Launch -----------------------------------------------
      t(
        id: 'tsk_onboarding',
        title: 'Finalize onboarding flow',
        projectId: 'prj_launch',
        status: TaskStatus.inProgress,
        priority: TaskPriority.urgent,
        assigneeId: 'usr_priya',
        labels: <String>['lbl_design', 'lbl_eng'],
        due: 2,
        start: -5,
        estimate: 720,
        favorite: true,
        createdDaysAgo: 12,
        description:
            '## Goal\n'
            'A new account reaches a populated workspace in **under 90 seconds**.\n\n'
            '### Scope\n'
            '- Six steps, each skippable except workspace creation\n'
            '- Seed the first project from the chosen goal\n'
            '- Persist progress so a refresh does not restart the flow\n\n'
            '> Decision from the 14th: no video, no tour. Just do the setup.',
        subtasks: <String>[
          'Welcome + goal selection',
          'Workspace creation step',
          'First project step',
          'First task step',
          'Preferences step',
          'Handoff animation into the dashboard',
        ],
        subtasksDone: 4,
      ),
      t(
        id: 'tsk_pricing_page',
        title: 'Create pricing page',
        projectId: 'prj_launch',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        assigneeId: 'usr_nadia',
        labels: <String>['lbl_content', 'lbl_design'],
        due: 5,
        start: -3,
        estimate: 480,
        createdDaysAgo: 10,
        description:
            'Four tiers: Free, Pro, Team, Enterprise. The comparison table has '
            'to answer "which one am I" without a sales call.\n\n'
            '- [ ] Plan copy signed off by Nadia\n'
            '- [ ] Annual/monthly toggle\n'
            '- [ ] FAQ block underneath',
        subtasks: <String>['Plan copy', 'Comparison table', 'FAQ block'],
        subtasksDone: 1,
      ),
      t(
        id: 'tsk_auth',
        title: 'Implement authentication',
        projectId: 'prj_launch',
        status: TaskStatus.done,
        priority: TaskPriority.urgent,
        assigneeId: 'usr_tomas',
        labels: <String>['lbl_eng'],
        due: -4,
        start: -18,
        estimate: 960,
        createdDaysAgo: 20,
        completedDaysAgo: 5,
        description:
            'Email + password, session refresh, and the reset flow end to end. '
            'Social providers are UI-only until the OAuth apps are approved.',
        subtasks: <String>[
          'Sign up + sign in',
          'Password reset',
          'Email verification',
          'Session persistence',
        ],
        subtasksDone: 4,
      ),
      t(
        id: 'tsk_runbook',
        title: 'Write launch-day runbook',
        projectId: 'prj_launch',
        status: TaskStatus.todo,
        priority: TaskPriority.high,
        assigneeId: demoUserId,
        labels: <String>['lbl_content'],
        due: 14,
        estimate: 180,
        createdDaysAgo: 6,
        dependsOn: <String>['tsk_onboarding'],
        description:
            'Who watches what, in what order, and what the rollback looks like. '
            'One page. If it needs two, the plan is too complicated.',
      ),
      t(
        id: 'tsk_status_page',
        title: 'Stand up a public status page',
        projectId: 'prj_launch',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        assigneeId: 'usr_tomas',
        labels: <String>['lbl_eng'],
        due: 11,
        estimate: 240,
        createdDaysAgo: 6,
      ),
      t(
        id: 'tsk_billing_copy',
        title: 'Review billing copy with legal',
        projectId: 'prj_launch',
        status: TaskStatus.review,
        priority: TaskPriority.medium,
        assigneeId: 'usr_nadia',
        labels: <String>['lbl_content'],
        due: -1,
        estimate: 90,
        createdDaysAgo: 8,
        description:
            'Refund window and trial terms need a second pair of eyes before '
            'the pricing page ships.',
      ),
      t(
        id: 'tsk_perf_budget',
        title: 'Agree a performance budget for first paint',
        projectId: 'prj_launch',
        status: TaskStatus.backlog,
        priority: TaskPriority.low,
        assigneeId: 'usr_tomas',
        labels: <String>['lbl_eng', 'lbl_research'],
        estimate: 120,
        createdDaysAgo: 5,
      ),
      t(
        id: 'tsk_press_kit',
        title: 'Assemble the press kit',
        projectId: 'prj_launch',
        status: TaskStatus.backlog,
        priority: TaskPriority.low,
        assigneeId: 'usr_nadia',
        labels: <String>['lbl_content'],
        due: 18,
        createdDaysAgo: 4,
      ),
      t(
        id: 'tsk_docs',
        title: 'Draft the getting-started docs',
        projectId: 'prj_launch',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        assigneeId: demoUserId,
        labels: <String>['lbl_content'],
        due: 8,
        estimate: 300,
        createdDaysAgo: 7,
        subtasks: <String>['Quickstart', 'Keyboard shortcuts', 'Data export'],
        subtasksDone: 1,
      ),

      // --- Mobile App Redesign -------------------------------------------
      t(
        id: 'tsk_mobile_nav',
        title: 'Review mobile navigation',
        projectId: 'prj_mobile',
        status: TaskStatus.review,
        priority: TaskPriority.high,
        assigneeId: 'usr_priya',
        labels: <String>['lbl_design', 'lbl_research'],
        due: 1,
        start: -7,
        estimate: 420,
        favorite: true,
        createdDaysAgo: 15,
        description:
            'Five destinations was too many; the prototype tests better at four '
            'with a **More** sheet.\n\n'
            '1. Dashboard\n2. Tasks\n3. Calendar\n4. Focus\n\n'
            'Everything else moves behind *More*.',
        subtasks: <String>[
          'Prototype both variants',
          'Run five moderated sessions',
          'Write up the recommendation',
        ],
        subtasksDone: 3,
      ),
      t(
        id: 'tsk_offline',
        title: 'Offline-first task editing',
        projectId: 'prj_mobile',
        status: TaskStatus.inProgress,
        priority: TaskPriority.urgent,
        assigneeId: 'usr_lukas',
        labels: <String>['lbl_eng'],
        due: 6,
        start: -4,
        estimate: 1080,
        createdDaysAgo: 11,
        dependsOn: <String>['tsk_mobile_nav'],
        description:
            'Writes queue locally and replay on reconnect. Conflict rule: last '
            'write wins per field, not per document.',
        subtasks: <String>[
          'Local write queue',
          'Replay on reconnect',
          'Conflict resolution per field',
          'Offline banner + retry affordance',
        ],
        subtasksDone: 2,
      ),
      t(
        id: 'tsk_swipe',
        title: 'Swipe actions on task rows',
        projectId: 'prj_mobile',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        assigneeId: 'usr_lukas',
        labels: <String>['lbl_design', 'lbl_eng'],
        due: 9,
        estimate: 240,
        createdDaysAgo: 6,
        description:
            'Right to complete, left to reveal snooze and archive. Haptic on '
            'the completion threshold.',
      ),
      t(
        id: 'tsk_bottom_sheet',
        title: 'Task detail as a draggable sheet',
        projectId: 'prj_mobile',
        status: TaskStatus.done,
        priority: TaskPriority.high,
        assigneeId: 'usr_lukas',
        labels: <String>['lbl_eng'],
        due: -3,
        start: -12,
        estimate: 360,
        createdDaysAgo: 14,
        completedDaysAgo: 3,
      ),
      t(
        id: 'tsk_dark_mode_audit',
        title: 'Audit dark mode contrast on small screens',
        projectId: 'prj_mobile',
        status: TaskStatus.todo,
        priority: TaskPriority.low,
        assigneeId: 'usr_priya',
        labels: <String>['lbl_design'],
        due: 16,
        estimate: 150,
        createdDaysAgo: 3,
      ),
      t(
        id: 'tsk_ios_crash',
        title: 'Crash on rotate in the calendar month view',
        projectId: 'prj_mobile',
        status: TaskStatus.inProgress,
        priority: TaskPriority.urgent,
        assigneeId: 'usr_lukas',
        labels: <String>['lbl_bug', 'lbl_eng'],
        due: -2,
        estimate: 120,
        createdDaysAgo: 4,
        description:
            'Reproducible on iPhone SE, portrait to landscape while the month '
            'grid is mid-animation. Stack trace points at the grid delegate.',
      ),

      // --- Marketing Campaign --------------------------------------------
      t(
        id: 'tsk_launch_campaign',
        title: 'Prepare launch campaign',
        projectId: 'prj_marketing',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        assigneeId: 'usr_nadia',
        labels: <String>['lbl_content', 'lbl_growth'],
        due: 12,
        start: -8,
        estimate: 600,
        createdDaysAgo: 13,
        subtasks: <String>[
          'Narrative one-pager',
          'Email sequence',
          'Social assets',
          'Founder post',
        ],
        subtasksDone: 2,
      ),
      t(
        id: 'tsk_case_studies',
        title: 'Three customer case studies',
        projectId: 'prj_marketing',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        assigneeId: 'usr_nadia',
        labels: <String>['lbl_content'],
        due: 15,
        estimate: 480,
        createdDaysAgo: 9,
        dependsOn: <String>['tsk_launch_campaign'],
      ),
      t(
        id: 'tsk_seo',
        title: 'Fix metadata and Open Graph on every marketing route',
        projectId: 'prj_marketing',
        status: TaskStatus.done,
        priority: TaskPriority.medium,
        assigneeId: demoUserId,
        labels: <String>['lbl_growth', 'lbl_quickwin'],
        due: -6,
        estimate: 90,
        createdDaysAgo: 12,
        completedDaysAgo: 6,
      ),
      t(
        id: 'tsk_weekly_report',
        title: 'Send the weekly growth report',
        projectId: 'prj_marketing',
        status: TaskStatus.todo,
        priority: TaskPriority.low,
        assigneeId: 'usr_grace',
        labels: <String>['lbl_growth'],
        due: 3,
        estimate: 45,
        createdDaysAgo: 30,
        recurrence: const RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          weekdays: <int>[DateTime.friday],
        ),
        description:
            'Sign-ups, activation rate, and the one number that moved.',
      ),
      t(
        id: 'tsk_webinar',
        title: 'Book the launch webinar slot',
        projectId: 'prj_marketing',
        status: TaskStatus.backlog,
        priority: TaskPriority.low,
        assigneeId: 'usr_nadia',
        createdDaysAgo: 5,
      ),

      // --- Website Revamp ------------------------------------------------
      t(
        id: 'tsk_site_ia',
        title: 'Rework the site information architecture',
        projectId: 'prj_website',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        assigneeId: 'usr_priya',
        labels: <String>['lbl_design', 'lbl_research'],
        due: 20,
        start: 6,
        estimate: 360,
        createdDaysAgo: 8,
      ),
      t(
        id: 'tsk_site_hero',
        title: 'Design the new hero section',
        projectId: 'prj_website',
        status: TaskStatus.backlog,
        priority: TaskPriority.medium,
        assigneeId: 'usr_priya',
        labels: <String>['lbl_design'],
        due: 27,
        start: 13,
        estimate: 300,
        createdDaysAgo: 8,
        dependsOn: <String>['tsk_site_ia'],
      ),
      t(
        id: 'tsk_site_testimonials',
        title: 'Collect testimonials from beta customers',
        projectId: 'prj_website',
        status: TaskStatus.backlog,
        priority: TaskPriority.low,
        assigneeId: 'usr_nadia',
        labels: <String>['lbl_content'],
        due: 30,
        createdDaysAgo: 7,
      ),

      // --- Q4 Growth ------------------------------------------------------
      t(
        id: 'tsk_activation',
        title: 'Instrument the activation funnel',
        projectId: 'prj_growth',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        assigneeId: 'usr_grace',
        labels: <String>['lbl_growth', 'lbl_eng'],
        due: 7,
        start: -6,
        estimate: 420,
        createdDaysAgo: 10,
        description:
            'Six events, named consistently, documented in one table. Nothing '
            'ships to the dashboard until the naming is agreed.',
        subtasks: <String>[
          'Event taxonomy',
          'Client instrumentation',
          'Verification dashboard',
        ],
        subtasksDone: 1,
      ),
      t(
        id: 'tsk_empty_states',
        title: 'Rewrite empty states across the product',
        projectId: 'prj_growth',
        status: TaskStatus.done,
        priority: TaskPriority.medium,
        assigneeId: 'usr_priya',
        labels: <String>['lbl_content', 'lbl_quickwin'],
        due: -8,
        estimate: 180,
        createdDaysAgo: 16,
        completedDaysAgo: 8,
      ),
      t(
        id: 'tsk_referral',
        title: 'Prototype a referral loop',
        projectId: 'prj_growth',
        status: TaskStatus.backlog,
        priority: TaskPriority.low,
        assigneeId: 'usr_grace',
        labels: <String>['lbl_growth'],
        due: 40,
        estimate: 600,
        createdDaysAgo: 6,
      ),
      t(
        id: 'tsk_churn_interviews',
        title: 'Interview five churned trial accounts',
        projectId: 'prj_growth',
        status: TaskStatus.todo,
        priority: TaskPriority.high,
        assigneeId: 'usr_grace',
        labels: <String>['lbl_research'],
        due: 10,
        estimate: 300,
        createdDaysAgo: 5,
      ),

      // --- Recent completions, for a believable trend ----------------------
      t(
        id: 'tsk_design_tokens',
        title: 'Finalize the design system tokens',
        projectId: 'prj_designsys',
        status: TaskStatus.done,
        priority: TaskPriority.high,
        assigneeId: 'usr_priya',
        labels: <String>['lbl_design'],
        due: -30,
        estimate: 600,
        createdDaysAgo: 44,
        completedDaysAgo: 30,
        archived: true,
      ),
      t(
        id: 'tsk_command_palette',
        title: 'Ship the command palette',
        projectId: 'prj_launch',
        status: TaskStatus.done,
        priority: TaskPriority.high,
        assigneeId: 'usr_tomas',
        labels: <String>['lbl_eng'],
        due: -9,
        estimate: 480,
        createdDaysAgo: 22,
        completedDaysAgo: 9,
      ),
      t(
        id: 'tsk_keyboard_shortcuts',
        title: 'Keyboard shortcuts for every primary action',
        projectId: 'prj_launch',
        status: TaskStatus.done,
        priority: TaskPriority.medium,
        assigneeId: 'usr_tomas',
        labels: <String>['lbl_eng'],
        due: -7,
        estimate: 240,
        createdDaysAgo: 18,
        completedDaysAgo: 7,
      ),
      t(
        id: 'tsk_dashboard_perf',
        title: 'Optimize dashboard performance',
        projectId: 'prj_launch',
        status: TaskStatus.done,
        priority: TaskPriority.high,
        assigneeId: 'usr_tomas',
        labels: <String>['lbl_eng'],
        due: -2,
        estimate: 300,
        createdDaysAgo: 9,
        completedDaysAgo: 2,
        description:
            'The snapshot was recomputed on every rebuild. Now computed once '
            'per task-list change and shared by the dashboard and analytics.',
      ),
      t(
        id: 'tsk_timeline_zoom',
        title: 'Timeline zoom levels',
        projectId: 'prj_launch',
        status: TaskStatus.done,
        priority: TaskPriority.medium,
        assigneeId: 'usr_tomas',
        labels: <String>['lbl_eng'],
        due: -1,
        estimate: 240,
        createdDaysAgo: 8,
        completedDaysAgo: 1,
      ),
      t(
        id: 'tsk_notification_grouping',
        title: 'Group notifications by day',
        projectId: 'prj_mobile',
        status: TaskStatus.done,
        priority: TaskPriority.low,
        assigneeId: 'usr_lukas',
        labels: <String>['lbl_eng', 'lbl_quickwin'],
        due: -1,
        estimate: 120,
        createdDaysAgo: 6,
        completedDaysAgo: 1,
      ),
      t(
        id: 'tsk_a11y_pass',
        title: 'Accessibility pass on the task list',
        projectId: 'prj_mobile',
        status: TaskStatus.done,
        priority: TaskPriority.high,
        assigneeId: 'usr_priya',
        labels: <String>['lbl_design', 'lbl_eng'],
        due: -4,
        estimate: 300,
        createdDaysAgo: 13,
        completedDaysAgo: 4,
      ),
      t(
        id: 'tsk_export',
        title: 'Workspace JSON export',
        projectId: 'prj_launch',
        status: TaskStatus.done,
        priority: TaskPriority.low,
        assigneeId: 'usr_tomas',
        labels: <String>['lbl_eng'],
        due: -11,
        estimate: 120,
        createdDaysAgo: 15,
        completedDaysAgo: 11,
      ),
      t(
        id: 'tsk_label_manager',
        title: 'Label management UI',
        projectId: 'prj_launch',
        status: TaskStatus.done,
        priority: TaskPriority.medium,
        assigneeId: 'usr_priya',
        labels: <String>['lbl_design'],
        due: -13,
        estimate: 180,
        createdDaysAgo: 19,
        completedDaysAgo: 13,
      ),

      // --- Personal workspace ---------------------------------------------
      t(
        id: 'tsk_personal_reading',
        title: 'Finish "Shape Up" and write three takeaways',
        projectId: '',
        status: TaskStatus.todo,
        priority: TaskPriority.low,
        assigneeId: demoUserId,
        due: 5,
        estimate: 180,
        createdDaysAgo: 12,
      ),
      t(
        id: 'tsk_personal_gym',
        title: 'Swim on Tuesday and Thursday',
        projectId: '',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        assigneeId: demoUserId,
        due: 1,
        createdDaysAgo: 30,
        recurrence: const RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          weekdays: <int>[DateTime.tuesday, DateTime.thursday],
        ),
      ),
    ].map((Task task) {
      // Tasks seeded with an empty projectId belong to the Personal workspace.
      if (task.projectId != null && task.projectId!.isEmpty) {
        return Task(
          id: task.id,
          workspaceId: 'wsp_personal',
          title: task.title,
          description: task.description,
          status: task.status,
          priority: task.priority,
          assigneeId: task.assigneeId,
          dueDate: task.dueDate,
          startDate: task.startDate,
          estimateMinutes: task.estimateMinutes,
          subtasks: task.subtasks,
          recurrence: task.recurrence,
          sortIndex: task.sortIndex,
          createdAt: task.createdAt,
          updatedAt: task.updatedAt,
          completedAt: task.completedAt,
          createdById: task.createdById,
        );
      }
      return task;
    }).toList();
  }

  static List<Comment> _comments(DateTime Function(int, int) at) => <Comment>[
    Comment(
      id: 'cmt_1',
      taskId: 'tsk_onboarding',
      authorId: 'usr_priya',
      body:
          'Step 4 tested badly — people expect to type a task, not pick from a '
          'list. Swapped it for a single input with three suggestions underneath.',
      createdAt: at(-3, 11),
      reactions: const <Reaction>[
        Reaction(emoji: '👍', userIds: <String>['usr_jordan', 'usr_tomas']),
      ],
    ),
    Comment(
      id: 'cmt_2',
      taskId: 'tsk_onboarding',
      authorId: demoUserId,
      body:
          'Agreed. @Tomás Ferreira can we persist partial progress so a refresh '
          'does not send them back to step one?',
      createdAt: at(-3, 13),
      mentionedUserIds: const <String>['usr_tomas'],
      replyToId: 'cmt_1',
    ),
    Comment(
      id: 'cmt_3',
      taskId: 'tsk_onboarding',
      authorId: 'usr_tomas',
      body:
          'Already writes to local storage on each step. I will add the resume '
          'banner so it is visible rather than magic.',
      createdAt: at(-2, 9),
      replyToId: 'cmt_1',
      reactions: const <Reaction>[
        Reaction(emoji: '🎯', userIds: <String>['usr_priya']),
      ],
    ),
    Comment(
      id: 'cmt_4',
      taskId: 'tsk_ios_crash',
      authorId: 'usr_lukas',
      body:
          'Narrowed it down: the grid delegate is rebuilt while the layout pass '
          'is in flight. Fix is to key the grid on the visible month.',
      createdAt: at(-1, 15),
    ),
    Comment(
      id: 'cmt_5',
      taskId: 'tsk_offline',
      authorId: 'usr_lukas',
      body:
          'Queue and replay are done. Conflict resolution is the interesting '
          'part — going per field rather than per document so two people '
          'editing different properties never clobber each other.',
      createdAt: at(-2, 16),
      reactions: const <Reaction>[
        Reaction(emoji: '🔥', userIds: <String>['usr_jordan', 'usr_priya']),
      ],
    ),
    Comment(
      id: 'cmt_6',
      taskId: 'tsk_pricing_page',
      authorId: 'usr_nadia',
      body:
          'Draft copy is in. Still not happy with how Team and Enterprise read '
          'next to each other — the difference is support, not features.',
      createdAt: at(-1, 10),
    ),
    Comment(
      id: 'cmt_7',
      taskId: 'tsk_mobile_nav',
      authorId: 'usr_priya',
      body:
          'Five of five participants found Focus faster with four destinations. '
          'Writing it up now, but the recommendation is not going to change.',
      createdAt: at(-4, 14),
      reactions: const <Reaction>[
        Reaction(
          emoji: '👏',
          userIds: <String>['usr_jordan', 'usr_lukas', 'usr_nadia'],
        ),
      ],
    ),
    Comment(
      id: 'cmt_8',
      taskId: 'tsk_activation',
      authorId: 'usr_grace',
      body:
          'Event names are the whole game here. Once they are wrong in the '
          'warehouse they are wrong forever, so I would rather spend a day on '
          'the taxonomy than fix it in December.',
      createdAt: at(-2, 12),
    ),
    Comment(
      id: 'cmt_9',
      taskId: 'tsk_billing_copy',
      authorId: demoUserId,
      body: 'Sent over this morning. Expecting comments back by Thursday.',
      createdAt: at(-1, 9),
    ),
    Comment(
      id: 'cmt_10',
      taskId: 'tsk_dashboard_perf',
      authorId: 'usr_tomas',
      body:
          'Snapshot is computed once per task-list change now instead of on '
          'every rebuild. The analytics screen reads the same value.',
      createdAt: at(-2, 17),
      reactions: const <Reaction>[
        Reaction(emoji: '🚀', userIds: <String>['usr_jordan']),
      ],
    ),
  ];

  static List<AppNotification> _notifications(DateTime Function(int, int) at) =>
      <AppNotification>[
        AppNotification(
          id: 'ntf_1',
          workspaceId: workspaceId,
          type: NotificationType.mention,
          title: 'Jordan Avery mentioned you',
          body: 'in Finalize onboarding flow',
          createdAt: at(0, 8),
          actorId: demoUserId,
          taskId: 'tsk_onboarding',
        ),
        AppNotification(
          id: 'ntf_2',
          workspaceId: workspaceId,
          type: NotificationType.deadline,
          title: 'Due tomorrow',
          body: 'Review mobile navigation',
          createdAt: at(0, 7),
          taskId: 'tsk_mobile_nav',
        ),
        AppNotification(
          id: 'ntf_3',
          workspaceId: workspaceId,
          type: NotificationType.assignment,
          title: 'Priya Raman assigned you a task',
          body: 'Draft the getting-started docs',
          createdAt: at(-1, 16),
          actorId: 'usr_priya',
          taskId: 'tsk_docs',
        ),
        AppNotification(
          id: 'ntf_4',
          workspaceId: workspaceId,
          type: NotificationType.comment,
          title: 'Lukas Brandt commented',
          body: 'Narrowed it down: the grid delegate is rebuilt while…',
          createdAt: at(-1, 15),
          actorId: 'usr_lukas',
          taskId: 'tsk_ios_crash',
        ),
        AppNotification(
          id: 'ntf_5',
          workspaceId: workspaceId,
          type: NotificationType.deadline,
          title: 'Overdue',
          body: 'Crash on rotate in the calendar month view',
          createdAt: at(-1, 9),
          taskId: 'tsk_ios_crash',
        ),
        AppNotification(
          id: 'ntf_6',
          workspaceId: workspaceId,
          type: NotificationType.taskCompleted,
          title: 'Tomás Ferreira completed a task',
          body: 'Timeline zoom levels',
          createdAt: at(-1, 18),
          actorId: 'usr_tomas',
          taskId: 'tsk_timeline_zoom',
          isRead: true,
        ),
        AppNotification(
          id: 'ntf_7',
          workspaceId: workspaceId,
          type: NotificationType.projectUpdate,
          title: 'Product Launch reached a milestone',
          body: 'Private beta',
          createdAt: at(-6, 12),
          projectId: 'prj_launch',
          isRead: true,
        ),
        AppNotification(
          id: 'ntf_8',
          workspaceId: workspaceId,
          type: NotificationType.comment,
          title: 'Grace Whitfield commented',
          body: 'Event names are the whole game here…',
          createdAt: at(-2, 12),
          actorId: 'usr_grace',
          taskId: 'tsk_activation',
          isRead: true,
        ),
        AppNotification(
          id: 'ntf_9',
          workspaceId: workspaceId,
          type: NotificationType.assignment,
          title: 'You were added to Q4 Growth',
          body: 'Grace Whitfield added you to the project',
          createdAt: at(-9, 10),
          actorId: 'usr_grace',
          projectId: 'prj_growth',
          isRead: true,
        ),
        AppNotification(
          id: 'ntf_10',
          workspaceId: workspaceId,
          type: NotificationType.mention,
          title: 'Nadia Haddad mentioned you',
          body: 'in Create pricing page',
          createdAt: at(-3, 11),
          actorId: 'usr_nadia',
          taskId: 'tsk_pricing_page',
          isRead: true,
        ),
      ];

  /// Activity is derived from the task set so the feed can never contradict it.
  static List<Activity> _activities(
    List<Task> tasks,
    DateTime Function(int, int) at,
  ) {
    final List<Activity> activities = <Activity>[];
    int counter = 0;

    for (final Task task in tasks) {
      if (task.workspaceId != workspaceId) continue;
      activities.add(
        Activity(
          id: 'act_${counter++}',
          workspaceId: workspaceId,
          type: ActivityType.taskCreated,
          actorId: task.createdById,
          createdAt: task.createdAt,
          taskId: task.id,
          projectId: task.projectId,
        ),
      );
      if (task.completedAt != null) {
        activities.add(
          Activity(
            id: 'act_${counter++}',
            workspaceId: workspaceId,
            type: ActivityType.taskCompleted,
            actorId: task.assigneeId ?? task.createdById,
            createdAt: task.completedAt!,
            taskId: task.id,
            projectId: task.projectId,
          ),
        );
      }
    }

    activities.addAll(<Activity>[
      Activity(
        id: 'act_status_1',
        workspaceId: workspaceId,
        type: ActivityType.statusChanged,
        actorId: 'usr_priya',
        createdAt: at(-1, 14),
        taskId: 'tsk_mobile_nav',
        projectId: 'prj_mobile',
        from: 'inProgress',
        to: 'review',
      ),
      Activity(
        id: 'act_priority_1',
        workspaceId: workspaceId,
        type: ActivityType.priorityChanged,
        actorId: demoUserId,
        createdAt: at(-2, 10),
        taskId: 'tsk_ios_crash',
        projectId: 'prj_mobile',
        from: 'high',
        to: 'urgent',
      ),
      Activity(
        id: 'act_assign_1',
        workspaceId: workspaceId,
        type: ActivityType.assigneeChanged,
        actorId: 'usr_priya',
        createdAt: at(-1, 16),
        taskId: 'tsk_docs',
        projectId: 'prj_launch',
        to: 'Jordan Avery',
      ),
      Activity(
        id: 'act_due_1',
        workspaceId: workspaceId,
        type: ActivityType.dueDateChanged,
        actorId: demoUserId,
        createdAt: at(-3, 9),
        taskId: 'tsk_pricing_page',
        projectId: 'prj_launch',
        to: 'in 5 days',
      ),
      Activity(
        id: 'act_member_1',
        workspaceId: workspaceId,
        type: ActivityType.memberJoined,
        actorId: 'usr_grace',
        createdAt: at(-24, 11),
      ),
    ]);

    activities.sort(
      (Activity a, Activity b) => b.createdAt.compareTo(a.createdAt),
    );
    return activities;
  }

  /// Two weeks of focus sessions with a believable weekday rhythm — busier
  /// midweek, quiet at the weekend.
  static List<FocusSession> _focusSessions(DateTime Function(int, int) at) {
    final Random random = Random(7);
    final List<FocusSession> sessions = <FocusSession>[];
    const List<String> taskIds = <String>[
      'tsk_onboarding',
      'tsk_offline',
      'tsk_activation',
      'tsk_pricing_page',
      'tsk_mobile_nav',
    ];

    for (int dayOffset = -13; dayOffset <= 0; dayOffset++) {
      final DateTime day = at(dayOffset, 10);
      final bool weekend =
          day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
      final int rounds = weekend ? random.nextInt(2) : 2 + random.nextInt(4);
      for (int round = 0; round < rounds; round++) {
        sessions.add(
          FocusSession(
            id: 'fcs_${dayOffset}_$round',
            workspaceId: workspaceId,
            phase: FocusPhase.focus,
            taskId: taskIds[random.nextInt(taskIds.length)],
            startedAt: at(dayOffset, 9 + round * 2),
            plannedMinutes: 25,
            actualMinutes: 25 - random.nextInt(4),
            wasCompleted: random.nextInt(10) > 1,
          ),
        );
      }
    }
    return sessions;
  }
}
