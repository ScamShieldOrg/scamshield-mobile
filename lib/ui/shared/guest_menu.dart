import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/auth_user.dart';
import 'scam_shield_brand_badge.dart';

enum _GuestDestination {
  history('Lịch Sử Kiểm Tra', Icons.history),
  myReports('Báo Cáo Của Tôi', Icons.folder_shared_outlined),
  myAppeals('Khiếu nại của tôi', Icons.gavel_outlined);

  const _GuestDestination(this.title, this.icon);

  final String title;
  final IconData icon;
}

class GuestMenu extends StatelessWidget {
  const GuestMenu({
    super.key,
    this.user,
    this.onLogin,
    this.onSignOut,
  });

  /// Supplied when an authenticated session is active.
  final AuthUser? user;

  /// Invoked when the user chooses to sign in from the drawer.
  final VoidCallback? onLogin;

  /// Supplied only while an authenticated session is active.
  final VoidCallback? onSignOut;
  final ValueChanged<bool>? onLightModeChanged;

  @override
  Widget build(BuildContext context) {
    final currentUser = user;
    final secondaryIdentity = currentUser?.email?.isNotEmpty == true
        ? currentUser!.email!
        : currentUser?.phoneNumber;

    return Drawer(
      width: 292,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
      ),
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ScamShieldBrandBadge(),
            ),
            const SizedBox(height: 8),
            const Divider(),
            for (final destination in _GuestDestination.values)
              ListTile(
                leading: Icon(destination.icon),
                title: Text(destination.title),
                selected: destination == _GuestDestination.check,
                selectedColor: Colors.white,
                selectedTileColor: AppTheme.navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: const Text(
                  'ScamShield',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                trailing: IconButton(
                  tooltip: 'Đóng menu',
                  color: Colors.white,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: colors.surfaceContainerLow,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final destination in _GuestDestination.values)
                    ListTile(
                      leading: _MenuIcon(icon: destination.icon),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                      ),
                      title: Text(destination.title),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () =>
                          _openSection(context, destination.title, const [
                            (
                              'Tính năng đang được chuẩn bị',
                              'Mục này chưa khả dụng trên ứng dụng di động.',
                            ),
                          ]),
                    ),
                  ListTile(
                    leading: const _MenuIcon(
                      icon: Icons.person_outline_rounded,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                    title: const Text('Tài khoản'),
                    onTap: () => _openAccountInfo(context, 'Tài khoản'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: colors.surfaceContainerLow,
              child: SwitchListTile(
                secondary: _MenuIcon(
                  icon: isLight
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
                title: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isLight ? 'Chế độ sáng' : 'Chế độ tối',
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ),
                value: isLight,
                onChanged: onLightModeChanged,
              ),
            ),
            if (currentUser != null) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.page,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUser.displayName,
                      style: const TextStyle(
                        fontFamily: 'sans-serif',
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    if (secondaryIdentity != null &&
                        secondaryIdentity != currentUser.displayName) ...[
                      const SizedBox(height: 2),
                      Text(
                        secondaryIdentity,
                        style: const TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 12.5,
                          color: AppTheme.mutedInk,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.muted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        currentUser.roleLabel,
                        style: const TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (onSignOut case final signOut?)
              ListTile(
                textColor: colors.error,
                iconColor: colors.error,
                leading: const Icon(Icons.logout),
                title: const Text('Đăng xuất'),
                onTap: () {
                  Navigator.of(context).pop();
                  signOut();
                },
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Đăng nhập'),
                onTap: () {
                  Navigator.of(context).pop();
                  if (onLogin != null) {
                    onLogin!();
                  } else {
                    _openAccountInfo(context, 'Đăng nhập');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add_alt_outlined),
                title: const Text('Tạo tài khoản miễn phí'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openAccountInfo(context, 'Tạo tài khoản miễn phí');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openAccountInfo(BuildContext context, String title) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _SectionPage(
          title: title,
          cards: const [
            (
              'Tính năng đang phát triển',
              'Màn hình tạo tài khoản trên di động đang được hoàn thiện. Bạn có thể đăng nhập bằng tài khoản đã có hoặc dùng chế độ khách.',
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuIcon extends StatelessWidget {
  const _MenuIcon({required this.icon, this.background, this.foreground});

  final IconData icon;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: background ?? colors.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 19,
        color: foreground ?? colors.onSecondaryContainer,
      ),
    );
  }
}

class _SectionPage extends StatelessWidget {
  const _SectionPage({
    required this.title,
    required this.cards,
    this.onSignOut,
    this.onLightModeChanged,
  });

  final String title;
  final List<(String, String)> cards;
  final VoidCallback? onSignOut;
  final ValueChanged<bool>? onLightModeChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScamShieldHeader(),
      endDrawer: GuestMenu(
        onSignOut: onSignOut,
        onLightModeChanged: onLightModeChanged,
      ),
      bottomNavigationBar: ScamShieldNavigation(
        selected: ScamShieldTab.menu,
        onSignOut: onSignOut,
        onLightModeChanged: onLightModeChanged,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            for (final (heading, description) in cards)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    heading,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(description),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
