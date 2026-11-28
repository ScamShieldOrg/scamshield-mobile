import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/resource_entry.dart';
import 'public_report_evidence.dart';
import 'verified_resource_details.dart';

class ResourceCard extends StatelessWidget {
  const ResourceCard({super.key, required this.entry, required this.list});

  final ResourceEntry entry;
  final ResourceList list;

  bool get _isWarning => list == ResourceList.warnings;

  String? _dateLabel(BuildContext context) {
    final date = entry.date;
    if (date == null) return null;
    final formatted = MaterialLocalizations.of(
      context,
    ).formatCompactDate(date.toLocal());
    return _isWarning ? 'Cập nhật $formatted' : 'Xác thực $formatted';
  }

  void _showDetails(BuildContext context) {
    final date = _dateLabel(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: SizedBox(
            width: double.infinity,
            child: _isWarning
                ? _WarningDetails(entry: entry, date: date)
                : VerifiedResourceDetails(entry: entry, date: date),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final date = _dateLabel(context);
    final verified = AppTheme.verifiedColors(theme.brightness);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isWarning
                      ? colors.errorContainer
                      : verified.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isWarning
                      ? Icons.warning_amber_rounded
                      : Icons.verified_outlined,
                  color: _isWarning
                      ? colors.onErrorContainer
                      : verified.foreground,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.displayTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!_isWarning) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: verified.background,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Đã xác minh',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: verified.foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    if (_isWarning || date != null) ...[
                      const SizedBox(height: 8),
                      if (_isWarning)
                        Text(
                          entry.warningCategory.isEmpty
                              ? entry.typeLabel
                              : '${entry.typeLabel} · ${entry.warningCategory}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      if (date != null || _isWarning) const SizedBox(height: 4),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          if (_isWarning)
                            Text(
                              '${entry.warnings} lượt cảnh báo',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.error,
                              ),
                            ),
                          if (date != null)
                            Text(
                              date,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarningDetails extends StatelessWidget {
  const _WarningDetails({required this.entry, required this.date});

  final ResourceEntry entry;
  final String? date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: colors.onErrorContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Chi tiết cảnh báo',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Đóng',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.typeLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                entry.displayTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colors.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${entry.warnings} báo cáo đã được duyệt',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onErrorContainer,
                      ),
                    ),
                  ),
                  if (date != null)
                    Text(
                      date!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Detail(
                icon: Icons.category_outlined,
                label: 'Loại lừa đảo',
                value: entry.warningCategory.isEmpty
                    ? 'Chưa có thông tin về loại lừa đảo'
                    : entry.warningCategory,
              ),
              if (entry.warningCategoryDescription.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _Detail(
                  icon: Icons.description_outlined,
                  label: 'Hành vi biểu hiện',
                  value: entry.warningCategoryDescription,
                ),
              ],
            ],
          ),
        ),
        if (entry.publicEvidenceId != null ||
            entry.publicReportDescription.isNotEmpty) ...[
          const SizedBox(height: 16),
          PublicReportEvidence(
            id: entry.publicEvidenceId,
            behaviorDescription: entry.publicReportDescription,
          ),
        ],
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
