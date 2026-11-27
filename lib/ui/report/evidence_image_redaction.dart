import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../core/theme/app_theme.dart';

const maxReportEvidenceBytes = 5 * 1024 * 1024;

Future<ui.Image> decodeEvidenceImage(Uint8List bytes) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  try {
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    try {
      final codec = await descriptor.instantiateCodec(
        targetWidth:
            descriptor.width >= descriptor.height && descriptor.width > 4096
            ? 4096
            : null,
        targetHeight:
            descriptor.height > descriptor.width && descriptor.height > 4096
            ? 4096
            : null,
      );
      try {
        return (await codec.getNextFrame()).image;
      } finally {
        codec.dispose();
      }
    } finally {
      descriptor.dispose();
    }
  } finally {
    buffer.dispose();
  }
}

// Masks are stored in image-relative coordinates from 0 to 1.
Future<Uint8List> exportRedactedEvidence(
  ui.Image source,
  List<ui.Rect> masks,
) async {
  var width = source.width;
  var height = source.height;
  for (var attempt = 0; attempt < 4; attempt++) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      source,
      ui.Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      ui.Paint()..filterQuality = ui.FilterQuality.low,
    );
    final paint = ui.Paint()..color = AppTheme.error;
    for (final mask in masks) {
      canvas.drawRect(
        ui.Rect.fromLTRB(
          (mask.left * width).floorToDouble(),
          (mask.top * height).floorToDouble(),
          (mask.right * width).ceilToDouble(),
          (mask.bottom * height).ceilToDouble(),
        ),
        paint,
      );
    }
    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(width, height);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) throw StateError('PNG encoding failed');
        if (data.lengthInBytes <= maxReportEvidenceBytes) {
          return data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          );
        }
      } finally {
        image.dispose();
      }
    } finally {
      picture.dispose();
    }
    width = (width * .75).round().clamp(1, width);
    height = (height * .75).round().clamp(1, height);
  }
  throw const FormatException(
    'Ảnh sau khi che vượt quá 5 MB. Hãy chọn ảnh nhỏ hơn.',
  );
}
