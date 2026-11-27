import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

typedef EvidenceSuggestion = ({ui.Rect mask, String label, String text});

const _channel = MethodChannel('scamshield/evidence_ocr');

Future<List<EvidenceSuggestion>> suggestEvidenceMasks(ui.Image image) async {
  // Scan the same oriented pixels used for masking and export.
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) throw StateError('Could not encode OCR input');
  final lines = await _channel.invokeListMethod<Object?>(
    'scan',
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
  if (lines == null) throw StateError('Missing OCR result');
  return findEvidenceSuggestions(lines, image.width, image.height);
}

final _patterns = [
  (
    label: 'Email',
    regex: RegExp(r'[\w.%+-]+@[\w.-]+\.[a-z]{2,}', caseSensitive: false),
    group: 0,
  ),
  (
    label: 'Mã OTP hoặc PIN',
    regex: RegExp(
      r'\b(?:OTP|PIN)[ \t]*[:=\-]?\s*(\d{4,8})\b',
      caseSensitive: false,
    ),
    group: 1,
  ),
  (
    label: 'Mã OTP hoặc PIN',
    regex: RegExp(
      r'\b(\d{4,8})\s*(?:là\s+|is\s+)?(?:mã\s+)?(?:OTP|PIN)\b',
      caseSensitive: false,
    ),
    group: 1,
  ),
  (
    label: 'Số điện thoại, tài khoản hoặc giấy tờ',
    regex: RegExp(r'(?<!\d)\+?\d(?:[ .()\-]?\d){8,18}(?!\d)'),
    group: 0,
  ),
];

List<EvidenceSuggestion> findEvidenceSuggestions(
  List<Object?> lines,
  int width,
  int height,
) {
  final suggestions = <ui.Rect, EvidenceSuggestion>{};
  const unit = ui.Rect.fromLTWH(0, 0, 1, 1);
  for (var index = 0; index < lines.length; index++) {
    final text = StringBuffer();
    final spans = <({int start, int end, ui.Rect box})>[];
    for (final line in lines.skip(index).take(2).whereType<List>()) {
      if (text.isNotEmpty) text.write('\n');
      for (final word in line.whereType<List>()) {
        if (word.length != 5 || word.first is! String) continue;
        final coords = word.skip(1).whereType<num>().toList();
        if (coords.length != 4 || coords.any((value) => !value.isFinite)) {
          continue;
        }
        final box = ui.Rect.fromLTRB(
          coords[0].toDouble(),
          coords[1].toDouble(),
          coords[2].toDouble(),
          coords[3].toDouble(),
        ).intersect(unit);
        if (box.isEmpty) continue;
        final start = text.length;
        text.write(word.first);
        spans.add((start: start, end: text.length, box: box));
        text.write(' ');
      }
    }
    final content = text.toString();
    final lineBreak = content.indexOf('\n');
    for (final pattern in _patterns) {
      for (final match in pattern.regex.allMatches(content)) {
        if (lineBreak >= 0 && match.start >= lineBreak) continue;
        final value = match[pattern.group]!;
        final start = match.start + match[0]!.indexOf(value);
        final end = start + value.length;
        ui.Rect? combined;
        for (final span in spans) {
          if (span.start < end && span.end > start) {
            combined = combined?.expandToInclude(span.box) ?? span.box;
          }
        }
        if (combined == null) continue;
        final mask = ui.Rect.fromLTRB(
          math.max(0, combined.left - 3 / width),
          math.max(0, combined.top - 3 / height),
          math.min(1, combined.right + 3 / width),
          math.min(1, combined.bottom + 3 / height),
        );
        suggestions.putIfAbsent(
          mask,
          () => (mask: mask, label: pattern.label, text: value),
        );
      }
    }
  }
  return suggestions.values.toList();
}
