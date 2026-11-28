import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/education_hub.dart';

class EducationScenarioCard extends StatelessWidget {
  const EducationScenarioCard({super.key, required this.scenario});

  final EducationScenario scenario;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final example = scenario.example;
    final displayTag = scenario.tag?.toLowerCase().replaceAllMapped(
      RegExp(r'(^|\s[-–—]\s+)(\S)'),
      (match) => '${match[1]}${match[2]!.toUpperCase()}',
    );
    final badge = switch (scenario.badge?.toLowerCase()) {
      'cực đại' => 'Nguy cơ rất cao',
      'nguy cấp' => 'Nguy cơ cao',
      _ => scenario.badge,
    };
    final accent = switch (scenario.badge?.toLowerCase()) {
      'cực đại' || 'nguy cấp' => colors.error,
      _ => colors.primary,
    };
    final sections = [
      if (scenario.actions.isNotEmpty)
        ('Cách xử lý', Icons.shield_outlined, scenario.actions),
      if (scenario.recognitionSigns.isNotEmpty)
        ('Dấu hiệu nhận biết', Icons.manage_search, scenario.recognitionSigns),
      if (scenario.goal case final goal?)
        ('Mục đích của kẻ lừa đảo', Icons.track_changes, [goal]),
      if (scenario.tips.isNotEmpty)
        ('Mẹo phòng tránh', Icons.lightbulb_outline, scenario.tips),
    ];
    final summary = scenario.summary;
    final title = Text(
      scenario.title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        height: 1.25,
      ),
    );
    final subtitle = summary == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              summary,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (scenario.tag != null || badge != null)
            ColoredBox(
              color: Color.alphaBlend(
                accent.withValues(alpha: .09),
                colors.surface,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (displayTag case final tag?)
                      Text.rich(
                        TextSpan(
                          children: [
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: 17,
                                color: accent,
                              ),
                            ),
                            TextSpan(text: '  $tag'),
                          ],
                        ),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (badge != null)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            badge,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (example?.message == null && sections.isEmpty)
            ListTile(title: title, subtitle: subtitle)
          else
            ExpansionTile(
              title: title,
              subtitle: subtitle,
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              shape: const Border(),
              collapsedShape: const Border(),
              expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              children: [
                if (example != null && example.message != null)
                  _ScenarioExample(example: example, message: example.message!),
                for (final (heading, icon, items) in sections)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: icon == Icons.shield_outlined
                          ? Color.alphaBlend(
                              colors.secondary.withValues(alpha: .12),
                              colors.surface,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              icon,
                              size: 18,
                              color: colors.onSecondaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                heading,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              for (final item in items)
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Text(
                                    items.length == 1 ? item : '• $item',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ScenarioExample extends StatelessWidget {
  const _ScenarioExample({required this.example, required this.message});

  final EducationExample example;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (label, icon) = switch (example.channel) {
      'SMS' => ('Tin nhắn SMS', Icons.sms_outlined),
      'VIDEO' => ('Cuộc gọi video', Icons.videocam_outlined),
      'CALL' => ('Cuộc gọi', Icons.call_outlined),
      'CHAT' => ('Đoạn chat', Icons.chat_bubble_outline),
      _ => ('Ví dụ minh họa', Icons.forum_outlined),
    };
    final highlight = example.highlight;
    final fragments = highlight == null ? [message] : message.split(highlight);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.navy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.shieldBlue.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(icon, size: 18, color: AppTheme.shieldBlue),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    if (example.sender != null || example.time != null)
                      Text(
                        [example.sender, example.time].nonNulls.join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFCFDAED),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  for (final (index, fragment) in fragments.indexed) ...[
                    if (index > 0)
                      TextSpan(
                        text: highlight,
                        style: TextStyle(
                          color: colors.error,
                          backgroundColor: colors.error.withValues(alpha: .10),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    TextSpan(text: fragment),
                  ],
                ],
              ),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
