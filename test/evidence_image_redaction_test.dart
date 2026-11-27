import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_mobile/ui/report/evidence_image_redaction.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('export replaces the selected pixels in the actual PNG', () async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);
    final picture = recorder.endRecording();
    addTearDown(picture.dispose);
    final source = await picture.toImage(10, 10);
    addTearDown(source.dispose);

    final bytes = await exportRedactedEvidence(source, const [
      ui.Rect.fromLTRB(.24, .33, .67, .72),
    ]);
    expect(bytes.length, lessThanOrEqualTo(maxReportEvidenceBytes));
    final result = await decodeEvidenceImage(bytes);
    addTearDown(result.dispose);
    expect((result.width, result.height), (10, 10));

    final pixels = (await result.toByteData())!;
    for (var y = 0; y < result.height; y++) {
      for (var x = 0; x < result.width; x++) {
        final covered = x >= 2 && x < 7 && y >= 3 && y < 8;
        expect(
          pixels.getUint32((y * result.width + x) * 4),
          covered ? 0xFF2020FF : 0xFFFFFFFF,
          reason: 'Pixel at ($x, $y)',
        );
      }
    }
  });
}
