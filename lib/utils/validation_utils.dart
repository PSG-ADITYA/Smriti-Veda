class ValidationUtils {
  /// Validates password based on standard security criteria:
  /// - Minimum 8 characters
  /// - At least one uppercase letter (A-Z)
  /// - At least one lowercase letter (a-z)
  /// - At least one numeric digit (0-9)
  /// - At least one special symbol (!@#$%^&* etc.)
  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Password invalid: Must be at least 8 characters long.';
    }

    final hasUppercase = value.contains(RegExp(r'[A-Z]'));
    final hasLowercase = value.contains(RegExp(r'[a-z]'));
    final hasDigits = value.contains(RegExp(r'[0-9]'));
    final hasSpecialSymbol = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>\-_=+]'));

    final List<String> missing = [];
    if (!hasUppercase) missing.add('an uppercase letter (A-Z)');
    if (!hasLowercase) missing.add('a lowercase letter (a-z)');
    if (!hasDigits) missing.add('a number (0-9)');
    if (!hasSpecialSymbol) missing.add('a special symbol (!@#\$%^&*)');

    if (missing.isNotEmpty) {
      return 'Password invalid: It must contain ${missing.join(", ")}.';
    }

    return null;
  }

  /// Validates phone number:
  /// Must contain exactly 10 subscriber digits (e.g. 9876543210).
  static String? validatePhoneNumber(String? value, {String countryCode = '+91'}) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is compulsory.';
    }

    // Strip non-digit characters
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length != 10) {
      return 'Phone number invalid: Must be exactly 10 digits (e.g. $countryCode 98765 43210).';
    }

    return null;
  }

  /// Format phone number with country code
  static String formatPhone(String rawPhone, {String countryCode = '+91'}) {
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '$countryCode ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    return rawPhone.trim();
  }
}
