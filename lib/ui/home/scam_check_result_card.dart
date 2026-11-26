import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/services/scam_check_service.dart';

class ScamCheckResultCard extends StatelessWidget {
  const ScamCheckResultCard({
    super.key,
    required this.result,
    required this.inputLabel,
  });

  final ScamCheckResult result;
  final String inputLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final verdict = result.verdict.trim().toUpperCase();
    final (title, icon, accent) = switch (verdict) {
      'SCAM_RISK' || 'DANGEROUS' => (
        'Nguy cơ lừa đảo cao',
        Icons.gpp_bad_outlined,
        colors.error,
      ),
      'SUSPICIOUS' => (
        'Có dấu hiệu đáng ngờ',
        Icons.warning_amber_rounded,
        theme.brightness == Brightness.dark
            ? Colors.amber.shade300
            : Colors.brown.shade700,
      ),
      'LOW_RISK' ||
      'SAFE' => ('Rủi ro thấp', Icons.verified_user_outlined, colors.primary),
      _ => (
        'Chưa đủ dữ liệu để kết luận',
        Icons.help_outline_rounded,
        colors.onSurfaceVariant,
      ),
    };
    final rawExplanation = result.explanation?.trim() ?? '';
    final technicalSummary =
        RegExp(
          r'độ tự tin|độ tin cậy|đánh giá đa chiều|tỷ lệ đồng thuận|chuyên gia AI|\btier\s*[12]\b|\bthreshold\b|>=|≤|≥',
          caseSensitive: false,
        ).hasMatch(rawExplanation) ||
        rawExplanation.length > 320;
    final explanation = technicalSummary ? '' : rawExplanation;
    final guidance = result.guidance?.trim() ?? '';
    final steps = {
      if (guidance.isNotEmpty && guidance != explanation) guidance,
      ...result.recommendations.where((step) => step != explanation),
      if (technicalSummary &&
          guidance.isEmpty &&
          result.recommendations.isEmpty &&
          verdict == 'UNKNOWN')
        'Hãy kiểm chứng qua kênh chính thức trước khi làm theo yêu cầu trong nội dung này.',
    };
    final score = result.riskScore;
    final scamType = switch (verdict) {
      'SCAM_RISK' ||
      'DANGEROUS' ||
      'SUSPICIOUS' ||
      'SAFE' ||
      'LOW_RISK' => result.scamType,
      _ => null,
    };
    final confidence = result.confidence;
    final technicalDetails = {
      if (technicalSummary) rawExplanation,
      if (result.technicalExplanation case final detail?)
        if (detail.trim().isNotEmpty && detail.trim() != explanation)
          detail.trim(),
      if (confidence != null)
        'Độ tự tin của mô hình · ${(confidence * 100).toStringAsFixed(1)}%',
    };
    final hasEvidence =
        explanation.isNotEmpty || result.urgencyKeywords.isNotEmpty;
    final hasDetails =
        steps.isNotEmpty || hasEvidence || technicalDetails.isNotEmpty;

    final dark = theme.brightness == Brightness.dark;
    final header = switch (verdict) {
      'SCAM_RISK' || 'DANGEROUS' => const Color(0xFFD62732),
      _ => dark ? colors.secondaryContainer : AppTheme.navy,
    };
    final headerAccent = switch (verdict) {
      'SCAM_RISK' || 'DANGEROUS' => const Color(0xFFFFD7D5),
      'SUSPICIOUS' => const Color(0xFFFFD48A),
      'SAFE' || 'LOW_RISK' => AppTheme.shieldBlue,
      _ => const Color(0xFFCFDAED),
    };

    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: header,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: headerAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Kết quả · $inputLabel',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: headerAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.18,
                        ),
                      ),
                      if (scamType != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          scamType,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: headerAccent,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (score != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, hasDetails ? 0 : 16),
                  child: _RiskScore(score: score, accent: accent),
                ),
              if (hasDetails)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (steps.isNotEmpty) ...[
                        _SectionHeading(
                          icon: Icons.shield_outlined,
                          title: 'Bạn nên làm gì?',
                          color: colors.primary,
                        ),
                        const SizedBox(height: 8),
                        for (final step in steps)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: colors.secondary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _ResultText(
                                    text: step,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      if (hasEvidence) ...[
                        if (steps.isNotEmpty) const Divider(height: 20),
                        _SectionHeading(
                          icon: Icons.manage_search,
                          title: result.urgencyKeywords.isEmpty
                              ? 'Vì sao có kết quả này?'
                              : 'Dấu hiệu nhận biết',
                          color: colors.primary,
                        ),
                        if (explanation.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _ResultText(
                            text: explanation,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                        if (result.urgencyKeywords.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Cụm từ tạo cảm giác gấp gáp',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final keyword in result.urgencyKeywords)
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: colors.secondaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
                                    ),
                                    child: Text(
                                      keyword,
                                      style: theme.textTheme.labelMedium,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                      if (technicalDetails.isNotEmpty) ...[
                        if (steps.isNotEmpty || hasEvidence)
                          const Divider(height: 22),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          minTileHeight: 44,
                          childrenPadding: const EdgeInsets.only(top: 4),
                          shape: const Border(),
                          collapsedShape: const Border(),
                          leading: Icon(
                            Icons.notes_rounded,
                            size: 20,
                            color: colors.onSurfaceVariant,
                          ),
                          title: Text(
                            'Chi tiết phân tích',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          expandedCrossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            for (final detail in technicalDetails)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _ResultText(
                                  text: detail,
                                  style: theme.textTheme.bodySmall,
                                  separated: true,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiskScore extends StatelessWidget {
  const _RiskScore({required this.score, required this.accent});

  final num score;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      label: 'Điểm rủi ro',
      value: '${score.round()} trên 100',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 2,
            children: [
              Text('Điểm rủi ro', style: theme.textTheme.titleSmall),
              Text.rich(
                TextSpan(
                  text: '${score.round()}',
                  children: [
                    TextSpan(
                      text: ' / 100',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var segment = 0; segment < 5; segment++) ...[
                if (segment > 0) const SizedBox(width: 4),
                Expanded(
                  child: LinearProgressIndicator(
                    value: ((score - 20 * segment) / 20).clamp(0.0, 1.0),
                    minHeight: 5,
                    color: accent,
                    backgroundColor: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(5),
                    stopIndicatorRadius: 0,
                    trackGap: 0,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _ResultText extends StatelessWidget {
  const _ResultText({
    required this.text,
    required this.style,
    this.separated = false,
  });

  final String text;
  final TextStyle? style;
  final bool separated;

  @override
  Widget build(BuildContext context) {
    final lines = text.split(RegExp(r'\r?\n')).map((line) => line.trim());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in lines.where((line) => line.isNotEmpty))
          Container(
            margin: EdgeInsets.only(bottom: separated ? 10 : 0),
            padding: separated
                ? const EdgeInsetsDirectional.only(start: 10)
                : const EdgeInsets.symmetric(vertical: 3),
            decoration: separated
                ? BoxDecoration(
                    border: BorderDirectional(
                      start: BorderSide(
                        width: 2,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  )
                : null,
            child: Text.rich(
              TextSpan(
                children: [
                  for (final part
                      in line
                          .replaceFirst(RegExp(r'^#{1,6}\s+'), '')
                          .replaceFirst(RegExp(r'^[-*]\s+'), '• ')
                          .splitMapJoin(
                            RegExp(r'\*\*([^*]+)\*\*'),
                            onMatch: (match) => '\u0000${match[1]}\u0000',
                          )
                          .split('\u0000')
                          .indexed)
                    TextSpan(
                      text: part.$2,
                      style: part.$1.isOdd
                          ? const TextStyle(fontWeight: FontWeight.w700)
                          : null,
                    ),
                ],
              ),
              style: style?.copyWith(height: 1.45),
            ),
          ),
      ],
    );
  }
}
