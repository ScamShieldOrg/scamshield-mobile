import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum UserBottomNavTab { check, history, report, news, account }

class UserBottomNav extends StatelessWidget {
  const UserBottomNav({
    super.key,
    required this.onSelectTab,
    this.activeTab,
    this.hasNewsDot = true,
  });

  final UserBottomNavTab? activeTab;
  final ValueChanged<UserBottomNavTab> onSelectTab;
  final bool hasNewsDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildItem(
                tab: UserBottomNavTab.check,
                icon: Icons.search_rounded,
                label: 'Kiểm tra',
              ),
              _buildItem(
                tab: UserBottomNavTab.history,
                icon: Icons.history_rounded,
                label: 'Lịch sử',
              ),
              _buildCenterReportButton(),
              _buildItem(
                tab: UserBottomNavTab.news,
                icon: Icons.notifications_none_rounded,
                label: 'Tin tức',
                showDot: hasNewsDot,
              ),
              _buildItem(
                tab: UserBottomNavTab.account,
                icon: Icons.person_outline_rounded,
                label: 'Tài khoản',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem({
    required UserBottomNavTab tab,
    required IconData icon,
    required String label,
    bool showDot = false,
  }) {
    final selected = tab == activeTab;
    final color = selected ? AppTheme.navy : AppTheme.mutedInk;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onSelectTab(tab),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 22, color: color),
                  if (showDot)
                    Positioned(
                      top: -1,
                      right: -2,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'sans-serif',
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterReportButton() {
    final selected = activeTab == UserBottomNavTab.report;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onSelectTab(UserBottomNavTab.report),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: const Offset(0, -10),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.navy,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.navy.withValues(alpha: 0.24),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -5),
              child: Text(
                'Báo cáo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'sans-serif',
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
