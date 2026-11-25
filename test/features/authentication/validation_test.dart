import 'package:flutter_test/flutter_test.dart';
import 'package:futuremug_interviewer/features/authentication/domain/country_code.dart';
import 'package:futuremug_interviewer/features/authentication/domain/credential_rules.dart';

void main() {
  group('CountryCode.validate', () {
    final india = CountryCode.all.firstWhere((c) => c.dialCode == '+91');
    final germany = CountryCode.all.firstWhere((c) => c.dialCode == '+49');

    test('accepts a valid Indian mobile number', () {
      expect(india.validate('9876543210'), isNull);
    });

    test('rejects empty, wrong length, non-digits and bad first digit', () {
      expect(india.validate(''), isNotNull);
      expect(india.validate('98765'), isNotNull);
      expect(india.validate('98765432101'), isNotNull);
      expect(india.validate('98765abcde'), isNotNull);
      expect(india.validate('1234567890'), isNotNull);
    });

    test('supports a length range', () {
      expect(germany.validate('1512345678'), isNull);
      expect(germany.validate('15123456789'), isNull);
      expect(germany.validate('151234567'), isNotNull);
    });
  });

  group('CredentialRules', () {
    test('username', () {
      expect(CredentialRules.username('alex.morgan'), isNull);
      expect(CredentialRules.username('abc'), isNotNull);
      expect(CredentialRules.username('has space'), isNotNull);
      expect(CredentialRules.username(''), isNotNull);
    });

    test('password needs 8+ characters with a letter and a number', () {
      expect(CredentialRules.password('Secret123'), isNull);
      expect(CredentialRules.password('short1'), isNotNull);
      expect(CredentialRules.password('onlyletters'), isNotNull);
      expect(CredentialRules.password('12345678'), isNotNull);
    });

    test('confirm password must match', () {
      expect(CredentialRules.confirmPassword('Secret123', 'Secret123'), isNull);
      expect(CredentialRules.confirmPassword('Secret124', 'Secret123'), isNotNull);
      expect(CredentialRules.confirmPassword('', 'Secret123'), isNotNull);
    });

    test('strength grows with length and variety', () {
      expect(CredentialRules.strength(''), 0);
      expect(CredentialRules.strength('abc'), 1);
      expect(
        CredentialRules.strength('Abcdefgh1234!'),
        greaterThan(CredentialRules.strength('abcdefgh')),
      );
      expect(CredentialRules.strength('Abcdefgh1234!'), 4);
    });
  });
}
