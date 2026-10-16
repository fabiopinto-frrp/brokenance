import 'package:shared_preferences/shared_preferences.dart';

/// Small, non-secret settings kept on the device (theme, language, hidden balance).
/// Tokens are NOT stored here: they go in [SessionStorage] (the secure keychain/keystore).
class AppPreferences {
  AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _themeModeKey = 'theme_mode';
  static const _localeKey = 'locale';
  static const _balanceHiddenKey = 'balance_hidden';

  static Future<AppPreferences> load() async => AppPreferences(await SharedPreferences.getInstance());

  /// 'system', 'light' or 'dark'. Null when never set.
  String? get themeMode => _prefs.getString(_themeModeKey);
  Future<void> setThemeMode(String value) => _prefs.setString(_themeModeKey, value);

  /// 'pt' or 'en'. Null means "follow the device".
  String? get locale => _prefs.getString(_localeKey);
  Future<void> setLocale(String? value) =>
      value == null ? _prefs.remove(_localeKey) : _prefs.setString(_localeKey, value);

  /// Whether the current balance is hidden behind dots (the eye button).
  bool get balanceHidden => _prefs.getBool(_balanceHiddenKey) ?? false;
  Future<void> setBalanceHidden(bool value) => _prefs.setBool(_balanceHiddenKey, value);
}
