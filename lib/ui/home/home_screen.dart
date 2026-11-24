import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../dispute/submit_dispute_screen.dart';
import '../shared/guest_menu.dart';
import '../shared/scam_shield_brand_badge.dart';
import '../shared/user_app_bar.dart';
import '../shared/user_bottom_nav.dart';
import '../shared/user_sidebar_drawer.dart';
import 'home_intro.dart';
import 'scam_check_card.dart';
import 'scam_warnings.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onSignOut});

  final VoidCallback? onSignOut;

  void _openLogin(BuildContext context) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _openSubmitDispute(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const SubmitDisputeScreen()),
    );
  }

  void _showComingSoon(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Tính năng "$featureName" trên di động đang được phát triển.',
          ),
        ),
      );
  }

  Future<void> _handleSignOut(BuildContext context, AuthState authState) async {
    await authState.signOut();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Đã đăng xuất.')));
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState?>();
    final user = authState?.user;
    final isRegisteredUser =
        user != null && user.role.toUpperCase() == 'REGISTERED_USER';
    final VoidCallback? effectiveSignOut =
        onSignOut ??
        (authState != null && authState.isAuthenticated
            ? () => _handleSignOut(context, authState)
            : null);

    return Scaffold(
      drawer: isRegisteredUser
          ? UserSidebarDrawer(
              activeDestination: UserSidebarDestination.scamCheck,
              unreadNotificationCount: 3,
              onSignOut: effectiveSignOut,
              onSelectDestination: (destination) {
                if (destination == UserSidebarDestination.dispute) {
                  _openSubmitDispute(context);
                } else if (destination != UserSidebarDestination.scamCheck) {
                  _showComingSoon(context, destination.title);
                }
              },
            )
          : GuestMenu(
              user: user,
              onLogin: () => _openLogin(context),
              onSignOut: effectiveSignOut,
            ),
      appBar: isRegisteredUser
          ? UserAppBar(
              user: user,
              unreadNotificationCount: 3,
              onNotificationsTap: () => _showComingSoon(context, 'Thông Báo'),
            )
          : AppBar(
              titleSpacing: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  tooltip: 'Mở menu',
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: const ScamShieldBrandBadge(),
              actions: [
                if (user != null)
                  Builder(
                    builder: (context) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: IconButton(
                        tooltip: user.displayName,
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.navy,
                          foregroundColor: AppTheme.shieldBlue,
                          child: Text(
                            user.displayName.isNotEmpty
                                ? user.displayName.characters.first
                                      .toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontFamily: 'sans-serif',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton.icon(
                      key: const ValueKey('home_login_action'),
                      onPressed: () => _openLogin(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.navy,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 36),
                      ),
                      icon: const Icon(Icons.login, size: 17),
                      label: const Text(
                        'Đăng nhập',
                        style: TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 26, 16, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (user != null) ...[
                    Card(
                      margin: const EdgeInsets.only(bottom: 18),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.muted,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.verified_user_outlined,
                                color: AppTheme.blue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Xin chào, ${user.displayName}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'sans-serif',
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.ink,
                                    ),
                                  ),
                                  Text(
                                    user.roleLabel,
                                    style: const TextStyle(
                                      fontFamily: 'sans-serif',
                                      fontSize: 12,
                                      color: AppTheme.mutedInk,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isRegisteredUser)
                              TextButton.icon(
                                key: const ValueKey('home_open_dispute_action'),
                                onPressed: () => _openSubmitDispute(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.navy,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.gavel_outlined,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Khiếu nại',
                                  style: TextStyle(
                                    fontFamily: 'sans-serif',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const HomeIntro(),
                  const SizedBox(height: 24),
                  const ScamCheckCard(),
                  const SizedBox(height: 28),
                  const ScamWarnings(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: isRegisteredUser
          ? UserBottomNav(
              activeTab: UserBottomNavTab.check,
              hasNewsDot: true,
              onSelectTab: (tab) {
                if (tab == UserBottomNavTab.check) {
                  return;
                }
                final label = switch (tab) {
                  UserBottomNavTab.check => 'Kiểm tra',
                  UserBottomNavTab.history => 'Lịch sử',
                  UserBottomNavTab.report => 'Gửi báo cáo mới',
                  UserBottomNavTab.news => 'Tin tức & Thông báo',
                  UserBottomNavTab.account => 'Tài khoản',
                };
                _showComingSoon(context, label);
              },
            )
          : null,
    );
  }
}
