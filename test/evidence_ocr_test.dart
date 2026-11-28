import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_mobile/ui/report/evidence_ocr.dart';

void main() {
  test('suggests only the OTP value across an OCR line break', () {
    final suggestions = findEvidenceSuggestions(
      [
        [
          ['OTP:', .1, .1, .2, .2],
        ],
        [
          ['123456', .3, .3, .5, .4],
        ],
      ],
      100,
      100,
    );

    final suggestion = suggestions.single;
    expect(suggestion.label, 'Mã OTP hoặc PIN');
    expect(suggestion.mask.top, greaterThan(.2));
    expect(suggestion.mask.bottom, greaterThan(.4));
  });

  test('groups formatted digits and clips padding inside the image', () {
    final suggestions = findEvidenceSuggestions(
      [
        [
          ['0912', 0, .1, .2, .2],
          ['345', .3, .1, .5, .2],
          ['678', .6, .1, .8, .2],
        ],
      ],
      100,
      100,
    );

    expect(suggestions.single.mask.left, 0);
    expect(suggestions.single.mask.right, greaterThan(.8));
  });
}
