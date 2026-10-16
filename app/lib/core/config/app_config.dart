import 'package:flutter/foundation.dart';

/// Build-time configuration.
abstract final class AppConfig {
  /// Where the API runs. Override with `--dart-define=API_URL=https://api.example.com`.
  ///
  /// Default (development): the Docker API on this computer. The Android emulator reaches the
  /// computer at 10.0.2.2, the iOS simulator at localhost.
  ///
  /// Release builds must use https: passwords and tokens are never sent unencrypted.
  static String get apiBaseUrl {
    const fromEnvironment = String.fromEnvironment('API_URL');
    final url = fromEnvironment.isNotEmpty
        ? fromEnvironment
        : (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        ? 'http://10.0.2.2:3000'
        : 'http://localhost:3000';
    checkSecureUrl(url, release: kReleaseMode);
    return url;
  }

  /// Stops a release build that would talk to the API over plain http.
  @visibleForTesting
  static void checkSecureUrl(String url, {required bool release}) {
    if (release && Uri.parse(url).scheme != 'https') {
      throw StateError(
        'Release builds need an https API address. Build with --dart-define=API_URL=https://... (got $url)',
      );
    }
  }
}
