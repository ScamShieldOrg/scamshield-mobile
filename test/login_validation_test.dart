import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_mobile/ui/auth/login_validation.dart';

void main() {
  group('validateLoginIdentifier', () {
    test('accepts valid email and 10-digit phone numbers', () {
      expect(validateLoginIdentifier('nguyenvana@gmail.com'), isNull);
      expect(validateLoginIdentifier('  0987654321  '), isNull);
    });

    test('rejects empty, malformed email, and invalid phone lengths', () {
      expect(validateLoginIdentifier(''), isNotNull);
      expect(validateLoginIdentifier('   '), isNotNull);
      expect(validateLoginIdentifier('invalid@domain'), isNotNull);
      expect(validateLoginIdentifier('098765432'), isNotNull);
      expect(validateLoginIdentifier('09876abcde'), isNotNull);
      expect(validateLoginIdentifier('plainuser'), isNotNull);
    });
  });

  group('validateLoginPassword', () {
    test('accepts passwords with at least 6 characters', () {
      expect(validateLoginPassword('123456'), isNull);
      expect(validateLoginPassword('Secret123!'), isNull);
    });

    test('rejects empty or short passwords', () {
      expect(validateLoginPassword(''), isNotNull);
      expect(validateLoginPassword('12345'), isNotNull);
    });
  });
}
