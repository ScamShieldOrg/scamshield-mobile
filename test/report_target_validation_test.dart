import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_mobile/ui/report/report_target_validation.dart';

void main() {
  test('rejects identifiers that match no supported target type', () {
    for (final (type, value) in [
      (ReportTargetType.bank, '123'),
      (ReportTargetType.website, 'not-a-url'),
      (ReportTargetType.phone, 'abc'),
    ]) {
      expect(matchesReportTarget(type, value), isFalse);
      expect(reportTargetTypeWarning(type, value), isNotNull);
    }
  });

  test('keeps the more specific hint when another target type matches', () {
    expect(
      reportTargetTypeWarning(ReportTargetType.bank, 'https://example.com'),
      contains(ReportTargetType.website.label),
    );
    expect(reportTargetTypeWarning(ReportTargetType.bank, '123456'), isNull);
  });
}
