import 'package:flutter/material.dart';

import '../education/education_screen.dart';
import '../resources/resource_screen.dart';
import 'scamshield_header.dart';
import 'scamshield_navigation.dart';

enum _GuestDestination {
  history('Lịch sử kiểm tra', Icons.history),
  myReports('Báo cáo của tôi', Icons.folder_shared_outlined),
  myAppeals('Khiếu nại của tôi', Icons.gavel_outlined);

  const _GuestDestination(this.title, this.icon);

  final String title;
  final IconData icon;
}

class GuestMenu extends StatelessWidget {
  const GuestMenu({
    super.key,
    this.onSignOut,
    this.onLightModeChanged,
    this.isEducationOpen = false,
    this.isResourcesOpen = false,
  });

  /// Supplied only while an authenticated session is active.
  final VoidCallback? onSignOut;
  final ValueChanged<bool>? onLightModeChanged;
  final bool isEducationOpen;
  final bool isResourcesOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLight = colors.brightness == Brightness.light;
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
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF194984)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                leading: const _MenuIcon(
                  icon: Icons.verified_user_outlined,
                  background: Color(0x263BAEFF),
                  foreground: Color(0xFF89CEFF),
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
                  ListTile(
                    leading: const _MenuIcon(icon: Icons.manage_search_rounded),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                    title: const Text('Tra cứu tài nguyên'),
                    selected: isResourcesOpen,
                    onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      if (isResourcesOpen) return;
                      final route = MaterialPageRoute<void>(
                        builder: (_) => ResourceScreen(
                          onSignOut: onSignOut,
                          onLightModeChanged: onLightModeChanged,
                        ),
                      );
                      if (isEducationOpen) {
                        navigator.pushReplacement(route);
                      } else {
                        navigator.push(route);
                      }
                    },
                  ),
                  ListTile(
                    leading: const _MenuIcon(icon: Icons.menu_book_outlined),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                    title: const Text('Cẩm nang an toàn'),
                    selected: isEducationOpen,
                    onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      if (isEducationOpen) return;
                      final route = MaterialPageRoute<void>(
                        builder: (_) => EducationScreen(
                          onSignOut: onSignOut,
                          onLightModeChanged: onLightModeChanged,
                        ),
                      );
                      if (isResourcesOpen) {
                        navigator.pushReplacement(route);
                      } else {
                        navigator.push(route);
                      }
                    },
                  ),
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
            const SizedBox(height: 14),
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
              FilledButton.icon(
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Đăng nhập'),
                onPressed: () => _openAccountInfo(context, 'Đăng nhập'),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                icon: const Icon(Icons.person_add_alt_outlined, size: 18),
                label: const Text('Tạo tài khoản miễn phí'),
                onPressed: () =>
                    _openAccountInfo(context, 'Tạo tài khoản miễn phí'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openAccountInfo(BuildContext context, String title) {
    _openSection(context, title, const [
      (
        'Chưa kết nối tài khoản',
        'Ứng dụng di động chưa kết nối dịch vụ tài khoản. Bạn vẫn có thể sử dụng chế độ khách.',
      ),
    ]);
  }

  void _openSection(
    BuildContext context,
    String title,
    List<(String, String)> cards,
  ) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => _SectionPage(
          title: title,
          cards: cards,
          onSignOut: onSignOut,
          onLightModeChanged: onLightModeChanged,
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
