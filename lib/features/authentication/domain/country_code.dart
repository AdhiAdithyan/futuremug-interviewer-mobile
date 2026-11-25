import 'package:flutter/foundation.dart';

/// Supported countries with their national-number length rules.
///
/// Basic validation for 1A. Milestone 1B replaces this with full per-country
/// validation (e.g. the `phone_numbers_parser` package).
@immutable
class CountryCode {
  const CountryCode({
    required this.name,
    required this.dialCode,
    required this.flag,
    required this.minLength,
    required this.maxLength,
    required this.example,
    this.validFirstDigits,
  });

  final String name;
  final String dialCode;
  final String flag;
  final int minLength;
  final int maxLength;
  final String example;

  /// Allowed first digits of a mobile number, if the country restricts them.
  final String? validFirstDigits;

  static const List<CountryCode> all = [
    CountryCode(
      name: 'India',
      dialCode: '+91',
      flag: '🇮🇳',
      minLength: 10,
      maxLength: 10,
      example: '9876543210',
      validFirstDigits: '6789',
    ),
    CountryCode(
      name: 'United States',
      dialCode: '+1',
      flag: '🇺🇸',
      minLength: 10,
      maxLength: 10,
      example: '4155552671',
    ),
    CountryCode(
      name: 'United Kingdom',
      dialCode: '+44',
      flag: '🇬🇧',
      minLength: 10,
      maxLength: 10,
      example: '7400123456',
      validFirstDigits: '7',
    ),
    CountryCode(
      name: 'United Arab Emirates',
      dialCode: '+971',
      flag: '🇦🇪',
      minLength: 9,
      maxLength: 9,
      example: '501234567',
      validFirstDigits: '5',
    ),
    CountryCode(
      name: 'Singapore',
      dialCode: '+65',
      flag: '🇸🇬',
      minLength: 8,
      maxLength: 8,
      example: '81234567',
      validFirstDigits: '89',
    ),
    CountryCode(
      name: 'Australia',
      dialCode: '+61',
      flag: '🇦🇺',
      minLength: 9,
      maxLength: 9,
      example: '412345678',
      validFirstDigits: '4',
    ),
    CountryCode(
      name: 'Germany',
      dialCode: '+49',
      flag: '🇩🇪',
      minLength: 10,
      maxLength: 11,
      example: '15123456789',
      validFirstDigits: '1',
    ),
  ];

  /// Returns an error message, or `null` if [digits] is a valid mobile number.
  String? validate(String digits) {
    if (digits.isEmpty) return 'Enter your mobile number';
    if (!RegExp(r'^\d+$').hasMatch(digits)) return 'Use digits only';
    if (digits.length < minLength || digits.length > maxLength) {
      return minLength == maxLength
          ? 'A $name mobile number has $minLength digits'
          : 'A $name mobile number has $minLength–$maxLength digits';
    }
    final first = validFirstDigits;
    if (first != null && !first.contains(digits[0])) {
      return 'This is not a valid $name mobile number';
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is CountryCode && other.dialCode == dialCode && other.name == name;

  @override
  int get hashCode => Object.hash(dialCode, name);
}
