import 'package:flutter/material.dart';
import 'package:kairo/core/extensions/context_extensions.dart';
import 'package:kairo/core/theme/app_icons.dart';
import 'package:kairo/core/theme/design_tokens.dart';
import 'package:kairo/domain/entities/user.dart';

/// A person, drawn as initials on their own accent colour.
///
/// Initials rather than remote images by default: the demo works offline, no
/// avatar service is required, and every workspace member is instantly
/// distinguishable by colour. A remote [User.avatarUrl] is honoured when set.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.user,
    this.size = 28,
    this.showTooltip = true,
    this.borderColor,
    super.key,
  });

  /// Placeholder used where a task has no assignee.
  const AppAvatar.unassigned({
    this.size = 28,
    this.showTooltip = true,
    this.borderColor,
    super.key,
  }) : user = null;

  final User? user;
  final double size;
  final bool showTooltip;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final User? person = user;

    if (person == null) {
      final Widget placeholder = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          shape: BoxShape.circle,
          border: Border.all(color: colors.hairline),
        ),
        child: Icon(
          AppIcons.assignee,
          size: size * 0.5,
          color: colors.inkFaint,
        ),
      );
      return showTooltip
          ? Tooltip(message: context.l10n.fieldUnassigned, child: placeholder)
          : placeholder;
    }

    final Color accent = person.accentColorValue == null
        ? colors.brand
        : Color(person.accentColorValue!);

    final Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.lerp(accent, Colors.white, 0.18)!,
            Color.lerp(accent, Colors.black, 0.14)!,
          ],
        ),
        shape: BoxShape.circle,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 2),
        image: person.avatarUrl == null
            ? null
            : DecorationImage(
                image: NetworkImage(person.avatarUrl!),
                fit: BoxFit.cover,
              ),
      ),
      alignment: Alignment.center,
      child: person.avatarUrl != null
          ? null
          : Text(
              person.initials,
              style: TextStyle(
                fontSize: size * 0.38,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: Colors.white,
                height: 1,
              ),
            ),
    );

    return Semantics(
      label: person.name,
      image: true,
      child: showTooltip
          ? Tooltip(
              message: person.jobTitle.isEmpty
                  ? person.name
                  : '${person.name} · ${person.jobTitle}',
              child: avatar,
            )
          : avatar,
    );
  }
}

/// Overlapping avatars with an overflow count. Used on project cards and the
/// workspace members row.
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    required this.users,
    this.size = 26,
    this.maxVisible = 4,
    super.key,
  });

  final List<User> users;
  final double size;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final List<User> visible = users.take(maxVisible).toList();
    final int overflow = users.length - visible.length;
    final double overlap = size * 0.32;

    return SizedBox(
      height: size,
      width: visible.isEmpty
          ? 0
          : size +
                (visible.length - 1 + (overflow > 0 ? 1 : 0)) *
                    (size - overlap),
      child: Stack(
        children: <Widget>[
          for (int i = 0; i < visible.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: AppAvatar(
                user: visible[i],
                size: size,
                borderColor: colors.surface,
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: visible.length * (size - overlap),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: colors.surfaceSunken,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$overflow',
                  style: TextStyle(
                    fontSize: size * 0.32,
                    fontWeight: FontWeight.w700,
                    color: colors.inkMuted,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A workspace or project mark: the emoji on its own tinted square.
class EmojiTile extends StatelessWidget {
  const EmojiTile({
    required this.emoji,
    required this.colorValue,
    this.size = 34,
    this.radius = Radii.md,
    super.key,
  });

  final String emoji;
  final int colorValue;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final Color color = Color(colorValue);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.colors.isDark ? 0.20 : 0.13),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: size * 0.46, height: 1)),
    );
  }
}
