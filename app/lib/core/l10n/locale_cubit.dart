import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../l10n/generated/app_localizations.dart';
import '../storage/app_preferences.dart';

/// The app language: Portuguese, English, or null to follow the device.
/// When the device uses another language, the app falls back to English.
class LocaleCubit extends Cubit<Locale?> {
  LocaleCubit(this._preferences) : super(_read(_preferences.locale));

  final AppPreferences _preferences;

  static Locale? _read(String? code) {
    final supported = AppLocalizations.supportedLocales.map((locale) => locale.languageCode);
    return code != null && supported.contains(code) ? Locale(code) : null;
  }

  /// Pass null to follow the device language again.
  Future<void> setLocale(Locale? locale) async {
    emit(locale);
    await _preferences.setLocale(locale?.languageCode);
  }
}
