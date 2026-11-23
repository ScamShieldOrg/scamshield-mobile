import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/auth_user.dart';
import 'scam_shield_brand_badge.dart';

enum _GuestDestination {
  check('Kiểm tra', Icons.manage_search_outlined),
  resources('Tài nguyên', Icons.folder_open_outlined),
  trends('Xu hướng lừa đảo', Icons.trending_up),
  guide('Cẩm nang an toàn', Icons.menu_book_outlined),
  leaderboard('Bảng vinh danh', Icons.emoji_events_outlined);

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

  @override
  Widget build(BuildContext context) {
    final currentUser = user;
    final secondaryIdentity = currentUser?.email?.isNotEmpty == true
        ? currentUser!.email!
        : currentUser?.phoneNumber;

    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                onTap: () {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  if (destination != _GuestDestination.check) {
                    navigator.push<void>(
                      MaterialPageRoute(
                        builder: (_) => _GuestSection(destination: destination),
                      ),
                    );
                  }
                },
              ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Tài khoản',
                style: TextStyle(fontWeight: FontWeight.w700),
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

class _GuestSection extends StatelessWidget {
  const _GuestSection({required this.destination});

  final _GuestDestination destination;

  @override
  Widget build(BuildContext context) {
    final cards = switch (destination) {
      _GuestDestination.resources => const [
        (
          'Danh sách cảnh báo',
          'Danh sách số điện thoại và tên miền đã được báo cáo sẽ xuất hiện khi có dữ liệu tra cứu.',
        ),
      ],
      _GuestDestination.trends => const [
        (
          'Chưa có số liệu xu hướng',
          'Bạn có thể xem các tình huống minh họa trong mục Cảnh báo lừa đảo trên trang Kiểm tra.',
        ),
      ],
      _GuestDestination.guide => const [
        (
          'Kiểm tra người gửi',
          'Khi nhận tin nhắn bất ngờ, hãy xác minh qua ứng dụng hoặc kênh liên hệ chính thức.',
        ),
        (
          'Giữ kín mã xác thực',
          'Chỉ nhập mã OTP vào ứng dụng hoặc trang chính thức khi bạn chủ động thực hiện giao dịch.',
        ),
        (
          'Kiểm tra tên miền',
          'Nếu nghi ngờ một đường dẫn, hãy tự mở trang chính thức thay vì bấm vào liên kết trong tin nhắn.',
        ),
      ],
      _GuestDestination.leaderboard => const [
        (
          'Chưa có dữ liệu bảng vinh danh',
          'Mục này hiển thị những thành viên có đóng góp cho cộng đồng ScamShield.',
        ),
      ],
      _GuestDestination.check => const <(String, String)>[],
    };

    return _SectionPage(title: destination.title, cards: cards);
  }
}

class _SectionPage extends StatelessWidget {
  const _SectionPage({required this.title, required this.cards});

  final String title;
  final List<(String, String)> cards;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
