import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The product's icon vocabulary.
///
/// One family (Lucide) and one indirection: features reference *meaning*
/// (`AppIcons.overdue`) rather than a glyph name, so an icon can be swapped
/// once here and change everywhere it carries that meaning. It also makes it
/// impossible for two screens to use different icons for the same concept.
abstract final class AppIcons {
  // Navigation
  static const IconData dashboard = LucideIcons.layoutDashboard;
  static const IconData tasks = LucideIcons.listTodo;
  static const IconData inbox = LucideIcons.inbox;
  static const IconData projects = LucideIcons.folderKanban;
  static const IconData calendar = LucideIcons.calendarDays;
  static const IconData timeline = LucideIcons.chartGantt;
  static const IconData focus = LucideIcons.timer;
  static const IconData analytics = LucideIcons.chartColumn;
  static const IconData favorites = LucideIcons.star;
  static const IconData archive = LucideIcons.archive;
  static const IconData settings = LucideIcons.settings;
  static const IconData search = LucideIcons.search;
  static const IconData notifications = LucideIcons.bell;
  static const IconData notificationsOff = LucideIcons.bellOff;
  static const IconData home = LucideIcons.house;

  // Task workflow
  static const IconData statusBacklog = LucideIcons.circleDashed;
  static const IconData statusTodo = LucideIcons.circle;
  static const IconData statusInProgress = LucideIcons.circleDot;
  static const IconData statusReview = LucideIcons.eye;
  static const IconData statusDone = LucideIcons.circleCheck;
  static const IconData complete = LucideIcons.circleCheckBig;
  static const IconData checkAll = LucideIcons.checkCheck;
  static const IconData check = LucideIcons.check;

  // Priority — each level gets a distinct *shape*, not only a colour, so the
  // information survives greyscale and colour-blindness.
  static const IconData priorityUrgent = LucideIcons.flame;
  static const IconData priorityHigh = LucideIcons.arrowUp;
  static const IconData priorityMedium = LucideIcons.flag;
  static const IconData priorityLow = LucideIcons.arrowDown;

  // Metadata
  static const IconData assignee = LucideIcons.user;
  static const IconData members = LucideIcons.users;
  static const IconData invite = LucideIcons.userPlus;
  static const IconData label = LucideIcons.tag;
  static const IconData labels = LucideIcons.tags;
  static const IconData dueDate = LucideIcons.calendar;
  static const IconData estimate = LucideIcons.clock;
  static const IconData recurrence = LucideIcons.repeat;
  static const IconData dependency = LucideIcons.workflow;
  static const IconData blockedBy = LucideIcons.gitBranch;
  static const IconData milestone = LucideIcons.milestone;
  static const IconData subtasks = LucideIcons.clipboardList;
  static const IconData attachment = LucideIcons.paperclip;
  static const IconData comment = LucideIcons.messageSquare;
  static const IconData activity = LucideIcons.workflow;
  static const IconData workflow = LucideIcons.workflow;
  static const IconData overdue = LucideIcons.triangleAlert;
  static const IconData project = LucideIcons.folderKanban;

  // Actions
  static const IconData add = LucideIcons.plus;
  static const IconData edit = LucideIcons.pencil;
  static const IconData delete = LucideIcons.trash2;
  static const IconData duplicate = LucideIcons.copy;
  static const IconData copyLink = LucideIcons.link2;
  static const IconData close = LucideIcons.x;
  static const IconData more = LucideIcons.ellipsis;
  static const IconData moreVertical = LucideIcons.ellipsisVertical;
  static const IconData filter = LucideIcons.listFilter;
  static const IconData sort = LucideIcons.arrowUpDown;
  static const IconData group = LucideIcons.filter;
  static const IconData drag = LucideIcons.gripVertical;
  static const IconData retry = LucideIcons.refreshCw;
  static const IconData download = LucideIcons.download;
  static const IconData upload = LucideIcons.upload;
  static const IconData signOut = LucideIcons.logOut;

  // Direction
  static const IconData chevronRight = LucideIcons.chevronRight;
  static const IconData chevronLeft = LucideIcons.chevronLeft;
  static const IconData chevronDown = LucideIcons.chevronDown;
  static const IconData chevronUp = LucideIcons.chevronUp;
  static const IconData arrowRight = LucideIcons.arrowRight;
  static const IconData arrowLeft = LucideIcons.arrowLeft;
  static const IconData enterKey = LucideIcons.cornerDownLeft;

  // Views
  static const IconData viewList = LucideIcons.listTodo;
  static const IconData viewBoard = LucideIcons.folderKanban;
  static const IconData viewCalendar = LucideIcons.calendarDays;
  static const IconData viewTimeline = LucideIcons.chartGantt;
  static const IconData sidebar = LucideIcons.panelLeft;
  static const IconData sidebarClose = LucideIcons.panelLeftClose;

  // Theme
  static const IconData themeLight = LucideIcons.sunMedium;
  static const IconData themeDark = LucideIcons.moon;
  static const IconData themeSystem = LucideIcons.monitor;
  static const IconData appearance = LucideIcons.palette;

  // Focus mode
  static const IconData play = LucideIcons.play;
  static const IconData pause = LucideIcons.pause;
  static const IconData stop = LucideIcons.square;
  static const IconData skip = LucideIcons.skipForward;
  static const IconData ambience = LucideIcons.volume2;

  // Feedback and status
  static const IconData success = LucideIcons.circleCheck;
  static const IconData error = LucideIcons.circleAlert;
  static const IconData warning = LucideIcons.triangleAlert;
  static const IconData info = LucideIcons.circleAlert;
  static const IconData offline = LucideIcons.wifiOff;
  static const IconData loading = LucideIcons.loaderCircle;
  static const IconData celebrate = LucideIcons.partyPopper;
  static const IconData reaction = LucideIcons.smile;
  static const IconData like = LucideIcons.thumbsUp;

  // Marketing and settings
  static const IconData brandSpark = LucideIcons.sparkles;
  static const IconData speed = LucideIcons.zap;
  static const IconData target = LucideIcons.target;
  static const IconData launch = LucideIcons.rocket;
  static const IconData command = LucideIcons.command;
  static const IconData security = LucideIcons.shieldCheck;
  static const IconData billing = LucideIcons.creditCard;
  static const IconData docs = LucideIcons.bookOpen;
  static const IconData data = LucideIcons.fileText;
  static const IconData password = LucideIcons.lock;
  static const IconData email = LucideIcons.mail;
  static const IconData reveal = LucideIcons.eye;
  static const IconData conceal = LucideIcons.eyeOff;

  // Rich text editor
  static const IconData bold = LucideIcons.bold;
  static const IconData italic = LucideIcons.italic;
  static const IconData heading = LucideIcons.heading2;
  static const IconData bulletList = LucideIcons.list;
  static const IconData numberedList = LucideIcons.listOrdered;
  static const IconData quote = LucideIcons.quote;
  static const IconData code = LucideIcons.squareCode;
  static const IconData inlineCode = LucideIcons.code;
  static const IconData preview = LucideIcons.type;
  static const IconData undo = LucideIcons.undo2;
}
