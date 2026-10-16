import '../../../core/l10n/l10n.dart';

/// Form checks that mirror the API rules, so most mistakes are caught before sending.
abstract final class AuthValidators {
  static final _username = RegExp(r'^[a-zA-Z0-9._-]{3,30}$');

  static String? Function(String?) required(AppLocalizations l10n) =>
      (value) => (value == null || value.trim().isEmpty) ? l10n.validationRequired : null;

  static String? Function(String?) username(AppLocalizations l10n) => (value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return l10n.validationRequired;
    return _username.hasMatch(text) ? null : l10n.validationUsername;
  };

  static String? Function(String?) newPassword(AppLocalizations l10n) => (value) {
    if (value == null || value.isEmpty) return l10n.validationRequired;
    return value.length < 8 ? l10n.validationPasswordLength : null;
  };

  static String? Function(String?) confirmPassword(AppLocalizations l10n, String Function() password) =>
      (value) {
        if (value == null || value.isEmpty) return l10n.validationRequired;
        return value != password() ? l10n.validationPasswordsMatch : null;
      };
}
