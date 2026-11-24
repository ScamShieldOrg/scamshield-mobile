import 'package:flutter/material.dart';

import '../shared/scamshield_header.dart';
import '../shared/guest_menu.dart';
import '../shared/scamshield_navigation.dart';
import 'home_intro.dart';
import 'scam_check_card.dart';
import 'scam_warnings.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onSignOut, this.onLightModeChanged});

  final VoidCallback? onSignOut;
  final ValueChanged<bool>? onLightModeChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: GuestMenu(
        onSignOut: onSignOut,
        onLightModeChanged: onLightModeChanged,
      ),
      appBar: const ScamShieldHeader(),
      bottomNavigationBar: ScamShieldNavigation(
        selected: ScamShieldTab.check,
        onSignOut: onSignOut,
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
    );
  }
}
