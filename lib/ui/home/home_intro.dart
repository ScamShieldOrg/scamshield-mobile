import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class HomeIntro extends StatelessWidget {
  const HomeIntro({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.muted,
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 15, color: Color(0xFFF59E0B)),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Phân tích nội dung & Xác minh nguồn tin đáng ngờ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Kiểm tra trước khi tin tưởng\nBảo vệ bạn khỏi lừa đảo số',
          textAlign: TextAlign.center,
          style: text.headlineMedium?.copyWith(
            color: AppTheme.navy,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
            height: 1.19,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Kiểm tra tin nhắn SMS, liên kết website lạ hoặc số điện thoại khả nghi.',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(
            color: AppTheme.mutedInk,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
