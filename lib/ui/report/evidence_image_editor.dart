import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'evidence_image_redaction.dart';
import 'evidence_ocr.dart';

typedef EvidenceImageEdit = ({Uint8List bytes, List<Rect> masks});

class EvidenceImageEditor extends StatefulWidget {
  const EvidenceImageEditor({
    super.key,
    required this.name,
    required this.bytes,
    this.initialMasks = const [],
  });

  final String name;
  final Uint8List bytes;
  final List<Rect> initialMasks;

  @override
  State<EvidenceImageEditor> createState() => _EvidenceImageEditorState();
}

class _EvidenceImageEditorState extends State<EvidenceImageEditor> {
  final _transform = TransformationController();
  final _previewKey = GlobalKey();
  late final _masks = List<Rect>.of(widget.initialMasks);
  bool get _hasChanges => !listEquals(_masks, widget.initialMasks);
  final _suggestions = <EvidenceSuggestion>[];
  int _suggestionNumber = 1;
  ui.Image? _image;
  int? _pointer;
  Offset? _start;
  Offset? _corner;
  Rect? _draft;
  bool _panning = false;
  bool _saving = false;
  bool _scanning = false;
  bool _confirmingDiscard = false;
  String? _error;
  String? _scanNotice;

  @override
  void initState() {
    super.initState();
    _openImage();
  }

  Future<void> _openImage() async {
    try {
      final image = await decodeEvidenceImage(widget.bytes);
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() => _image = image);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Không mở được ảnh. Hãy chọn ảnh PNG hoặc JPG hợp lệ.',
        );
      }
    }
  }

  @override
  void dispose() {
    _transform.dispose();
    _image?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final image = _image;
    if (_saving || _pointer != null || image == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final bytes = _masks.isEmpty
          ? widget.bytes
          : await exportRedactedEvidence(image, _masks);
      if (mounted) {
        Navigator.of(
          context,
        ).pop((bytes: bytes, masks: List<Rect>.unmodifiable(_masks)));
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error is FormatException
            ? error.message
            : 'Không lưu được ảnh đã che. Vui lòng thử lại.';
      });
    }
  }

  Future<void> _scan() async {
    final image = _image!.clone();
    setState(() {
      _scanning = true;
      _scanNotice = null;
    });
    try {
      final suggestions = await suggestEvidenceMasks(image);
      if (!mounted) return;
      setState(() {
        _suggestionNumber = 1;
        _suggestions.addAll(
          suggestions.where((item) => !_masks.contains(item.mask)),
        );
        if (_suggestions.isEmpty) {
          _scanNotice =
              'Không tìm thấy vùng cần gợi ý. Bạn có thể che thủ công.';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _scanNotice =
              'Không quét được ảnh. Hãy thử lại hoặc che thủ công.',
        );
      }
    } finally {
      image.dispose();
      if (mounted) setState(() => _scanning = false);
    }
  }

  void _reviewSuggestion({required bool apply}) {
    setState(() {
      final suggestion = _suggestions.removeAt(0);
      _suggestionNumber++;
      if (apply) _masks.add(suggestion.mask);
      _clearSelection();
    });
  }

  Future<void> _discard() async {
    if (_saving || _confirmingDiscard) return;
    if (!_hasChanges) {
      Navigator.of(context).pop();
      return;
    }
    _confirmingDiscard = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bỏ thay đổi?'),
        content: const Text('Các chỉnh sửa chưa lưu sẽ bị bỏ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Chỉnh tiếp'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Bỏ thay đổi'),
          ),
        ],
      ),
    );
    _confirmingDiscard = false;
    if (mounted && discard == true) Navigator.of(context).pop();
  }

  void _clearSelection() {
    _pointer = null;
    _start = null;
    _draft = null;
    _corner = null;
  }

  void _addMask(Offset start, Offset end) {
    final mask = Rect.fromPoints(start, end);
    final image = _image!;
    if (mask.width * image.width >= 2 && mask.height * image.height >= 2) {
      _masks.add(mask);
    }
  }

  void _zoomBy(double step) {
    final viewport = _previewKey.currentContext?.size;
    if (viewport == null) return;
    final center = viewport.center(Offset.zero);
    final anchor = _transform.toScene(center);
    final scale = (_transform.value.getMaxScaleOnAxis() + step).clamp(1.0, 4.0);
    setState(() {
      _clearSelection();
      if (scale <= 1) _panning = false;
    });
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        (center.dx - anchor.dx * scale).clamp(
          viewport.width * (1 - scale),
          0.0,
        ),
        (center.dy - anchor.dy * scale).clamp(
          viewport.height * (1 - scale),
          0.0,
        ),
        0,
        1,
      )
      ..scaleByDouble(scale, scale, scale, 1);
  }

  Widget _imageCanvas(ui.Image image) => LayoutBuilder(
    builder: (context, constraints) {
      final fitted = applyBoxFit(
        BoxFit.contain,
        Size(image.width.toDouble(), image.height.toDouble()),
        constraints.biggest,
      ).destination;

      Offset point(Offset position) => Offset(
        (position.dx / fitted.width).clamp(0, 1),
        (position.dy / fitted.height).clamp(0, 1),
      );

      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: InteractiveViewer(
          key: _previewKey,
          transformationController: _transform,
          maxScale: 4,
          panEnabled: _panning && !_saving,
          scaleEnabled: false,
          child: Center(
            child: SizedBox.fromSize(
              size: fitted,
              child: Semantics(
                image: true,
                label: 'Ảnh minh chứng',
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) {
                    if (_panning ||
                        _saving ||
                        _pointer != null ||
                        event.buttons != kPrimaryButton) {
                      return;
                    }
                    _pointer = event.pointer;
                    _start = point(event.localPosition);
                  },
                  onPointerMove: (event) {
                    if (event.pointer != _pointer) return;
                    final current = point(event.localPosition);
                    final delta = current - _start!;
                    if (_draft == null &&
                        Offset(
                              delta.dx * fitted.width,
                              delta.dy * fitted.height,
                            ).distance <
                            4) {
                      return;
                    }
                    setState(() => _draft = Rect.fromPoints(_start!, current));
                  },
                  onPointerUp: (event) {
                    if (event.pointer != _pointer) return;
                    final end = point(event.localPosition);
                    setState(() {
                      final start = _draft != null ? _start : _corner;
                      _clearSelection();
                      if (start == null) {
                        _corner = end;
                      } else {
                        _addMask(start, end);
                      }
                    });
                  },
                  onPointerCancel: (event) {
                    if (event.pointer == _pointer) setState(_clearSelection);
                  },
                  child: CustomPaint(
                    foregroundPainter: _MaskPainter(
                      _masks,
                      _draft,
                      _corner,
                      _suggestions.firstOrNull?.mask,
                      _suggestionNumber,
                    ),
                    child: RawImage(image: image, fit: BoxFit.fill),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final image = _image;
    final scale = _transform.value.getMaxScaleOnAxis();
    final controls = Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _panning
                ? 'Kéo để di chuyển ảnh. Nhấn bàn tay lần nữa để vẽ.'
                : _corner != null
                ? 'Chạm vào góc đối diện để hoàn tất vùng che.'
                : 'Kéo hoặc chạm hai góc để đánh dấu vùng cần che.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Material(
              color: colors.secondaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colors.primary.withAlpha(42)),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IconButton.filledTonal(
                    tooltip: _panning ? 'Vẽ vùng che' : 'Di chuyển ảnh',
                    style: IconButton.styleFrom(
                      backgroundColor: _panning
                          ? colors.primary
                          : colors.surface,
                      foregroundColor: _panning
                          ? colors.onPrimary
                          : colors.primary,
                    ),
                    isSelected: _panning,
                    onPressed: image == null || _saving || scale <= 1
                        ? null
                        : () => setState(() {
                            _clearSelection();
                            _panning = !_panning;
                          }),
                    icon: const Icon(Icons.pan_tool_outlined),
                    selectedIcon: const Icon(Icons.pan_tool_rounded),
                  ),
                  IconButton(
                    tooltip: 'Phóng to',
                    onPressed: image == null || _saving || scale >= 4
                        ? null
                        : () => _zoomBy(.5),
                    icon: const Icon(Icons.zoom_in_outlined),
                  ),
                  IconButton(
                    tooltip: 'Thu nhỏ',
                    onPressed: image == null || _saving || scale <= 1
                        ? null
                        : () => _zoomBy(-.5),
                    icon: const Icon(Icons.zoom_out_outlined),
                  ),
                  IconButton(
                    tooltip: 'Vừa khung',
                    onPressed: image == null || _saving
                        ? null
                        : () {
                            setState(() {
                              _clearSelection();
                              _panning = false;
                            });
                            _transform.value = Matrix4.identity();
                          },
                    icon: const Icon(Icons.fit_screen_outlined),
                  ),
                  IconButton(
                    tooltip: 'Hoàn tác',
                    onPressed: _saving || (_masks.isEmpty && _corner == null)
                        ? null
                        : () {
                            setState(() {
                              if (_corner == null) _masks.removeLast();
                              _clearSelection();
                            });
                          },
                    icon: const Icon(Icons.undo_rounded),
                  ),
                  IconButton.filledTonal(
                    tooltip: _scanning ? 'Đang quét ảnh…' : 'Gợi ý vùng che',
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.accentAmber,
                      foregroundColor: AppTheme.navy,
                    ),
                    onPressed:
                        image == null ||
                            _saving ||
                            _scanning ||
                            _suggestions.isNotEmpty
                        ? null
                        : _scan,
                    icon: _scanning
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.document_scanner_outlined),
                  ),
                ],
              ),
            ),
          ),
          if (_suggestions.firstOrNull case final suggestion?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _SuggestionReview(
                number: _suggestionNumber,
                label: suggestion.text,
                onApply: _saving ? null : () => _reviewSuggestion(apply: true),
                onSkip: _saving ? null : () => _reviewSuggestion(apply: false),
              ),
            )
          else ...[
            if (_scanNotice case final notice?)
              Semantics(
                liveRegion: true,
                child: Text(notice, style: theme.textTheme.bodySmall),
              ),
          ],
        ],
      ),
    );
    final preview = image == null
        ? Center(
            child: _error == null ? const CircularProgressIndicator() : null,
          )
        : _imageCanvas(image);

    return PopScope<EvidenceImageEdit>(
      canPop: !_saving && !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _discard();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _saving ? null : _discard),
          title: Text(
            'Che thông tin nhạy cảm',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, bounds) {
              if (bounds.maxWidth >= 520 &&
                  bounds.maxWidth > bounds.maxHeight) {
                return Row(
                  children: [
                    SizedBox(
                      width: 250,
                      child: SingleChildScrollView(child: controls),
                    ),
                    Expanded(child: preview),
                  ],
                );
              }
              return Column(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: bounds.maxHeight * .55,
                    ),
                    child: SingleChildScrollView(child: controls),
                  ),
                  Expanded(child: preview),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.outlineVariant)),
          ),
          child: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error case final error?)
                  Text(error, style: TextStyle(color: colors.error)),
                Text(
                  '${_masks.length} vùng che',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                OverflowBar(
                  alignment: MainAxisAlignment.spaceBetween,
                  spacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _saving || _masks.isEmpty
                          ? null
                          : () => setState(() {
                              _masks.clear();
                              _suggestions.clear();
                              _clearSelection();
                            }),
                      icon: const Icon(Icons.restore_rounded),
                      label: const Text('Khôi phục'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: _saving ? null : _discard,
                      child: const Text('Hủy'),
                    ),
                    FilledButton.icon(
                      onPressed:
                          _saving ||
                              image == null ||
                              !_hasChanges ||
                              _pointer != null
                          ? null
                          : _save,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(_saving ? 'Đang lưu ảnh…' : 'Lưu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionReview extends StatelessWidget {
  const _SuggestionReview({
    required this.number,
    required this.label,
    this.onApply,
    this.onSkip,
  });

  final int number;
  final String label;
  final VoidCallback? onApply;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: Color.alphaBlend(
        AppTheme.accentAmber.withAlpha(26),
        colors.surface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.accentAmber.withAlpha(140)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 10, end: 4),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Gợi ý $number: ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: label),
                    ],
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Bỏ qua gợi ý',
              iconSize: 18,
              onPressed: onSkip,
              icon: const Icon(Icons.skip_next_outlined),
            ),
            IconButton.filled(
              tooltip: 'Che vùng này',
              iconSize: 15,
              style: IconButton.styleFrom(
                minimumSize: const Size.square(32),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              onPressed: onApply,
              icon: const Icon(Icons.check_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaskPainter extends CustomPainter {
  _MaskPainter(
    List<Rect> masks,
    this.draft,
    this.corner,
    this.suggestion,
    this.suggestionNumber,
  ) : masks = List.of(masks);

  final List<Rect> masks;
  final Rect? draft;
  final Offset? corner;
  final Rect? suggestion;
  final int suggestionNumber;

  @override
  void paint(Canvas canvas, Size size) {
    Rect scale(Rect rect) => Rect.fromLTRB(
      rect.left * size.width,
      rect.top * size.height,
      rect.right * size.width,
      rect.bottom * size.height,
    );
    final fill = Paint()..color = AppTheme.evidenceMaskRed;
    for (final mask in masks) {
      canvas.drawRect(scale(mask), fill);
    }
    if (draft case final rect?) canvas.drawRect(scale(rect), fill);
    if (suggestion case final rect?) {
      final frame = RRect.fromRectAndRadius(
        scale(rect).inflate(3),
        const Radius.circular(3),
      );
      canvas.drawRRect(
        frame,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      canvas.drawRRect(
        frame,
        Paint()
          ..color = AppTheme.accentAmber
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.25,
      );
      final label = TextPainter(
        text: TextSpan(
          text: '$suggestionNumber',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final badgeWidth = label.width + 4;
      final badgeHeight = label.height + 2;
      final x = frame.left.clamp(
        0.0,
        (size.width - badgeWidth).clamp(0.0, double.infinity),
      );
      final y = frame.top >= badgeHeight + 3
          ? frame.top - badgeHeight - 3
          : frame.bottom + 3;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, badgeWidth, badgeHeight),
          const Radius.circular(4),
        ),
        Paint()..color = AppTheme.accentAmber,
      );
      label.paint(canvas, Offset(x + 2, y + 1));
      label.dispose();
    }
    if (corner case final point?) {
      final position = Offset(point.dx * size.width, point.dy * size.height);
      canvas.drawCircle(position, 5, Paint()..color = Colors.white);
      canvas.drawCircle(position, 3, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _MaskPainter oldDelegate) => true;
}
