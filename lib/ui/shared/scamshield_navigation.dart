import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/auth_state.dart';
import '../auth/login_screen.dart';
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
        if (tab == selected) return;

        final confirm = confirmTabChange;
        if (confirm != null && (!await confirm() || !context.mounted)) return;

        final navigator = Navigator.of(context);
        if (tab == ScamShieldTab.check) {
          navigator.popUntil((route) => route.isFirst);
          return;
        }
        String? reportToken;
        if (tab == ScamShieldTab.report) {
          reportToken = context.read<AuthState?>()?.session?.accessToken;
          if (reportToken == null || reportToken.isEmpty) {
            final proceed = await showReportLoginPrompt(context);
            if (proceed != true || !context.mounted) return;
            final loggedIn = await navigator.push<bool>(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
            if (loggedIn != true || !navigator.mounted) return;
            reportToken = navigator.context
                .read<AuthState?>()
                ?.session
                ?.accessToken;
            if (reportToken == null || reportToken.isEmpty) return;
          }
        }
        final route = MaterialPageRoute<void>(
          builder: (_) => reportToken != null
              ? ReportScreen(
                  accessToken: reportToken,
                  onSignOut: onSignOut,
                  onLightModeChanged: onLightModeChanged,
                )
              : _TabPage(
                  tab: tab,
                  onSignOut: onSignOut,
                  onLightModeChanged: onLightModeChanged,
                ),
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
    final title = tab == ScamShieldTab.appeal
        ? 'Gửi Khiếu Nại'
        : 'Huy Hiệu & Đổi Thưởng';
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
