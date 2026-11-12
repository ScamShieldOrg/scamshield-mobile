import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../shared/guest_menu.dart';
import 'home_intro.dart';
import 'scam_check_card.dart';
import 'scam_warnings.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onSignOut});

  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GuestMenu(onSignOut: onSignOut),
      appBar: AppBar(
        titleSpacing: 0,
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Mở menu',
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.navy,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: AppTheme.shieldBlue,
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'ScamShield VN',
                style: TextStyle(
                  fontFamily: 'sans-serif',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
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
