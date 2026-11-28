import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/auth_state.dart';
import '../auth/login_screen.dart';
import '../dispute/submit_dispute_screen.dart';
import '../report/report_screen.dart';
import 'guest_menu.dart';
import 'scamshield_header.dart';

enum ScamShieldTab { report, appeal, check, rewards, menu }

class ScamShieldNavigation extends StatelessWidget {
  const ScamShieldNavigation({
    super.key,
    required this.selected,
    this.onSignOut,
    this.onLightModeChanged,
    this.confirmTabChange,
  });

  final ScamShieldTab selected;
  final VoidCallback? onSignOut;
  final ValueChanged<bool>? onLightModeChanged;
  final Future<bool> Function()? confirmTabChange;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final navigation = NavigationBar(
      selectedIndex: selected.index,
      onDestinationSelected: (index) async {
        final tab = ScamShieldTab.values[index];
        if (tab == ScamShieldTab.menu) {
          final scaffold = Scaffold.of(context);
          if (scaffold.hasEndDrawer) {
            scaffold.openEndDrawer();
          } else {
            scaffold.openDrawer();
          }
          return;
        }
        final navigator = Navigator.of(context);
        var token = context.read<AuthState?>()?.session?.accessToken;
        final requiresLogin = tab != ScamShieldTab.check;
        if (tab == selected &&
            (!requiresLogin || (token?.isNotEmpty ?? false))) {
          return;
        }

        final confirm = confirmTabChange;
        if (tab != selected &&
            confirm != null &&
            (!await confirm() || !context.mounted)) {
          return;
        }

        if (tab == ScamShieldTab.check) {
          navigator.popUntil((route) => route.isFirst);
          return;
        }

        if (token == null || token.isEmpty) {
          final message = switch (tab) {
            ScamShieldTab.report => 'Vui lòng đăng nhập để gửi báo cáo.',
            ScamShieldTab.appeal => 'Vui lòng đăng nhập để gửi khiếu nại.',
            _ => 'Vui lòng đăng nhập để xem huy hiệu.',
          };
          final proceed = await _showLoginPrompt(context, message);
          if (proceed != true || !context.mounted) return;
          final loggedIn = await navigator.push<bool>(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
          if (loggedIn != true || !context.mounted) return;
          token = context.read<AuthState?>()?.session?.accessToken;
          if (token == null || token.isEmpty) return;
        }
        final reportToken = token;
        final route = MaterialPageRoute<void>(
          builder: (_) => switch (tab) {
            ScamShieldTab.appeal => const SubmitDisputeScreen(),
            ScamShieldTab.report => ReportScreen(
              accessToken: reportToken,
              onSignOut: onSignOut,
              onLightModeChanged: onLightModeChanged,
            ),
            _ => _TabPage(
              tab: tab,
              onSignOut: onSignOut,
              onLightModeChanged: onLightModeChanged,
            ),
          },
        );
        if (selected == ScamShieldTab.check || selected == ScamShieldTab.menu) {
          navigator.popUntil((route) => route.isFirst);
          navigator.push(route);
        } else {
          navigator.pushReplacement(route);
        }
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.note_add_outlined),
          label: 'Báo cáo',
        ),
        const NavigationDestination(
          icon: Icon(Icons.gavel_outlined),
          label: 'Khiếu nại',
        ),
        NavigationDestination(
          icon: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              child: Icon(Icons.policy_outlined, color: colors.onPrimary),
            ),
          ),
          label: 'Kiểm tra\nlừa đảo',
        ),
        const NavigationDestination(
          icon: Icon(Icons.emoji_events_outlined),
          label: 'Huy hiệu',
        ),
        const NavigationDestination(
          icon: Icon(Icons.menu_rounded),
          label: 'Menu',
        ),
      ],
    );
    return DefaultTextStyle.merge(
      textAlign: TextAlign.center,
      child: navigation,
    );
  }
}

class _TabPage extends StatelessWidget {
  const _TabPage({required this.tab, this.onSignOut, this.onLightModeChanged});

  final ScamShieldTab tab;
  final VoidCallback? onSignOut;
  final ValueChanged<bool>? onLightModeChanged;

  @override
  Widget build(BuildContext context) {
    const title = 'Huy Hiệu & Đổi Thưởng';
    return Scaffold(
      appBar: const ScamShieldHeader(),
      endDrawer: GuestMenu(onSignOut: onSignOut),
      bottomNavigationBar: ScamShieldNavigation(
        selected: tab,
        onSignOut: onSignOut,
        onLightModeChanged: onLightModeChanged,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            const Text('Tính năng đang được chuẩn bị.'),
          ],
        ),
      ),
    );
  }
}

Future<bool?> _showLoginPrompt(BuildContext context, String message) =>
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Center(
          child: CircleAvatar(
            radius: 26,
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
            child: const Icon(Icons.verified_user_outlined),
          ),
        ),
        title: const Text(
          'Cần đăng nhập',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text(
                'Đến trang đăng nhập',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
          ],
        ),
      ),
    );
