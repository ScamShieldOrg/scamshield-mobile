import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_mobile/ui/home/scam_check_validation.dart';

void main() {
  test('accepts a domain and rejects credentials in a URL', () {
    expect(parseScamCheckLink('example.com/path')?.host, 'example.com');
    expect(parseScamCheckLink('https://user@example.com'), isNull);
  });

  test('validates phone numbers after removing formatting', () {
    expect(normalizeScamCheckPhone('+84 (90) 123-4567'), '+84901234567');
    expect(isScamCheckPhone('+84 (90) 123-4567'), isTrue);
    expect(isScamCheckPhone('abc123'), isFalse);
  });
}
