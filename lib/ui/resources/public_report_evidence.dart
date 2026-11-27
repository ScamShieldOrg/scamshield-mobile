import 'package:flutter/material.dart';

import '../../data/repositories/resource_repository.dart';

class PublicReportEvidence extends StatefulWidget {
  const PublicReportEvidence({
    super.key,
    required this.id,
    required this.behaviorDescription,
  });

  final int? id;
  final String behaviorDescription;

  @override
  State<PublicReportEvidence> createState() => _PublicReportEvidenceState();
}

class _PublicReportEvidenceState extends State<PublicReportEvidence> {
  Future<List<String>>? _images;

  void _loadImages() {
    final id = widget.id;
    if (id == null) return;
    setState(() {
      _images = const ResourceRepository().loadPublicEvidence(id);
    });
  }

  void _openImage(String url, String label) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(label)),
          body: SafeArea(
            child: InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  semanticLabel: label,
                  errorBuilder: (_, _, _) =>
                      const Text('Không tải được ảnh minh chứng.'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final behavior = widget.behaviorDescription.trim();
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        backgroundColor: colors.surface,
        collapsedBackgroundColor: colors.surfaceContainerLow,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.fact_check_outlined,
            size: 20,
            color: colors.onPrimary,
          ),
        ),
        title: Text(
          'Báo cáo liên quan',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        onExpansionChanged: (expanded) {
          if (expanded && _images == null) _loadImages();
        },
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Divider(height: 1, color: colors.outlineVariant),
          const SizedBox(height: 16),
          if (behavior.isNotEmpty) ...[
            Text(
              'Mô tả ngắn gọn hành vi',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              behavior,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 16),
          ],
          if (widget.id != null) ...[
            Text(
              'Ảnh minh chứng công khai',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const _EvidencePrivacyNotice(),
            const SizedBox(height: 12),
            FutureBuilder<List<String>>(
              future: _images,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator(
                    semanticsLabel: 'Đang tải ảnh minh chứng',
                  );
                }
                if (snapshot.hasError) {
                  return Column(
                    children: [
                      const Text('Không tải được ảnh minh chứng.'),
                      TextButton(
                        onPressed: _loadImages,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  );
                }
                final links = snapshot.data;
                if (links == null || links.isEmpty) {
                  return const Text('Hiện chưa có ảnh minh chứng công khai.');
                }
                return Column(
                  children: [
                    for (final (index, link) in links.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerLow,
                            border: Border.all(color: colors.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Image.network(
                                link,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.contain,
                                semanticLabel:
                                    'Ảnh minh chứng công khai ${index + 1}',
                                errorBuilder: (_, _, _) => TextButton(
                                  onPressed: _loadImages,
                                  child: Text(
                                    'Tải lại ảnh minh chứng ${index + 1}',
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: IconButton.filledTonal(
                                  tooltip:
                                      'Phóng to ảnh minh chứng ${index + 1}',
                                  onPressed: () => _openImage(
                                    link,
                                    'Ảnh minh chứng ${index + 1}',
                                  ),
                                  icon: const Icon(
                                    Icons.open_in_full_rounded,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _EvidencePrivacyNotice extends StatelessWidget {
  const _EvidencePrivacyNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 20,
            color: colors.onSecondaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Một số thông tin nhạy cảm có thể bị che để bảo vệ quyền riêng tư của người báo cáo.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSecondaryContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
