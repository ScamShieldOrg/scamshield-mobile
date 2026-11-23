import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../shared/scam_shield_brand_badge.dart';

class LoginHeroBanner extends StatelessWidget {
  const LoginHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.navy,
              AppTheme.navyMid,
              AppTheme.navyLight,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -56,
              right: -44,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.shieldBlue.withValues(alpha: 0.14),
                ),
              ),
            ),
            Positioned(
              bottom: -64,
              left: -36,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.blue.withValues(alpha: 0.16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ScamShieldBrandBadge(
                    darkSurface: true,
                    showSubtitle: true,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Cổng Giám Sát An Toàn Số',
                    style: text.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hệ thống bảo vệ chủ động, ngăn chặn lừa đảo trực tuyến.',
                    style: text.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.76),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SecurityFeatureBadge(
                        icon: Icons.verified_user_outlined,
                        iconColor: AppTheme.shieldBlue,
                        label: 'Bảo vệ 24/7',
                      ),
                      _SecurityFeatureBadge(
                        icon: Icons.lock_outline,
                        iconColor: AppTheme.shieldBlue,
                        label: 'Chuẩn Zero-PII',
                      ),
                      _SecurityFeatureBadge(
                        icon: Icons.bolt_rounded,
                        iconColor: AppTheme.accentAmber,
                        label: 'Liên thông xử lý',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityFeatureBadge extends StatelessWidget {
  const _SecurityFeatureBadge({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
