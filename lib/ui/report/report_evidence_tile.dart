import 'package:flutter/material.dart';

import '../../data/services/report_service.dart';

class ReportEvidenceTile extends StatelessWidget {
  const ReportEvidenceTile({
    super.key,
    required this.file,
    required this.redacted,
    required this.onEdit,
    required this.onRemove,
  });

  final ReportEvidence file;
  final bool redacted;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  void _openPreview(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(file.name, overflow: TextOverflow.ellipsis),
          ),
          body: SafeArea(
            child: InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: Image(
                  image: ResizeImage(
                    MemoryImage(file.bytes),
                    width: 2048,
                    height: 2048,
                    policy: ResizeImagePolicy.fit,
                  ),
                  fit: BoxFit.contain,
                  semanticLabel: file.name,
                  errorBuilder: (_, _, _) =>
                      const Text('Không mở được ảnh minh chứng.'),
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
    final isPdf = file.name.toLowerCase().endsWith('.pdf');
    final fileType = file.name.split('.').last.toUpperCase();
    return Card.outlined(
      margin: const EdgeInsets.only(top: 8),
      color: colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isPdf ? null : () => _openPreview(context),
        child: _buildContent(theme, colors, isPdf, fileType),
      ),
    );
  }

  Widget _buildContent(
    ThemeData theme,
    ColorScheme colors,
    bool isPdf,
    String fileType,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox.square(
                dimension: 44,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ColoredBox(
                    color: colors.secondaryContainer,
                    child: isPdf
                        ? Icon(
                            Icons.picture_as_pdf_outlined,
                            color: colors.primary,
                          )
                        : Image.memory(
                            file.bytes,
                            cacheWidth: 132,
                            fit: BoxFit.cover,
                            excludeFromSemantics: true,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.image_outlined,
                              color: colors.primary,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      redacted ? '$fileType · Đã che thông tin' : fileType,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Xóa tệp ${file.name}',
                onPressed: onRemove,
                style: IconButton.styleFrom(minimumSize: const Size.square(48)),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          if (!isPdf) ...[
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: onEdit,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              icon: const Icon(Icons.visibility_off_outlined, size: 18),
              label: Text(redacted ? 'Chỉnh vùng che' : 'Che thông tin'),
            ),
          ],
        ],
      ),
    );
  }
}
