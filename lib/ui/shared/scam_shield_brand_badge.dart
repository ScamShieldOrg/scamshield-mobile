import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ScamShieldBrandBadge extends StatelessWidget {
  const ScamShieldBrandBadge({
    super.key,
    this.darkSurface = false,
    this.showSubtitle = false,
  });

  final bool darkSurface;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    final tileColor = darkSurface
        ? Colors.white.withValues(alpha: 0.12)
        : AppTheme.navy;
    final iconColor = darkSurface ? Colors.white : AppTheme.shieldBlue;
    final titleColor = darkSurface ? Colors.white : AppTheme.ink;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            darkSurface ? Icons.verified_user_outlined : Icons.shield_outlined,
            color: iconColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      darkSurface ? 'ScamShield' : 'ScamShield VN',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: darkSurface ? 18 : 19,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                  ),
                  if (darkSurface) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'VN',
                        style: TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (showSubtitle) ...[
                const SizedBox(height: 2),
                Text(
                  'AI THREAT VERIFICATION • VIETNAM',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.white.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
