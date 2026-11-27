import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'evidence_image_redaction.dart';

class EvidenceImageEditor extends StatefulWidget {
  const EvidenceImageEditor({
    super.key,
    required this.name,
    required this.bytes,
  });

  final String name;
  final Uint8List bytes;

  @override
  State<EvidenceImageEditor> createState() => _EvidenceImageEditorState();
}

class _EvidenceImageEditorState extends State<EvidenceImageEditor> {
  final _transform = TransformationController();
  final _previewKey = GlobalKey();
  final _masks = <Rect>[];
  ui.Image? _image;
  int? _pointer;
  Offset? _start;
  Offset? _corner;
  Rect? _draft;
  bool _panning = false;
  bool _saving = false;
  bool _confirmingDiscard = false;
  String? _error;

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
    if (_saving || _pointer != null) return;
    final image = _image!;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final bytes = await exportRedactedEvidence(image, _masks);
      if (mounted) Navigator.of(context).pop(bytes);
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

  Future<void> _discard() async {
    if (_saving || _confirmingDiscard) return;
    if (_masks.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    _confirmingDiscard = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bỏ thay đổi?'),
        content: const Text('Các vùng che chưa lưu sẽ bị bỏ.'),
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
                    foregroundPainter: _MaskPainter(_masks, _draft, _corner),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            _panning
                ? 'Kéo để di chuyển ảnh. Nhấn lại nút bàn tay để tiếp tục che thông tin.'
                : _corner != null
                ? 'Chạm vào góc đối diện để hoàn tất vùng che.'
                : 'Kéo hoặc chạm vào hai góc của vùng cần che. Giữ lại nội dung cần đối chiếu.',
            style: theme.textTheme.bodySmall,
          ),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton.filledTonal(
                tooltip: _panning ? 'Vẽ vùng che' : 'Di chuyển ảnh',
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
            ],
          ),
        ],
      ),
    );
    final preview = image == null
        ? Center(
            child: _error == null ? const CircularProgressIndicator() : null,
          )
        : _imageCanvas(image);

    return PopScope<Uint8List>(
      canPop: !_saving && _masks.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _discard();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _saving ? null : _discard),
          title: const Text('Che thông tin nhạy cảm'),
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
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error case final error?)
                Text(error, style: TextStyle(color: colors.error)),
              Text(
                '${_masks.length} vùng che',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              FilledButton.icon(
                onPressed: _saving || _masks.isEmpty || _pointer != null
                    ? null
                    : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Đang lưu ảnh…' : 'Lưu ảnh đã che'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaskPainter extends CustomPainter {
  _MaskPainter(List<Rect> masks, this.draft, this.corner)
    : masks = List.of(masks);

  final List<Rect> masks;
  final Rect? draft;
  final Offset? corner;

  @override
  void paint(Canvas canvas, Size size) {
    Rect scale(Rect rect) => Rect.fromLTRB(
      rect.left * size.width,
      rect.top * size.height,
      rect.right * size.width,
      rect.bottom * size.height,
    );
    final fill = Paint()..color = AppTheme.error;
    for (final mask in masks) {
      canvas.drawRect(scale(mask), fill);
    }
    if (draft case final rect?) canvas.drawRect(scale(rect), fill);
    if (corner case final point?) {
      final position = Offset(point.dx * size.width, point.dy * size.height);
      canvas.drawCircle(position, 5, Paint()..color = Colors.white);
      canvas.drawCircle(position, 3, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _MaskPainter oldDelegate) => true;
}
