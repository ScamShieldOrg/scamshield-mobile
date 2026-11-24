import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum UserSidebarDestination {
  scamCheck('Kiểm Tra Lừa Đảo', Icons.verified_user_outlined),
  checkHistory('Lịch Sử Kiểm Tra', Icons.history_rounded),
  submitReport('Gửi Báo Cáo Mới', Icons.report_outlined),
  myReports('Báo Cáo Của Tôi', Icons.folder_shared_outlined),
  dispute('Khiếu Nại Chỉ Số', Icons.gavel_outlined),
  notifications('Thông Báo', Icons.notifications_none_rounded),
  rewards('Huy Hiệu & Đổi Thưởng', Icons.military_tech_outlined);

  const UserSidebarDestination(this.title, this.icon);

  final String title;
  final IconData icon;
}

class UserSidebarDrawer extends StatelessWidget {
  const UserSidebarDrawer({
    super.key,
    required this.activeDestination,
    required this.onSelectDestination,
    this.unreadNotificationCount = 0,
    this.showNewReportDot = true,
    this.isLightMode = true,
    this.onLightModeChanged,
    this.onSignOut,
  });

  final UserSidebarDestination activeDestination;
  final ValueChanged<UserSidebarDestination> onSelectDestination;
  final int unreadNotificationCount;
  final bool showNewReportDot;
  final bool isLightMode;
  final ValueChanged<bool>? onLightModeChanged;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: AppTheme.navy,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'ScamShield VN',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng menu',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.ink,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                children: [
                  for (final destination in UserSidebarDestination.values)
                    _buildNavItem(context, destination),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Divider(height: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.wb_sunny_outlined,
                          size: 20,
                          color: AppTheme.mutedInk,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Chế độ sáng',
                            style: TextStyle(
                              fontFamily: 'sans-serif',
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.mutedInk,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: isLightMode,
                          activeTrackColor: AppTheme.muted,
                          onChanged: onLightModeChanged,
                        ),
                      ],
                    ),
                  ),
                  if (onSignOut != null)
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      leading: const Icon(
                        Icons.logout_rounded,
                        size: 20,
                        color: AppTheme.error,
                      ),
                      title: const Text(
                        'Đăng xuất an toàn',
                        style: TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.error,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        onSignOut!();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    UserSidebarDestination destination,
  ) {
    final selected = destination == activeDestination;
    Widget? trailing;

    if (destination == UserSidebarDestination.submitReport &&
        showNewReportDot) {
      trailing = Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppTheme.error,
          shape: BoxShape.circle,
        ),
      );
    } else if (destination == UserSidebarDestination.notifications &&
        unreadNotificationCount > 0) {
      trailing = Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          unreadNotificationCount > 99 ? '99+' : '$unreadNotificationCount',
          style: const TextStyle(
            fontFamily: 'sans-serif',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        selected: selected,
        selectedTileColor: AppTheme.muted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Icon(
          destination.icon,
          size: 20,
          color: selected ? AppTheme.navy : AppTheme.mutedInk,
        ),
        title: Text(
          destination.title,
          style: TextStyle(
            fontFamily: 'sans-serif',
            fontSize: 14.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppTheme.ink : AppTheme.mutedInk,
          ),
        ),
        trailing: trailing,
        onTap: () {
          Navigator.of(context).pop();
          onSelectDestination(destination);
        },
      ),
    );
  }
}
