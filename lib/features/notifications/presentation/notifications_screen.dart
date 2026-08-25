import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/motion/motion_scope.dart';
import 'package:kairo/core/presentation/enum_presentation.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/core/utils/date_utils.dart';
import 'package:kairo/core/widgets/app_avatar.dart';
import 'package:kairo/core/widgets/app_button.dart';
import 'package:kairo/core/widgets/app_segmented.dart';
import 'package:kairo/core/widgets/app_skeleton.dart';
import 'package:kairo/core/widgets/app_states.dart';
import 'package:kairo/core/widgets/app_surfaces.dart';
import 'package:kairo/domain/entities/collaboration.dart';
import 'package:kairo/domain/entities/user.dart';
import 'package:kairo/features/shell/presentation/app_shell.dart';
import 'package:kairo/l10n/generated/app_localizations.dart';

/// The inbox.
///
/// Grouped by day and filterable to unread. Opening a notification marks it
/// read and navigates to whatever it is about — the two things a notification
/// is for.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _unreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final AppL10n l10n = context.l10n;
    final AsyncValue<List<AppNotification>> async = ref.watch(
      notificationsProvider,
    );
    final int unread = ref.watch(unreadNotificationCountProvider);
    final String? workspaceId = ref.watch(activeWorkspaceIdProvider);

    final List<AppNotification> all = async.value ?? const <AppNotification>[];
    final List<AppNotification> visible = _unreadOnly
        ? all.where((AppNotification n) => !n.isRead).toList(growable: false)
        : all;

    return ShellPage(
      title: l10n.notificationsTitle,
      subtitle: unread == 0
          ? l10n.emptyNotificationsTitle
          : l10n.notificationsUnreadCount(unread),
      padded: false,
      actions: <Widget>[
        if (unread > 0)
          PageAction(
            label: l10n.notificationsMarkAllRead,
            icon: AppIcons.checkAll,
            onPressed: workspaceId == null
                ? null
                : () => ref
                      .read(notificationRepositoryProvider)
                      .markAllRead(workspaceId),
          ),
      ],
      toolbar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.colors.hairline)),
        ),
        child: Row(
          children: <Widget>[
            AppSegmentedControl<bool>(
              value: _unreadOnly,
              dense: true,
              options: <SegmentOption<bool>>[
                SegmentOption<bool>(value: false, label: l10n.notificationsAll),
                SegmentOption<bool>(
                  value: true,
                  label: l10n.notificationsUnread,
                ),
              ],
              onChanged: (bool value) => setState(() => _unreadOnly = value),
            ),
          ],
        ),
      ),
      child: async.isLoading
          ? Padding(
              padding: EdgeInsets.all(context.gutter),
              child: SkeletonList(
                count: 6,
                separator: Spacing.lg,
                itemBuilder: (BuildContext context) => const Row(
                  children: <Widget>[
                    Skeleton.circle(size: 30),
                    SizedBox(width: Spacing.md),
                    Expanded(child: Skeleton(height: 12)),
                  ],
                ),
              ),
            )
          : visible.isEmpty
          ? AppEmptyState(
              icon: AppIcons.notifications,
              title: l10n.emptyNotificationsTitle,
              message: l10n.emptyNotificationsBody,
            )
          : _NotificationList(notifications: visible),
    );
  }
}

class _NotificationList extends ConsumerWidget {
  const _NotificationList({required this.notifications});

  final List<AppNotification> notifications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l10n = context.l10n;
    final Map<String, User> members = ref.watch(membersByIdProvider);

    // Grouped into Today / Yesterday / Earlier — enough structure to scan by,
    // without a header for every single date.
    final Map<String, List<AppNotification>> groups =
        <String, List<AppNotification>>{};
    for (final AppNotification notification in notifications) {
      final String key = Dates.isToday(notification.createdAt)
          ? l10n.notificationsToday
          : (Dates.daysBetween(notification.createdAt, DateTime.now()) == 1
                ? l10n.timeYesterday
                : l10n.notificationsEarlier);
      groups.putIfAbsent(key, () => <AppNotification>[]).add(notification);
    }

    int index = 0;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.gutter,
        Spacing.lg,
        context.gutter,
        Spacing.huge,
      ),
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final MapEntry<String, List<AppNotification>> group
                  in groups.entries) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                    top: Spacing.lg,
                    bottom: Spacing.sm,
                  ),
                  child: AppEyebrow(group.key),
                ),
                for (final AppNotification notification in group.value)
                  _NotificationTile(
                    key: ValueKey<String>(notification.id),
                    notification: notification,
                    actor: notification.actorId == null
                        ? null
                        : members[notification.actorId!],
                    index: index++,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationTile extends ConsumerStatefulWidget {
  const _NotificationTile({
    required this.notification,
    required this.actor,
    required this.index,
    super.key,
  });

  final AppNotification notification;
  final User? actor;
  final int index;

  @override
  ConsumerState<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends ConsumerState<_NotificationTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final AppNotification notification = widget.notification;
    final Color accent = notification.type.color(colors);

    return Entrance(
      index: widget.index,
      offset: 6,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _open,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: context.motion(Motion.fast),
            margin: const EdgeInsets.only(bottom: Spacing.sm),
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: notification.isRead
                  ? (_hovered ? colors.surfaceSunken : colors.surface)
                  : colors.brandSoft,
              borderRadius: Radii.brMd,
              border: Border.all(
                color: notification.isRead
                    ? colors.hairline
                    : colors.brandBorder,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    if (widget.actor != null)
                      AppAvatar(user: widget.actor, size: 32)
                    else
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          notification.type.icon,
                          size: 15,
                          color: accent,
                        ),
                      ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.surface, width: 2),
                        ),
                        child: Icon(
                          notification.type.icon,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        notification.title,
                        style: context.textStyles.titleSmall?.copyWith(
                          fontWeight: notification.isRead
                              ? FontWeight.w600
                              : FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.body,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Dates.relative(notification.createdAt, context.l10n),
                        style: context.textStyles.labelSmall?.copyWith(
                          color: colors.inkFaint,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _hovered
                        ? AppIconButton(
                            icon: AppIcons.check,
                            tooltip: context.l10n.notificationsMarkRead,
                            size: 26,
                            iconSize: 13,
                            onPressed: () => ref
                                .read(notificationRepositoryProvider)
                                .markRead(notification.id),
                          )
                        : Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: colors.brand,
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open() {
    final AppNotification notification = widget.notification;
    if (!notification.isRead) {
      ref.read(notificationRepositoryProvider).markRead(notification.id);
    }
    if (notification.taskId != null) {
      openTaskDetail(context, notification.taskId!);
    }
  }
}
