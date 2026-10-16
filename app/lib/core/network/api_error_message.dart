import '../l10n/l10n.dart';
import 'api_exception.dart';

/// The translated message for an API error. Features add their own codes here as they are
/// built (for example `invalid_credentials` with the login screen).
String apiErrorMessage(AppLocalizations l10n, Object error) {
  if (error is! ApiException) return l10n.errorUnknown;
  return switch (error.code) {
    ApiException.network => l10n.errorNetwork,
    ApiException.timeout => l10n.errorTimeout,
    'invalid_refresh_token' || 'refresh_token_expired' => l10n.errorSessionExpired,
    _ => l10n.errorUnknown,
  };
}
