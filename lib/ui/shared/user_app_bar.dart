import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/auth_user.dart';

class UserAppBar extends StatelessWidget implements PreferredSizeWidget {
  const UserAppBar({
    super.key,
    this.user,
    this.unreadNotificationCount = 0,
    this.onNotificationsTap,
    this.onProfileTap,
  });

  final AuthUser? user;
  final int unreadNotificationCount;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leadingWidth: 64,
      leading: Builder(
        builder: (context) => Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: Material(
              color: AppTheme.muted,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                key: const ValueKey('user_menu_button'),
                borderRadius: BorderRadius.circular(10),
                onTap: () => Scaffold.of(context).openDrawer(),
                child: const Icon(
                  Icons.menu_rounded,
                  color: AppTheme.ink,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, color: AppTheme.navy, size: 22),
          SizedBox(width: 7),
          Flexible(
            child: Text(
              'ScamShield',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Thông báo',
              onPressed: onNotificationsTap,
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: AppTheme.ink,
                size: 24,
              ),
            ),
            if (unreadNotificationCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unreadNotificationCount > 99
                          ? '99+'
                          : '$unreadNotificationCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 14, left: 2),
          child: Builder(
            builder: (context) => InkWell(
              customBorder: const CircleBorder(),
              onTap: onProfileTap ?? () => Scaffold.of(context).openDrawer(),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: AppTheme.navy,
                foregroundColor: Colors.white,
                child: user != null && user!.displayName.isNotEmpty
                    ? Text(
                        user!.displayName.characters.first.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : const Icon(Icons.person_outline, size: 19),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
