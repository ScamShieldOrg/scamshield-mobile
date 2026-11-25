import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/user_quota_state.dart';
import '../../core/theme/app_theme.dart';

class AiQuotaBanner extends StatelessWidget {
  const AiQuotaBanner({
    super.key,
    this.usedCount,
    this.maxCount,
  });

  /// Optional explicit overrides; when omitted, reads real quota from [UserQuotaState].
  final int? usedCount;
  final int? maxCount;

  @override
  Widget build(BuildContext context) {
    final quotaState = context.watch<UserQuotaState?>();
    final effectiveUsed = usedCount ?? quotaState?.quota?.used;
    final effectiveMax = maxCount ?? quotaState?.quota?.limit;
    final isLoading =
        usedCount == null &&
        maxCount == null &&
        (quotaState?.isLoading ?? false) &&
        effectiveUsed == null;
    final hasData = effectiveUsed != null && effectiveMax != null;

    double? progress;
    if (isLoading) {
      progress = null;
    } else if (hasData) {
      final safeMax = effectiveMax <= 0 ? 1 : effectiveMax;
      progress = (effectiveUsed.clamp(0, safeMax)) / safeMax;
    } else {
      progress = 0;
    }

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  size: 16,
                  color: AppTheme.blue,
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'Hạn mức tra cứu AI',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isLoading)
                  const Text(
                    'Đang tải...',
                    style: TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mutedInk,
                    ),
                  )
                else if (hasData)
                  Text(
                    'Đã dùng $effectiveUsed/$effectiveMax lượt hôm nay',
                    style: const TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  )
                else
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: quotaState == null ? null : quotaState.refresh,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Chưa tải được',
                          style: TextStyle(
                            fontFamily: 'sans-serif',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.mutedInk,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.refresh_rounded,
                          size: 14,
                          color: AppTheme.blue,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppTheme.muted,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.navy),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
