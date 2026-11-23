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
    expect(isScamCheckPhone('1900 1234'), isTrue);
    expect(isScamCheckPhone('1800 12'), isFalse);
    expect(isScamCheckPhone('+84 0912 345 678'), isFalse);
  });

  test('accepts formatted bank accounts within the supported length', () {
    expect(isScamCheckBankAccount('0123.456-789'), isTrue);
    expect(isScamCheckBankAccount('12345'), isFalse);
    expect(isScamCheckBankAccount('0123/456'), isFalse);
    expect(isScamCheckBankAccount(List.filled(31, '1').join()), isFalse);
  });

  test('counts distinct links and phone occurrences in a message', () {
    final counts = countScamCheckIndicators(
      'example.com example.com https://example.vn 0912345678 khac.Do',
    );
    expect(counts, (links: 2, phones: 1));
  });
}
