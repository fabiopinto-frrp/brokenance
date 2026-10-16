import '../l10n/l10n.dart';
import 'api_exception.dart';

/// The translated message for an API error. Add each feature's codes here as it is built.
String apiErrorMessage(AppLocalizations l10n, Object error) {
  if (error is! ApiException) return l10n.errorUnknown;
  return switch (error.code) {
    ApiException.network => l10n.errorNetwork,
    ApiException.timeout => l10n.errorTimeout,
    'invalid_refresh_token' || 'refresh_token_expired' => l10n.errorSessionExpired,
    'invalid_credentials' => l10n.errorInvalidCredentials,
    'username_taken' => l10n.errorUsernameTaken,
    'registration_disabled' => l10n.errorRegistrationDisabled,
    'too_many_requests' => l10n.errorTooManyRequests,
    'validation_error' => l10n.errorValidation,
    'invalid_current_password' => l10n.errorInvalidCurrentPassword,
    _ => l10n.errorUnknown,
  };
}
