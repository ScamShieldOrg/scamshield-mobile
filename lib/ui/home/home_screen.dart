import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/auth_state.dart';
import '../auth/login_screen.dart';
import '../shared/guest_menu.dart';
import '../shared/scamshield_header.dart';
import '../shared/scamshield_navigation.dart';
import 'home_intro.dart';
import 'scam_check_card.dart';
import 'scam_warnings.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onSignOut, this.onLightModeChanged});

  final VoidCallback? onSignOut;
  final ValueChanged<bool>? onLightModeChanged;

  void _openLogin(BuildContext context) {
    Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const LoginScreen()));
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
    final VoidCallback? effectiveSignOut =
        onSignOut ??
        (authState != null && authState.isAuthenticated
            ? () => _handleSignOut(context, authState)
            : null);

    return Scaffold(
      appBar: const ScamShieldHeader(),
      endDrawer: GuestMenu(
        user: user,
        onLogin: () => _openLogin(context),
        onSignOut: effectiveSignOut,
        onLightModeChanged: onLightModeChanged,
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
      bottomNavigationBar: ScamShieldNavigation(
        selected: ScamShieldTab.check,
        onSignOut: effectiveSignOut,
        onLightModeChanged: onLightModeChanged,
      ),
    );
  }
}
