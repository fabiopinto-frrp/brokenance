import 'package:flutter/foundation.dart';

/// Build-time configuration.
abstract final class AppConfig {
  /// Where the API runs. Override with `--dart-define=API_URL=https://api.example.com`.
  ///
  /// Default (development): the Docker API on this computer. The Android emulator reaches the
  /// computer at 10.0.2.2, the iOS simulator at localhost.
  static String get apiBaseUrl {
    const fromEnvironment = String.fromEnvironment('API_URL');
    if (fromEnvironment.isNotEmpty) return fromEnvironment;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }
}
