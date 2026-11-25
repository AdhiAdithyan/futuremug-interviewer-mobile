/// Validation for usernames and passwords, shared by sign-up and password
/// reset so the rules can't drift apart. Each returns an error or `null`.
abstract final class CredentialRules {
  static final RegExp _usernamePattern = RegExp(r'^[a-zA-Z0-9._-]{4,30}$');

  static String? username(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Choose a username';
    if (!_usernamePattern.hasMatch(v)) {
      return '4–30 characters: letters, numbers, dot, dash or underscore';
    }
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Choose a password';
    if (v.length < 8) return 'Use at least 8 characters';
    if (!RegExp('[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Use at least one letter and one number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Re-enter your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  /// 0 (empty) to 4 (strong), for the strength meter.
  static int strength(String value) {
    if (value.isEmpty) return 0;
    var score = 0;
    if (value.length >= 8) score++;
    if (value.length >= 12) score++;
    if (RegExp('[a-z]').hasMatch(value) && RegExp('[A-Z]').hasMatch(value)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(value) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      score++;
    }
    return score.clamp(1, 4);
  }
}
