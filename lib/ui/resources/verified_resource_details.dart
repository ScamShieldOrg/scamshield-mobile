import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/resource_entry.dart';

class VerifiedResourceDetails extends StatelessWidget {
  const VerifiedResourceDetails({super.key, required this.entry, this.date});

  final ResourceEntry entry;
  final String? date;

  static const _contactIcons = {
    'Website chính thức': Icons.language_rounded,
    'Hotline chính thức': Icons.call_outlined,
    'Thông tin đã xác thực': Icons.verified_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final verified = AppTheme.verifiedColors(theme.brightness);
    final contacts = entry.details.entries.where(
      (detail) =>
          detail.value.isNotEmpty && _contactIcons.containsKey(detail.key),
    );
    final profile = entry.details.entries.where(
      (detail) =>
          detail.value.isNotEmpty && !_contactIcons.containsKey(detail.key),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: verified.background,
            border: Border.all(color: verified.border),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_rounded, color: verified.foreground),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đơn vị đã xác minh',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: verified.foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              SelectableText(
                entry.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (date != null) ...[
                const SizedBox(height: 8),
                Text(
                  date!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (contacts.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Kênh liên hệ đã xác minh',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final contact in contacts)
            for (final value
                in contact.value
                    .split('\n')
                    .where((value) => value.trim().isNotEmpty))
              _ContactRow(
                label: contact.key,
                value: value,
                icon: _contactIcons[contact.key]!,
              ),
        ],
        if (profile.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Thông tin đơn vị',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          for (final detail in profile)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.key,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  SelectableText(detail.value),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verified = AppTheme.verifiedColors(theme.brightness);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: verified.foreground, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium),
                SelectableText(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sao chép $label',
            icon: const Icon(Icons.content_copy_outlined, size: 18),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Đã sao chép')));
            },
          ),
        ],
      ),
    );
  }
}
