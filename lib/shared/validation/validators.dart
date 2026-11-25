/// Form validators shared across features. Each returns an error message or
/// `null` when the value is valid.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _e164 = RegExp(r'^\+[1-9]\d{6,14}$');

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return 'Enter $fieldName';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email';
    if (!_email.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  /// International format, e.g. +919876543210.
  static String? phoneE164(String? value) {
    final v = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (v.isEmpty) return 'Enter your mobile number';
    if (!_e164.hasMatch(v)) {
      return 'Use the international format, e.g. +919876543210';
    }
    return null;
  }

  /// A number between [min] and [max] (inclusive); decimals allowed.
  static String? number(
    String? value, {
    required String fieldName,
    required double min,
    required double max,
  }) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter $fieldName';
    final parsed = double.tryParse(v);
    if (parsed == null) return 'Enter a number';
    if (parsed < min || parsed > max) {
      return 'Enter a value from ${_fmt(min)} to ${_fmt(max)}';
    }
    return null;
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}
